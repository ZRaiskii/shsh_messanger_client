// lib/features/settings/data/datasources/settings_remote_datasource.dart
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shsh_social/features/settings/data/models/settings_model.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/utils/constants.dart';

abstract class SettingsRemoteDataSource {
  Future<SettingsModel> fetchSettings();
}

class SettingsRemoteDataSourceImpl implements SettingsRemoteDataSource {
  final http.Client client;

  SettingsRemoteDataSourceImpl({required this.client});

  @override
  Future<SettingsModel> fetchSettings() async {
    final response = await client.get(
      Uri.parse('${Constants.baseUrl}/settings'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return SettingsModel.fromJson(
          json.decode(utf8.decode(response.bodyBytes)));
    } else {
      throw ServerException();
    }
  }
}
