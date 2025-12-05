class AppState extends ChangeNotifier {
  final List<String> _nameQueue = [];
  String? _currentName;
  bool _isStreaming = false;

  List<String> get nameQueue => _nameQueue;
  String? get currentName => _currentName;
  bool get isStreaming => _isStreaming;

  void setStreaming(bool val) {
    _isStreaming = val;
    notifyListeners();
  }

  void addName(String name) {
    // Basic deduplication and profanity filter placeholder
    if (!_nameQueue.contains(name) && name.trim().isNotEmpty) {
      _nameQueue.add(name);
      if (_currentName == null) {
        processNextName();
      }
      notifyListeners();
    }
  }

  void processNextName() {
    if (_nameQueue.isNotEmpty) {
      _currentName = _nameQueue.removeAt(0);
      notifyListeners();
    } else {
      _currentName = null;
      notifyListeners();
    }
  }

  void finishedWriting() {
    processNextName();
  }
}