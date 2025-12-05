import 'package:flutter/foundation.dart';

class AppState extends ChangeNotifier {
  bool _isPolling = false;
  bool _isStreaming = false; // Added this
  String _streamKey = '';
  String _apiKey = '';
  String _videoId = '';
  List<String> _names = []; // Store chat names here

  // Getters
  bool get isPolling => _isPolling;
  bool get isStreaming => _isStreaming; // Added this
  String get streamKey => _streamKey;
  String get apiKey => _apiKey;
  String get videoId => _videoId;
  List<String> get names => _names;

  // Setters
  void setPolling(bool value) {
    _isPolling = value;
    notifyListeners();
  }

  void setStreaming(bool value) { // Added this
    _isStreaming = value;
    notifyListeners();
  }

  void updateStreamKey(String value) {
    _streamKey = value;
    notifyListeners();
  }

  void updateApiKey(String value) {
    _apiKey = value;
    notifyListeners();
  }

  void updateVideoId(String value) {
    _videoId = value;
    notifyListeners();
  }

  void addName(String name) { // Added this
    _names.add(name);
    notifyListeners();
  }

  void finishedWriting() {
    // Logic to handle when writing animation finishes (e.g., remove name from queue)
    if (_names.isNotEmpty) {
      _names.removeAt(0);
      notifyListeners();
    }
  }
}