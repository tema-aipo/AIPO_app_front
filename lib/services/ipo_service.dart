import 'package:dio/dio.dart';
import '../network/dio_client.dart';
import '../network/api_endpoints.dart';

/// 공모주 관련 API 호출을 담당하는 서비스 클래스
class IpoService {
  final Dio _dio = DioClient.instance.dio;

  // ── 홈 화면 데이터 조회 ───────────────────────────────
  /// 홈 화면의 대표 공모주, 트렌딩, 매력지수 탭 데이터를 가져옵니다.
  /// [tab] : 'recentGrowth', 'subscriptionUpcoming', 'favorite' 중 하나 (기본값 'recentGrowth')
  Future<Map<String, dynamic>> getHomeData({String tab = 'recentGrowth'}) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.home,
        queryParameters: {'tab': tab},
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  // ── 공모주 목록 조회 ──────────────────────────────────
  /// 검색, 정렬, 페이지네이션을 포함한 공모주 목록을 가져옵니다.
  Future<Map<String, dynamic>> getIpoList({
    int page = 0,
    int size = 20,
    String? keyword,
    String sort = 'subscriptionStartDate',
    String direction = 'asc',
  }) async {
    try {
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
    } catch (e) {
      rethrow;
    }
  }

  // ── 공모주 상세 조회 ──────────────────────────────────
  /// 특정 공모주의 상세 정보(수요예측, 일정, 증거금 등)를 가져옵니다.
  Future<Map<String, dynamic>> getIpoDetail(String ipoId) async {
    try {
      final response = await _dio.get(ApiEndpoints.ipoDetail(ipoId));
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  // ── 캘린더 데이터 조회 ────────────────────────────────
  /// 특정 월의 공모주 일정(청약, 환불, 상장 등)을 가져옵니다.
  /// [month] : 'YYYY-MM' 형식 (예: '2026-04')
  Future<List<dynamic>> getCalendarData(String month) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.calendar,
        queryParameters: {'month': month},
      );
      return response.data as List<dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  // ── 관심종목 토글 ─────────────────────────────────────
  /// 관심종목 등록/삭제 처리를 합니다.
  Future<void> toggleFavorite(String ipoId, bool isFavorite) async {
    try {
      final String url = '/users/me/favorites/$ipoId'; 
      if (isFavorite) {
        await _dio.post(url);
      } else {
        await _dio.delete(url);
      }
    } catch (e) {
      rethrow;
    }
  }
}
