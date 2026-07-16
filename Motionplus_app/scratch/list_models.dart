import 'dart:convert';
import 'dart:io';

void main() async {
  final apiKey = 'YOUR_API_KEY_HERE';
  final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=\$apiKey');
  
  try {
    final client = HttpClient();
    final request = await client.getUrl(url);
    final response = await request.close();
    
    final responseBody = await response.transform(utf8.decoder).join();
    print('Status code: \${response.statusCode}');
    print('Response: \$responseBody');
  } catch (e) {
    print('Error: \$e');
  }
}
