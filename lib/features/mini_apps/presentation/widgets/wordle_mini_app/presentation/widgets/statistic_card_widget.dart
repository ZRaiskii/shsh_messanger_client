import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../../../core/error/exceptions.dart';
import '../../../../../../../core/utils/AppColors.dart';
import '../../../../../../../core/utils/constants.dart';
import '../../../../../../auth/data/models/user_model.dart';
import '../../../../../../auth/data/services/TokenManager.dart';
import '../../../../../../profile/data/models/profile_model.dart';
import '../../../../../../settings/data/services/theme_manager.dart';
import '../../data/wordle_manager.dart';

class StatisticsCard extends StatefulWidget {
  final WordleManager wordleManager;

  StatisticsCard({required this.wordleManager});

  @override
  _StatisticsCardState createState() => _StatisticsCardState();
}

class _StatisticsCardState extends State<StatisticsCard>
    with SingleTickerProviderStateMixin {
  Future<ProfileModel>? _profileFuture;
  bool _isLoading = true;
  String? _error;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.forward();
  }

  Future<void> _loadProfileData() async {
    try {
      final userId = await getCachedUserId();
      _profileFuture = getProfile(userId);
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Ошибка загрузки данных';
      });
    }
  }

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

  Future<ProfileModel> getProfile(String userId) async {
    try {
      final response = await _handleRequestWithTokenRefresh(() async {
        final headers = await _getHeaders();
        return await http.Client().get(
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

  Widget _buildStatItem(
      IconData icon, String value, String label, Color color) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: color.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = isWhiteNotifier.value ? AppColors.light() : AppColors.dark();

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        color: colors.cardColor,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: FutureBuilder<ProfileModel>(
            future: _profileFuture,
            builder: (context, snapshot) {
              if (_profileFuture == null) {
                return _buildShimmerLoader();
              } else if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildShimmerLoader();
              } else if (snapshot.hasError) {
                return _buildErrorState(colors);
              } else if (snapshot.hasData) {
                final profile = snapshot.data!;
                return Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Colors.blueAccent, Colors.purpleAccent],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.2),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(3.0),
                            child: CircleAvatar(
                              radius: 30,
                              backgroundColor: colors.cardColor,
                              child: profile.avatarUrl.isNotEmpty
                                  ? ClipOval(
                                      child: CachedNetworkImage(
                                        imageUrl: profile.avatarUrl,
                                        fit: BoxFit.cover,
                                        width: 60,
                                        height: 60,
                                        placeholder: (context, url) =>
                                            CircularProgressIndicator(
                                                color: Colors.white),
                                        errorWidget: (context, url, error) =>
                                            Icon(Icons.person, size: 30),
                                      ),
                                    )
                                  : Icon(Icons.person, size: 30),
                            ),
                          ),
                        ),
                        SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile.username,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: colors.textColor,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                profile.descriptionOfProfile,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: colors.textColor.withOpacity(0.8),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Divider(
                        color: colors.textColor.withOpacity(0.1), height: 1),
                    SizedBox(height: 20),
                    Wrap(
                      spacing: 20,
                      runSpacing: 20,
                      children: [
                        _buildStatItem(
                          Icons.emoji_events_rounded,
                          widget.wordleManager.totalWins.toString(),
                          'Побед',
                          Colors.amber,
                        ),
                        _buildStatItem(
                          Icons.games_rounded,
                          widget.wordleManager.totalGames.toString(),
                          'Игр',
                          Colors.blue,
                        ),
                        _buildStatItem(
                          Icons.local_fire_department_rounded,
                          widget.wordleManager.streak.toString(),
                          'Серия',
                          Colors.red,
                        ),
                      ],
                    ),
                  ],
                );
              }
              return SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerLoader() {
    return AnimatedContainer(
      duration: Duration(milliseconds: 800),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey[300]!,
            Colors.grey[100]!,
            Colors.grey[300]!,
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(radius: 30, backgroundColor: Colors.white),
              SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 120,
                      height: 24,
                      color: Colors.white,
                    ),
                    SizedBox(height: 8),
                    Container(
                      width: 80,
                      height: 16,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Divider(),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              3,
              (index) => Container(
                width: 100,
                height: 60,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(AppColors colors) {
    return Column(
      children: [
        Icon(Icons.error_outline_rounded, size: 40, color: Colors.redAccent),
        SizedBox(height: 16),
        Text(
          'Ошибка загрузки данных',
          style: TextStyle(
            color: colors.textColor,
            fontSize: 16,
          ),
        ),
        SizedBox(height: 8),
        ElevatedButton.icon(
          icon: Icon(Icons.refresh_rounded),
          label: Text('Повторить'),
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          onPressed: _loadProfileData,
        ),
      ],
    );
  }
}
