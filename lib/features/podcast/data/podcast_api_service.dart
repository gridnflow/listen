import 'package:dio/dio.dart';

class PodcastSearchResult {
  final String title;
  final String author;
  final String feedUrl;
  final String artworkUrl;

  const PodcastSearchResult({
    required this.title,
    required this.author,
    required this.feedUrl,
    required this.artworkUrl,
  });
}

class PodcastApiService {
  final Dio _dio;

  PodcastApiService(this._dio);

  Future<List<PodcastSearchResult>> search(String query) async {
    if (query.trim().isEmpty) return [];

    final response = await _dio.get(
      'https://itunes.apple.com/search',
      queryParameters: {
        'term': query,
        'media': 'podcast',
        'limit': 20,
      },
    );

    final results = response.data['results'] as List<dynamic>;
    return results
        .where((r) => r['feedUrl'] != null)
        .map((r) => PodcastSearchResult(
              title: r['collectionName'] ?? '',
              author: r['artistName'] ?? '',
              feedUrl: r['feedUrl'] ?? '',
              artworkUrl: r['artworkUrl600'] ?? r['artworkUrl100'] ?? '',
            ))
        .toList();
  }
}
