import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/AppColors.dart';
import '../../../settings/data/services/theme_manager.dart';

class UserAvatar extends StatelessWidget {
  final double size;
  final String? avatarUrl;

  const UserAvatar({this.size = 80, this.avatarUrl, super.key});

  @override
  Widget build(BuildContext context) {
    final colors = isWhiteNotifier.value ? AppColors.light() : AppColors.dark();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.cardColor,
        border: Border.all(color: colors.primaryColor, width: 2),
      ),
      child: avatarUrl != null
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: avatarUrl!,
                fit: BoxFit.cover,
                width: 80,
                height: 80,
                placeholder: (context, url) => CircularProgressIndicator(),
                errorWidget: (context, url, error) => Icon(Icons.error),
              ),
            )
          : Icon(Icons.person, size: size * 0.6, color: colors.iconColor),
    );
  }
}
