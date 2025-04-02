import 'package:html/parser.dart' as parser;
import 'package:http/http.dart' as http;

class QuoteService {
  static const String _url = 'https://quote-citation.com/random';

  Future<String?> getRandomQuote() async {
    try {
      final response = await http.get(
        Uri.parse(_url),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 4.4.2; XMP-6250 Build/HAWK) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/30.0.0.0 Safari/537.36 ADAPI/2.0 (UUID:9e7df0ed-2a5c-4a19-bec7-2cc54800f99d) RK3188-ADAPI/1.2.84.533 (MODEL:XMP-6250)'
        },
      );

      if (response.statusCode == 200) {
        final document = parser.parse(response.body);
        final quoteElement = document.querySelector('.quote-text p');
        return quoteElement?.text.trim();
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
