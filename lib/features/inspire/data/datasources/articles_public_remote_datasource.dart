import 'package:dio/dio.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../models/public_article_feed.dart';
import '../models/public_article_detail.dart';

class ArticlesPublicRemoteDataSource {
  final DioClient _dioClient;

  ArticlesPublicRemoteDataSource({required DioClient dioClient})
    : _dioClient = dioClient;

  Future<PublicArticleFeedResponse> getPublicFeed({
    String? section,
    String? tag,
    String? seriesId,
    String? date,
    String? query,
    int limit = 20,
    ArticlesPublicCursor? cursor,
    String? from,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        if (section != null) 'section': section,
        if (tag != null) 'tag': tag,
        if (seriesId != null) 'seriesId': seriesId,
        if (date != null) 'date': date,
        if (query != null) 'q': query,
        'limit': limit,
        if (from != null) 'from': from,
        if (cursor != null) ...cursor.toQueryParameters(),
      };

      final response = await _dioClient.get(
        '/articles/public',
        queryParameters: queryParameters,
      );

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return PublicArticleFeedResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
      }

      throw ApiException.unknown(message: 'Gagal memuat artikel');
    } on DioException catch (e) {
      if (e.error is ApiException) {
        throw e.error as ApiException;
      }
      throw ApiException.unknown(message: 'Gagal memuat artikel: ${e.message}');
    }
  }

  Future<PublicArticleDetail> getPublicBySlug(String slug) async {
    try {
      final response = await _dioClient.get('/articles/public/$slug');

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return PublicArticleDetail.fromJson(
          response.data as Map<String, dynamic>,
        );
      }

      throw ApiException.unknown(message: 'Gagal memuat artikel');
    } on DioException catch (e) {
      if (e.error is ApiException) {
        throw e.error as ApiException;
      }
      throw ApiException.unknown(message: 'Gagal memuat artikel: ${e.message}');
    }
  }
}
