import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../../../core/utils/AppColors.dart';
import '../../../profile/domain/entities/profile.dart';
import '../../../settings/data/services/theme_manager.dart'; // Импортируем AppColors
import '../../data/models/photo_model.dart';
import 'expandable_text_widget.dart';
import 'full_screen_image_widget.dart';

class FullScreenProfileInfo extends StatefulWidget {
  final String userId;
  final Profile profile;
  final Future<void> Function() onPickImage;
  final Future<void> Function(String) onUpdateEmoji;
  final Future<void> Function(bool) onUpdatePremium;
  final List<PhotoModel> mediaUrls; // List of media URLs

  const FullScreenProfileInfo({
    super.key,
    required this.userId,
    required this.profile,
    required this.onPickImage,
    required this.onUpdateEmoji,
    required this.onUpdatePremium,
    required this.mediaUrls,
  });

  @override
  _FullScreenProfileInfoState createState() => _FullScreenProfileInfoState();
}

class _FullScreenProfileInfoState extends State<FullScreenProfileInfo>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isImageViewOpen = false;

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: 1, vsync: this); // Only one tab for now
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool get isFavoriteChat {
    return widget.userId == widget.profile.id;
  }

  @override
  Widget build(BuildContext context) {
    final colors = isWhiteNotifier.value ? AppColors.light() : AppColors.dark();

    return DefaultTabController(
      length: 1,
      child: Scaffold(
        backgroundColor: colors.backgroundColor,
        appBar: AppBar(
          title: Text(
            isFavoriteChat ? "" : widget.profile.username,
            style: TextStyle(color: colors.textColor),
          ),
          backgroundColor: colors.appBarColor,
          iconTheme: IconThemeData(color: colors.iconColor),
        ),
        body: Stack(
          children: [
            if (isFavoriteChat)
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildProfileHeader(context, colors),
                  ),
                  TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    labelColor: colors.primaryColor,
                    unselectedLabelColor: colors.textColor.withOpacity(0.5),
                    indicatorColor: colors.primaryColor,
                    tabs: [
                      Tab(text: 'Медиа'),
                      // Hide other tabs for now
                      // Tab(text: 'Избранное'),
                      // Tab(text: 'Файлы'),
                      // Tab(text: 'Ссылки'),
                      // Tab(text: 'Голосовые'),
                    ],
                  ),
                  SizedBox(
                    height: 400, // Set a fixed height for the TabBarView
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildMediaSection(colors),
                        // Hide other sections for now
                        // _buildFavoritesSection(),
                        // _buildFilesSection(),
                        // _buildLinksSection(),
                        // _buildVoiceSection(),
                      ],
                    ),
                  ),
                ],
              )
            else
              SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProfileHeader(context, colors),
                      const SizedBox(height: 16),
                      ExpandableText(
                        text: widget.profile.descriptionOfProfile,
                        style: TextStyle(color: colors.textColor),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoSection(context, colors),
                      const SizedBox(height: 16),
                      TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        labelColor: colors.primaryColor,
                        unselectedLabelColor: colors.textColor.withOpacity(0.5),
                        indicatorColor: colors.primaryColor,
                        tabs: [
                          Tab(text: 'Медиа'),
                          // Hide other tabs for now
                          // Tab(text: 'Избранное'),
                          // Tab(text: 'Файлы'),
                          // Tab(text: 'Ссылки'),
                          // Tab(text: 'Голосовые'),
                        ],
                      ),
                      SizedBox(
                        height: 400, // Set a fixed height for the TabBarView
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildMediaSection(colors),
                            // Hide other sections for now
                            // _buildFavoritesSection(),
                            // _buildFilesSection(),
                            // _buildLinksSection(),
                            // _buildVoiceSection(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_isImageViewOpen)
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                  child: Container(
                    color: colors.overlayColor.withOpacity(0.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, AppColors colors) {
    final bool isLottieEmoji =
        widget.profile.nicknameEmoji?.startsWith('assets/') ?? false;

    return Row(
      children: [
        GestureDetector(
          onTap: () {
            if (widget.profile.avatarUrl.isNotEmpty) {
              setState(() {
                _isImageViewOpen = true;
              });
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      FullScreenImageView(
                    imageUrl: widget.profile.avatarUrl,
                    onClose: () {
                      setState(() {
                        _isImageViewOpen = false;
                      });
                    },
                    timestamp: DateTime.now(),
                  ),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    const begin = 0.0;
                    const end = 1.0;
                    const curve = Curves.ease;

                    final tween = Tween(begin: begin, end: end);
                    final curvedAnimation = CurvedAnimation(
                      parent: animation,
                      curve: curve,
                    );

                    return FadeTransition(
                      opacity: tween.animate(curvedAnimation),
                      child: child,
                    );
                  },
                ),
              );
            }
          },
          child: Hero(
            tag: widget.profile.username,
            child: isFavoriteChat
                ? CircleAvatar(
                    backgroundColor: colors.backgroundColor,
                    radius: 24,
                    child: Icon(
                      Icons.star,
                      color: colors.primaryColor,
                      size: 30,
                    ),
                  )
                : CircleAvatar(
                    radius: 40,
                    backgroundColor: colors.cardColor,
                    child: widget.profile.avatarUrl.isNotEmpty
                        ? ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: widget.profile.avatarUrl,
                              fit: BoxFit.cover,
                              width: 80,
                              height: 80,
                              placeholder: (context, url) =>
                                  CircularProgressIndicator(),
                              errorWidget: (context, url, error) =>
                                  Icon(Icons.error),
                            ),
                          )
                        : Icon(Icons.person, size: 40, color: colors.textColor),
                  ),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  isFavoriteChat ? 'Избранное' : widget.profile.username,
                  style: TextStyle(
                    color: colors.textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                if (widget.profile.premium &&
                    widget.profile.nicknameEmoji != null &&
                    widget.profile.nicknameEmoji!.isNotEmpty &&
                    !isFavoriteChat)
                  GestureDetector(
                    onTap: () {},
                    child: isLottieEmoji
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: Lottie.asset(
                              widget.profile.nicknameEmoji!,
                              fit: BoxFit.contain,
                            ),
                          )
                        : Text(
                            widget.profile.nicknameEmoji!,
                            style: TextStyle(
                              color: colors.textColor,
                              fontSize: 20,
                            ),
                          ),
                  ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoSection(BuildContext context, AppColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Информация',
          style: TextStyle(
            color: colors.textColor.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                _buildInfoRow(context, Icons.wc, 'Пол',
                    _getGenderTranslation(widget.profile.gender), colors),
                _buildDivider(colors),
                _buildInfoRow(context, Icons.cake, 'Дата рождения',
                    formatDate(widget.profile.dateOfBirth), colors),
                _buildDivider(colors),
                _buildInfoRow(context, Icons.timer, 'Срок действия премиума',
                    formatDate(widget.profile.premiumExpiresAt), colors),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMediaSection(AppColors colors) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4.0,
        mainAxisSpacing: 4.0,
      ),
      itemCount: widget.mediaUrls.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            setState(() {
              _isImageViewOpen = true;
            });
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    FullScreenImageView(
                  imageUrl: widget.mediaUrls[index].photoUrl,
                  onClose: () {
                    setState(() {
                      _isImageViewOpen = false;
                    });
                  },
                  timestamp: DateTime.parse(widget.mediaUrls[index].timestamp),
                ),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  const begin = 0.0;
                  const end = 1.0;
                  const curve = Curves.ease;

                  final tween = Tween(begin: begin, end: end);
                  final curvedAnimation = CurvedAnimation(
                    parent: animation,
                    curve: curve,
                  );

                  return FadeTransition(
                    opacity: tween.animate(curvedAnimation),
                    child: child,
                  );
                },
              ),
            );
          },
          child: Hero(
            tag: widget.mediaUrls[index],
            child: Image.network(
              widget.mediaUrls[index].photoUrl,
              fit: BoxFit.cover,
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label,
      String value, AppColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colors.iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: colors.textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: colors.textColor.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(AppColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Divider(
        color: colors.dividerColor,
        thickness: 1,
      ),
    );
  }

  String formatDate(DateTime? date) {
    if (date == null) return 'Не указана';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day.$month.$year';
  }

  String _getGenderTranslation(String? gender) {
    if (gender == null) {
      return 'Не указан';
    }
    switch (gender.toUpperCase()) {
      case 'MALE':
        return 'Мужской';
      case 'FEMALE':
        return 'Женский';
      default:
        return 'Не указан';
    }
  }
}
