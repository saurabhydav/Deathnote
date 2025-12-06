import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../providers/app_state.dart';

enum AnimationStyle { typewriter, fadeIn, scale, blur, slide, spacing }

class GhostParticle {
  final Offset startOffset;
  final Offset endOffset;
  final double scale;
  final double speed;
  final double rotation;
  final double opacity;

  GhostParticle({
    required this.startOffset,
    required this.endOffset,
    required this.scale,
    required this.speed,
    required this.rotation,
    required this.opacity,
  });
}

class DeathNoteArea extends StatefulWidget {
  final bool isBackgroundOnly;
  final bool isTextOnly;

  const DeathNoteArea({
    Key? key,
    this.isBackgroundOnly = false,
    this.isTextOnly = false
  }) : super(key: key);

  @override
  _DeathNoteAreaState createState() => _DeathNoteAreaState();
}

class _DeathNoteAreaState extends State<DeathNoteArea> with TickerProviderStateMixin {
  late AnimationController _controller; 
  late AnimationController _pulseController; 
  late AnimationController _flickerController; 
  late AnimationController _ghostSwarmController;

  late AudioPlayer _sfxPlayer;
  late AudioPlayer _bgmPlayer;
  late AudioPlayer _pageSfxPlayer;

  List<String> _writtenNames = []; 
  String? _currentWritingName; 
  final int _maxLinesPerPage = 5; 
  final double _lineHeight = 60.0; 
  final double _startTopPosition = 60.0; 

  AnimationStyle _currentStyle = AnimationStyle.typewriter;
  bool _isWriting = false;
  List<GhostParticle> _ghosts = [];
  Timer? _idleTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: Duration(milliseconds: 1000));
    _ghostSwarmController = AnimationController(vsync: this, duration: Duration(seconds: 8));
    _pulseController = AnimationController(vsync: this, duration: Duration(seconds: 1))..repeat(reverse: true);
    _flickerController = AnimationController(vsync: this, duration: Duration(milliseconds: 100));
    _startFlickerLoop();

    if (!widget.isBackgroundOnly) {
      _sfxPlayer = AudioPlayer();
      _bgmPlayer = AudioPlayer();
      _pageSfxPlayer = AudioPlayer();
      _initAudio();
      
      if (widget.isTextOnly) {
        _startIdleGhostTimer();
        _startSimulation();
      }
    } else {
      _sfxPlayer = AudioPlayer();
      _bgmPlayer = AudioPlayer();
      _pageSfxPlayer = AudioPlayer();
    }
  }

  void _startSimulation() async {
    await Future.delayed(Duration(seconds: 3));
    List<String> testNames = ["L Lawliet", "Light Yagami", "Misa Amane", "Ryuk", "Near", "Mello"];
    int index = 0;
    Timer.periodic(Duration(seconds: 3), (timer) {
      if (mounted && !_isWriting) {
        _handleNewName(testNames[index % testNames.length]);
        index++;
      }
    });
  }

  void _startFlickerLoop() {
    Timer.periodic(Duration(milliseconds: 500), (timer) {
      if (mounted && Random().nextBool()) {
        _flickerController.forward(from: 0.0);
      }
    });
  }

  void _initAudio() async {
    await _sfxPlayer.setVolume(1.0);
    await _pageSfxPlayer.setVolume(1.0);
    
    // BACKGROUND MUSIC SETUP
    try {
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop); // Set to loop
      await _bgmPlayer.setVolume(0.4);
      await _bgmPlayer.play(AssetSource('sounds/theme.mp3'));
      
      // FORCE LOOP: If it stops, play it again
      _bgmPlayer.onPlayerComplete.listen((event) {
        _bgmPlayer.play(AssetSource('sounds/theme.mp3'));
      });
    } catch(e) {
      print("BGM Error: $e");
    }
  }

  void _startIdleGhostTimer() {
    if (widget.isBackgroundOnly) return;
    _idleTimer = Timer.periodic(Duration(seconds: 2), (timer) {
      if (!_isWriting && !_ghostSwarmController.isAnimating) {
        if (mounted) {
          _spawnGhosts(count: 6); 
          _ghostSwarmController.forward(from: 0.0);
        }
      }
    });
  }

  void _spawnGhosts({int count = 6}) {
    _ghosts.clear();
    final random = Random();

    for (int i = 0; i < count; i++) {
      double startX = (random.nextDouble() * 350) - 175; 
      double startY = (random.nextDouble() * 900) - 100; 
      double scale = 0.6 + random.nextDouble() * 0.4;
      double opacity = 0.2; 
      double distance = 150.0;
      double speedMult = 0.2; 

      double angle = random.nextDouble() * 2 * pi;
      double endX = startX + ((random.nextDouble() * 40) - 20);
      double endY = startY - distance;

      _ghosts.add(GhostParticle(
        startOffset: Offset(startX, startY),
        endOffset: Offset(endX, endY),
        scale: scale, 
        speed: speedMult,
        rotation: (random.nextDouble() * 0.5) - 0.25,
        opacity: opacity,
      ));
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.isBackgroundOnly) return;

    final appState = Provider.of<AppState>(context);
    if (appState.isPolling && appState.names.isNotEmpty && !_isWriting) {
       _handleNewName(appState.names.first);
    }
  }

  void _handleNewName(String targetName) async {
    if (_isWriting) return;
    setState(() => _isWriting = true);

    bool pageFull = _writtenNames.length >= _maxLinesPerPage;

    if (pageFull) {
      try { await _pageSfxPlayer.play(AssetSource('sounds/pageflip.mp3')); } catch(e) {}
      
      setState(() {
        _writtenNames.clear();
        _currentWritingName = targetName;
        _currentStyle = AnimationStyle.typewriter;
      });
    } else {
      setState(() {
        _currentWritingName = targetName;
        _currentStyle = AnimationStyle.typewriter;
      });
    }

    // Start Writing Sound (Looped while writing)
    try {
      await _sfxPlayer.setReleaseMode(ReleaseMode.loop);
      await _sfxPlayer.play(AssetSource('sounds/scribble.mp3'));
    } catch (e) {}

    _controller.reset();
    await _controller.forward();
    
    // Stop Writing Sound
    try { 
      await _sfxPlayer.stop(); 
      await _sfxPlayer.setReleaseMode(ReleaseMode.stop); // Reset release mode
    } catch(e) {}
    
    await Future.delayed(Duration(milliseconds: 500)); 
    
    if (mounted) {
      setState(() {
        _writtenNames.add(_currentWritingName!); 
        _currentWritingName = null;
        _isWriting = false;
      });
      Provider.of<AppState>(context, listen: false).finishedWriting();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isBackgroundOnly) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Color(0xFF1A1A1A),
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [Color(0xFF252525), Color(0xFF000000)],
            stops: [0.3, 1.0],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: NotebookPainter(lineHeight: _lineHeight))),
            
            Positioned(
              top: 20, left: 0, right: 0,
              child: Center(
                child: Opacity(
                  opacity: 0.8,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(color: Colors.red.withOpacity(0.2), blurRadius: 10, spreadRadius: 2)
                      ]
                    ),
                    child: Text(
                      "ENTER YOUR NAME IN CHAT TO ENTER THE DEATH NOTE...",
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                        shadows: [Shadow(color: Colors.red, blurRadius: 10)]
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _ghostSwarmController,
            builder: (context, child) {
              return Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter, 
                children: _ghosts.map((ghost) {
                  double t = (_ghostSwarmController.value * ghost.speed).clamp(0.0, 1.0);
                  double curX = ghost.startOffset.dx + ((ghost.endOffset.dx - ghost.startOffset.dx) * t);
                  double curY = ghost.startOffset.dy + ((ghost.endOffset.dy - ghost.startOffset.dy) * t);
                  double opacity = (1.0 - t).clamp(0.0, 0.8);

                  return Positioned(
                    left: (MediaQuery.of(context).size.width / 2) + curX - 20, 
                    top: curY, 
                    child: Opacity(
                      opacity: ghost.opacity * fade, 
                      child: Transform.rotate(
                        angle: ghost.rotation,
                        child: SvgPicture.asset('assets/animations/ghost.svg', width: 40 * ghost.scale, height: 40 * ghost.scale),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),

        Positioned(
          top: _startTopPosition, 
          left: 0, right: 0,
          child: Column(
            children: [
              ..._writtenNames.map((n) => Container(
                height: _lineHeight,
                alignment: Alignment.center,
                child: _buildStaticText(n),
              )),

              if (_currentWritingName != null)
                Container(
                  height: _lineHeight,
                  alignment: Alignment.center,
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_controller, _pulseController, _flickerController]),
                    builder: (context, child) => _buildAnimatedText(_currentWritingName!),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
  
  double get fade => 1.0;

  Widget _buildStaticText(String text) {
    return Text(text, style: _getTextStyle(1.0));
  }

  Widget _buildAnimatedText(String text) {
    TextStyle style = _getTextStyle(1.0 + (0.05 * _pulseController.value));
    switch (_currentStyle) {
      case AnimationStyle.typewriter:
        int len = (text.length * _controller.value).toInt();
        if (len > text.length) len = text.length;
        return Text(text.substring(0, len), style: style, textAlign: TextAlign.center);
      default:
        return Opacity(
          opacity: _controller.value,
          child: Text(text, style: style, textAlign: TextAlign.center),
        );
    }
  }

  TextStyle _getTextStyle(double scale) {
    double flicker = 1.0 - (_flickerController.value * 0.3);
    return TextStyle(
      fontFamily: 'DeathNote',
      fontSize: 32, 
      color: Colors.white.withOpacity(0.95 * flicker),
      fontStyle: FontStyle.italic,
      fontWeight: FontWeight.bold,
      letterSpacing: 2.0,
      shadows: [
        Shadow(color: Colors.black, blurRadius: 2, offset: Offset(2, 2)),
        Shadow(color: Colors.redAccent, blurRadius: 15, offset: Offset(0, 0)),
      ],
    ).apply(fontSizeFactor: scale);
  }

  @override
  void dispose() {
    _controller.dispose();
    _ghostSwarmController.dispose();
    _pulseController.dispose();
    _flickerController.dispose();
    _sfxPlayer.dispose();
    _bgmPlayer.dispose();
    _pageSfxPlayer.dispose();
    _idleTimer?.cancel();
    super.dispose();
  }
}

class NotebookPainter extends CustomPainter {
  final double lineHeight;
  NotebookPainter({this.lineHeight = 60.0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.08)..strokeWidth = 1;
    for (double i = 40; i < size.height; i += 40) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}