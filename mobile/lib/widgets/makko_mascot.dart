import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A small, animated Makko shark drawn from Flutter canvas primitives.
///
/// The idle loop only runs while this widget is visible, its route and
/// TickerMode are active, and the app is in the foreground. Reduced motion
/// leaves the shark in a clear, open-eyed pose.
class MakkoMascot extends StatefulWidget {
  final bool visible;
  final double width;
  final double height;

  const MakkoMascot({
    super.key,
    this.visible = true,
    this.width = 112,
    this.height = 104,
  });

  @override
  State<MakkoMascot> createState() => _MakkoMascotState();
}

class _MakkoMascotState extends State<MakkoMascot>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _idleController;
  late final AnimationController _reactionController;
  bool _motionAllowed = false;
  bool _appIsResumed = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final lifecycleState = WidgetsBinding.instance.lifecycleState;
    _appIsResumed =
        lifecycleState == null || lifecycleState == AppLifecycleState.resumed;
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    );
    _reactionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  @override
  void didUpdateWidget(covariant MakkoMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visible != widget.visible) _syncMotion();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appIsResumed = state == AppLifecycleState.resumed;
    _syncMotion();
  }

  void _syncMotion() {
    final media = MediaQuery.maybeOf(context);
    final reduceMotion =
        (media?.disableAnimations ?? false) ||
        (media?.accessibleNavigation ?? false);
    final routeVisible = ModalRoute.isCurrentOf(context) ?? true;
    final tickerEnabled = TickerMode.valuesOf(context).enabled;
    final nextMotionAllowed =
        widget.visible &&
        _appIsResumed &&
        routeVisible &&
        tickerEnabled &&
        !reduceMotion;

    if (_motionAllowed == nextMotionAllowed) return;
    _motionAllowed = nextMotionAllowed;
    if (_motionAllowed) {
      _idleController.repeat();
    } else {
      _idleController.stop(canceled: false);
      _reactionController
        ..stop(canceled: false)
        ..value = 0;
    }
    if (mounted) setState(() {});
  }

  void _react() {
    if (!_motionAllowed) return;
    _reactionController.forward(from: 0);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _idleController.dispose();
    _reactionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final semanticsLabel = _motionAllowed
        ? 'Makko shark mascot. Tap for a small fin wave.'
        : 'Makko shark mascot.';

    return Semantics(
      button: _motionAllowed,
      label: semanticsLabel,
      child: GestureDetector(
        key: const Key('makko-mascot'),
        behavior: HitTestBehavior.opaque,
        onTap: _motionAllowed ? _react : null,
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: CustomPaint(
            painter: _MakkoSharkPainter(
              idle: _idleController,
              reaction: _reactionController,
              animated: _motionAllowed,
            ),
          ),
        ),
      ),
    );
  }
}

class _MakkoSharkPainter extends CustomPainter {
  static const _outline = Color(0xFF15556A);
  static const _body = Color(0xFF55C5D5);
  static const _bodyLight = Color(0xFF83DCE3);
  static const _bodyShade = Color(0xFF37AFC2);
  static const _belly = Color(0xFFFFF7E9);
  static const _eye = Color(0xFF123B50);

  final Animation<double> idle;
  final Animation<double> reaction;
  final bool animated;

  _MakkoSharkPainter({
    required this.idle,
    required this.reaction,
    required this.animated,
  }) : super(repaint: Listenable.merge([idle, reaction]));

  @override
  void paint(Canvas canvas, Size size) {
    const artSize = Size(190, 118);
    final scale = math.min(
      size.width / artSize.width,
      size.height / artSize.height,
    );
    canvas.save();
    canvas.translate(
      (size.width - artSize.width * scale) / 2,
      (size.height - artSize.height * scale) / 2,
    );
    canvas.scale(scale);

    final phase = animated ? idle.value : 0.0;
    final wave = math.sin(phase * math.pi * 2);
    final reactionPeak = animated
        ? math.sin(reaction.value * math.pi).clamp(0.0, 1.0).toDouble()
        : 0.0;
    final tailAngle = wave * 0.2 + reactionPeak * 0.34;
    final finAngle = math.cos(phase * math.pi * 2) * 0.045 + reactionPeak * 0.1;
    final blink = animated ? _blinkAt(phase) : 0.0;

    _drawTail(canvas, tailAngle);
    _drawDorsalFin(canvas, finAngle);
    _drawFarPectoralFin(canvas, -finAngle * 0.7);
    _drawBody(canvas);
    _drawBelly(canvas);
    _drawFace(canvas, blink);
    _drawNearPectoralFin(canvas, finAngle * 0.8);
    canvas.restore();
  }

  double _blinkAt(double phase) {
    const start = 0.72;
    const end = 0.79;
    if (phase < start || phase > end) return 0;
    final progress = (phase - start) / (end - start);
    return math.sin(progress * math.pi).clamp(0.0, 1.0).toDouble();
  }

  void _drawTail(Canvas canvas, double angle) {
    canvas.save();
    canvas.translate(31, 60);
    canvas.rotate(angle);
    final tail = Path()
      ..moveTo(15, -4)
      ..cubicTo(5, -8, -2, -17, -10, -29)
      ..cubicTo(-1, -27, 9, -21, 16, -14)
      ..cubicTo(14, -25, 18, -35, 27, -42)
      ..cubicTo(26, -28, 23, -15, 19, -5)
      ..close();
    canvas.drawPath(
      tail,
      Paint()
        ..shader = const LinearGradient(
          colors: [_bodyShade, _bodyLight],
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
        ).createShader(const Rect.fromLTWH(-18, -48, 42, 48)),
    );
    canvas.drawPath(
      tail,
      Paint()
        ..color = _outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.restore();
  }

  void _drawDorsalFin(Canvas canvas, double angle) {
    canvas.save();
    canvas.translate(91, 27);
    canvas.rotate(-angle);
    final fin = Path()
      ..moveTo(-18, 12)
      ..cubicTo(-14, 2, -8, -10, 1, -18)
      ..cubicTo(7, -11, 12, -2, 19, 8)
      ..cubicTo(9, 5, -4, 7, -18, 12)
      ..close();
    canvas.drawPath(fin, Paint()..color = _bodyShade);
    canvas.drawPath(
      fin,
      Paint()
        ..color = _outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.restore();
  }

  void _drawFarPectoralFin(Canvas canvas, double angle) {
    canvas.save();
    canvas.translate(108, 80);
    canvas.rotate(angle);
    final fin = Path()
      ..moveTo(-3, -5)
      ..cubicTo(5, -8, 17, -7, 27, -2)
      ..cubicTo(16, 1, 8, 7, 1, 12)
      ..close();
    canvas.drawPath(fin, Paint()..color = _bodyLight);
    canvas.drawPath(
      fin,
      Paint()
        ..color = _outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.restore();
  }

  void _drawNearPectoralFin(Canvas canvas, double angle) {
    canvas.save();
    canvas.translate(111, 79);
    canvas.rotate(angle);
    final fin = Path()
      ..moveTo(-4, -5)
      ..cubicTo(5, -7, 16, 0, 25, 10)
      ..cubicTo(15, 12, 7, 17, 0, 22)
      ..cubicTo(1, 11, 0, 1, -4, -5)
      ..close();
    canvas.drawPath(fin, Paint()..color = _bodyShade);
    canvas.drawPath(
      fin,
      Paint()
        ..color = _outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.3
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.restore();
  }

  void _drawBody(Canvas canvas) {
    final body = Path()
      ..moveTo(28, 60)
      ..cubicTo(38, 39, 61, 24, 90, 22)
      ..cubicTo(123, 18, 151, 31, 167, 49)
      ..cubicTo(175, 58, 174, 66, 165, 74)
      ..cubicTo(146, 90, 116, 96, 88, 91)
      ..cubicTo(59, 86, 39, 75, 28, 60)
      ..close();
    canvas.drawPath(
      body,
      Paint()
        ..shader = const LinearGradient(
          colors: [_bodyLight, _body],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(const Rect.fromLTWH(26, 20, 150, 78)),
    );
    canvas.drawPath(
      body,
      Paint()
        ..color = _outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeJoin = StrokeJoin.round,
    );
  }

  void _drawBelly(Canvas canvas) {
    final belly = Path()
      ..moveTo(48, 67)
      ..cubicTo(70, 72, 92, 71, 111, 66)
      ..cubicTo(132, 61, 151, 60, 169, 64)
      ..cubicTo(160, 83, 134, 93, 106, 91)
      ..cubicTo(80, 90, 59, 81, 48, 67)
      ..close();
    canvas.drawPath(belly, Paint()..color = _belly);
  }

  void _drawFace(Canvas canvas, double blink) {
    const eye = Offset(153, 46);
    final eyeHeight = 18.0 - (15.8 * blink);
    final eyeRect = Rect.fromCenter(center: eye, width: 16, height: eyeHeight);
    canvas.drawOval(eyeRect, Paint()..color = Colors.white);
    canvas.drawOval(
      Rect.fromCenter(center: eye, width: 10, height: eyeHeight * 0.84),
      Paint()..color = _eye,
    );
    if (blink < 0.8) {
      canvas.drawCircle(
        Offset(eye.dx - 2.0, eye.dy - eyeHeight * 0.19),
        2.2,
        Paint()..color = Colors.white,
      );
    }

    final smile = Path()
      ..moveTo(151, 65)
      ..quadraticBezierTo(159, 72, 168, 64);
    canvas.drawPath(
      smile,
      Paint()
        ..color = _outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _MakkoSharkPainter oldDelegate) =>
      oldDelegate.animated != animated;
}
