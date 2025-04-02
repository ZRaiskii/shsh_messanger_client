import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class News {
  final String id;
  final String newsTitle;
  final String newsBody;
  final String newsLink;
  final String? imageUrl;

  News({
    required this.id,
    required this.newsTitle,
    required this.newsBody,
    required this.newsLink,
    this.imageUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'news_title': newsTitle,
      'news_body': newsBody,
      'news_link': newsLink,
      'image_url': imageUrl,
    };
  }
}

class NewsManager {
  final String apiKey = "a69e9c737ca24e90b44f3cbad4eea880";
  final String apiUrl = "https://api.worldnewsapi.com/search-news";

  Future<List<News>> fetchNews({
    String text = "",
    List<String> categories = const [], // Новый параметр для категорий
    String language = "ru",
    int number = 100,
  }) async {
    List<News> newsList = [];
    try {
      String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // Проверка допустимых категорий
      final allowedCategories = [
        'politics',
        'sports',
        'business',
        'technology',
        'entertainment',
        'health',
        'science',
        'lifestyle',
        'travel',
        'culture',
        'education',
        'environment',
        'other'
      ];

      for (var category in categories) {
        if (!allowedCategories.contains(category)) {
          throw ArgumentError('Недопустимая категория: $category');
        }
      }

      // Формирование URL с категориями
      final Uri uri = Uri.parse(apiUrl).replace(queryParameters: {
        "text": text,
        "language": language,
        "earliest-publish-date": today,
        "number": number.toString(),
        "api-key": apiKey,
        if (categories.isNotEmpty)
          "categories": categories.join(','), // Добавление категорий
      });

      print(uri);

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        Map<String, dynamic> jsonResponse =
            json.decode(utf8.decode(response.bodyBytes));
        List<dynamic> newsItems = jsonResponse['news'];

        for (var item in newsItems) {
          News news = News(
            id: item['id'].toString(),
            newsTitle: item['title'],
            newsBody: item['text'],
            newsLink: item['url'],
            imageUrl: item['image'],
          );
          newsList.add(news);
        }
      } else {
        print("Не удалось загрузить новости: ${response.statusCode}");
      }
    } catch (e) {
      print("Ошибка при получении новостей: $e");
    }
    return newsList;
  }

  Future<void> saveNewsToJson(List<News> newsList, String filePath) async {
    // Преобразуем список новостей в JSON
    List<Map<String, dynamic>> jsonList =
        newsList.map((news) => news.toJson()).toList();
    String jsonString = jsonEncode(jsonList);

    // Сохраняем JSON в файл
    // В реальном приложении используйте пакет `path_provider` для работы с файловой системой
    print("Saved JSON: $jsonString");
  }
}
