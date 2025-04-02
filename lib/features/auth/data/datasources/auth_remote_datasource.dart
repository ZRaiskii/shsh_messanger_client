// lib/features/auth/data/datasources/auth_remote_datasource.dart
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shsh_social/core/utils/DeviceRegistration.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/utils/constants.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> register(String email, String username, String password);
  Future<UserModel> login(String email, String password);
  Future<UserModel> refreshToken(String refreshToken);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final http.Client client;

  AuthRemoteDataSourceImpl({required this.client});

  @override
  Future<UserModel> register(
      String email, String username, String password) async {
    try {
      final response = await client.post(
        Uri.parse('${Constants.baseUrl}${Constants.registrationEndpoint}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'username': username,
          'password': password,
          'confirmPassword': password,
        }),
      );

      if (response.statusCode == 200) {
        return UserModel(
            email: "", id: '', refreshToken: '', token: '', username: "");
      } else {
        throw ServerException();
      }
    } catch (e, stacktrace) {
      throw ServerException();
    }
  }

  @override
  Future<UserModel> login(String email, String password) async {
    final deviceId = await DeviceRegistration.getDeviceId();

    try {
      final response = await client.post(
        Uri.parse('${Constants.baseUrl}${Constants.loginEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
        body: json.encode({
          'email': email,
          'password': password,
          'deviceId': deviceId,
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(utf8.decode(response.bodyBytes));
        return UserModel(
          id: jsonResponse['userId'],
          email: email,
          username: '',
          token: jsonResponse['token'],
          refreshToken: jsonResponse['refreshToken'],
        );
      } else {
        throw ServerException(response.statusCode.toString());
      }
    } catch (e, stacktrace) {
      if (e.toString().contains("401")) {
        throw ServerException("Неверный логин или пароль!");
      } else {
        throw ServerException("Ошибка сервера!");
      }
    }
  }

  @override
  Future<UserModel> refreshToken(String refreshToken) async {
    final response = await client.post(
      Uri.parse('${Constants.baseUrl}${Constants.refreshTokenEndpoint}'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'refreshToken': refreshToken,
      }),
    );

    if (response.statusCode == 200) {
      return UserModel.fromJson(json.decode(utf8.decode(response.bodyBytes)));
    } else {
      throw ServerException();
    }
  }
}
