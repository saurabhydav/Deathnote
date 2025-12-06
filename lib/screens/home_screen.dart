import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'dart:async';

import '../providers/app_state.dart';
import '../services/native_bridge.dart';
import '../services/chat_service.dart';
import '../widgets/deathnote_area.dart';
import '../widgets/avatar_area.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _streamKeyController = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _videoIdController = TextEditingController();
  Timer? _timer;
  ChatService? _chatService;
  bool _isPreviewMode = false;
  final GlobalKey<AvatarAreaState> _avatarKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    _streamKeyController.dispose();
    _apiKeyController.dispose();
    _videoIdController.dispose();
    _timer?.cancel();
    WakelockPlus.disable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _updateSystemUI(bool isFullScreen) {
    if (isFullScreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  Future<void> _toggleStreaming(AppState appState) async {
    if (appState.isStreaming) {
      await NativeBridge.stopStream();
      appState.setStreaming(false);
      appState.setPolling(false);
      _timer?.cancel();
      _updateSystemUI(false);
    } else {
      String streamKey = _streamKeyController.text.trim();
      String apiKey = _apiKeyController.text.trim();
      String videoId = _videoIdController.text.trim();

      if (streamKey.isEmpty || apiKey.isEmpty || videoId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please fill all fields')));
        return;
      }

      appState.updateStreamKey(streamKey);
      appState.updateApiKey(apiKey);
      appState.updateVideoId(videoId);

      String endpoint = "rtmp://a.rtmp.youtube.com/live2/$streamKey";
      try {
        _updateSystemUI(true);
        WakelockPlus.enable();
        await Future.delayed(Duration(milliseconds: 500));
        await NativeBridge.startStream(endpoint);
        appState.setStreaming(true);
        _startChatPolling(appState, apiKey, videoId);
      } catch (e) {
         _updateSystemUI(false);
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  void _startChatPolling(AppState appState, String apiKey, String videoId) async {
    appState.setPolling(true);
    _chatService = ChatService(apiKey);
    _timer = Timer.periodic(Duration(seconds: 5), (timer) async {
      if (!appState.isPolling) { timer.cancel(); return; }
      if (_chatService != null) {
        List<String> messages = await _chatService!.fetchMessages(videoId);
        for (String msg in messages) {
           String lowerMsg = msg.toLowerCase().trim();
           String? nameToAdd;
           if (lowerMsg.startsWith("write ")) nameToAdd = msg.substring(6).trim();
           else if (lowerMsg.startsWith("kill ")) nameToAdd = msg.substring(5).trim();
           
           if (nameToAdd != null && nameToAdd.isNotEmpty && nameToAdd.length <= 25) {
              if (!appState.names.contains(nameToAdd)) appState.addName(nameToAdd);
           }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    bool hideUI = appState.isStreaming || _isPreviewMode;
    if (_isPreviewMode) _updateSystemUI(true);
    else if (!appState.isStreaming) _updateSystemUI(false);

    return Scaffold(
      appBar: hideUI ? null : AppBar(title: Text("Death Note Streamer")),
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        top: !hideUI,
        bottom: !hideUI,
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(flex: 50, child: Stack(children: [
                  Positioned.fill(child: DeathNoteArea(isBackgroundOnly: true)),
                  if (hideUI) Positioned.fill(child: DeathNoteArea(isTextOnly: true)),
                ])),
                Expanded(flex: 50, child: AvatarArea(key: _avatarKey)),
              ],
            ),
            if (!hideUI)
              Center(child: SingleChildScrollView(child: Container(
                margin: EdgeInsets.all(20), padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white24)),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text("STREAM SETUP", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  SizedBox(height: 20),
                  TextField(controller: _apiKeyController, decoration: InputDecoration(labelText: "YouTube API Key", border: OutlineInputBorder())),
                  SizedBox(height: 10),
                  TextField(controller: _videoIdController, decoration: InputDecoration(labelText: "Video ID", border: OutlineInputBorder())),
                  SizedBox(height: 10),
                  TextField(controller: _streamKeyController, decoration: InputDecoration(labelText: "RTMP Stream Key", border: OutlineInputBorder()), obscureText: true),
                  SizedBox(height: 20),
                  Row(children: [
                    Expanded(child: OutlinedButton(onPressed: () => setState(() => _isPreviewMode = true), child: Text("PREVIEW"), style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: BorderSide(color: Colors.white54)))),
                    SizedBox(width: 10),
                    Expanded(child: ElevatedButton(onPressed: () => _toggleStreaming(appState), child: Text("GO LIVE"), style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white))),
                  ])
                ]),
              ))),
            Positioned(
              bottom: 20, right: 20,
              child: hideUI 
                ? FloatingActionButton.small(backgroundColor: Colors.red.withOpacity(0.6), onPressed: () { if (_isPreviewMode) { setState(() => _isPreviewMode = false); _updateSystemUI(false); } else _toggleStreaming(appState); }, child: Icon(Icons.stop, color: Colors.white))
                : FloatingActionButton(heroTag: "pick_video", backgroundColor: Colors.blueGrey, onPressed: () => _avatarKey.currentState?.pickVideo(), child: Icon(Icons.folder_open, color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }
}