import 'dart:math';
import 'dart:ui'; // Required for ImageFilter
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

// Expanded list of animation styles
enum AnimationStyle { typewriter, fadeIn, scale, blur, slide, spacing }

class DeathNoteArea extends StatefulWidget {
  @override
  _DeathNoteAreaState createState() => _DeathNoteAreaState();
}

class _DeathNoteAreaState extends State<DeathNoteArea> with TickerProviderStateMixin {
  late AnimationController _controller;
  String name = "Death Note"; 
  AnimationStyle _currentStyle = AnimationStyle.typewriter;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: Duration(seconds: 4));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final appState = Provider.of<AppState>(context);
    
    // Trigger writing if polling is active and queue has names
    if (appState.isPolling && appState.names.isNotEmpty) {
       _startWriting(appState.names.last);
    }
  }

  void _startWriting(String targetName) {
    setState(() {
      name = targetName;
      // Randomly pick one of the 6 styles
      _currentStyle = AnimationStyle.values[Random().nextInt(AnimationStyle.values.length)];
    });

    _controller.reset();
    _controller.forward().then((_) {
        // Notify app state when animation completes
        Provider.of<AppState>(context, listen: false).finishedWriting();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.black,
      padding: EdgeInsets.all(20),
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
      fontFamily: 'DeathNote', // The custom handwriting font
      fontSize: 40,
      color: Colors.white,
      fontStyle: FontStyle.italic,
      shadows: [Shadow(color: Colors.red, blurRadius: 10)],
    );

    switch (_currentStyle) {
      case AnimationStyle.typewriter:
        // Classic Death Note: Letters appear one by one
        int length = (name.length * _controller.value).toInt();
        if (length > name.length) length = name.length;
        return Text(name.substring(0, length), style: baseStyle);

      case AnimationStyle.fadeIn:
        // Ghostly: Fades in from 0 to 1
        return Opacity(
          opacity: _controller.value,
          child: Text(name, style: baseStyle),
        );

      case AnimationStyle.scale:
        // Dramatic: Zooms in from nothing
        return Transform.scale(
          scale: _controller.value,
          child: Text(name, style: baseStyle),
        );

      case AnimationStyle.blur:
        // Mystery: Starts blurry, becomes clear
        // Blur value goes from 10.0 down to 0.0
        double blurValue = (1 - _controller.value) * 10;
        return ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: blurValue, sigmaY: blurValue),
          child: Opacity(
            // Also fade in slightly so it's not a blocky blur at start
            opacity: _controller.value.clamp(0.2, 1.0), 
            child: Text(name, style: baseStyle),
          ),
        );

      case AnimationStyle.slide:
        // Rising: Slides up from the bottom + Fades in
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _controller.value)), // Move UP as controller increases
          child: Opacity(
            opacity: _controller.value,
            child: Text(name, style: baseStyle),
          ),
        );

      case AnimationStyle.spacing:
        // Cinematic: Letters start close and spread out slightly
        return Text(
          name, 
          style: baseStyle.copyWith(
            // Letter spacing increases from -5 to 2
            letterSpacing: -5 + (7 * _controller.value),
            // Fade in as well
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
    super.dispose();
  }
}

class NotebookPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 1;

    for (double i = 40; i < size.height; i += 40) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}