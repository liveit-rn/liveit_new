import 'package:flutter/foundation.dart';

@immutable
class PublicArticleAsset {
  final String id;
  final String kind;
  final String url;
  final String mime;
  final int sizeBytes;
  final int? width;
  final int? height;
  final double? durationSeconds;

  const PublicArticleAsset({
    required this.id,
    required this.kind,
    required this.url,
    required this.mime,
    required this.sizeBytes,
    required this.width,
    required this.height,
    required this.durationSeconds,
  });

  factory PublicArticleAsset.fromJson(Map<String, dynamic> json) {
    return PublicArticleAsset(
      id: json['id'] as String,
      kind: json['kind'] as String,
      url: json['url'] as String,
      mime: json['mime'] as String,
      sizeBytes: _readInt(json, 'sizeBytes'),
      width: _readNullableInt(json, 'width'),
      height: _readNullableInt(json, 'height'),
      durationSeconds: _readNullableDouble(json, 'durationSeconds'),
    );
  }

  static int _readInt(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }

  static int? _readNullableInt(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return null;
  }

  static double? _readNullableDouble(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return null;
  }
}

@immutable
class PublicArticleDetail {
  final String id;
  final String title;
  final String slug;
  final String section;
  final String? subtitle;
  final String? canonicalUrl;
  final String? snippet;
  final String? coverUrl;
  final String? authorDisplayName;
  final List<String> tags;
  final int wordCount;
  final int readingTimeMinutes;
  final int contentVersion;
  final DateTime publishedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> contentJson;
  final List<PublicArticleAsset> assets;

  const PublicArticleDetail({
    required this.id,
    required this.title,
    required this.slug,
    required this.section,
    required this.subtitle,
    required this.canonicalUrl,
    required this.snippet,
    required this.coverUrl,
    required this.authorDisplayName,
    required this.tags,
    required this.wordCount,
    required this.readingTimeMinutes,
    required this.contentVersion,
    required this.publishedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.contentJson,
    required this.assets,
  });

  factory PublicArticleDetail.fromJson(Map<String, dynamic> json) {
    final rawContent = json['contentJson'];
    final contentJson = rawContent is Map<String, dynamic>
        ? rawContent
        : <String, dynamic>{'type': 'doc', 'content': const []};

    final rawAssets = json['assets'];
    final assets = rawAssets is List
        ? rawAssets
              .whereType<Map<String, dynamic>>()
              .map(PublicArticleAsset.fromJson)
              .toList(growable: false)
        : const <PublicArticleAsset>[];

    return PublicArticleDetail(
      id: json['id'] as String,
      title: json['title'] as String,
      slug: json['slug'] as String,
      section: json['section'] as String,
      subtitle: _readString(json, 'subtitle'),
      canonicalUrl: _readString(json, 'canonicalUrl'),
      snippet: _readString(json, 'snippet'),
      coverUrl: _readString(json, 'coverUrl'),
      authorDisplayName: _readString(json, 'authorDisplayName'),
      tags: _readStringList(json['tags']),
      wordCount: _readInt(json, 'wordCount'),
      readingTimeMinutes: _readInt(json, 'readingTimeMinutes'),
      contentVersion: _readInt(json, 'contentVersion'),
      publishedAt: DateTime.parse(json['publishedAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      contentJson: contentJson,
      assets: assets,
    );
  }

  static String? _readString(Map<String, dynamic> json, String key) {
    final value = json[key];
    return value is String ? value : null;
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
