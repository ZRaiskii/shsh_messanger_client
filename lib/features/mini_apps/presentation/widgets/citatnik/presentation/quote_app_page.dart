import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../../../core/utils/AppColors.dart';
import '../data/quote_service.dart';
import '../../../../../settings/data/services/theme_manager.dart';

class QuoteScreen extends StatefulWidget {
  const QuoteScreen({super.key});

  @override
  State<QuoteScreen> createState() => _QuoteScreenState();
}

class _QuoteScreenState extends State<QuoteScreen>
    with TickerProviderStateMixin {
  String? _currentQuote;
  bool _isLoading = false;
  final QuoteService _service = QuoteService();

  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  late AnimationController _gradientController;
  late Animation<AlignmentGeometry> _gradientAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOut,
    );

    _gradientController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat(reverse: true);
    _gradientAnimation = Tween<AlignmentGeometry>(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).animate(
      CurvedAnimation(
        parent: _gradientController,
        curve: Curves.easeInOut,
      ),
    );

    _fetchQuote();
  }

  void _fetchQuote() async {
    setState(() {
      _isLoading = true;
      _currentQuote = null;
    });

    final quote = await _service.getRandomQuote();

    setState(() {
      _currentQuote = quote;
      _isLoading = false;
    });

    _scaleController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final colors = isWhiteNotifier.value ? AppColors.light() : AppColors.dark();

    return Scaffold(
      body: AnimatedBuilder(
        animation: _gradientAnimation,
        builder: (context, child) {
          return Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: _gradientAnimation.value,
                    end: _gradientAnimation.value == Alignment.topLeft
                        ? Alignment.bottomRight
                        : Alignment.topLeft,
                    colors: [
                      Color.lerp(
                        colors.backgroundColor.withOpacity(0.9),
                        colors.primaryColor.withOpacity(0.8),
                        0.5,
                      )!,
                      Color.lerp(
                        colors.accentColor.withOpacity(0.9),
                        colors.secondaryColor.withOpacity(0.7),
                        0.5,
                      )!,
                    ],
                    stops: const [0.1, 0.9],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Center(
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: _buildQuoteContent(colors),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildActionButton(colors),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildQuoteContent(AppColors colors) {
    if (_isLoading) {
      return Shimmer.fromColors(
        baseColor: colors.shimmerBase,
        highlightColor: colors.shimmerHighlight,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 300,
              height: 20,
              decoration: BoxDecoration(
                color: colors.shimmerBase,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: 250,
              height: 15,
              decoration: BoxDecoration(
                color: colors.shimmerBase,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
      );
    }

    if (_currentQuote != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Нажмите, чтобы скопировать',
            style: TextStyle(
              fontSize: 16,
              color: colors.textColor.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 15),
          GestureDetector(
            onTap: () => _copyQuoteToClipboard(_currentQuote!),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colors.cardColor,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: colors.shadowColor.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _currentQuote!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      color: colors.textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Icon(
                    Icons.copy_all,
                    color: colors.iconColor,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Text(
      'Не удалось загрузить цитату',
      style: TextStyle(color: colors.errorColor),
    );
  }

  Widget _buildActionButton(AppColors colors) {
    return ElevatedButton(
      onPressed: _fetchQuote,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: colors.buttonColor,
        elevation: 5,
        shadowColor: colors.shadowColor,
      ).copyWith(
        overlayColor: MaterialStateProperty.all(colors.shimmerHighlight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.refresh,
            color: colors.iconColor,
            size: 20,
          ),
          const SizedBox(width: 10),
          Text(
            'Следующая цитата',
            style: TextStyle(
              fontSize: 16,
              color: colors.buttonTextColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _copyQuoteToClipboard(String quote) {
    final colors = isWhiteNotifier.value ? AppColors.light() : AppColors.dark();
    Clipboard.setData(ClipboardData(text: quote)).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: colors.successColor,
                size: 24,
              ),
              const SizedBox(width: 10),
              Text(
                "Цитата скопирована!",
                style: TextStyle(
                  color: colors.textColor,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: colors.backgroundColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _gradientController.dispose();
    super.dispose();
  }
}
