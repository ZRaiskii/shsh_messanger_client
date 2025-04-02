import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/utils/AppColors.dart';
import '../../../settings/data/services/theme_manager.dart';

class CodeBlockWidget extends StatelessWidget {
  final String code;
  final String language;

  CodeBlockWidget({required this.code, required this.language});

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Код скопирован')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<String> lines = code.split('\n');
    final colors = isWhiteNotifier.value ? AppColors.light() : AppColors.dark();
    return Container(
      constraints: BoxConstraints(
        minWidth: 150.0,
      ),
      decoration: BoxDecoration(
        color: colors.cardColor,
        borderRadius: BorderRadius.circular(8.0),
      ),
      padding: const EdgeInsets.all(8.0),
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                language.isNotEmpty ? language : '',
                style: TextStyle(
                  fontSize: 12.0,
                  color: colors.textColor,
                ),
              ),
              GestureDetector(
                onTap: () => _copyToClipboard(context),
                child: Row(
                  children: [
                    Text(
                      'Скопировать',
                      style: TextStyle(
                        fontSize: 12.0,
                        color: colors.primaryColor,
                      ),
                    ),
                    Icon(
                      Icons.copy,
                      size: 16.0,
                      color: colors.primaryColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 4.0),
          Container(
            constraints: BoxConstraints(maxHeight: 200),
            child: Scrollbar(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Scrollbar(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: IntrinsicWidth(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 30.0,
                            margin: const EdgeInsets.only(right: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: List.generate(lines.length, (index) {
                                return Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontSize: 12.0,
                                    color: colors.hintColor,
                                  ),
                                );
                              }),
                            ),
                          ),
                          Flexible(
                            fit: FlexFit.loose,
                            child: SelectableText(
                              code,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12.0,
                                color: colors.textColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
