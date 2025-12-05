import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatService {
  static Future<List<String>> fetchChatMessages(String videoId, String apiKey) async {
    final url = 'https://www.googleapis.com/youtube/v3/liveChat/messages?liveChatId=$videoId&part=snippet,authorDetails&key=$apiKey';
    
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> items = data['items'];
        // Simply returning a list of messages for now
        return items.map((item) => item['snippet']['displayMessage'].toString()).toList();
      } else {
        print('Failed to load chat: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching chat: $e');
      return [];
    }
  }
}