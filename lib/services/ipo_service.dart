import 'package:dio/dio.dart';
import '../network/dio_client.dart';
import '../network/api_endpoints.dart';

class IpoService {
  static final IpoService instance = IpoService._();
  IpoService._();

  final Dio _dio = DioClient.instance.dio;

  Future<Map<String, dynamic>> getHomeData(String tab) async {
    final response = await _dio.get(
      ApiEndpoints.home,
      queryParameters: {'tab': tab},
    );
    final data = response.data as Map<String, dynamic>;

    return {
      'featuredIpos': data['featuredIpos'] ?? data['featured'] ?? [],
      'trendingIpos': data['trendingIpos'] ?? data['trending'] ?? [],
      'attractiveness': data['attractiveness'] ??
          {
            'items': data['attractivenessItems'] ?? data['attractive'] ?? [],
          },
      'attractivenessItems': data['attractivenessItems'] ??
          data['attractive'] ??
          (data['attractiveness']?['items']) ??
          [],
    };
  }

  Future<Map<String, dynamic>> getIpoList({
    int page = 0,
    int size = 20,
    String? keyword,
    String sort = 'subscriptionStartDate',
    String direction = 'asc',
  }) async {
    final response = await _dio.get(
      ApiEndpoints.ipos,
      queryParameters: {
        'page': page,
        'size': size,
        if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
        'sort': sort,
        'direction': direction,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getIpoDetail(String ipoId) async {
    final response = await _dio.get(ApiEndpoints.ipoDetail(ipoId));
    return response.data as Map<String, dynamic>;
  }

  /// [month] : 'YYYY-MM' 형식 (예: '2026-04')
  Future<Map<String, dynamic>> getCalendarData(String month,
      {String? selectedDate}) async {
    final parts = month.split('-');
    final int year = int.parse(parts[0]);
    final int monthInt = int.parse(parts[1]);

    final response = await _dio.get(
      ApiEndpoints.calendar,
      queryParameters: {
        'year': year,
        'month': monthInt,
        if (selectedDate != null) 'selectedDate': selectedDate,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<void> toggleFavorite(String ipoId, bool isFavorite) async {
    final String url = '/users/me/favorites/$ipoId';
    if (isFavorite) {
      await _dio.post(url);
    } else {
      await _dio.delete(url);
    }
  }
}
