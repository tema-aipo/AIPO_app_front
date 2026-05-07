import 'package:flutter/material.dart';
import '../network/auth_interceptor.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String investmentType;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.investmentType,
  });

  /// 백엔드 JSON 응답 → UserModel 변환
  factory UserModel.fromJson(Map<String, dynamic> json) {
    final rawType = json['investmentType'] as String? ?? '안정형';
    final loginId = json['loginId'] as String? ?? '';
    final fallbackId = (json['id'] ?? json['userId'] ?? '').toString();
    return UserModel(
      id: loginId.isNotEmpty ? loginId : fallbackId,
      name: json['name'] as String? ?? json['userName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      investmentType: rawType.startsWith('#') ? rawType : '#$rawType',
    );
  }
}

class AuthManager {
  static final AuthManager instance = AuthManager._internal();
  AuthManager._internal();

  final ValueNotifier<UserModel?> currentUser = ValueNotifier(null);
  UserModel? get user => currentUser.value;

  /// 백엔드 로그인 성공 후 호출 - 토큰 저장 및 유저 세팅
  Future<void> loginWithToken({
    required String accessToken,
    required String refreshToken,
    required UserModel user,
  }) async {
    await AuthInterceptor.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
    currentUser.value = user;
  }

  void updateInvestmentType(String newType) {
    if (currentUser.value != null) {
      currentUser.value = UserModel(
        id: currentUser.value!.id,
        name: currentUser.value!.name,
        email: currentUser.value!.email,
        investmentType: '#$newType',
      );
    }
  }

  Future<void> logout() async {
    await AuthInterceptor.clearTokens();
    currentUser.value = null;
  }
}
