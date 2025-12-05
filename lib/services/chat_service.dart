class ChatService {
  final String apiKey;
  String? liveChatId;
  String? nextPageToken;

  ChatService(this.apiKey);

  Future<bool> resolveLiveChatId(String videoId) async {
    final url = 'https://www.googleapis.com/youtube/v3/videos?part=liveStreamingDetails&id=$videoId&key=$apiKey';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['items'] != null && data['items'].isNotEmpty) {
        liveChatId = data['items'][0]['liveStreamingDetails']['activeLiveChatId'];
        return liveChatId != null;
      }
    }
    return false;
  }

  Future<List<String>> fetchMessages() async {
    if (liveChatId == null) return [];

    String url = 'https://www.googleapis.com/youtube/v3/liveChat/messages?liveChatId=$liveChatId&part=snippet,authorDetails&key=$apiKey';
    if (nextPageToken != null) {
      url += '&pageToken=$nextPageToken';
    }

    final response = await http.get(Uri.parse(url));
    List<String> foundNames = [];

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      nextPageToken = data['nextPageToken'];
      final items = data['items'] as List;

      for (var item in items) {
        String message = item['snippet']['displayMessage'] ?? "";
        String author = item['authorDetails']['displayName'] ?? "Unknown";
        
        // Intelligent Name Extraction
        String lowerMsg = message.toLowerCase();
        if (lowerMsg.startsWith("write ") || lowerMsg.startsWith("kill ")) {
          foundNames.add(message.split(" ").sublist(1).join(" "));
        } else if (lowerMsg.contains("add me")) {
          foundNames.add(author);
        }
      }
    }
    return foundNames;
  }
}