import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../data/youtube_service.dart';

class YoutubeSearchScreen extends StatefulWidget {
  const YoutubeSearchScreen({super.key});

  @override
  State<YoutubeSearchScreen> createState() => _YoutubeSearchScreenState();
}

class _YoutubeSearchScreenState extends State<YoutubeSearchScreen> {
  final _service = YoutubeService();
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  List<YoutubeSearchResult> _results = [];
  bool _searching = false;
  bool _hasSearched = false;
  bool _loadingMore = false;
  final Map<String, _DownloadState> _downloads = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    for (final ds in _downloads.values) {
      ds.token.cancel();
    }
    _controller.dispose();
    _scrollController.dispose();
    _service.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!mounted) return;
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _search() async {
    final q = _controller.text.trim();
    if (q.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _searching = true;
      _results = [];
      _hasSearched = false;
    });
    try {
      final results = await _service.search(q);
      if (mounted) {
        setState(() {
          _results = results;
          _hasSearched = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _hasSearched = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _searching || !_hasSearched) return;
    setState(() => _loadingMore = true);
    try {
      final more = await _service.loadMore();
      if (mounted && more.isNotEmpty) {
        setState(() => _results.addAll(more));
      }
    } catch (_) {
      // silently ignore load-more errors
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _download(YoutubeSearchResult result) async {
    final token = CancellationToken();
    if (mounted) {
      setState(() => _downloads[result.videoId] = _DownloadState(0.0, token));
    }
    try {
      await _service.downloadAudio(
        result,
        cancellationToken: token,
        onProgress: (p) {
          if (mounted && !token.isCancelled) {
            setState(
                () => _downloads[result.videoId] = _DownloadState(p, token));
          }
        },
      );
      if (mounted) {
        setState(
            () => _downloads[result.videoId] = _DownloadState(1.0, token));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${result.title}" added to library')),
        );
      }
    } on CancelledException {
      if (mounted) setState(() => _downloads.remove(result.videoId));
    } catch (e) {
      if (mounted) {
        setState(() => _downloads.remove(result.videoId));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e')),
        );
      }
    }
  }

  void _cancelDownload(String videoId) {
    _downloads[videoId]?.token.cancel();
  }

  String _formatDuration(Duration? d) {
    if (d == null) return '';
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('YouTube')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Search or paste YouTube URL...',
                prefixIcon: const Icon(Icons.youtube_searched_for, size: 22),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search_rounded),
                  onPressed: _search,
                ),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
            ),
          ),
          if (_searching)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_results.isEmpty && _hasSearched)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off_rounded,
                        size: 56,
                        color: theme.colorScheme.onSurfaceVariant
                            .withAlpha(120)),
                    const SizedBox(height: 16),
                    Text('No results found',
                        style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
            )
          else if (_results.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.youtube_searched_for,
                        size: 64,
                        color: theme.colorScheme.onSurfaceVariant
                            .withAlpha(100)),
                    const SizedBox(height: 16),
                    Text('Search for music to download',
                        style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _results.length + (_loadingMore ? 1 : 0),
                itemBuilder: (context, i) {
                  if (i == _results.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final r = _results[i];
                  final ds = _downloads[r.videoId];
                  final progress = ds?.progress;
                  final isDone = progress == 1.0;
                  final isDownloading = progress != null && !isDone;

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: r.thumbnailUrl != null
                          ? CachedNetworkImage(
                              imageUrl: r.thumbnailUrl!,
                              width: 80,
                              height: 52,
                              fit: BoxFit.cover,
                              placeholder: (ctx, url) => Container(
                                width: 80,
                                height: 52,
                                color: theme.colorScheme.surfaceContainerHighest,
                              ),
                              errorWidget: (ctx, url, err) =>
                                  _ThumbnailFallback(theme: theme),
                            )
                          : _ThumbnailFallback(theme: theme),
                    ),
                    title: Text(
                      r.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w500, fontSize: 14),
                    ),
                    subtitle: Text(
                      '${r.channelName}${r.duration != null ? '  ·  ${_formatDuration(r.duration)}' : ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    trailing: SizedBox(
                      width: 52,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: isDownloading
                            ? GestureDetector(
                                key: const ValueKey('downloading'),
                                onTap: () => _cancelDownload(r.videoId),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    CircularProgressIndicator(
                                      value: progress,
                                      strokeWidth: 2.5,
                                    ),
                                    Text(
                                      '${(progress * 100).toInt()}%',
                                      style: const TextStyle(fontSize: 9),
                                    ),
                                  ],
                                ),
                              )
                            : isDone
                                ? const Icon(
                                    key: ValueKey('done'),
                                    Icons.check_circle_rounded,
                                    color: Colors.greenAccent,
                                    size: 28,
                                  )
                                : IconButton(
                                    key: const ValueKey('idle'),
                                    icon: const Icon(
                                        Icons.download_rounded,
                                        size: 26),
                                    onPressed: () => _download(r),
                                  ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _DownloadState {
  final double progress;
  final CancellationToken token;
  const _DownloadState(this.progress, this.token);
}

class _ThumbnailFallback extends StatelessWidget {
  final ThemeData theme;
  const _ThumbnailFallback({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 52,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
      ),
      child: const Icon(Icons.music_video_rounded, size: 24),
    );
  }
}
