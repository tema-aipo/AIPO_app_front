import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ipo_service.dart';
import '../services/user_service.dart';

// 선택된 필터 인덱스 (0: 최근 상장순, 1: 청약 진행/예정순, 2: 관심 종목순)
final homeFilterProvider = StateProvider<int>((ref) => 0);

// 홈 데이터 상태
class HomeData {
  final Map<String, dynamic> raw;
  final List<dynamic> featuredIpos;
  final List<dynamic> trendingIpos;
  final List<dynamic> attractivenessItems;

  const HomeData({
    required this.raw,
    required this.featuredIpos,
    required this.trendingIpos,
    required this.attractivenessItems,
  });
}

const homeFilterKeys = ['recentGrowth', 'subscriptionUpcoming', 'favorite'];

// 홈 데이터 Notifier — 필터가 바뀌면 자동으로 재조회
class HomeDataNotifier extends AsyncNotifier<HomeData> {

  @override
  Future<HomeData> build() async {
    final filterIndex = ref.watch(homeFilterProvider);
    return _fetch(homeFilterKeys[filterIndex]);
  }

  Future<HomeData> _fetch(String filterKey) async {
    if (filterKey == 'favorite') {
      final results = await Future.wait([
        IpoService.instance.getHomeData('favorite'),
        UserService.instance.getFavorites(),
      ]);
      final data = results[0] as Map<String, dynamic>;
      final favorites = results[1] as List<dynamic>;
      return HomeData(
        raw: data,
        featuredIpos: data['featuredIpos'] ?? [],
        trendingIpos: data['trendingIpos'] ?? [],
        attractivenessItems: favorites,
      );
    }

    final data = await IpoService.instance.getHomeData(filterKey);
    return HomeData(
      raw: data,
      featuredIpos: data['featuredIpos'] ?? [],
      trendingIpos: data['trendingIpos'] ?? [],
      attractivenessItems:
          data['attractivenessItems'] ?? data['attractiveness']?['items'] ?? [],
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() {
      final filterIndex = ref.read(homeFilterProvider);
      return _fetch(homeFilterKeys[filterIndex]);
    });
  }
}

final homeDataProvider =
    AsyncNotifierProvider<HomeDataNotifier, HomeData>(HomeDataNotifier.new);
