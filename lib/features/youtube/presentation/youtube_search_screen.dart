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
  // videoId -> download progress (0.0–1.0), null = not downloading, 1.0 = done
  final Map<String, double> _downloadProgress = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _service.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
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
      setState(() {
        _results = results;
        _hasSearched = true;
      });
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
    setState(() => _downloadProgress[result.videoId] = 0.0);
    try {
      await _service.downloadAudio(
        result,
        onProgress: (p) {
          if (mounted) setState(() => _downloadProgress[result.videoId] = p);
        },
      );
      if (mounted) {
        setState(() => _downloadProgress[result.videoId] = 1.0);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${result.title}" added to library')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _downloadProgress.remove(result.videoId));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e')),
        );
      }
    }
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
    return Scaffold(
      appBar: AppBar(title: const Text('YouTube Download')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Search songs...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _search,
                ),
                border: const OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
            ),
          ),
          if (_searching)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_results.isEmpty && _hasSearched)
            const Expanded(child: Center(child: Text('No results found')))
          else
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _results.length + (_loadingMore ? 1 : 0),
                itemBuilder: (context, i) {
                  if (i == _results.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final r = _results[i];
                  final progress = _downloadProgress[r.videoId];
                  final isDone = progress == 1.0;
                  final isDownloading = progress != null && !isDone;

                  return ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: CachedNetworkImage(
                        imageUrl: r.thumbnailUrl!,
                        width: 72,
                        height: 48,
                        fit: BoxFit.cover,
                        placeholder: (ctx, url) => Container(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                        ),
                        errorWidget: (ctx, url, err) =>
                            const Icon(Icons.music_video),
                      ),
                    ),
                    title: Text(r.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                      '${r.channelName}${r.duration != null ? '  ·  ${_formatDuration(r.duration)}' : ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: SizedBox(
                      width: 48,
                      child: isDownloading
                          ? Stack(
                              alignment: Alignment.center,
                              children: [
                                CircularProgressIndicator(
                                  value: progress,
                                  strokeWidth: 2,
                                ),
                                Text(
                                  '${(progress * 100).toInt()}%',
                                  style: const TextStyle(fontSize: 9),
                                ),
                              ],
                            )
                          : isDone
                              ? const Icon(Icons.check_circle, color: Colors.green)
                              : IconButton(
                                  icon: const Icon(Icons.download_outlined),
                                  onPressed: () => _download(r),
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
