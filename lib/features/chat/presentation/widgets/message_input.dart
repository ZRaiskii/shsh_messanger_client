import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:pro_image_editor/core/models/editor_callbacks/pro_image_editor_callbacks.dart';
import 'package:pro_image_editor/core/models/editor_configs/pro_image_editor_configs.dart';
import 'package:pro_image_editor/features/main_editor/main_editor.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shsh_social/features/profile/presentation/widgets/emoji_picker_content.dart';
import '../../domain/entities/draft.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../../core/utils/constants.dart';
import '../../domain/entities/message.dart';
import '../../../../core/utils/AppColors.dart';
import '../../../settings/data/services/theme_manager.dart';

import '../../data/services/chat_state_manager.dart';
import 'package:flutter/services.dart';

import 'package:lottie/lottie.dart';

class MessageInput extends StatefulWidget {
  final String? chatId;
  final String userId;
  final String recipientId;
  final Function(String) onSend;
  final Function(String) onSendPhoto;
  final Function(bool) typing;
  final ValueNotifier<Message?> replyMessageNotifier;
  final Function({
    required String messageId,
    required String chatId,
    required String senderId,
    required String newContent,
  }) onEditMessage;

  const MessageInput({
    this.chatId,
    required this.userId,
    required this.recipientId,
    required this.onSend,
    required this.onSendPhoto,
    required this.typing,
    required this.replyMessageNotifier,
    required this.onEditMessage,
    super.key,
  });

  @override
  _MessageInputState createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput>
    with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _isShiftPressed = false;
  bool _isControlPressed = false;
  final FocusNode _focusNode = FocusNode();
  bool _showEmojiPicker = false;
  Timer? _typingTimer;
  final ValueNotifier<bool> _hasTextNotifier = ValueNotifier<bool>(false);
  final String _draftKeyPrefix = "draft_widget_v2";
  bool _isOverlayVisible = false;
  String? _selectedEmoji;
  OverlayEntry? overlayEntry;
  final Map<String, AnimationController> _animationControllers = {};

  @override
  void initState() {
    super.initState();
    RawKeyboard.instance.addListener(_handleKeyEvent);
    _controller.addListener(_onTextChanged);
    ChatStateManager.instance.editingMessageNotifier
        .addListener(_updateEditingMessage);
    _loadDraft();
    _focusNode.addListener(_onFocusChange);
  }

  void _onTextChanged() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _hasTextNotifier.value = _controller.text.isNotEmpty;
    });
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      setState(() {
        _showEmojiPicker = false;
      });
    }
  }

  @override
  void dispose() {
    RawKeyboard.instance.removeListener(_handleKeyEvent);
    _focusNode.dispose();
    _typingTimer?.cancel();
    ChatStateManager.instance.editingMessageNotifier
        .removeListener(_updateEditingMessage);
    _animationControllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  void _showOverlay(String emojiPath) {
    if (overlayEntry != null) return;

    _selectedEmoji = emojiPath;

    overlayEntry = OverlayEntry(
      builder: (context) => GestureDetector(
        onTap: _hideOverlay,
        child: Stack(
          children: [
            AnimatedOpacity(
              opacity: 1.0,
              duration: Duration(milliseconds: 300),
              child: Container(
                color: Colors.transparent,
              ),
            ),
            Center(
              child: AnimatedOpacity(
                opacity: 1.0,
                duration: Duration(milliseconds: 300),
                child: Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.grey.withOpacity(0.5)),
                  ),
                  child: Lottie.asset(
                    _selectedEmoji!,
                    width: 100,
                    height: 100,
                    fit: BoxFit.contain,
                    animate: true,
                    repeat: true,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    Overlay.of(context)?.insert(overlayEntry!);
  }

  void _hideOverlay() {
    if (overlayEntry == null) return;

    overlayEntry?.remove();
    overlayEntry = null;
  }

  void _updateEditingMessage() {
    final editingMessage =
        ChatStateManager.instance.editingMessageNotifier.value;
    if (editingMessage != null) {
      setState(() {
        _controller.text = editingMessage.content;
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: _controller.text.length),
        );
      });
    }
  }

  // Метод для отмены редактирования
  void _cancelEditing() {
    ChatStateManager.instance.editingMessageNotifier.value = null;
    _controller.clear();
  }

  // Метод для отправки измененного сообщения
  void _sendEditedMessage() {
    final editedMessage =
        ChatStateManager.instance.editingMessageNotifier.value;
    if (editedMessage != null) {
      final newContent = _controller.text.trim(); // Удаляем лишние пробелы

      // Проверяем, изменилось ли сообщение
      if (newContent.isNotEmpty && newContent != editedMessage.content) {
        _sendTypingStatus(false);
        widget.onEditMessage(
          messageId: editedMessage.id,
          chatId: widget.chatId!,
          senderId: widget.userId,
          newContent: newContent,
        );
        _clearDraft();
        _cancelEditing();
      } else {
        // Если сообщение не изменилось или пустое, показываем уведомление
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Сообщение не изменилось или пустое.'),
          ),
        );
      }
    }
  }

  // Метод для отправки статуса печатания
  void _sendTypingStatus(bool isTyping) {
    if (widget.chatId != null) {
      widget.typing(isTyping);
    }
  }

  void _startTypingTimer() {
    // _typingTimer?.cancel();

    _sendTypingStatus(true);

    _typingTimer = Timer(Duration(milliseconds: 1500), () {
      // _sendTypingStatus(false);
    });
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (Platform.isWindows &&
        ChatStateManager.instance.editingMessageNotifier.value == null) {
      if (event is RawKeyDownEvent) {
        // Игнорируем повторные события нажатия
        if (event.repeat) return;

        // Handle Shift + Enter for new line
        if (HardwareKeyboard.instance.isShiftPressed &&
            event.logicalKey == LogicalKeyboardKey.enter) {
          final currentText = _controller.text;
          final currentSelection = _controller.selection;

          // Вставляем один перевод строки
          final newText = currentText.replaceRange(
            currentSelection.start,
            currentSelection.end,
            '\n',
          );
          FocusScope.of(context).requestFocus(_focusNode);

          _controller.value = TextEditingValue(
            text: newText,
            selection:
                TextSelection.collapsed(offset: currentSelection.start + 1),
          );

          // Обновляем сообщение в стейте, если редактируем
          if (ChatStateManager.instance.editingMessageNotifier.value != null) {
            ChatStateManager.instance.editingMessageNotifier.value?.content =
                newText;
          }
          Future.microtask(
              () => FocusScope.of(context).requestFocus(_focusNode));
          return;
        }
        // Handle Enter to send message
        else if (event.logicalKey == LogicalKeyboardKey.enter) {
          // _sendMessage();
          return;
        }

        // Обработка Ctrl+V
        if ((event.logicalKey == LogicalKeyboardKey.controlLeft ||
            event.logicalKey == LogicalKeyboardKey.controlRight)) {
          setState(() => _isControlPressed = true);
        }
        if (_isControlPressed && event.logicalKey == LogicalKeyboardKey.keyV) {
          _pasteImageFromClipboard();
        }
      } else if (event is RawKeyUpEvent) {
        // Сброс флагов при отпускании клавиш
        if (event.logicalKey == LogicalKeyboardKey.shiftLeft ||
            event.logicalKey == LogicalKeyboardKey.shiftRight) {
          setState(() => _isShiftPressed = false);
        }
        if (event.logicalKey == LogicalKeyboardKey.controlLeft ||
            event.logicalKey == LogicalKeyboardKey.controlRight) {
          setState(() => _isControlPressed = false);
        }
      }
    }
  }

  Future<void> _pasteImageFromClipboard() async {
    if (Platform.isWindows) {
      try {
        final imageBytes = await Pasteboard.image;

        if (imageBytes != null) {
          final tempDir = await getTemporaryDirectory();
          final imageFile = File('${tempDir.path}/pasted_image.png');
          await imageFile.writeAsBytes(imageBytes);

          if (mounted) {
            _showPhotoEditor(imageFile);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('В буфере обмена нет изображения.'),
              ),
            );
          }
        }
      } catch (e) {
        print(e);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка при вставке изображения: $e'),
            ),
          );
        }
      }
    }
  }

  void _sendMessage() {
    final message = _controller.text.trim();
    if (message.isNotEmpty) {
      widget.onSend(message);
      _sendTypingStatus(false);
      _controller.clear();
      _focusNode.requestFocus();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Сообщение не может быть пустым.'),
        ),
      );
    }
  }

  bool isPhotoUrl(String text) {
    return text.startsWith('http') &&
        (text.endsWith('.jpg') ||
            text.endsWith('.png') ||
            text.endsWith('.jpeg'));
  }

  final Map<String, List<String>> emojiCategories = {
    'Смайлики': [
      "😀",
      "😃",
      "😄",
      "😁",
      "😆",
      "😅",
      "😂",
      "🤣",
      "😭",
      "😉",
      "😗",
      "😙",
      "😚",
      "😘",
      "🥰",
      "😍",
      "🤩",
      "🥳",
      "🫠",
      "🙃",
      "🙂",
      "🥲",
      "🥹",
      "😊",
      "☺️",
      "😌",
      "😏",
      "😴",
      "😪",
      "🤤",
      "😋",
      "😛",
      "😝",
      "😜",
      "🤪",
      "🥴",
      "😔",
      "🥺",
      "😬",
      "🫥",
      "😑",
      "😐",
      "😶",
      "😶‍🌫️",
      "🤐",
      "🫡",
      "🤔",
      "🤫",
      "🫢",
      "🤭",
      "🥱",
      "🤗",
      "🫣",
      "😱",
      "🤨",
      "🧐",
      "😒",
      "🙄",
      "😮‍💨",
      "😤",
      "😠",
      "😡",
      "🤬",
      "😞",
      "😰",
      "😓",
      "😨",
      "😟",
      "😧",
      "😥",
      "😦",
      "😢",
      "😮",
      "😯",
      "🙁",
      "😲",
      "🫤",
      "😳",
      "😕",
      "🤯",
      "😖",
      "😣",
      "😩",
      "😫",
      "😵",
      "😵‍💫",
      "🫨",
      "🥶",
      "🥵",
      "🤢",
      "🤮",
      "🤧",
      "🤒",
      "🤕",
      "😷",
      "🤥",
      "😇",
      "🤠",
      "🤑",
      "🤓",
      "😎",
      "🥸",
      "🤡",
      "😈",
      "👿",
      "👻",
      "🎃",
      "💩",
      "☠️",
      "🤖",
      "👹",
      "👽",
    ],
    // 'Анимации': [
    //   // Лица и эмоции
    //   'assets/heart_emoji.json', // Сердце
    //   'assets/laughing_emoji.json', // Смеющийся emoji
    //   'assets/crying_emoji.json', // Плачущий emoji
    //   'assets/angry_emoji.json', // Сердитый emoji
    //   'assets/blush.json', // Улыбка с румянцем
    //   'assets/experssionless.json', // Без выражения
    //   'assets/Grin.json', // Широкая улыбка
    //   'assets/Grinning.json', // Улыбка
    //   'assets/halo.json', // Ореол
    //   'assets/heart-eyes.json', // Сердечные глаза
    //   'assets/heart-face.json', // Лицо с сердечками
    //   'assets/holding-back-tears.json', // Сдерживающий слёзы
    //   'assets/hot-face.json', // Горячее лицо
    //   'assets/hug-face.json', // Обнимающее лицо
    //   'assets/imp-smile.json', // Улыбка с рожками
    //   'assets/Joy.json', // Слёзы радости
    //   'assets/kiss.json', // Поцелуй
    //   'assets/Kissing-closed-eyes.json', // Поцелуй с закрытыми глазами
    //   'assets/Kissing-heart.json', // Поцелуй с сердечком
    //   'assets/Kissing.json', // Поцелуй
    //   'assets/Launghing.json', // Смех
    //   'assets/Loudly-crying.json', // Громкий плач
    //   'assets/melting.json', // Таящее лицо
    //   'assets/mind-blown.json', // Взорванный мозг
    //   'assets/money-face.json', // Лицо с деньгами
    //   'assets/neutral-face.json', // Нейтральное лицо
    //   'assets/partying-face.json', // Лицо на вечеринке
    //   'assets/pensive.json', // Задумчивое лицо
    //   'assets/pleading.json', // Умоляющее лицо
    //   'assets/raised-eyebrow.json', // Поднятая бровь
    //   'assets/relieved.json', // Облегчение
    //   'assets/Rofl.json', // Катающийся от смеха
    //   'assets/roling-eyes.json', // Закатывание глаз
    //   'assets/screaming.json', // Крик
    //   'assets/shushing-face.json', // Тихое лицо
    //   'assets/skull.json', // Череп
    //   'assets/sleep.json', // Сон
    //   'assets/smile.json', // Улыбка
    //   'assets/smile_with_big_eyes.json', // Улыбка с большими глазами
    //   'assets/smirk.json', // Ухмылка
    //   'assets/stuck-out-tongue.json', // Высунутый язык
    //   'assets/subglasses-face.json', // Лицо в очках
    //   'assets/thermometer-face.json', // Лицо с термометром
    //   'assets/thinking-face.json', // Задумчивое лицо
    //   'assets/upside-down-face.json', // Перевёрнутое лицо
    //   'assets/vomit.json', // Рвота
    //   'assets/warm-smile.json', // Тёплая улыбка
    //   'assets/Wink.json', // Подмигивание
    //   'assets/winky-tongue.json', // Подмигивание с языком
    //   'assets/woozy.json', // Одурманенный
    //   'assets/yawn.json', // Зевота
    //   'assets/yum.json', // Вкусно
    //   'assets/zany-face.json', // Сумасшедшее лицо
    //   'assets/zipper-face.json', // Лицо с молнией

    //   // Остальные анимации
    //   'assets/100.json', // 100 баллов
    //   'assets/alarm-clock.json', // Будильник
    //   'assets/battary-full.json', // Полная батарея
    //   'assets/battary-low.json', // Разряженная батарея
    //   'assets/birthday-cake.json', // Торт на день рождения
    //   'assets/blood.json', // Кровь
    //   'assets/bomb.json', // Бомба
    //   'assets/bowling.json', // Боулинг
    //   'assets/broking-heart.json', // Разбитое сердце
    //   'assets/chequered-flag.json', // Клетчатый флаг
    //   'assets/chinking-beer-mugs.json', // Бокалы пива
    //   'assets/clap.json', // Аплодисменты
    //   'assets/clown.json', // Клоун
    //   'assets/cold-face.json', // Холодное лицо
    //   'assets/collision.json', // Столкновение
    //   'assets/confetti-ball.json', // Конфетти
    //   'assets/cross-mark.json', // Крестик
    //   'assets/crossed-fingers.json', // Скрёщенные пальцы
    //   'assets/crystal-ball.json', // Хрустальный шар
    //   'assets/cursing.json', // Ругательство
    //   'assets/die.json', // Игральная кость
    //   'assets/dizy-dace.json', // Головокружение
    //   'assets/drool.json', // Слюни
    //   'assets/exclamation.json', // Восклицательный знак
    //   'assets/eyes.json', // Глаза
    //   'assets/fire.json', // Огонь
    //   'assets/folded-hands.json', // Сложенные руки
    //   'assets/gear.json', // Шестерёнка
    //   'assets/light-bulb.json', // Лампочка
    //   'assets/money-wings.json', // Деньги с крыльями
    //   'assets/mouth-none.json', // Лицо без рта
    //   'assets/muscle.json', // Мускулы
    //   'assets/party-popper.json', // Хлопушка
    //   'assets/pencil.json', // Карандаш
    //   'assets/pig.json', // Свинья
    //   'assets/poop.json', // Какашка
    //   'assets/question.json', // Вопросительный знак
    //   'assets/rainbow.json', // Радуга
    //   'assets/revolving-heart.json', // Вращающееся сердце
    //   'assets/salute.json', // Салют
    //   'assets/slot-machine.json', // Игровой автомат
    //   'assets/soccer-bal.json', // Футбольный мяч
    //   'assets/sparkles.json', // Блёстки
    //   'assets/thumbs-down.json', // Большой палец вниз
    //   'assets/thumbs-up.json', // Большой палец вверх
    //   'assets/victory.json', // Победа
    //   'assets/wave.json', // Волна
    // ],
    'Животные': [
      "🙈",
      "🙉",
      "🙊",
      "🐵",
      "🦁",
      "🐯",
      "🐱",
      "🐶",
      "🐺",
      "🦝",
      "🐲",
      "🦊",
      "🫎",
      "🐰",
      "🐴",
      "🐭",
      "🦄",
      "🐹",
      "🦓",
      "🐼",
      "🐗",
      "🐨",
      "🐽",
      "🐻‍❄️",
      "🐷",
      "🐻",
      "🐮",
      "🦎",
      "🐉",
      "🦖",
      "🦕",
      "🐢",
      "🐊",
      "🐍",
      "🐸",
      "🐇",
      "🐖",
      "🐕‍🦺",
      "🦮",
      "🐕",
      "🐩",
      "🐈‍⬛",
      "🐈",
      "🐀",
      "🐁",
      "🐎",
      "🫏",
      "🐄",
      "🐂",
      "🐃",
      "🦬",
      "🐏",
      "🐑",
      "🐐",
      "🦒",
      "🦫",
      "🦛",
      "🐿️",
      "🦏",
      "🐫",
      "🦣",
      "🐪",
      "🐘",
      "🦧",
      "🦘",
      "🦍",
      "🦥",
      "🐒",
      "🦙",
      "🐅",
      "🦌",
      "🐆",
      "🦨",
      "🐓",
      "🦡",
      "🐔",
      "🦔",
      "🐣",
      "🦦",
      "🐤",
      "🦇",
      "🐥",
      "🪽",
      "🦅",
      "🪶",
      "🦉",
      "🐦",
      "🦜",
      "🐦‍⬛",
      "🕊️",
      "🦤",
      "🦈",
      "🦢",
      "🐬",
      "🦆",
      "🐳",
      "🪿",
      "🦩",
      "🐟",
      "🦚",
      "🐠",
      "🦃",
      "🐡",
      "🐧",
      "🦐",
      "🦭",
      "🦞",
      "🦀",
      "🐚",
      "🦑",
      "🐌",
      "🐙",
      "🪼",
      "🦗",
      "🦪",
      "🪲",
      "🪸",
      "🦟",
      "🦂",
      "🪳",
      "🕷️",
      "🪰",
      "🕸️",
      "🐝",
      "🐞",
      "🦋",
      "🐛",
      "🪱",
      "🦠",
      "🐾"
    ],
    'Еда': [
      "🍓",
      "🍒",
      "🍎",
      "🍉",
      "🍑",
      "🍊",
      "🥭",
      "🍍",
      "🍌",
      "🍋",
      "🍈",
      "🍏",
      "🍐",
      "🥝",
      "🫒",
      "🫐",
      "🍇",
      "🥥",
      "🍅",
      "🌶️",
      "🫚",
      "🥕",
      "🍠",
      "🧅",
      "🌽",
      "🥦",
      "🥒",
      "🌰",
      "🍳",
      "🫘",
      "🥞",
      "🥔",
      "🧇",
      "🧄",
      "🥯",
      "🍆",
      "🥖",
      "🥑",
      "🥐",
      "🫑",
      "🫓",
      "🫛",
      "🍞",
      "🥬",
      "🥜",
      "🥚",
      "🥨",
      "🧀",
      "🍟",
      "🥓",
      "🍕",
      "🥩",
      "🫔",
      "🍗",
      "🌮",
      "🍖",
      "🌯",
      "🍔",
      "🥙",
      "🌭",
      "🧆",
      "🥪",
      "🥘",
      "🍝",
      "🦞",
      "🥫",
      "🍣",
      "🫕",
      "🍤",
      "🥣",
      "🥡",
      "🥗",
      "🍚",
      "🍲",
      "🍱",
      "🍛",
      "🥟",
      "🍜",
      "🍢",
      "🦪",
      "🍙",
      "🍘",
      "🍰",
      "🍥",
      "🍮",
      "🍡",
      "🎂",
      "🥠",
      "🧁",
      "🥮",
      "🍭",
      "🍧",
      "🍬",
      "🍨",
      "🍫",
      "🍦",
      "🍩",
      "🥧",
      "🍪",
      "🍯",
      "🥛",
      "🧂",
      "🍼",
      "🧈",
      "🍵",
      "🍿",
      "☕",
      "🧊",
      "🫖",
      "🫙",
      "🧉",
      "🥤",
      "🍺",
      "🧋",
      "🍻",
      "🧃",
      "🥂",
      "🍾",
      "🍷",
      "🥃",
      "🫗",
      "🍸",
      "🍹",
      "🍶",
      "🥢",
      "🍴",
      "🥄",
      "🔪",
      "🍽️"
    ],
    'Транспорт': [
      "🛑",
      "🚧",
      "🚨",
      "⛽",
      "🛢️",
      "🧭",
      "🛞",
      "🛟",
      "⚓",
      "🚲",
      "🩼",
      "🦼",
      "🦽",
      "🛴",
      "🚦",
      "🚥",
      "🚇",
      "🚏",
      "🛵",
      "🏍️",
      "🚙",
      "🚗",
      "🛻",
      "🚐",
      "🚚",
      "🚛",
      "🚜",
      "🏎️",
      "🚒",
      "🚑",
      "🚓",
      "🚕",
      "🛺",
      "🚌",
      "🚈",
      "🚝",
      "🚉",
      "🚊",
      "🚞",
      "🚎",
      "🚋",
      "🚃",
      "🚂",
      "🚄",
      "🚅",
      "🚍",
      "🚔",
      "🚘",
      "🚖",
      "🚆",
      "🚢",
      "🛳️",
      "🛥️",
      "🚤",
      "⛴️",
      "⛵",
      "🛶",
      "🚟",
      "🚠",
      "🚡",
      "🚁",
      "🛸",
      "🚀",
      "🎪",
      "🎠",
      "🎡",
      "🎢",
      "🛝",
      "🛩️",
      "🛬",
      "🛫",
      "✈️",
      "🗼",
      "🗽",
      "🗿",
      "🗻",
      "🏛️",
      "💈",
      "⛲",
      "⛩️",
      "🕍",
      "🏗️",
      "🏰",
      "🏯",
      "🏩",
      "💒",
      "⛪",
      "🛕",
      "🕋",
      "🕌",
      "🏢",
      "🏤",
      "🏭",
      "🏥",
      "🏬",
      "🏚️",
      "🏪",
      "🏠",
      "🏟️",
      "🏡",
      "🏦",
      "🏘️",
      "🏫",
      "🛖",
      "🏨",
      "⛺",
      "🏣",
      "🏕️",
      "🛣️",
      "🛤️",
      "🌁",
      "🌉",
      "🌃",
      "🌇",
      "🌆",
      "🏙️",
      "⛱️",
      "🗾",
      "🗺️",
      "🌐",
      "💺",
      "🧳"
    ],
    'Спорт': [
      "🎗️",
      "🥇",
      "🥈",
      "🥉",
      "🏅",
      "🎖️",
      "🏆",
      "📢",
      "⚽",
      "⚾",
      "🥎",
      "🏀",
      "🏐",
      "🏈",
      "🏉",
      "🛷",
      "🥌",
      "🏒",
      "🏑",
      "🏏",
      "🥍",
      "🏸",
      "🎾",
      "🥅",
      "🎿",
      "⛸️",
      "🛼",
      "🩰",
      "🛹",
      "⛳",
      "🎯",
      "🏹",
      "🥏",
      "🪃",
      "🏓",
      "🪁",
      "🎳",
      "🎣",
      "♟️",
      "🤿",
      "🪀",
      "🩱",
      "🧩",
      "🎽",
      "🎮",
      "🥋",
      "🕹️",
      "🥊",
      "👾",
      "🎱",
    ],
    'Природа': [
      "💐",
      "🌹",
      "🥀",
      "🌺",
      "🌷",
      "🪷",
      "🌸",
      "💮",
      "🏵️",
      "🪻",
      "🌻",
      "🌼",
      "🍂",
      "🍁",
      "🍄",
      "🌾",
      "🌱",
      "🌿",
      "🍃",
      "☘️",
      "🍀",
      "🪴",
      "🌵",
      "🌴",
      "🌳",
      "🌲",
      "🪵",
      "🪹",
      "🪺",
      "🪨",
      "⛰️",
      "🏔️",
      "❄️",
      "☃️",
      "⛄",
      "🌫️",
      "🌄",
      "🌅",
      "🏖️",
      "🏝️",
      "🏞️",
      "🏜️",
      "🌋",
      "🔥",
      "🌡️",
      "🌈",
      "🫧",
      "🌊",
      "🌬️",
      "🌀",
      "🌪️",
      "⚡",
      "☔",
      "💧",
      "🌤️",
      "⛅",
      "🌥️",
      "🌦️",
      "☁️",
      "🌨️",
      "⛈️",
      "🌩️",
      "🌧️",
      "☀️",
      "🌞",
      "🌝",
      "🌚",
      "🌜",
      "🌛",
      "⭐",
      "🌟",
      "✨",
      "🌏",
      "🌎",
      "🌍",
      "🌌",
      "🌠",
      "🕳️",
      "☄️",
      "🌙",
      "💫",
      "🪐",
      "🌑",
      "🌒",
      "🌓",
      "🌔",
      "🌕",
      "🌖",
      "🌗",
      "🌘",
    ],
    'Погода': [
      '☀️',
      '🌤',
      '⛅',
      '🌥',
      '☁️',
      '🌦',
      '🌧',
      '⛈',
      '🌩',
      '🌨',
      '❄️',
      '🌪',
      '🌫',
      '🌬',
      '🌈'
    ],
    'Символы': [
      "🔴",
      "🟠",
      "🟡",
      "🟢",
      "🔵",
      "🟣",
      "🟤",
      "⚫",
      "⚪",
      "🟥",
      "🟧",
      "🟨",
      "🟩",
      "🟪",
      "🟫",
      "⬛",
      "⬜",
      "❤️",
      "🧡",
      "💛",
      "💙",
      "💙",
      "💜",
      "🤎",
      "🖤",
      "🤍",
      "🩷",
      "🩵",
      "🩶",
      "♥️",
      "♦️",
      "♣️",
      "♠️",
      "♈",
      "♉",
      "♊",
      "♋",
      "♌",
      "♍",
      "♎",
      "♐",
      "♑",
      "♒",
      "♏",
      "♓",
      "⛎",
      "♀️",
      "♂️",
      "⚧️",
      "💭",
      "🗯️",
      "💬",
      "🗨️",
      "❕",
      "❗",
      "❔",
      "❓",
      "⁉️",
      "‼️",
      "⭕",
      "❌",
      "🚫",
      "🚳",
      "🚭",
      "🚯",
      "🚱",
      "🚷",
      "📵",
      "🔞",
      "🔕",
      "🔇",
      "🅰️",
      "🆎",
      "🅱️",
      "🅾️",
      "🆑",
      "🆘",
      "🛑",
      "⛔",
      "📛",
      "🈹",
      "🈲",
      "🉑",
      "🈶",
      "🈚",
      "🈸",
      "🈺",
      "🈷️",
      "✴️",
      "🉐",
      "㊙️",
      "㊗️",
      "🈴",
      "🈵",
      "♨️",
      "💢",
      "🔻",
      "🔺",
      "🔀",
      "▶️",
      "⏩",
      "⏭️",
      "⏯️",
      "◀️",
      "⏪",
      "⏮️",
      "🔼",
      "🔂",
      "🔁",
      "📶",
      "🎦",
      "🆚",
      "🔅",
      "🔆",
      "⏫",
      "🔽",
      "⏬",
      "⏸️",
      "⏹️",
      "⏺️",
      "⏏️",
      "📴",
      "🛜",
      "📳",
      "📲",
      "🔈",
      "🔉",
      "🔊",
      "🎼",
      "🎵",
      "🎶",
      "☢️",
      "❇️",
      "✳️",
      "🔰",
      "〽️",
      "⚜️",
      "🔱",
      "🚸",
      "⚠️",
      "☣️",
      "♻️",
      "💱",
      "💲",
      "💹",
      "🈯",
      "❎",
      "✅",
      "✔️",
      "☑️",
      "⬆️",
      "↗️",
      "➡️",
      "↘️",
      "⬇️",
      "↙️",
      "⬅️",
      "↖️",
      "↕️",
      "🔛",
      "🔙",
      "🔄",
      "🔃",
      "⤵️",
      "⤴️",
      "↪️",
      "↩️",
      "↔️",
      "🔝",
      "🔚",
      "🔜",
      "🆕",
      "🆓",
      "🆙",
      "🆗",
      "🆒",
      "🆖",
      "🔡",
      "🔠",
      "🔤",
      "🔣",
      "🈳",
      "🈂️",
      "🈁",
      "🅿️",
      "ℹ️",
      "🔢",
      "#️⃣",
      "*️⃣",
      "0️⃣",
      "1️⃣",
      "2️⃣",
      "3️⃣",
      "4️⃣",
      "5️⃣",
      "6️⃣",
      "7️⃣",
      "8️⃣",
      "9️⃣",
      "🔟",
      "💠",
      "🔷",
      "🔹",
      "🌐",
      "🏧",
      "Ⓜ️",
      "🚾",
      "🚻",
      "🚹",
      "🚺",
      "♿",
      "🚼",
      "🛗",
      "🛅",
      "🛄",
      "🛃",
      "🛂",
      "🚰",
      "🚮",
      "💟",
      "⚛️",
      "🛐",
      "🕉️",
      "🔯",
      "☸️",
      "🕎",
      "☮️",
      "♾️",
      "☯️",
      "🆔",
      "☪️",
      "🪯",
      "✝️",
      "☦️",
      "✡️",
      "➕",
      "➖",
      "✖️",
      "➗",
      "⚕️",
      "🟰",
      "➰",
      "➿",
      "〰️",
      "©️",
      "®️",
      "™️",
      "🔘",
      "🔳",
      "◼️",
      "◾",
      "▪️",
      "🔲",
      "◻️",
      "◽",
      "▫️",
      "👁️‍🗨️"
    ],
    'Флаги': [
      "🏁",
      "🚩",
      "🎌",
      "🏴",
      "🏳️",
      "🏳️‍🌈",
      "🏳️‍⚧️",
      "🏴‍☠️",
      "🇦🇨",
      "🇦🇩",
      "🇦🇷",
      "🇦🇪",
      "🇦🇸",
      "🇦🇫",
      "🇦🇹",
      "🇦🇬",
      "🇦🇺",
      "🇦🇮",
      "🇦🇼",
      "🇦🇱",
      "🇦🇽",
      "🇦🇲",
      "🇦🇿",
      "🇦🇴",
      "🇧🇦",
      "🇦🇶",
      "🇧🇧",
      "🇧🇩",
      "🇧🇪",
      "🇧🇫",
      "🇧🇬",
      "🇧🇭",
      "🇧🇮",
      "🇧🇯",
      "🇧🇱",
      "🇧🇲",
      "🇧🇳",
      "🇧🇿",
      "🇧🇴",
      "🇨🇦",
      "🇧🇶",
      "🇨🇨",
      "🇧🇷",
      "🇨🇩",
      "🇧🇸",
      "🇨🇫",
      "🇧🇹",
      "🇨🇬",
      "🇧🇻",
      "🇨🇭",
      "🇧🇼",
      "🇨🇮",
      "🇧🇾",
      "🇨🇰",
      "🇨🇼",
      "🇩🇴",
      "🇨🇻",
      "🇩🇲",
      "🇨🇺",
      "🇩🇰",
      "🇩🇯",
      "🇨🇷",
      "🇨🇵",
      "🇩🇬",
      "🇨🇴",
      "🇩🇪",
      "🇨🇳",
      "🇨🇿",
      "🇨🇲",
      "🇨🇾",
      "🇨🇱",
      "🇨🇽",
      "🇩🇿",
      "🇪🇺",
      "🇪🇦",
      "🇫🇮",
      "🇪🇨",
      "🇫🇯",
      "🇪🇪",
      "🇫🇰",
      "🇪🇬",
      "🇫🇲",
      "🇪🇭",
      "🇫🇴",
      "🇪🇷",
      "🇫🇷",
      "🇪🇸",
      "🇬🇦",
      "🇪🇹",
      "🇬🇧",
      "🇬🇩",
      "🇬🇵",
      "🇬🇪",
      "🇬🇶",
      "🇬🇫",
      "🇬🇷",
      "🇬🇬",
      "🇬🇸",
      "🇬🇭",
      "🇬🇹",
      "🇬🇮",
      "🇬🇺",
      "🇬🇱",
      "🇬🇼",
      "🇬🇲",
      "🇬🇾",
      "🇬🇳",
      "🇭🇰",
      "🇭🇲",
      "🇮🇲",
      "🇭🇳",
      "🇮🇳",
      "🇭🇷",
      "🇮🇴",
      "🇭🇹",
      "🇮🇶",
      "🇭🇺",
      "🇮🇷",
      "🇮🇨",
      "🇮🇸",
      "🇮🇩",
      "🇮🇹",
      "🇮🇪",
      "🇯🇪",
      "🇮🇱",
      "🇯🇲",
      "🇯🇴",
      "🇰🇷",
      "🇯🇵",
      "🇰🇼",
      "🇰🇪",
      "🇰🇾",
      "🇰🇭",
      "🇰🇿",
      "🇰🇮",
      "🇱🇧",
      "🇰🇲",
      "🇱🇨",
      "🇰🇳",
      "🇱🇮",
      "🇰🇵",
      "🇱🇰",
      "🇱🇷",
      "🇲🇪",
      "🇱🇸",
      "🇲🇫",
      "🇱🇹",
      "🇲🇬",
      "🇱🇺",
      "🇲🇭",
      "🇱🇻",
      "🇲🇰",
      "🇱🇾",
      "🇲🇱",
      "🇲🇦",
      "🇲🇲",
      "🇲🇨",
      "🇲🇳",
      "🇲🇩",
      "🇲🇴",
      "🇲🇵",
      "🇲🇾",
      "🇲🇶",
      "🇲🇿",
      "🇲🇷",
      "🇳🇦",
      "🇲🇸",
      "🇳🇨",
      "🇲🇹",
      "🇳🇪",
      "🇲🇺",
      "🇳🇫",
      "🇲🇻",
      "🇳🇬",
      "🇲🇼",
      "🇳🇮",
      "🇲🇽",
      "🇳🇱",
      "🇳🇴",
      "🇵🇬",
      "🇳🇵",
      "🇵🇭",
      "🇳🇷",
      "🇵🇰",
      "🇳🇺",
      "🇵🇱",
      "🇳🇿",
      "🇵🇲",
      "🇴🇲",
      "🇵🇳",
      "🇵🇦",
      "🇵🇷",
      "🇵🇪",
      "🇵🇸",
      "🇵🇫",
      "🇵🇹",
      "🇵🇼",
      "🇸🇧",
      "🇵🇾",
      "🇸🇨",
      "🇶🇦",
      "🇸🇩",
      "🇷🇪",
      "🇸🇪",
      "🇷🇴",
      "🇸🇬",
      "🇷🇸",
      "🇸🇭",
      "🇷🇺",
      "🇸🇮",
      "🇷🇼",
      "🇸🇯",
      "🇸🇦",
      "🇸🇰",
      "🇸🇽",
      "🇹🇯",
      "🇸🇻",
      "🇹🇭",
      "🇸🇹",
      "🇹🇬",
      "🇸🇸",
      "🇹🇫",
      "🇸🇷",
      "🇹🇩",
      "🇸🇴",
      "🇹🇨",
      "🇸🇳",
      "🇹🇦",
      "🇸🇲",
      "🇸🇿",
      "🇸🇱",
      "🇸🇾",
      "🇹🇰",
      "🇹🇿",
      "🇹🇱",
      "🇺🇦",
      "🇹🇲",
      "🇺🇬",
      "🇹🇳",
      "🇺🇲",
      "🇹🇴",
      "🇺🇳",
      "🇹🇷",
      "🇺🇸",
      "🇹🇹",
      "🇺🇾",
      "🇹🇻",
      "🇺🇿",
      "🇹🇼",
      "🇻🇦",
      "🇽🇰",
      "🇼🇸",
      "🏴󠁧󠁢󠁷󠁬󠁳󠁿",
      "🇼🇫",
      "🏴󠁧󠁢󠁳󠁣󠁴󠁿",
      "🇻🇺",
      "🏴󠁧󠁢󠁥󠁮󠁧󠁿",
      "🇻🇳",
      "🇿🇼",
      "🇻🇮",
      "🇿🇲",
      "🇿🇦",
      "🇻🇬",
      "🇻🇪",
      "🇾🇹",
      "🇻🇨",
      "🇾🇪"
    ],
    'Объекты': [
      "📱",
      "☎️",
      "📞",
      "📟",
      "📠",
      "🔌",
      "🔋",
      "🪫",
      "🖲️",
      "🖱️",
      "🖨️",
      "⌨️",
      "💻",
      "🖥️",
      "📀",
      "💿",
      "💾",
      "💽",
      "🪙",
      "💸",
      "💵",
      "💴",
      "💶",
      "💷",
      "💳",
      "💰",
      "🧾",
      "🧱",
      "🏮",
      "🔦",
      "💡",
      "🕯️",
      "🛍️",
      "🛒",
      "⚖️",
      "🧮",
      "🪟",
      "🧻",
      "🪞",
      "🪠",
      "🚪",
      "🧸",
      "🪑",
      "🪆",
      "🛏️",
      "🧷",
      "🛋️",
      "🪢",
      "🚿",
      "🧹",
      "🛁",
      "🚽",
      "🧴",
      "🧽",
      "👖",
      "👙",
      "🧣",
      "🩱",
      "🧤",
      "🥻",
      "🧦",
      "👘",
      "🧺",
      "👗",
      "🪮",
      "🪒",
      "🪥",
      "🎽",
      "👚",
      "👔",
      "👕",
      "🧼",
      "🩳",
      "🩲",
      "🧥",
      "🥼",
      "🦺",
      "⛑️",
      "🪖",
      "🎓",
      "🎩",
      "💼",
      "👜",
      "👛",
      "👝",
      "🎒",
      "🪭",
      "👑",
      "🧢",
      "👒",
      "🧳",
      "☂️",
      "🌂",
      "💍",
      "💎",
      "💄",
      "👠",
      "👟",
      "👞",
      "🥽",
      "👓",
      "🕶️",
      "🦯",
      "🥾",
      "👢",
      "👡",
      "🩴",
      "🥿",
      "⚗️",
      "🧫",
      "🧪",
      "🌡️",
      "💉",
      "💊",
      "🩹",
      "🩺",
      "🩻",
      "🪣",
      "🔨",
      "🪜",
      "🔧",
      "🪓",
      "🪚",
      "🧯",
      "🪛",
      "🛰️",
      "🔩",
      "📡",
      "🗜️",
      "🔬",
      "🧰",
      "🔭",
      "🧲",
      "🧬",
      "🪝",
      "⚒️",
      "🛠️",
      "⛏️",
      "⚙️",
      "🔗",
      "⛓️",
      "📎",
      "🖇️",
      "📏",
      "📐",
      "🖌️",
      "🖍️",
      "🖊️",
      "🖋️",
      "✒️",
      "✏️",
      "📝",
      "📖",
      "🔖",
      "📙",
      "📘",
      "📗",
      "📓",
      "📕",
      "📔",
      "📒",
      "📚",
      "🗒️",
      "📄",
      "📃",
      "📋",
      "📑",
      "📂",
      "📁",
      "🗂️",
      "🗃️",
      "✂️",
      "📍",
      "📌",
      "🪪",
      "📇",
      "📉",
      "📈",
      "📊",
      "🗄️",
      "🗑️",
      "📰",
      "🗞️",
      "🏷️",
      "📦",
      "📫",
      "📪",
      "📬",
      "📭",
      "📮",
      "✉️",
      "📧",
      "📩",
      "📨",
      "💌",
      "📤",
      "📥",
      "🗳️",
      "🕛",
      "🕧",
      "🕐",
      "🕜",
      "🕑",
      "🕝",
      "🕒",
      "🕞",
      "🕓",
      "🕟",
      "🕔",
      "🕠",
      "🕕",
      "🕡",
      "🕖",
      "🕢",
      "🕗",
      "🕣",
      "🕘",
      "🕤",
      "🕙",
      "🕥",
      "🕚",
      "🕦",
      "⏱️",
      "⌚",
      "🕰️",
      "⌛",
      "⏳",
      "⏲️",
      "⏰",
      "📅",
      "📆",
      "🗓️",
      "🪧",
      "🛎️",
      "🔔",
      "📯",
      "📢",
      "📣",
      "🔍",
      "🔎",
      "🔮",
      "🧿",
      "🪬",
      "📿",
      "🏺",
      "⚱️",
      "⚰️",
      "🪦",
      "🚬",
      "💣",
      "🪤",
      "📜",
      "⚔️",
      "🗡️",
      "🛡️",
      "🗝️",
      "🔑",
      "🔐",
      "🔏",
      "🔒",
      "🔓"
    ],
    // 'ЩЩ': [],
  };

  final Map<String, IconData> emojiCategoryIcons = {
    'Смайлики': Icons.emoji_emotions_outlined,
    'Анимации': Icons.animation,
    'Животные': Icons.pets_outlined,
    'Еда': Icons.fastfood_outlined,
    'Транспорт': Icons.directions_car_outlined,
    'Спорт': Icons.sports_soccer_outlined,
    'Природа': Icons.nature_outlined,
    'Погода': Icons.wb_sunny_outlined,
    'Символы': Icons.favorite_outlined,
    'Флаги': Icons.flag_outlined,
    'Объекты': Icons.phone_iphone_outlined,
  };

  Future<void> _loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final draftJson = prefs.getString('$_draftKeyPrefix.${widget.chatId}');
    if (draftJson != null) {
      final draft = Draft.fromJson(jsonDecode(draftJson));
      setState(() {
        _controller.text = draft.text;
        widget.replyMessageNotifier.value = draft.replyMessage;
      });
    }
  }

  Future<void> _saveDraft(String text) async {
    final prefs = await SharedPreferences.getInstance();
    final draft =
        Draft(text: text, replyMessage: widget.replyMessageNotifier.value);
    final draftJson = jsonEncode(draft.toJson());
    await prefs.setString('$_draftKeyPrefix.${widget.chatId}', draftJson);
  }

  Future<void> _clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_draftKeyPrefix.${widget.chatId}');
    widget.replyMessageNotifier.value = null;
  }

  void _pickImage() async {
    if (widget.chatId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Чат еще не создан. Отправьте текстовое сообщение, чтобы начать чат.'),
        ),
      );
      return;
    }

    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final File file = File(image.path);
      if (file.lengthSync() <= 20 * 1024 * 1024) {
        _showPhotoEditor(file);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Файл слишком большой. Максимальный размер 20 МБ.'),
          ),
        );
      }
    }
  }

  void _showPhotoEditor(File imageFile) {
    if (widget.chatId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Чат еще не создан. Отправьте текстовое сообщение, чтобы начать чат.'),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProImageEditor.file(
          imageFile,
          configs: ProImageEditorConfigs(
            i18n: I18n(
              layerInteraction: const I18nLayerInteraction(
                remove: 'Удалить',
                edit: 'Редактировать',
                rotateScale: 'Повернуть и масштабировать',
              ),
              paintEditor: const I18nPaintEditor(
                moveAndZoom: 'Масштаб',
                bottomNavigationBarText: 'Рисование',
                freestyle: 'Свободное рисование',
                arrow: 'Стрелка',
                line: 'Линия',
                rectangle: 'Прямоугольник',
                circle: 'Круг',
                dashLine: 'Пунктирная линия',
                blur: 'Размытие',
                pixelate: 'Пикселизация',
                lineWidth: 'Толщина линии',
                eraser: 'Ластик',
                toggleFill: 'Заливка',
                changeOpacity: 'Изменить прозрачность',
                undo: 'Отменить',
                redo: 'Повторить',
                done: 'Готово',
                back: 'Назад',
                smallScreenMoreTooltip: 'Ещё',
              ),
              textEditor: const I18nTextEditor(
                inputHintText: 'Введите текст',
                bottomNavigationBarText: 'Текст',
                back: 'Назад',
                done: 'Готово',
                textAlign: 'Выравнивание текста',
                fontScale: 'Масштаб шрифта',
                backgroundMode: 'Фоновый режим',
                smallScreenMoreTooltip: 'Ещё',
              ),
              cropRotateEditor: const I18nCropRotateEditor(
                bottomNavigationBarText: 'Обрезка/Поворот',
                rotate: 'Повернуть',
                flip: 'Отразить',
                ratio: 'Соотношение сторон',
                back: 'Назад',
                done: 'Готово',
                cancel: 'Отмена',
                undo: 'Отменить',
                redo: 'Повторить',
                smallScreenMoreTooltip: 'Ещё',
                reset: 'Сбросить',
              ),
              tuneEditor: const I18nTuneEditor(
                bottomNavigationBarText: 'Настройки',
                back: 'Назад',
                done: 'Готово',
                brightness: 'Яркость',
                contrast: 'Контраст',
                saturation: 'Насыщенность',
                exposure: 'Экспозиция',
                hue: 'Тон',
                temperature: 'Температура',
                sharpness: 'Резкость',
                fade: 'Затухание',
                luminance: 'Яркость',
                undo: 'Отменить',
                redo: 'Повторить',
              ),
              filterEditor: const I18nFilterEditor(
                bottomNavigationBarText: 'Фильтры',
                back: 'Назад',
                done: 'Готово',
                filters: const I18nFilters(
                  none: 'Без фильтра',
                  addictiveBlue: 'Синий оттенок',
                  addictiveRed: 'Красный оттенок',
                  aden: 'Aden',
                  amaro: 'Amaro',
                  ashby: 'Ashby',
                  brannan: 'Brannan',
                  brooklyn: 'Brooklyn',
                  charmes: 'Charmes',
                  clarendon: 'Clarendon',
                  crema: 'Crema',
                  dogpatch: 'Dogpatch',
                  earlybird: 'Earlybird',
                  f1977: '1977',
                  gingham: 'Gingham',
                  ginza: 'Ginza',
                  hefe: 'Hefe',
                  helena: 'Helena',
                  hudson: 'Hudson',
                  inkwell: 'Inkwell',
                  juno: 'Juno',
                  kelvin: 'Kelvin',
                  lark: 'Lark',
                  loFi: 'Lo-Fi',
                  ludwig: 'Ludwig',
                  maven: 'Maven',
                  mayfair: 'Mayfair',
                  moon: 'Moon',
                  nashville: 'Nashville',
                  perpetua: 'Perpetua',
                  reyes: 'Reyes',
                  rise: 'Rise',
                  sierra: 'Sierra',
                  skyline: 'Skyline',
                  slumber: 'Slumber',
                  stinson: 'Stinson',
                  sutro: 'Sutro',
                  toaster: 'Toaster',
                  valencia: 'Valencia',
                  vesper: 'Vesper',
                  walden: 'Walden',
                  willow: 'Willow',
                  xProII: 'X-Pro II',
                ),
              ),
              blurEditor: const I18nBlurEditor(
                bottomNavigationBarText: 'Размытие',
                back: 'Назад',
                done: 'Готово',
              ),
              emojiEditor: const I18nEmojiEditor(
                bottomNavigationBarText: 'Эмодзи',
                search: 'Поиск',
                categoryRecent: 'Недавние',
                categorySmileys: 'Смайлы и люди',
                categoryAnimals: 'Животные и природа',
                categoryFood: 'Еда и напитки',
                categoryActivities: 'Активности',
                categoryTravel: 'Путешествия и места',
                categoryObjects: 'Объекты',
                categorySymbols: 'Символы',
                categoryFlags: 'Флаги',
              ),
              stickerEditor: const I18nStickerEditor(
                bottomNavigationBarText: 'Стикеры',
              ),
              various: const I18nVarious(
                loadingDialogMsg: 'Пожалуйста, подождите...',
                closeEditorWarningTitle: 'Закрыть редактор изображений?',
                closeEditorWarningMessage:
                    'Вы уверены, что хотите закрыть редактор изображений? Ваши изменения не будут сохранены.',
                closeEditorWarningConfirmBtn: 'ОК',
                closeEditorWarningCancelBtn: 'Отмена',
              ),
              importStateHistoryMsg: 'Инициализация редактора',
              cancel: 'Отмена',
              undo: 'Отменить',
              redo: 'Повторить',
              done: 'Готово',
              remove: 'Удалить',
              doneLoadingMsg: 'Изменения применяются',
            ),
          ),
          callbacks: ProImageEditorCallbacks(
            onImageEditingComplete: (Uint8List bytes) async {
              try {
                // Создаем временный файл
                final tempDir = await getTemporaryDirectory();
                var tempFile =
                    File('${tempDir.path}/edited_image${DateTime.now()}.png');
                if (Platform.isWindows) {
                  tempFile = File(
                      '${tempDir.path}\\edited_image${DateTime.now().millisecondsSinceEpoch}.png');
                }
                await tempFile.writeAsBytes(bytes);

                // Загружаем фото на сервер
                final String? photoUrl = await _uploadPhoto(tempFile);
                if (photoUrl != null) {
                  // Передаем URL загруженного фото в коллбэк
                  widget.onSendPhoto(photoUrl);
                } else {
                  // Обработка случая, если загрузка не удалась
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Не удалось загрузить изображение')),
                  );
                }
              } catch (e) {
                print(e);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Произошла ошибка: $e')),
                );
              } finally {
                // Закрываем редактор
                Navigator.pop(context);
              }
            },
          ),
        ),
      ),
    );
  }

  Future<String?> _uploadPhoto(File file) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedUser = prefs.getString('cached_user');
    if (cachedUser != null) {
      final token =
          UserModel.fromJson(json.decode(cachedUser) as Map<String, dynamic>)
              .token;
      if (token != null && token.isNotEmpty) {
        final uri = Uri.parse(
            '${Constants.baseUrl}${Constants.uploadPhotoEndpoint}${widget.chatId}');
        final request = http.MultipartRequest('POST', uri);
        request.fields['chatId'] = widget.chatId!;
        request.headers['Authorization'] = 'Bearer $token';
        request.files.add(await http.MultipartFile.fromPath('file', file.path));

        final response = await request.send();
        if (response.statusCode == 200) {
          final responseBody = await response.stream.bytesToString();
          final jsonResponse = json.decode(responseBody);
          return jsonResponse['fileUrl'];
        } else {
          print('Ошибка при загрузке файла: ${response.statusCode}');
          return null;
        }
      } else {
        print('Токен отсутствует или пуст');
        return null;
      }
    } else {
      print('Кэшированный пользователь недоступен');
      return null;
    }
  }

  void _toggleEmojiPicker() {
    setState(() {
      _showEmojiPicker = !_showEmojiPicker;
      if (_showEmojiPicker) {
        _focusNode.unfocus(); // Скрываем клавиатуру
      } else {
        _focusNode.requestFocus(); // Показываем клавиатуру
      }
    });
  }

  void _onEmojiSelected(String emoji) {
    _controller.text += emoji;
  }

  void _sendVoiceMessage() {
    // Implement voice message functionality here
  }

  void _applyStyle(String tag) {
    final selection = _controller.selection;
    final selectedText = selection.textInside(_controller.text);
    var newText = "";
    if (tag == "```") {
      newText = '$tag$selectedText$tag';
    } else {
      newText = '<$tag>$selectedText<$tag>';
    }

    _controller.text = _controller.text.replaceRange(
      selection.start,
      selection.end,
      newText,
    );

    // Обновляем позицию курсора
    _controller.selection =
        TextSelection.collapsed(offset: selection.start + newText.length);
  }

  @override
  Widget build(BuildContext context) {
    final colors = isWhiteNotifier.value ? AppColors.light() : AppColors.dark();

    return Container(
      color: colors.backgroundColor,
      child: Column(
        children: [
          // Отображение редактируемого сообщения
          ValueListenableBuilder<Message?>(
            valueListenable: ChatStateManager.instance.editingMessageNotifier,
            builder: (context, editingMessage, _) {
              if (editingMessage != null) {
                return Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  decoration: BoxDecoration(
                    color: colors.cardColor,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  padding: const EdgeInsets.all(8.0),
                  margin: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 4.0),
                  child: IntrinsicWidth(
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 16, color: colors.iconColor),
                        SizedBox(width: 8),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              children: _formatMessageContent(
                                editingMessage.content,
                                editingMessage.senderId,
                                widget.userId,
                              ),
                              style: TextStyle(
                                fontSize: 12.0,
                                color: colors.textColor,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        GestureDetector(
                          onTap: _cancelEditing,
                          child: Icon(
                            Icons.close,
                            size: 16,
                            color: colors.textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          ValueListenableBuilder<Message?>(
            valueListenable: widget.replyMessageNotifier,
            builder: (context, replyMessage, _) {
              _saveDraft(_controller.text);
              if (replyMessage != null) {
                final bool isPhoto = isPhotoUrl(replyMessage.content);
                final bool isLottie =
                    replyMessage.content.startsWith('::animation_emoji/');

                return Center(
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    decoration: BoxDecoration(
                      color: colors.cardColor,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    padding: const EdgeInsets.all(8.0),
                    margin: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 4.0),
                    child: IntrinsicWidth(
                      child: Row(
                        children: [
                          Expanded(
                            child: isPhoto
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8.0),
                                    child: Image.network(
                                      replyMessage.content,
                                      fit: BoxFit.cover,
                                      width: 100,
                                      height: 100,
                                      loadingBuilder:
                                          (context, child, loadingProgress) {
                                        if (loadingProgress == null)
                                          return child;
                                        return Center(
                                          child: CircularProgressIndicator(
                                            value: loadingProgress
                                                        .expectedTotalBytes !=
                                                    null
                                                ? loadingProgress
                                                        .cumulativeBytesLoaded /
                                                    loadingProgress
                                                        .expectedTotalBytes!
                                                : null,
                                          ),
                                        );
                                      },
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return const Icon(Icons.error);
                                      },
                                    ),
                                  )
                                : isLottie
                                    ? Lottie.asset(
                                        replyMessage.content
                                            .replaceFirst(
                                                '::animation_emoji/', '')
                                            .replaceAll('::', ''),
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                      )
                                    : RichText(
                                        text: TextSpan(
                                          children: _formatMessageContent(
                                            replyMessage.content,
                                            replyMessage.senderId,
                                            widget.userId,
                                          ),
                                          style: TextStyle(
                                            fontSize: 12.0,
                                            color: colors.textColor,
                                          ),
                                        ),
                                      ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              widget.replyMessageNotifier.value = null;
                            },
                            child: Icon(
                              Icons.close,
                              size: 16,
                              color: colors.textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.emoji_emotions, color: colors.iconColor),
                  onPressed: _toggleEmojiPicker,
                ),
                Expanded(
                  child: ValueListenableBuilder<Message?>(
                    valueListenable:
                        ChatStateManager.instance.editingMessageNotifier,
                    builder: (context, editingMessage, _) {
                      if (editingMessage != null) {
                        _controller.text = editingMessage.content;
                        _controller.selection = TextSelection.fromPosition(
                          TextPosition(offset: _controller.text.length),
                        );
                      } else {
                        // _controller.clear();
                      }

                      return TextField(
                        keyboardType: TextInputType.multiline,
                        textCapitalization: TextCapitalization.sentences,
                        style: TextStyle(
                          color: colors.textColor,
                          fontFamily: "NotoColorEmoji",
                        ),
                        controller: _controller,
                        focusNode: _focusNode,
                        autofocus: true,
                        minLines: 1,
                        maxLines: 8,
                        textInputAction: Platform.isAndroid
                            ? TextInputAction.newline
                            : TextInputAction.send,
                        scrollPhysics: const AlwaysScrollableScrollPhysics(),
                        contextMenuBuilder:
                            (context, EditableTextState editableTextState) {
                          final List<ContextMenuButtonItem> buttonItems = [];

                          if (editableTextState
                              .textEditingValue.selection.isCollapsed) {
                            // Если текст не выделен, показываем стандартное меню
                            return AdaptiveTextSelectionToolbar.buttonItems(
                              anchors: editableTextState.contextMenuAnchors,
                              buttonItems: [
                                ContextMenuButtonItem(
                                  onPressed: () => editableTextState
                                      .pasteText(SelectionChangedCause.toolbar),
                                  label: 'Вставить',
                                ),
                                ContextMenuButtonItem(
                                  onPressed: () => editableTextState
                                      .selectAll(SelectionChangedCause.toolbar),
                                  label: 'Выделить всё',
                                ),
                              ],
                            );
                          } else {
                            // Если текст выделен, показываем пользовательское меню
                            buttonItems.addAll([
                              ContextMenuButtonItem(
                                onPressed: () =>
                                    editableTextState.copySelection(
                                        SelectionChangedCause.toolbar),
                                label: 'Копировать',
                              ),
                              ContextMenuButtonItem(
                                onPressed: () => editableTextState.cutSelection(
                                    SelectionChangedCause.toolbar),
                                label: 'Вырезать',
                              ),
                              ContextMenuButtonItem(
                                onPressed: () => editableTextState
                                    .pasteText(SelectionChangedCause.toolbar),
                                label: 'Вставить',
                              ),
                              ContextMenuButtonItem(
                                onPressed: () => editableTextState
                                    .selectAll(SelectionChangedCause.toolbar),
                                label: 'Выделить всё',
                              ),
                              ContextMenuButtonItem(
                                onPressed: () => _applyStyle('b'),
                                label: 'Жирный',
                              ),
                              ContextMenuButtonItem(
                                onPressed: () => _applyStyle('i'),
                                label: 'Курсив',
                              ),
                              ContextMenuButtonItem(
                                onPressed: () => _applyStyle('u'),
                                label: 'Подчеркнутый',
                              ),
                              ContextMenuButtonItem(
                                onPressed: () => _applyStyle('del'),
                                label: 'Зачеркнутый',
                              ),
                              ContextMenuButtonItem(
                                onPressed: () => _applyStyle('mark'),
                                label: 'Выделить',
                              ),
                              ContextMenuButtonItem(
                                onPressed: () => _applyStyle("```"),
                                label: 'Код',
                              ),
                            ]);

                            return AdaptiveTextSelectionToolbar.buttonItems(
                              buttonItems: buttonItems,
                              anchors: editableTextState.contextMenuAnchors,
                            );
                          }
                        },
                        onChanged: (text) {
                          _startTypingTimer();
                          _saveDraft(text);
                          if (text.length > 2000) {
                            _controller.text = text.substring(0, 2000);
                            _controller.selection = TextSelection.fromPosition(
                              TextPosition(offset: _controller.text.length),
                            );
                          }
                        },
                        onSubmitted: (text) {
                          final isShiftPressed =
                              HardwareKeyboard.instance.isShiftPressed;
                          if (Platform.isWindows && !isShiftPressed) {
                            if (ChatStateManager
                                    .instance.editingMessageNotifier.value !=
                                null) {
                              _sendEditedMessage();
                            } else {
                              _sendMessage();
                              _clearDraft();
                            }
                          }
                          FocusScope.of(context).requestFocus(_focusNode);
                        },
                        decoration: InputDecoration(
                          hintText: 'Сообщение',
                          hintStyle: TextStyle(color: colors.hintColor),
                          filled: true,
                          fillColor: colors.cardColor,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 8.0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20.0),
                            borderSide: BorderSide.none, // Убираем обводку
                          ),
                        ),
                      );
                    },
                  ),
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: _hasTextNotifier,
                  builder: (context, hasText, _) {
                    if (hasText) {
                      return IconButton(
                        icon: Icon(Icons.send, color: colors.iconColor),
                        onPressed: () {
                          if (ChatStateManager
                                  .instance.editingMessageNotifier.value !=
                              null) {
                            _sendEditedMessage();
                          } else {
                            _sendMessage();
                            _clearDraft();
                          }
                        },
                      );
                    } else {
                      return Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.attach_file,
                                color: colors.iconColor),
                            onPressed: _pickImage,
                          ),
                          IconButton(
                            icon: Icon(Icons.mic, color: colors.iconColor),
                            onPressed: _sendVoiceMessage,
                          ),
                        ],
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          // Emoji picker
          if (_showEmojiPicker)
            Container(
              height: 250,
              child: DefaultTabController(
                length: emojiCategories.length,
                child: Column(
                  children: [
                    TabBar(
                      isScrollable: true,
                      labelColor: Colors.blue,
                      unselectedLabelColor: Colors.grey,
                      tabs: [
                        ...emojiCategories.keys.map((String category) {
                          return Tab(
                            icon: Icon(
                              emojiCategoryIcons[category],
                              size: 20,
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          ...emojiCategories.values.map((List<String> emojis) {
                            return GridView.builder(
                              gridDelegate:
                                  SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 50,
                                childAspectRatio: 1.0,
                                crossAxisSpacing: 4.0,
                                mainAxisSpacing: 4.0,
                              ),
                              itemCount: emojis.length,
                              itemBuilder: (context, index) {
                                final emoji = emojis[index];

                                return GestureDetector(
                                  onTap: () {
                                    _onEmojiSelected(emoji);
                                  },
                                  onLongPress: () {
                                    if (emoji.startsWith("assets/")) {
                                      _showOverlay(emoji);
                                    }
                                  },
                                  child: Center(
                                    child: Text(
                                      emoji,
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontFamily: "NotoColorEmoji",
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                    if (_isOverlayVisible)
                      GestureDetector(
                        onTap: _hideOverlay,
                        child: Stack(
                          children: [
                            AnimatedOpacity(
                              opacity: _isOverlayVisible ? 1.0 : 0.0,
                              duration: Duration(milliseconds: 300),
                              child: Container(
                                color: Colors.transparent,
                              ),
                            ),
                            Center(
                              child: AnimatedOpacity(
                                opacity: _isOverlayVisible ? 1.0 : 0.0,
                                duration: Duration(milliseconds: 300),
                                child: Container(
                                  padding: EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(
                                        color: Colors.grey.withOpacity(0.5)),
                                  ),
                                  child: Lottie.asset(
                                    _selectedEmoji!,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.contain,
                                    animate: true,
                                    repeat: true,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  final lottieList = [
    "100.json",
    "alarm-clock.json",
    "angry_emoji.json",
    "battary-full.json",
    "battary-low.json",
    "birthday-cake.json",
    "blood.json",
    "blush.json",
    "bomb.json",
    "bowling.json",
    "broking-heart.json",
    "byte_code_emoji.json",
    "chequered-flag.json",
    "chinking-beer-mugs.json",
    "clap.json",
    "clown.json",
    "cold-face.json",
    "collision.json",
    "confetti-ball.json",
    "cross-mark.json",
    "crossed-fingers.json",
    "crying_emoji.json",
    "crystal-ball.json",
    "cursing.json",
    "die.json",
    "dizy-dace.json",
    "drool.json",
    "exclamation.json",
    "experssionless.json",
    "eyes.json",
    "file.py",
    "fire.json",
    "folded-hands.json",
    "gear.json",
    "grimacing.json",
    "Grin.json",
    "Grinning.json",
    "halo.json",
    "heart-eyes.json",
    "heart-face.json",
    "heart_emoji.json",
    "holding-back-tears.json",
    "hot-face.json",
    "hug-face.json",
    "imp-smile.json",
    "Joy.json",
    "kiss.json",
    "Kissing-closed-eyes.json",
    "Kissing-heart.json",
    "Kissing.json",
    "laughing_emoji.json",
    "Launghing.json",
    "light-bulb.json",
    "Loudly-crying.json",
    "melting.json",
    "mind-blown.json",
    "money-face.json",
    "money-wings.json",
    "mouth-none.json",
    "muscle.json",
    "neutral-face.json",
    "party-popper.json",
    "partying-face.json",
    "pencil.json",
    "pensive.json",
    "pig.json",
    "pleading.json",
    "poop.json",
    "question.json",
    "rainbow.json",
    "raised-eyebrow.json",
    "relieved.json",
    "revolving-heart.json",
    "Rofl.json",
    "roling-eyes.json",
    "salute.json",
    "screaming.json",
    "shushing-face.json",
    "skull.json",
    "sleep.json",
    "slot-machine.json",
    "smile.json",
    "smile_with_big_eyes.json",
    "smirk.json",
    "soccer-bal.json",
    "sparkles.json",
    "stuck-out-tongue.json",
    "subglasses-face.json",
    "thermometer-face.json",
    "thinking-face.json",
    "thumbs-down.json",
    "thumbs-up.json",
    "upside-down-face.json",
    "victory.json",
    "vomit.json",
    "warm-smile.json",
    "wave.json",
    "Wink.json",
    "winky-tongue.json",
    "woozy.json",
    "yawn.json",
    "yum.json",
    "zany-face.json",
    "zipper-face.json",
  ];

  void _onAnimatedEmojiSelected(String emojiPath) {
    widget.onSend('::animation_emoji/$emojiPath');
  }

  List<TextSpan> _formatMessageContent(
      String content, String senderId, String userId) {
    final RegExp urlRegExp = RegExp(r'https?://[^\s]+');
    final RegExp codeBlockRegex =
        RegExp(r'```(\w+)?\s*([\s\S]+?)```', dotAll: true);
    final RegExp tagRegex = RegExp(r'<(/?[^>]+)>');

    content = content.replaceAll(codeBlockRegex, '');

    final Iterable<Match> matches = urlRegExp.allMatches(content);
    List<TextSpan> textSpans = [];
    int lastIndex = 0;

    if (senderId == userId) {
      textSpans.add(TextSpan(
        text: 'Вы: ',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ));
    }

    for (Match match in matches) {
      if (lastIndex < match.start) {
        final String textPart = content.substring(lastIndex, match.start);
        textSpans.addAll(_parseTextContent(textPart));
      }
      textSpans.add(
        TextSpan(
          text: 'фотография',
          style: TextStyle(
            color: Colors.lightBlue,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
      lastIndex = match.end;
    }

    if (lastIndex < content.length) {
      final String remainingText = content.substring(lastIndex);
      textSpans.addAll(_parseTextContent(remainingText));
    }

    return textSpans;
  }

  List<TextSpan> _parseTextContent(String content) {
    final List<TextSpan> spans = [];
    final RegExp tagRegex = RegExp(r'<(/?[^>]+)>');
    final List<String> parts = content.split(tagRegex);
    final List<RegExpMatch> matches = tagRegex.allMatches(content).toList();

    for (int i = 0; i < parts.length; i++) {
      if (i < matches.length) {
        final String tag = matches[i].group(0)!;
        if (tag == '<b>' || tag == '<strong>') {
          spans.add(TextSpan(
              text: parts[i], style: TextStyle(fontWeight: FontWeight.bold)));
        } else if (tag == '</b>' || tag == '</strong>') {
          spans.add(TextSpan(text: parts[i]));
        } else if (tag == '<i>' || tag == '<em>') {
          spans.add(TextSpan(
              text: parts[i], style: TextStyle(fontStyle: FontStyle.italic)));
        } else if (tag == '</i>' || tag == '</em>') {
          spans.add(TextSpan(text: parts[i]));
        } else if (tag == '<del>' || tag == '<s>') {
          spans.add(TextSpan(
              text: parts[i],
              style: TextStyle(decoration: TextDecoration.lineThrough)));
        } else if (tag == '</del>' || tag == '</s>') {
          spans.add(TextSpan(text: parts[i]));
        } else if (tag == '<u>') {
          spans.add(TextSpan(
              text: parts[i],
              style: TextStyle(decoration: TextDecoration.underline)));
        } else if (tag == '</u>') {
          spans.add(TextSpan(text: parts[i]));
        } else if (tag == '<small>') {
          spans.add(TextSpan(text: parts[i], style: TextStyle(fontSize: 10)));
        } else if (tag == '</small>') {
          spans.add(TextSpan(text: parts[i]));
        } else if (tag == '<sub>') {
          spans.add(TextSpan(
              text: parts[i],
              style: TextStyle(fontFeatures: [FontFeature.subscripts()])));
        } else if (tag == '</sub>') {
          spans.add(TextSpan(text: parts[i]));
        } else if (tag == '<sup>') {
          spans.add(TextSpan(
              text: parts[i],
              style: TextStyle(fontFeatures: [FontFeature.superscripts()])));
        } else if (tag == '</sup>') {
          spans.add(TextSpan(text: parts[i]));
        } else if (tag == '<ins>') {
          spans.add(TextSpan(
              text: parts[i],
              style: TextStyle(decoration: TextDecoration.underline)));
        } else if (tag == '</ins>') {
          spans.add(TextSpan(text: parts[i]));
        } else if (tag == '<mark>') {
          spans.add(TextSpan(
              text: parts[i],
              style: TextStyle(backgroundColor: Colors.yellow)));
        } else if (tag == '</mark>') {
          spans.add(TextSpan(text: parts[i]));
        } else {
          spans.add(TextSpan(text: parts[i]));
        }
      } else {
        spans.add(TextSpan(text: parts[i]));
      }
    }

    return spans;
  }
}
