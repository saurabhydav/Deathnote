import 'dart:math';
import 'dart:ui'; 
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart'; 
import '../providers/app_state.dart';

enum AnimationStyle { typewriter, fadeIn, scale, blur, slide, spacing }

class DeathNoteArea extends StatefulWidget {
  @override
  _DeathNoteAreaState createState() => _DeathNoteAreaState();
}

class _DeathNoteAreaState extends State<DeathNoteArea> with TickerProviderStateMixin {
  late AnimationController _controller;
  
  // Audio Players
  late AudioPlayer _sfxPlayer; 
  late AudioPlayer _bgmPlayer; 
  
  String name = "Death Note"; 
  AnimationStyle _currentStyle = AnimationStyle.typewriter;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: Duration(seconds: 4));
    _controller.value = 0.0; 

    // Initialize Audio Players
    _sfxPlayer = AudioPlayer();
    _bgmPlayer = AudioPlayer();
    
    _initAudio();
  }

  void _initAudio() async {
    // 1. Setup Scribble Sound
    await _sfxPlayer.setVolume(1.0);

    // 2. Setup Background Music
    try {
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop); // Loop forever
      
      // CHANGED: Increased volume to 0.4 (40%)
      await _bgmPlayer.setVolume(0.4); 
      
      await _bgmPlayer.play(AssetSource('sounds/theme.mp3')); 
    } catch(e) {
      print("BGM Error: $e");
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final appState = Provider.of<AppState>(context);
    
    if (appState.isPolling && appState.names.isNotEmpty) {
       _startWriting(appState.names.last);
    }
  }

  void _startWriting(String targetName) async {
    setState(() {
      name = targetName;
      _currentStyle = AnimationStyle.values[Random().nextInt(AnimationStyle.values.length)];
    });

    try {
      await _sfxPlayer.stop(); 
      await _sfxPlayer.play(AssetSource('sounds/scribble.mp3'));
    } catch (e) {}

    _controller.reset();
    _controller.forward().then((_) async {
        try { await _sfxPlayer.stop(); } catch(e) {}
        Provider.of<AppState>(context, listen: false).finishedWriting();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A), 
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.2, 
          colors: [
            Color(0xFF252525), 
            Color(0xFF000000), 
          ],
          stops: [0.3, 1.0],
        ),
      ),
      child: CustomPaint(
        painter: NotebookPainter(),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return _buildAnimatedText();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedText() {
    TextStyle baseStyle = TextStyle(
      fontFamily: 'DeathNote', 
      fontSize: 50, 
      color: Colors.white.withOpacity(0.95), 
      fontStyle: FontStyle.italic,
      shadows: [
        Shadow(color: Colors.black, blurRadius: 15, offset: Offset(0, 0)) 
      ],
    );

    switch (_currentStyle) {
      case AnimationStyle.typewriter:
        int length = (name.length * _controller.value).toInt();
        if (length > name.length) length = name.length;
        return Text(name.substring(0, length), style: baseStyle);

      case AnimationStyle.fadeIn:
        return Opacity(
          opacity: _controller.value,
          child: Text(name, style: baseStyle),
        );

      case AnimationStyle.scale:
        return Transform.scale(
          scale: _controller.value,
          child: Text(name, style: baseStyle),
        );

      case AnimationStyle.blur:
        double blurValue = (1 - _controller.value) * 10;
        return ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: blurValue, sigmaY: blurValue),
          child: Opacity(
            opacity: _controller.value.clamp(0.2, 1.0), 
            child: Text(name, style: baseStyle),
          ),
        );

      case AnimationStyle.slide:
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _controller.value)), 
          child: Opacity(
            opacity: _controller.value,
            child: Text(name, style: baseStyle),
          ),
        );

      case AnimationStyle.spacing:
        return Text(
          name, 
          style: baseStyle.copyWith(
            letterSpacing: -5 + (7 * _controller.value),
            color: Colors.white.withOpacity(_controller.value)
          )
        );
        
      default:
        return Text(name, style: baseStyle);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _sfxPlayer.dispose();
    _bgmPlayer.dispose(); 
    super.dispose();
  }
}

class NotebookPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.08) 
      ..strokeWidth = 1;

    for (double i = 60; i < size.height; i += 60) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}