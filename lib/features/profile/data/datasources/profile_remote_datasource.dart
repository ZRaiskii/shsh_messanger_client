import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/data/services/TokenManager.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/utils/constants.dart';
import '../models/profile_model.dart';

abstract class ProfileRemoteDataSource {
  Future<ProfileModel> getProfile(String userId);
  Future<void> updateProfile(String userId, ProfileModel profile);
  Future<String> uploadAvatar(String userId, File file);
  Future<void> deleteAvatar(String userId);
  Future<void> updateEmoji(String userId, String emoji);
  Future<void> updatePremium(String userId, bool isPremium);
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final http.Client client;

  ProfileRemoteDataSourceImpl({required this.client});

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedUser = prefs.getString('cached_user');
    if (cachedUser != null) {
      final token =
          UserModel.fromJson(json.decode(cachedUser) as Map<String, dynamic>)
              .token;
      return {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
    } else {
      throw ServerException('Токен недоступен');
    }
  }

  Future<String> getCachedUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedUser = prefs.getString('cached_user');
    if (cachedUser != null) {
      return UserModel.fromJson(json.decode(cachedUser) as Map<String, dynamic>)
          .id;
    }
    return '';
  }

  Future<http.Response> _handleRequestWithTokenRefresh(
      Future<http.Response> Function() request) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedUser = prefs.getString('cached_user');
    if (cachedUser == null) {
      throw CacheException();
    }

    final token =
        UserModel.fromJson(json.decode(cachedUser) as Map<String, dynamic>)
            .token;
    if (token.isEmpty) {
      throw CacheException();
    }

    http.Response response = await request();

    if (response.statusCode == 401) {
      await TokenManager.refreshToken();

      final updatedCachedUser = prefs.getString('cached_user');
      if (updatedCachedUser == null) {
        throw CacheException();
      }
      final updatedToken = UserModel.fromJson(
              json.decode(updatedCachedUser) as Map<String, dynamic>)
          .token;
      if (updatedToken.isEmpty) {
        throw CacheException();
      }

      response = await request();
    }

    return response;
  }

  @override
  Future<ProfileModel> getProfile(String userId) async {
    try {
      final response = await _handleRequestWithTokenRefresh(() async {
        final headers = await _getHeaders();
        return await client.get(
          Uri.parse(
              '${Constants.baseUrl}${Constants.getUserProfileEndpoint}$userId'),
          headers: headers,
        );
      });

      if (response.statusCode == 200) {
        return ProfileModel.fromJson(
            json.decode(utf8.decode(response.bodyBytes)));
      } else {
        throw ServerException(response.statusCode.toString());
      }
    } catch (e) {
      throw ServerException();
    }
  }

  @override
  Future<void> updateProfile(String userId, ProfileModel profile) async {
    try {
      final response = await _handleRequestWithTokenRefresh(() async {
        final headers = await _getHeaders();

        String gender = profile.gender ?? "М";
        if (gender == "М") {
          gender = "MALE";
        } else if (gender == "Ж") {
          gender = "FEMALE";
        }

        String dateOfBirth =
            profile.dateOfBirth!.toIso8601String().split('T')[0];

        final updateRequest = UpdateUserProfileRequest(
          username: profile.username,
          email: profile.email,
          descriptionOfProfile: profile.descriptionOfProfile,
          avatarUrl: profile.avatarUrl,
          chatWallpaperUrl: profile.chatWallpaperUrl ?? "",
          gender: gender,
          dateOfBirth: dateOfBirth,
        );

        return await client.post(
          Uri.parse(
              '${Constants.baseUrl}${Constants.updateUserProfileEndpoint}'),
          headers: headers,
          body: json.encode(updateRequest.toJson()),
        );
      });

      if (response.statusCode != 200) {
        throw ServerException();
      }
    } catch (e) {
      throw ServerException();
    }
  }

  @override
  Future<String> uploadAvatar(String userId, File file) async {
    var userId = await getCachedUserId();
    print('userId on post = $userId');

    final headers = await _getHeaders();
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('${Constants.baseUrl}/ups/api/photos/upload-avatar/$userId'),
    );
    request.headers.addAll(headers);
    request.files.add(
      http.MultipartFile(
        'file',
        file.readAsBytes().asStream(),
        file.lengthSync(),
        filename: file.path.split('/').last,
        contentType: MediaType('image', 'jpeg'),
      ),
    );
    print('send');
    var response = await request.send();
    print('sended');
    final answer = await response.stream.bytesToString();

    print('status = ${response.statusCode.toString()}');
    print('answer = $answer');

    if (response.statusCode == 200) {
      return await response.stream.bytesToString();
    } else {
      throw ServerException();
    }
  }

  @override
  Future<void> deleteAvatar(String userId) async {
    try {
      final response = await _handleRequestWithTokenRefresh(() async {
        final headers = await _getHeaders();
        return await client.delete(
          Uri.parse(
              '${Constants.baseUrl}${Constants.deleteAvatarEndpoint}$userId'),
          headers: headers,
        );
      });

      if (response.statusCode != 200) {
        throw ServerException();
      }
    } catch (e) {
      throw ServerException();
    }
  }

  @override
  Future<void> updateEmoji(String userId, String emoji) async {
    var userId = await getCachedUserId();
    try {
      final response = await _handleRequestWithTokenRefresh(() async {
        final headers = await _getHeaders();
        return await client.patch(
          Uri.parse(
              '${Constants.baseUrl}${Constants.updateUserEmojiEndpoint}/$userId/emoji'),
          headers: headers,
          body: json.encode({'emoji': emoji}),
        );
      });
      if (response.statusCode != 200) {
        throw ServerException(response.body);
      }
    } catch (e) {
      throw ServerException();
    }
  }

  @override
  Future<void> updatePremium(String userId, bool isPremium) async {
    try {
      final response = await _handleRequestWithTokenRefresh(() async {
        final headers = await _getHeaders();
        return await client.patch(
          Uri.parse(
              '${Constants.baseUrl}${Constants.updateUserPremiumEndpoint}$userId'),
          headers: headers,
          body: json.encode({'changePremium': isPremium}),
        );
      });

      if (response.statusCode != 200) {
        throw ServerException();
      }
    } catch (e) {
      throw ServerException();
    }
  }
}

class UpdateUserProfileRequest {
  final String username;
  final String email;
  final String descriptionOfProfile;
  final String avatarUrl;
  final String chatWallpaperUrl;
  final String gender;
  final String dateOfBirth;

  UpdateUserProfileRequest({
    required this.username,
    required this.email,
    required this.descriptionOfProfile,
    required this.avatarUrl,
    required this.chatWallpaperUrl,
    required this.gender,
    required this.dateOfBirth,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
      'descriptionOfProfile': descriptionOfProfile,
      'avatarUrl': avatarUrl,
      'chatWallpaperUrl': chatWallpaperUrl,
      'gender': gender,
      'dateOfBirth': dateOfBirth,
    };
  }
}
