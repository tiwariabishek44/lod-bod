import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lod_board/core/theme/app_typography.dart';

class LodbodSplashScreen extends StatefulWidget {
  const LodbodSplashScreen({super.key, this.onComplete});

  final VoidCallback? onComplete;

  @override
  State<LodbodSplashScreen> createState() => _LodbodSplashScreenState();
}

class _LodbodSplashScreenState extends State<LodbodSplashScreen> {
  Timer? _progressTimer;
  int _progressStep = 0;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    _prepareThenStartProgress();
  }

  Future<void> _prepareThenStartProgress() async {
    try {
      await precacheImage(
        const AssetImage('assets/images/lodbod_nepal_splash_background.png'),
        context,
      );
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'splash artwork preloading',
        ),
      );
    }
    if (!mounted) return;

    _progressTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() => _progressStep++);
      if (_progressStep == 10) {
        timer.cancel();
        _complete();
      }
    });
  }

  void _complete() {
    if (mounted) widget.onComplete?.call();
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF092A49),
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            const Image(
              image: AssetImage(
                'assets/images/lodbod_nepal_splash_background.png',
              ),
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0, .53, .76, 1],
                  colors: [
                    Color(0x00082B4B),
                    Color(0x00082B4B),
                    Color(0x16082B4B),
                    Color(0x30082B4B),
                  ],
                ),
              ),
            ),
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) => Stack(
                  children: [
                    Positioned(
                      left: constraints.maxWidth * .09,
                      top: constraints.maxHeight * .603,
                      child: const _LocationPill('Birgunj'),
                    ),
                    Positioned(
                      left: constraints.maxWidth * .63,
                      top: constraints.maxHeight * .55,
                      child: const _LocationPill('Kathmandu'),
                    ),
                  ],
                ),
              ),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final scale = math.min(
                    1.0,
                    math.min(
                      constraints.maxWidth / 390,
                      constraints.maxHeight / 760,
                    ),
                  );
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 22 * scale),
                    child: Column(
                      children: [
                        const Spacer(flex: 1),
                        _SpeedTruckMark(width: 98 * scale, height: 64 * scale),
                        SizedBox(height: 12 * scale),
                        _LodbodWordmark(scale: scale),
                        SizedBox(height: 8 * scale),
                        Text(
                          'TRUCKING  •  LOAD BIDDING',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _splashNavy,
                            fontSize: AppTypography.size(10.5 * scale),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 3.1 * scale,
                          ),
                        ),
                        SizedBox(height: 17 * scale),
                        SizedBox(
                          width: 72 * scale,
                          height: 14 * scale,
                          child: const CustomPaint(
                            painter: _OrangeRouteAccent(),
                          ),
                        ),
                        SizedBox(height: 19 * scale),
                        _FeatureStrip(scale: scale),
                        const Spacer(flex: 4),
                        _LoadingProgress(
                          scale: scale,
                          progressStep: _progressStep,
                        ),
                        SizedBox(height: 19 * scale),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _splashNavy = Color(0xFF082B4B);
const _splashOrange = Color(0xFFFF5900);

class _SpeedTruckMark extends StatelessWidget {
  const _SpeedTruckMark({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size(width, height),
    painter: const _SpeedTruckMarkPainter(),
  );
}

class _SpeedTruckMarkPainter extends CustomPainter {
  const _SpeedTruckMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 108, size.height / 68);
    final paint = Paint()..color = _splashOrange;
    final whitePaint = Paint()..color = Colors.white;

    for (final line in const [
      Rect.fromLTWH(0, 11, 29, 5),
      Rect.fromLTWH(8, 25, 27, 5),
      Rect.fromLTWH(17, 39, 18, 5),
    ]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(line, const Radius.circular(3)),
        paint,
      );
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(34, 8, 49, 39),
        const Radius.circular(6),
      ),
      paint,
    );
    final cab = Path()
      ..moveTo(78, 16)
      ..lineTo(91, 16)
      ..quadraticBezierTo(94, 16, 96, 19)
      ..lineTo(106, 33)
      ..lineTo(106, 44)
      ..quadraticBezierTo(106, 48, 102, 48)
      ..lineTo(78, 48)
      ..close();
    canvas.drawPath(cab, paint);

    final window = Path()
      ..moveTo(84, 20)
      ..lineTo(91, 20)
      ..lineTo(100, 32)
      ..lineTo(84, 32)
      ..close();
    canvas.drawPath(window, whitePaint);

    for (final x in const [51.0, 91.0]) {
      canvas.drawCircle(Offset(x, 48), 8, paint);
      canvas.drawCircle(Offset(x, 48), 3.6, whitePaint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SpeedTruckMarkPainter oldDelegate) => false;
}

class _LodbodWordmark extends StatelessWidget {
  const _LodbodWordmark({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: TextStyle(
          fontSize: AppTypography.size(37 * scale),
          height: .98,
          fontWeight: FontWeight.w900,
          letterSpacing: .3 * scale,
        ),
        children: const [
          TextSpan(
            text: 'LOD',
            style: TextStyle(color: _splashNavy),
          ),
          TextSpan(
            text: 'BOD',
            style: TextStyle(color: _splashOrange),
          ),
        ],
      ),
    );
  }
}

class _FeatureStrip extends StatelessWidget {
  const _FeatureStrip({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 66 * scale,
      child: Row(
        children: [
          Expanded(
            child: _SplashFeature(
              scale: scale,
              icon: Icons.inventory_2_outlined,
              label: 'Post Loads',
            ),
          ),
          Container(
            width: 1,
            height: 37 * scale,
            color: _splashNavy.withValues(alpha: .14),
          ),
          Expanded(
            child: _SplashFeature(
              scale: scale,
              icon: Icons.gavel_rounded,
              label: 'Get Bids',
            ),
          ),
          Container(
            width: 1,
            height: 37 * scale,
            color: _splashNavy.withValues(alpha: .14),
          ),
          Expanded(
            child: _SplashFeature(
              scale: scale,
              icon: Icons.local_shipping_outlined,
              label: 'Move Anywhere',
            ),
          ),
        ],
      ),
    );
  }
}

class _SplashFeature extends StatelessWidget {
  const _SplashFeature({
    required this.scale,
    required this.icon,
    required this.label,
  });

  final double scale;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 43 * scale,
          height: 43 * scale,
          decoration: BoxDecoration(
            color: const Color(0xFFFFE5D7).withValues(alpha: .9),
            borderRadius: BorderRadius.circular(12 * scale),
          ),
          child: Icon(icon, color: _splashNavy, size: 25 * scale),
        ),
        SizedBox(height: 5 * scale),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            style: TextStyle(
              color: _splashNavy,
              fontSize: AppTypography.size(12.5 * scale),
              fontWeight: FontWeight.w800,
              letterSpacing: -.15,
            ),
          ),
        ),
      ],
    );
  }
}

class _OrangeRouteAccent extends CustomPainter {
  const _OrangeRouteAccent();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(1, size.height * .78)
      ..cubicTo(
        size.width * .3,
        size.height * .1,
        size.width * .68,
        size.height * .05,
        size.width - 1,
        size.height * .52,
      );
    canvas.drawPath(
      path,
      Paint()
        ..color = _splashOrange
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _OrangeRouteAccent oldDelegate) => false;
}

class _LocationPill extends StatelessWidget {
  const _LocationPill(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .92),
        borderRadius: BorderRadius.circular(99),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33082743),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
        child: Text(
          label,
          style: TextStyle(
            color: _splashNavy,
            fontSize: AppTypography.size(11.5),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _LoadingProgress extends StatelessWidget {
  const _LoadingProgress({required this.scale, required this.progressStep});

  final double scale;
  final int progressStep;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 262 * scale,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 6 * scale,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .3),
                  borderRadius: BorderRadius.circular(99),
                ),
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: progressStep / 10,
                  heightFactor: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF7200), _splashOrange],
                      ),
                      borderRadius: BorderRadius.circular(99),
                      boxShadow: const [
                        BoxShadow(color: Color(0x66FF5900), blurRadius: 6),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 9 * scale),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Preparing your workspace...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: AppTypography.size(11.5 * scale),
                      fontWeight: FontWeight.w500,
                      letterSpacing: -.1,
                      shadows: const [
                        Shadow(
                          color: Color(0x55000000),
                          blurRadius: 5,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${progressStep * 10}%',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: AppTypography.size(11.5 * scale),
                      fontWeight: FontWeight.w700,
                      shadows: const [
                        Shadow(
                          color: Color(0x55000000),
                          blurRadius: 5,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
