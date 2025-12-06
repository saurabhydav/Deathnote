import 'package:flutter/foundation.dart';

class AppState extends ChangeNotifier {
  bool _isPolling = false;
  bool _isStreaming = false;
  String _streamKey = '';
  String _apiKey = '';
  String _videoId = '';
  List<String> _names = []; 

  bool get isPolling => _isPolling;
  bool get isStreaming => _isStreaming;
  String get streamKey => _streamKey;
  String get apiKey => _apiKey;
  String get videoId => _videoId;
  List<String> get names => _names;

  void setPolling(bool value) {
    _isPolling = value;
    notifyListeners();
  }

  void setStreaming(bool value) {
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

  void addName(String name) {
    // Only add if not already in the queue to avoid spam
    if (!_names.contains(name)) {
      _names.add(name);
      notifyListeners();
    }
  }

  void finishedWriting() {
    // Remove the FIRST name (FIFO queue)
    if (_names.isNotEmpty) {
      _names.removeAt(0);
      notifyListeners();
    }
  }
}