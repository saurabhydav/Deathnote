class NativeBridge {
  static const MethodChannel _channel = MethodChannel('deathnote_live/stream');

  static Future<bool> startStream(String url) async {
    try {
      final result = await _channel.invokeMethod('startStream', {'url': url});
      return result == true;
    } catch (e) {
      print("Error starting stream: $e");
      return false;
    }
  }

  static Future<void> stopStream() async {
    await _channel.invokeMethod('stopStream');
  }
}