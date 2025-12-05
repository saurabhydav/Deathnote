import 'package:flutter/services.dart';

class NativeBridge {
  static const MethodChannel _channel = MethodChannel('deathnote_live/stream');

  static Future<void> startStream(String url) async {
    try {
      await _channel.invokeMethod('startStream', {'url': url});
    } catch (e) {
      print("Failed to start stream: $e");
    }
  }

  static Future<void> stopStream() async {
    try {
      await _channel.invokeMethod('stopStream');
    } catch (e) {
      print("Failed to stop stream: $e");
    }
  }
}