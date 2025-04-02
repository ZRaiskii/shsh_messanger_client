import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'full_screen_image_widget.dart';

class PhotoMessageWidget extends StatefulWidget {
  final String imageUrl;

  PhotoMessageWidget({required this.imageUrl});

  @override
  _PhotoMessageWidgetState createState() => _PhotoMessageWidgetState();
}

class _PhotoMessageWidgetState extends State<PhotoMessageWidget> {
  Size? _imageSize;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _getImageDimensions(widget.imageUrl);
  }

  Future<Future<Size>> _getImageDimensions(String imageUrl) async {
    final Completer<Size> completer = Completer();
    final Image image = Image.network(imageUrl);

    image.image.resolve(ImageConfiguration()).addListener(
      ImageStreamListener((ImageInfo info, bool _) {
        if (mounted) {
          setState(() {
            _imageSize =
                Size(info.image.width.toDouble(), info.image.height.toDouble());
            _isLoading = false;
          });
        }

        if (_imageSize != null) {
          completer.complete(_imageSize);
        }
      }),
    );

    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    const double maxWidth = 300.0;
    const double maxHeight = 300.0;

    if (_isLoading) {
      return Container(
        width: maxWidth,
        height: maxHeight,
        color: Colors.grey[300],
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (_hasError) {
      return Icon(Icons.error);
    } else if (_imageSize != null) {
      final double aspectRatio = _imageSize!.width / _imageSize!.height;
      final double width = aspectRatio > 1 ? maxWidth : maxHeight * aspectRatio;
      final double height =
          aspectRatio > 1 ? maxWidth / aspectRatio : maxHeight;

      return GestureDetector(
        onTap: () {
          _showImagePreview(context, widget.imageUrl);
        },
        child: CachedNetworkImage(
          imageUrl: widget.imageUrl,
          fit: BoxFit.contain,
          width: width,
          height: height,
          // Removed cache settings to ensure high-quality image loading
          placeholder: (context, url) => Container(
            width: width,
            height: height,
            color: Colors.grey[300],
            child: Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (context, url, error) => Icon(Icons.error),
          fadeInDuration: Duration.zero,
          fadeOutDuration: Duration.zero,
          // Optional: Increase the cache width and height if needed
          memCacheWidth: (width * 2).toInt(),
          memCacheHeight: (height * 2).toInt(),
        ),
      );
    } else {
      return Container(); // Fallback in case of unexpected state
    }
  }

  void _showImagePreview(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            FullScreenImageView(
          imageUrl: imageUrl,
          onClose: () {
            if (mounted) {
              setState(() {
                // _isImageViewOpen = false; // Unused variable
              });
            }
          },
          timestamp: DateTime.now(),
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
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
}
