import 'package:flutter/material.dart';

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
}

class AuthManager {
  static final AuthManager instance = AuthManager._internal();
  AuthManager._internal();

  final ValueNotifier<UserModel?> currentUser = ValueNotifier(null);

  bool login(String id, String password) {
    // 임시 계정 매칭
    if (id == 'guest' && password == '1234') {
      currentUser.value = UserModel(
        id: 'guest',
        name: 'AIPO',
        email: 'guest@aipo.com',
        investmentType: '#안정형',
      );
      return true;
    }
    return false;
  }

  void updateInvestmentType(String newType) {
    if (currentUser.value != null) {
      currentUser.value = UserModel(
        id: currentUser.value!.id,
        name: currentUser.value!.name,
        email: currentUser.value!.email,
        investmentType: '#$newType', // Add hash as per mockup design
      );
    }
  }

  void logout() {
    currentUser.value = null;
  }
}
