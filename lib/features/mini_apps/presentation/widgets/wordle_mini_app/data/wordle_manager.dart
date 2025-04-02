import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WordleManager {
  String _currentWord;
  List<String> _guesses;
  int _attempts;
  final ValueNotifier<int> streakNotifier;
  final ValueNotifier<int> totalGamesNotifier;
  final ValueNotifier<int> totalWinsNotifier;
  final ValueNotifier<List<String>> guessesNotifier = ValueNotifier([]);
  final ValueNotifier<List<List<Color>>> colorsNotifier = ValueNotifier([]);

  WordleManager()
      : _guesses = [],
        _attempts = 0,
        streakNotifier = ValueNotifier(0),
        totalGamesNotifier = ValueNotifier(0),
        totalWinsNotifier = ValueNotifier(0),
        _currentWord = "" {
    loadStats();
  }

  String get currentWord => _currentWord;
  List<String> get guesses => _guesses;
  int get attempts => _attempts;
  int get streak => streakNotifier.value;
  int get totalGames => totalGamesNotifier.value;
  int get totalWins => totalWinsNotifier.value;

  Future<void> loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    totalGamesNotifier.value = prefs.getInt('totalGames') ?? 0;
    totalWinsNotifier.value = prefs.getInt('totalWins') ?? 0;
    streakNotifier.value = prefs.getInt('streak') ?? 0;
  }

  Future<void> _saveStats() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('totalGames', totalGamesNotifier.value);
    await prefs.setInt('totalWins', totalWinsNotifier.value);
    await prefs.setInt('streak', streakNotifier.value);
  }

  void startNewGame() {
    _currentWord = _getRandomWord();
    _guesses.clear();
    _attempts = 0;
    totalGamesNotifier.value++;

    // Clear notifiers
    guessesNotifier.value = [];
    colorsNotifier.value = [];
  }

  void makeGuess(String guess) {
    _guesses.add(guess);
    _attempts++;

    // Обновляем guessesNotifier
    guessesNotifier.value = List.from(_guesses);

    List<Color> colors = [];
    for (int i = 0; i < guess.length; i++) {
      String correctChar = _currentWord.toLowerCase()[i];
      String guessChar = guess.toLowerCase()[i];

      if (guessChar.toLowerCase() == correctChar.toLowerCase()) {
        colors.add(Colors.green);
      } else if (_currentWord.contains(guessChar)) {
        int correctCount = _currentWord.split(correctChar).length - 1;
        int guessCount = guess.split(guessChar).length - 1;

        if (guessCount > correctCount) {
          colors.add(Colors.grey);
        } else {
          colors.add(Colors.yellow);
        }
      } else {
        colors.add(Colors.grey);
      }
    }

    // Обновляем colorsNotifier
    List<List<Color>> newColors = List.from(colorsNotifier.value);
    newColors.add(colors);
    colorsNotifier.value = newColors;

    if (guess == _currentWord) {
      streakNotifier.value++;
      totalWinsNotifier.value++;
    } else if (_attempts == 5) {
      streakNotifier.value = 0;
    }

    _saveStats();
  }

  String _getRandomWord() {
    // Логика для получения случайного слова
    final words = [
      'ширь',
      'банан',
      'океан',
      'гора',
      'лес',
      'день',
      'ночь',
      'луг',
      'поле',
      'река',
      'озеро',
      'пруд',
      'ветер',
      'луч',
      'свет',
      'тень',
      'дом',
      'край',
      'путь',
      'мост',
      'город',
      'село',
      'улица',
      'площадь',
      'двор',
      'сад',
      'цветок',
      'трава',
      'лист',
      'дерево',
      'ветка',
      'корень',
      'плод',
      'ягода',
      'орех',
      'фрукт',
      'овощ',
      'семя',
      'земля',
      'песок',
      'глина',
      'камень',
      'скала',
      'утёс',
      'берег',
      'волна',
      'прилив',
      'отлив',
      'капля',
      'роса',
      'дождь',
      'снег',
      'град',
      'туман',
      'пар',
      'облако',
      'небо',
      'звезда',
      'луна',
      'солнце',
      'заря',
      'рассвет',
      'закат',
      'вечер',
      'утро',
      'полдень',
      'полночь',
      'секунда',
      'минута',
      'час',
      'неделя',
      'месяц',
      'год',
      'век',
      'эпоха',
      'история',
      'судьба',
      'жизнь',
      'мир',
      'покой',
      'радость',
      'печаль',
      'грусть',
      'счастье',
      'боль',
      'страдание',
      'надежда',
      'мечта',
      'мысль',
      'разум',
      'ум',
      'внимание',
      'память',
      'знание',
      'наука',
      'искусство',
      'музыка',
      'живопись',
      'поэзия',
      'литература',
      'книга',
      'страница',
      'буква',
      'слово',
      'речь',
      'звук',
      'мелодия',
      'песня',
      'голос',
      'шёпот',
      'крик',
      'смех',
      'слеза',
      'улыбка',
      'взгляд',
      'глаз',
      'нос',
      'рот',
      'ухо',
      'лоб',
      'щека',
      'подбородок',
      'шея',
      'плечо',
      'рука',
      'ладонь',
      'палец',
      'ноготь',
      'спина',
      'грудь',
      'живот',
      'нога',
      'стопа',
      'пятка',
      'колено',
      'бедро',
      'кость',
      'кожа',
      'волос',
      'сердце',
      'кровь',
      'дыхание',
      'вдох',
      'выдох',
      'сон',
      'душа',
      'тело',
      'здоровье',
      'сила',
      'слабость',
      'усталость',
      'отдых',
      'еда',
      'пища',
      'напиток',
      'вода',
      'чай',
      'кофе',
      'молоко',
      'мёд',
      'сахар',
      'соль',
      'перец',
      'масло',
      'хлеб',
      'мясо',
      'рыба',
      'сыр',
      'овсянка',
      'суп',
      'борщ',
      'каша',
      'блюдо',
      'тарелка',
      'ложка',
      'вилка',
      'нож',
      'чашка',
      'стакан',
      'бутылка',
      'скатерть',
      'стол',
      'стул',
      'диван',
      'кресло',
      'кровать',
      'подушка',
      'одеяло',
      'простыня',
      'пол',
      'потолок',
      'стена',
      'окно',
      'дверь',
      'замок',
      'ключ',
      'коридор',
      'комната',
      'кухня',
      'ванна',
      'зеркало',
      'шкаф',
      'полка',
      'картина',
      'часы',
      'свеча',
      'лампа',
      'огонь',
      'пламя',
      'дым',
      'тепло',
      'холод',
      'мороз',
      'жара',
      'лето',
      'осень',
      'зима',
      'весна',
      'праздник',
      'торжество',
      'радость',
      'удовольствие',
      'подарок',
      'игра',
      'забава',
      'смех',
      'шутка',
      'развлечение',
      'спорт',
      'гонка',
      'прыжок',
      'бег',
      'плавание',
      'лыжа',
      'конь',
      'мяч',
      'турнир',
      'победа',
      'поражение',
      'приз',
      'участие',
      'успех',
      'триумф',
      'план',
      'цель',
      'задача',
      'решение',
      'выбор',
      'шаг',
      'движение',
      'направление',
      'дорога',
      'тропа',
      'поворот',
      'перекрёсток',
      'путник',
      'попутчик',
      'друг',
      'товарищ',
      'брат',
      'сестра',
      'отец',
      'мать',
      'родитель',
      'сын',
      'дочь',
      'семья',
      'род',
      'предок',
      'наследие',
      'страна',
      'народ',
      'культура',
      'традиция',
      'обычай',
      'язык',
      'словарь',
      'грамматика',
      'букварь',
      'учебник',
      'школа',
      'учитель',
      'ученик',
      'студент',
      'университет',
      'лекция',
      'экзамен',
      'задание',
      'урок',
      'перемена',
      'отдых',
      'каникулы',
      'путешествие',
      'поездка',
      'туризм',
      'гостиница',
      'номер',
      'ключ',
      'ресепшн',
      'билет',
      'поезд',
      'самолёт',
      'автобус',
      'машина',
      'велосипед',
      'корабль',
      'лодка',
      'порт',
      'станция',
      'аэропорт',
      'багаж',
      'чемодан',
      'рюкзак',
      'карман',
      'кошелёк',
      'деньги',
      'монета',
      'банк',
      'карта',
      'счёт',
      'доход',
      'расход',
      'богатство',
      'бедность',
      'экономика',
      'рынок',
      'магазин',
      'покупка',
      'цена',
      'скидка',
      'товар',
      'продукт',
      'качество',
      'реклама',
      'бренд',
      'мода',
      'стиль',
      'одежда',
      'платье',
      'рубашка',
      'брюки',
      'юбка',
      'куртка',
      'пальто',
      'обувь',
      'ботинок',
      'туфля',
      'носк',
      'перчатка',
      'шляпа',
      'шарф',
      'зонт',
      'сумка',
      'чемодан',
      'подарок',
      'украшение',
      'кольцо',
      'браслет',
      'ожерелье',
      'серьга',
      'часы',
      'очки',
      'зрение',
      'слух',
      'вкус',
      'обоняние',
      'осязание',
      'ощущение',
      'эмоция',
      'чувство',
      'радость',
      'грусть',
      'страх',
      'удивление',
      'гордость',
      'стыд',
      'вина',
      'зависть',
      'ревность',
      'дружба',
      'любовь',
      'уважение',
      'поддержка',
      'помощь',
      'забота',
      'верность',
      'предательство',
      'ложь',
      'правда',
      'честность',
      'справедливость'
    ];
    return words[Random().nextInt(words.length)];
  }
}
