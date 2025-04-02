import 'dart:convert';
import 'package:html/parser.dart' as parser;
import 'package:http/http.dart' as http;

class Currency {
  final String name;
  final double rate;

  Currency({
    required this.name,
    required this.rate,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'rate': rate,
    };
  }
}

class CurrencyManager {
  final String usdUrl = "https://ru.investing.com/currencies/usd-rub";
  final String eurUrl = "https://ru.investing.com/currencies/eur-rub";
  final String btcApiUrl = "https://blockchain.info/ticker";

  // Метод для парсинга курсов USD и EUR
  Future<double> parseCurrency(String url) async {
    try {
      // Выполняем HTTP-запрос к сайту
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        // Парсим HTML-код страницы
        var document = parser.parse(response.body);

        // Находим элемент с курсом валюты по указанному классу
        var currencyElement = document.querySelector(
            '.text-5xl\\/9.font-bold.text-\\[\\#232526\\].md\\:text-\\[42px\\].md\\:leading-\\[60px\\]');
        if (currencyElement != null) {
          String rateText = currencyElement.text.trim();
          return double.tryParse(rateText.replaceAll(',', '.')) ?? 0.0;
        } else {
          print("Currency element not found");
        }
      } else {
        print("Failed to load currency data: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching currency: $e");
    }
    return 0.0;
  }

  // Метод для получения курса биткоина через API
  Future<double> fetchBitcoinRate() async {
    try {
      final response = await http.get(Uri.parse(btcApiUrl));
      if (response.statusCode == 200) {
        // Парсим JSON-ответ
        Map<String, dynamic> data = jsonDecode(response.body);

        // Получаем курс в USD
        Map<String, dynamic> usdData = data['USD'];
        double lastRate = usdData['last'].toDouble();
        return lastRate;
      } else {
        print("Failed to fetch Bitcoin rate: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching Bitcoin rate: $e");
    }
    return 0.0;
  }

  // Метод для получения всех валют
  Future<List<Currency>> fetchCurrencies() async {
    List<Currency> currencies = [];

    // Парсим курс доллара
    double usdRate = await parseCurrency(usdUrl);
    currencies.add(Currency(name: "USD", rate: usdRate));

    // Парсим курс евро
    double eurRate = await parseCurrency(eurUrl);
    currencies.add(Currency(name: "EUR", rate: eurRate));

    // Получаем курс биткоина через API
    double btcRate = await fetchBitcoinRate();
    currencies.add(Currency(name: "BTC", rate: btcRate));

    return currencies;
  }

  // Сохранение данных в JSON
  Future<void> saveCurrenciesToJson(
      List<Currency> currencies, String filePath) async {
    List<Map<String, dynamic>> jsonList =
        currencies.map((currency) => currency.toJson()).toList();
    String jsonString = jsonEncode(jsonList);

    print("Saved JSON: $jsonString");
  }
}
