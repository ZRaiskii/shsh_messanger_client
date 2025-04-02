import 'package:flutter/material.dart';

import '../../../../core/utils/AppColors.dart';
import 'package:lottie/lottie.dart';

class EmojiPickerContent extends StatefulWidget {
  final Function(String) onUpdateEmoji;
  final AppColors colors; // Добавляем AppColors

  const EmojiPickerContent({
    required this.onUpdateEmoji,
    required this.colors, // Передаем AppColors
    Key? key,
  }) : super(key: key);

  @override
  _EmojiPickerContentState createState() => _EmojiPickerContentState();
}

class _EmojiPickerContentState extends State<EmojiPickerContent> {
  final Map<String, List<String>> emojiCategories = {
    'Фрукты и овощи': [
      '🍎',
      '🍓',
      '🍉',
      '🍒',
      '🍑',
      '🍋',
      '🍌',
      '🍇',
      '🍈',
      '🍐',
      '🍊',
      '🍍'
    ],
    'Еда': [
      '🍔',
      '🍟',
      '🍕',
      '🍖',
      '🍗',
      '🍙',
      '🍚',
      '🍛',
      '🍜',
      '🍝',
      '🍞',
      '🍟'
    ],
    'Десерты': [
      '🍦',
      '🍧',
      '🍨',
      '🍩',
      '🍪',
      '🎂',
      '🍰',
      '🍮',
      '🍭',
      '🍬',
      '🍫'
    ],
    'Напитки': ['🍺', '🍻', '🍸', '🍹', '🍷', '🍶', '🍵', '☕'],
    'Природа': [
      '🌳',
      '🌴',
      '🍃',
      '🌷',
      '🌹',
      '🌺',
      '🌻',
      '🌼',
      '🌸',
      '🌱',
      '🍀',
      '🌾'
    ],
    'Транспорт': [
      '🚗',
      '🚕',
      '🚙',
      '🚌',
      '🚎',
      '🏍',
      '🚲',
      '🛴',
      '🚂',
      '🚄',
      '🚅',
      '🚈'
    ],
    'Спорт': [
      '⚽',
      '🏀',
      '🏈',
      '⚾',
      '🎾',
      '🏐',
      '🏉',
      '🎱',
      '🏒',
      '🏓',
      '🏸',
      '🥊'
    ],
    'Профессии': [
      '👨‍⚕️',
      '👩‍⚕️',
      '👨‍🌾',
      '👩‍🌾',
      '👨‍🍳',
      '👩‍🍳',
      '👨‍🏫',
      '👩‍🏫',
      '👨‍🔬',
      '👩‍🔬',
      '👨‍💼',
      '👩‍💼',
      '👨‍🏭',
      '👩‍🏭',
      '👨‍💻',
      '👩‍💻'
    ],
    'IT': [
      '💻',
      '🖥',
      '📱',
      '📟',
      '📡',
      '💾',
      '💽',
      '💿',
      '📀',
      '📂',
      '📁',
      '📄',
      '📃',
      '📑',
      '📊',
      '📈'
    ],
    'Другие': [
      '🎉',
      '🎈',
      '🎁',
      '🎊',
      '🎆',
      '🎇',
      '🎂',
      '🎃',
      '🎄',
      '🎅',
      '🎆'
    ],
    'Анимированные': [
      // Лица и эмоции
      'assets/heart_emoji.json', // Сердце
      'assets/laughing_emoji.json', // Смеющийся emoji
      'assets/crying_emoji.json', // Плачущий emoji
      'assets/angry_emoji.json', // Сердитый emoji
      'assets/blush.json', // Улыбка с румянцем
      'assets/experssionless.json', // Без выражения
      'assets/Grin.json', // Широкая улыбка
      'assets/Grinning.json', // Улыбка
      'assets/halo.json', // Ореол
      'assets/heart-eyes.json', // Сердечные глаза
      'assets/heart-face.json', // Лицо с сердечками
      'assets/holding-back-tears.json', // Сдерживающий слёзы
      'assets/hot-face.json', // Горячее лицо
      'assets/hug-face.json', // Обнимающее лицо
      'assets/imp-smile.json', // Улыбка с рожками
      'assets/Joy.json', // Слёзы радости
      'assets/kiss.json', // Поцелуй
      'assets/Kissing-closed-eyes.json', // Поцелуй с закрытыми глазами
      'assets/Kissing-heart.json', // Поцелуй с сердечком
      'assets/Kissing.json', // Поцелуй
      'assets/Launghing.json', // Смех
      'assets/Loudly-crying.json', // Громкий плач
      'assets/melting.json', // Таящее лицо
      'assets/mind-blown.json', // Взорванный мозг
      'assets/money-face.json', // Лицо с деньгами
      'assets/neutral-face.json', // Нейтральное лицо
      'assets/partying-face.json', // Лицо на вечеринке
      'assets/pensive.json', // Задумчивое лицо
      'assets/pleading.json', // Умоляющее лицо
      'assets/raised-eyebrow.json', // Поднятая бровь
      'assets/relieved.json', // Облегчение
      'assets/Rofl.json', // Катающийся от смеха
      'assets/roling-eyes.json', // Закатывание глаз
      'assets/screaming.json', // Крик
      'assets/shushing-face.json', // Тихое лицо
      'assets/skull.json', // Череп
      'assets/sleep.json', // Сон
      'assets/smile.json', // Улыбка
      'assets/smile_with_big_eyes.json', // Улыбка с большими глазами
      'assets/smirk.json', // Ухмылка
      'assets/stuck-out-tongue.json', // Высунутый язык
      'assets/subglasses-face.json', // Лицо в очках
      'assets/thermometer-face.json', // Лицо с термометром
      'assets/thinking-face.json', // Задумчивое лицо
      'assets/upside-down-face.json', // Перевёрнутое лицо
      'assets/vomit.json', // Рвота
      'assets/warm-smile.json', // Тёплая улыбка
      'assets/Wink.json', // Подмигивание
      'assets/winky-tongue.json', // Подмигивание с языком
      'assets/woozy.json', // Одурманенный
      'assets/yawn.json', // Зевота
      'assets/yum.json', // Вкусно
      'assets/zany-face.json', // Сумасшедшее лицо
      'assets/zipper-face.json', // Лицо с молнией

      // Остальные анимации
      'assets/100.json', // 100 баллов
      'assets/alarm-clock.json', // Будильник
      'assets/battary-full.json', // Полная батарея
      'assets/battary-low.json', // Разряженная батарея
      'assets/birthday-cake.json', // Торт на день рождения
      'assets/blood.json', // Кровь
      'assets/bomb.json', // Бомба
      'assets/bowling.json', // Боулинг
      'assets/broking-heart.json', // Разбитое сердце
      'assets/chequered-flag.json', // Клетчатый флаг
      'assets/chinking-beer-mugs.json', // Бокалы пива
      'assets/clap.json', // Аплодисменты
      'assets/clown.json', // Клоун
      'assets/cold-face.json', // Холодное лицо
      'assets/collision.json', // Столкновение
      'assets/confetti-ball.json', // Конфетти
      'assets/cross-mark.json', // Крестик
      'assets/crossed-fingers.json', // Скрёщенные пальцы
      'assets/crystal-ball.json', // Хрустальный шар
      'assets/cursing.json', // Ругательство
      'assets/die.json', // Игральная кость
      'assets/dizy-dace.json', // Головокружение
      'assets/drool.json', // Слюни
      'assets/exclamation.json', // Восклицательный знак
      'assets/eyes.json', // Глаза
      'assets/fire.json', // Огонь
      'assets/folded-hands.json', // Сложенные руки
      'assets/gear.json', // Шестерёнка
      'assets/light-bulb.json', // Лампочка
      'assets/money-wings.json', // Деньги с крыльями
      'assets/mouth-none.json', // Лицо без рта
      'assets/muscle.json', // Мускулы
      'assets/party-popper.json', // Хлопушка
      'assets/pencil.json', // Карандаш
      'assets/pig.json', // Свинья
      'assets/poop.json', // Какашка
      'assets/question.json', // Вопросительный знак
      'assets/rainbow.json', // Радуга
      'assets/revolving-heart.json', // Вращающееся сердце
      'assets/salute.json', // Салют
      'assets/slot-machine.json', // Игровой автомат
      'assets/soccer-bal.json', // Футбольный мяч
      'assets/sparkles.json', // Блёстки
      'assets/thumbs-down.json', // Большой палец вниз
      'assets/thumbs-up.json', // Большой палец вверх
      'assets/victory.json', // Победа
      'assets/wave.json', // Волна
    ],
  };

  final Map<String, IconData> categoryIcons = {
    'Фрукты и овощи': Icons.apple,
    'Еда': Icons.fastfood,
    'Десерты': Icons.icecream,
    'Напитки': Icons.local_bar,
    'Природа': Icons.nature,
    'Транспорт': Icons.directions_car,
    'Спорт': Icons.sports_soccer,
    'Профессии': Icons.work,
    'IT': Icons.computer,
    'Другие': Icons.celebration,
    'Анимированные': Icons.animation,
  };

  String selectedCategory = 'Фрукты и овощи';
  List<String> displayedEmojis = [];

  @override
  void initState() {
    super.initState();
    displayedEmojis = emojiCategories[selectedCategory]!;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: widget.colors.backgroundColor,
      title: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categoryIcons.keys.map((category) {
                return IconButton(
                  icon: Icon(
                    categoryIcons[category],
                    size: 20,
                    color: widget.colors.iconColor,
                  ),
                  onPressed: () {
                    setState(() {
                      selectedCategory = category;
                      displayedEmojis = emojiCategories[category]!;
                    });
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 150,
        child: PageView.builder(
          itemCount: (displayedEmojis.length / 12).ceil(),
          itemBuilder: (context, pageIndex) {
            final start = pageIndex * 12;
            final end = (start + 12 > displayedEmojis.length)
                ? displayedEmojis.length
                : start + 12;
            return Wrap(
              spacing: 6.0,
              runSpacing: 6.0,
              children: displayedEmojis.sublist(start, end).map((emoji) {
                if (emoji.endsWith('.json')) {
                  // Анимированный emoji
                  return GestureDetector(
                    onTap: () {
                      widget.onUpdateEmoji(emoji);
                      Navigator.of(context).pop();
                    },
                    child: Lottie.asset(
                      emoji,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                    ),
                  );
                } else {
                  // Обычный emoji
                  return GestureDetector(
                    onTap: () {
                      widget.onUpdateEmoji(emoji);
                      Navigator.of(context).pop();
                    },
                    child: Chip(
                      label: Text(emoji),
                      padding: EdgeInsets.all(4.0),
                      backgroundColor: widget.colors.cardColor,
                      labelStyle: TextStyle(
                        color: widget.colors.textColor,
                      ),
                    ),
                  );
                }
              }).toList(),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(
            'Отмена',
            style: TextStyle(
              color: widget.colors.textColor,
            ),
          ),
        ),
      ],
    );
  }
}
