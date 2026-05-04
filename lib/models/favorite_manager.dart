import 'package:flutter/material.dart';
import '../screens/calendar_screen.dart'; // EventType
import '../screens/mypage_screen.dart'; // MyPageTask

class FavoriteManager {
  static final FavoriteManager instance = FavoriteManager._internal();
  FavoriteManager._internal();

  final ValueNotifier<List<MyPageTask>> favoritesNotifier = ValueNotifier([
    MyPageTask(
        score: 92,
        name: '스페이스테크놀로지',
        broker: '미래에셋증권',
        period: '04.08 ~ 04.09',
        type: EventType.subscription),
    MyPageTask(
        score: 85,
        name: '바이오메디컬',
        broker: '신영증권',
        period: '04.10 ~ 04.11',
        type: EventType.demandForecast),
    MyPageTask(
        score: 80,
        name: 'AI솔루션즈',
        broker: '한국투자증권',
        period: '04.15',
        type: EventType.listing),
  ]);

  // 카탈로그: 상세에서 이름만으로 찜 추가 시 모의로 채워넣을 스펙 딕셔너리
  final Map<String, MyPageTask> _catalog = {
    '스페이스테크놀로지': MyPageTask(score: 92, name: '스페이스테크놀로지', broker: '미래에셋증권', period: '04.08 ~ 04.09', type: EventType.subscription),
    '바이오메디컬': MyPageTask(score: 85, name: '바이오메디컬', broker: '신영증권', period: '04.10 ~ 04.11', type: EventType.demandForecast),
    'AI솔루션즈': MyPageTask(score: 80, name: 'AI솔루션즈', broker: '한국투자증권', period: '04.15', type: EventType.listing),
  };

  bool isFavorite(String name) {
    return favoritesNotifier.value.any((task) => task.name == name);
  }

  void toggleFavorite(String name) {
    List<MyPageTask> current = List.from(favoritesNotifier.value);
    
    if (isFavorite(name)) {
      current.removeWhere((task) => task.name == name);
    } else {
      // 추가
      MyPageTask generic = MyPageTask(score: 70, name: name, broker: '정보 수집중', period: '미정', type: EventType.favorite);
      current.insert(0, _catalog[name] ?? generic);
    }
    
    favoritesNotifier.value = current;
  }
}
