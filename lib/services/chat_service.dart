import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatService {
  final String apiKey;
  String? _liveChatId;

  // Constructor that accepts the API Key
  ChatService(this.apiKey);

  // Method to fetch messages using the stored API Key
  Future<List<String>> fetchMessages(String videoId) async {
    try {
      // 1. Get Live Chat ID if we don't have it
      if (_liveChatId == null) {
        final videoUrl = 'https://www.googleapis.com/youtube/v3/videos?part=liveStreamingDetails&id=$videoId&key=$apiKey';
        final videoResponse = await http.get(Uri.parse(videoUrl));
        
        if (videoResponse.statusCode == 200) {
          final videoData = json.decode(videoResponse.body);
          if (videoData['items'] != null && videoData['items'].isNotEmpty) {
            _liveChatId = videoData['items'][0]['liveStreamingDetails']?['activeLiveChatId'];
          }
        }
      }

      if (_liveChatId == null) return [];

      // 2. Fetch Messages
      final chatUrl = 'https://www.googleapis.com/youtube/v3/liveChat/messages?liveChatId=$_liveChatId&part=snippet,authorDetails&key=$apiKey';
      final chatResponse = await http.get(Uri.parse(chatUrl));

      if (chatResponse.statusCode == 200) {
        final chatData = json.decode(chatResponse.body);
        List<dynamic> items = chatData['items'];
        
        return items.map<String>((item) {
          return item['snippet']['displayMessage'].toString();
        }).toList();
      }
    } catch (e) {
      print('ChatService Error: $e');
    }
    return [];
  }
}