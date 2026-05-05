import 'package:flutter/material.dart';

/// ⚠️ 현재 이 클래스는 실제 API 연동으로 인해 사용되지 않지만,
/// 기존 코드와의 호환성을 위해 에러가 나지 않도록 최소한의 껍데기만 남겨둡니다.
class FavoriteManager {
  static final FavoriteManager instance = FavoriteManager._internal();
  FavoriteManager._internal();

  final ValueNotifier<List<dynamic>> favoritesNotifier = ValueNotifier([]);

  bool isFavorite(String name) => false;

  void toggleFavorite(String name) {
    // 실제 로직은 IpoService.toggleFavorite를 사용하세요.
  }
}
