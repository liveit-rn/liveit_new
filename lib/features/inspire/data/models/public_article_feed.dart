import 'package:flutter/foundation.dart';

@immutable
class ArticlesPublicCursor {
  final DateTime createdAt;
  final String id;

  const ArticlesPublicCursor({required this.createdAt, required this.id});

  factory ArticlesPublicCursor.fromJson(Map<String, dynamic> json) {
    return ArticlesPublicCursor(
      createdAt: DateTime.parse(json['createdAt'] as String),
      id: json['id'] as String,
    );
  }

  Map<String, dynamic> toQueryParameters() {
    return {'cursorCreatedAt': createdAt.toIso8601String(), 'cursorId': id};
  }
}

@immutable
class PublicArticleFeedItem {
  final String id;
  final String title;
  final String slug;
  final String section;
  final String? subtitle;
  final String? snippet;
  final String? coverUrl;
  final String? authorDisplayName;
  final List<String> tags;
  final int wordCount;
  final int readingTimeMinutes;
  final DateTime publishedAt;

  const PublicArticleFeedItem({
    required this.id,
    required this.title,
    required this.slug,
    required this.section,
    required this.subtitle,
    required this.snippet,
    required this.coverUrl,
    required this.authorDisplayName,
    required this.tags,
    required this.wordCount,
    required this.readingTimeMinutes,
    required this.publishedAt,
  });

  factory PublicArticleFeedItem.fromJson(Map<String, dynamic> json) {
    final coverUrl = _readString(json, 'coverUrl') ??
        _readStringMap(json, 'coverAsset', 'url');

    return PublicArticleFeedItem(
      id: json['id'] as String,
      title: json['title'] as String,
      slug: json['slug'] as String,
      section: json['section'] as String,
      subtitle: _readString(json, 'subtitle'),
      snippet: _readString(json, 'snippet'),
      coverUrl: coverUrl,
      authorDisplayName: _readString(json, 'authorDisplayName'),
      tags: _readStringList(json['tags']),
      wordCount: _readInt(json, 'wordCount'),
      readingTimeMinutes: _readInt(json, 'readingTimeMinutes'),
      publishedAt: DateTime.parse(json['publishedAt'] as String),
    );
  }

  static String? _readString(Map<String, dynamic> json, String key) {
    final value = json[key];
    return value is String ? value : null;
  }

  static String? _readStringMap(
    Map<String, dynamic> json,
    String mapKey,
    String key,
  ) {
    final map = json[mapKey];
    if (map is Map<String, dynamic>) {
      final value = map[key];
      return value is String ? value : null;
    }
    return null;
  }

  static List<String> _readStringList(Object? value) {
    if (value is List) {
      return value.whereType<String>().toList(growable: false);
    }
    return const [];
  }

  static int _readInt(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }
}

@immutable
class PublicArticleFeedResponse {
  final List<PublicArticleFeedItem> items;
  final ArticlesPublicCursor? nextCursor;

  const PublicArticleFeedResponse({
    required this.items,
    required this.nextCursor,
  });

  factory PublicArticleFeedResponse.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = rawItems is List
        ? rawItems
            .whereType<Map<String, dynamic>>()
            .map(PublicArticleFeedItem.fromJson)
            .toList(growable: false)
        : const <PublicArticleFeedItem>[];

    final rawCursor = json['nextCursor'];
    final nextCursor = rawCursor is Map<String, dynamic>
        ? ArticlesPublicCursor.fromJson(rawCursor)
        : null;

    return PublicArticleFeedResponse(items: items, nextCursor: nextCursor);
  }
}
