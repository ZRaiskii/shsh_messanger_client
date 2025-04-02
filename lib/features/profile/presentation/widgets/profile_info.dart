import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';
import '../../domain/usecases/update_profile_usecase.dart';
import '../../../settings/presentation/pages/premium_page.dart';
import '../../domain/entities/profile.dart';
import '../bloc/profile_bloc.dart';
import '../../../../core/utils/AppColors.dart';
import '../../../settings/data/services/theme_manager.dart';
import 'date_picker_content.dart';
import 'description_picker_content.dart';
import 'emoji_picker_content.dart';
import 'gender_switcher.dart';

class ProfileInfo extends StatefulWidget {
  final Profile profile;
  final Future Function() onPickImage;
  final Future Function(String) onUpdateEmoji;
  final Future Function(bool) onUpdatePremium;

  const ProfileInfo({
    super.key,
    required this.profile,
    required this.onPickImage,
    required this.onUpdateEmoji,
    required this.onUpdatePremium,
  });

  @override
  _ProfileInfoState createState() => _ProfileInfoState();
}

class _ProfileInfoState extends State<ProfileInfo>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isFullScreen = false;
  final TextEditingController _descriptionController = TextEditingController();
  bool _isEditingDescription = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_animationController)
      ..addListener(() => setState(() {}));
    _descriptionController.text = widget.profile.descriptionOfProfile;
  }

  @override
  void dispose() {
    _animationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = isWhiteNotifier.value ? AppColors.light() : AppColors.dark();

    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        if (state is ProfileLoading) {
          return _buildShimmerLoader(colors);
        }

        if (state is ProfileSuccess && state.profile != null) {
          return GestureDetector(
            onVerticalDragEnd: (details) {
              if (details.primaryVelocity! > 0) {
                _animationController.forward();
                setState(() => _isFullScreen = true);
              }
            },
            child: Stack(
              children: [
                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: _buildProfileHeader(
                            context, colors, state.profile!),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoSection(context, colors, state.profile!),
                    ],
                  ),
                ),
                if (_isFullScreen)
                  _buildFullScreenAvatar(state.profile!.avatarUrl, colors),
              ],
            ),
          );
        }

        return Center(
            child: CircularProgressIndicator(color: colors.primaryColor));
      },
    );
  }

  Widget _buildShimmerLoader(AppColors colors) {
    return Shimmer.fromColors(
      baseColor: colors.shimmerBase,
      highlightColor: colors.shimmerHighlight,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: colors.shimmerBase,
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 150,
                      height: 24,
                      color: colors.shimmerBase,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 200,
                      height: 20,
                      color: colors.shimmerBase,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: colors.cardColor,
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: List.generate(
                5,
                (index) => Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        color: colors.shimmerBase,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 16,
                              color: colors.shimmerBase,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              height: 12,
                              color: colors.shimmerBase,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(
      BuildContext context, AppColors colors, Profile profile) {
    final bool isLottieEmoji =
        widget.profile.nicknameEmoji?.startsWith('assets/') ?? false;
    return Hero(
      tag: profile.avatarUrl,
      child: Row(
        children: [
          GestureDetector(
            onTap: widget.onPickImage, // Используем onPickImage
            child: CircleAvatar(
              backgroundImage: widget.profile.avatarUrl.isNotEmpty
                  ? NetworkImage(widget.profile.avatarUrl)
                  : null,
              radius: 40,
              child: widget.profile.avatarUrl.isEmpty
                  ? Icon(Icons.person, size: 40, color: colors.iconColor)
                  : null,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _showUsernameChangeDialog(context),
                    child: Text(
                      widget.profile.username,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: colors.textColor,
                              ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (widget.profile.premium)
                    GestureDetector(
                      onTap: () {
                        _showEmojiPicker(context, widget.onUpdateEmoji, colors);
                      },
                      child: isLottieEmoji
                          ? SizedBox(
                              width: 24, // Размер Lottie-анимации
                              height: 24,
                              child: Lottie.asset(
                                widget.profile.nicknameEmoji!
                                    .replaceFirst('animation_emoji/', '')
                                    .replaceAll('', ''),
                                fit: BoxFit.contain,
                              ),
                            )
                          : Text(
                              widget.profile.nicknameEmoji != null
                                  ? widget.profile.nicknameEmoji!
                                  : "⭐️",
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    color: colors.textColor,
                                  ),
                            ),
                    ),
                ],
              ),
              Text(
                widget.profile.email,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.textColor,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(
      BuildContext context, AppColors colors, Profile profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Информация',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colors.textColor,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: colors.cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              _buildEditableDescription(context, colors, profile),
              _buildDivider(colors),
              _buildInfoRow(
                context,
                Icons.email,
                'Подтверждение почты',
                profile.isVerifiedEmail ? "Подтверждено" : "Не подтверждено",
                colors,
                () => _showEmailVerificationDialog(context),
                trailing: profile.isVerifiedEmail
                    ? Lottie.asset(
                        'assets/animations/verified.json',
                        width: 40,
                        height: 24,
                        fit: BoxFit.contain,
                      )
                    : null,
              ),
              _buildDivider(colors),
              _buildInfoRow(
                context,
                Icons.wc,
                'Пол',
                _getGenderTranslation(profile.gender),
                colors,
                () => _showGenderPickerDialog(context),
              ),
              _buildDivider(colors),
              _buildInfoRow(
                context,
                Icons.cake,
                'Дата рождения',
                formatDate(profile.dateOfBirth),
                colors,
                () => _showDatePickerDialog(context),
              ),
              _buildDivider(colors),
              _buildPremiumRow(context, colors, profile),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditableDescription(
      BuildContext context, AppColors colors, Profile profile) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: colors.iconColor, size: 18),
              const SizedBox(width: 8),
              Text(
                'О себе',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.textColor.withOpacity(0.7),
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _isEditingDescription
              ? TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: colors.inputBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.save, color: colors.accentColor),
                      onPressed: () async {
                        final profileBloc =
                            BlocProvider.of<ProfileBloc>(context);
                        profileBloc.add(UpdateProfileEvent(UpdateProfileParams(
                          userId: widget.profile.id,
                          profile: widget.profile.copyWith(
                              descriptionOfProfile:
                                  _descriptionController.text),
                        )));
                        setState(() => _isEditingDescription = false);
                      },
                    ),
                  ),
                  maxLines: 3,
                  style: TextStyle(color: colors.textColor),
                )
              : Container(
                  width: double.infinity,
                  child: InkWell(
                    onTap: () => setState(() => _isEditingDescription = true),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        profile.descriptionOfProfile.isEmpty
                            ? 'Добавьте описание'
                            : profile.descriptionOfProfile,
                        style: TextStyle(
                          color: profile.descriptionOfProfile.isEmpty
                              ? colors.textColor.withOpacity(0.5)
                              : colors.textColor,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label,
      String value, AppColors colors, VoidCallback onTap,
      {Widget? trailing}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: colors.listItemBackground,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, color: colors.iconColor, size: 20),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        color: value == 'Не подтверждено'
                            ? colors.errorColor
                            : colors.textColor,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (label.isNotEmpty)
                      Text(
                        label,
                        style: TextStyle(
                          color: colors.textColor.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 16),
                trailing,
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumRow(
      BuildContext context, AppColors colors, Profile profile) {
    final DateTime now = DateTime.now();
    final DateTime expiry = profile.premiumExpiresAt ?? now;
    final double progress = expiry.isBefore(now)
        ? 0
        : expiry.difference(now).inDays /
            30; // 30 дней - условный срок премиума

    return Column(
      children: [
        _buildDivider(colors),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.star, color: colors.accentColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Премиум статус',
                    style: TextStyle(
                      color: colors.textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: colors.progressBackground,
                color: colors.accentColor,
                minHeight: 8,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Осталось: ${expiry.difference(now).inDays} дней',
                    style: TextStyle(color: colors.textColor.withOpacity(0.7)),
                  ),
                  TextButton(
                    onPressed: () => _showPremiumExpirationDialog(context),
                    child: Text(
                      'Продлить',
                      style: TextStyle(color: colors.accentColor),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDivider(AppColors colors) {
    return Divider(
      color: colors.dividerColor,
      thickness: 0.5,
      height: 0.5,
    );
  }

  Widget _buildFullScreenAvatar(String avatarUrl, AppColors colors) {
    return Hero(
      tag: avatarUrl, // Используем тот же тег, что и в _buildProfileHeader
      child: GestureDetector(
        onTap: () {
          _animationController.reverse();
          setState(() => _isFullScreen = false);
        },
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) => Opacity(
            opacity: _animation.value,
            child: Container(
              color: colors.overlayColor,
              child: Center(
                // Убираем внутренний Hero
                child: CachedNetworkImage(
                  imageUrl: avatarUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: colors.shimmerBase,
                    highlightColor: colors.shimmerHighlight,
                    child: Container(
                      width: 200,
                      height: 200,
                      color: colors.shimmerBase,
                    ),
                  ),
                  errorWidget: (context, url, error) => CircleAvatar(
                    backgroundImage: widget.profile.avatarUrl.isNotEmpty
                        ? NetworkImage(widget.profile.avatarUrl)
                        : null,
                    radius: 40,
                    child: widget.profile.avatarUrl.isEmpty
                        ? Icon(Icons.person, size: 40, color: colors.iconColor)
                        : null,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showEmojiPicker(
      BuildContext context, Function(String) onUpdateEmoji, AppColors colors) {
    showDialog(
      context: context,
      builder: (context) {
        return EmojiPickerContent(
          onUpdateEmoji: onUpdateEmoji,
          colors: colors,
        );
      },
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
    if (gender == null) return 'Не указан';
    switch (gender.toUpperCase()) {
      case 'MALE':
        return 'Мужской';
      case 'FEMALE':
        return 'Женский';
      default:
        return 'Не указан';
    }
  }

  void _showUsernameChangeDialog(BuildContext context) {
    final colors = isWhiteNotifier.value ? AppColors.light() : AppColors.dark();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Изменение имени пользователя',
            style: TextStyle(color: colors.textColor),
          ),
          content: Text(
            'Изменение имени пользователя временно недоступно. Пожалуйста, попробуйте позже.',
            style: TextStyle(color: colors.textColor),
          ),
          backgroundColor: colors.cardColor,
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'ОК',
                style: TextStyle(color: colors.primaryColor),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showPremiumExpirationDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PremiumPage()),
    );
  }

  void _showDatePickerDialog(BuildContext context) {
    final colors = isWhiteNotifier.value ? AppColors.light() : AppColors.dark();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Выберите дату рождения',
            style: TextStyle(
                color: colors.textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold),
          ),
          backgroundColor: colors.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          content: DatePickerContent(colors: colors, profile: widget.profile),
        );
      },
    );
  }

  void _showGenderPickerDialog(BuildContext context) {
    final colors = isWhiteNotifier.value ? AppColors.light() : AppColors.dark();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Выберите пол',
            style: TextStyle(
                color: colors.textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold),
          ),
          backgroundColor: colors.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          content: GenderPickerContent(colors: colors, profile: widget.profile),
        );
      },
    );
  }

  void _showEmailVerificationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Уведомление'),
          content:
              Text('Функциональность подтверждения почты пока не реализована.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Закрыть диалог
              },
              child: Text('ОК'),
            ),
          ],
        );
      },
    );
  }

  void _showDescriptionChangeDialog(BuildContext context) {
    final colors = isWhiteNotifier.value ? AppColors.light() : AppColors.dark();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Изменить описание профиля',
            style: TextStyle(
                color: colors.textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold),
          ),
          backgroundColor: colors.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          content: DescriptionPickerContent(
            colors: colors,
            profile: widget.profile,
          ),
        );
      },
    );
  }
}
