import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:solar_icons/solar_icons.dart';
import '../../../models/running_session.dart';

/// Strava-style share achievement screen
/// Allows users to add a background image and overlay workout stats with GPS route
class ShareAchievementScreen extends StatefulWidget {
  final RunningSession session;

  const ShareAchievementScreen({super.key, required this.session});

  @override
  State<ShareAchievementScreen> createState() => _ShareAchievementScreenState();
}

class _ShareAchievementScreenState extends State<ShareAchievementScreen> {
  File? _backgroundImage;
  final GlobalKey _shareKey = GlobalKey();
  bool _isGenerating = false;

  String _formatTime(int? seconds) {
    if (seconds == null) return '00:00';
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  String _formatDistance(double distance) {
    return distance.toStringAsFixed(2);
  }

  String _formatPace(double? pace) {
    if (pace == null) return '--:--';
    final minutes = pace.floor();
    final seconds = ((pace - minutes) * 60).round();
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _backgroundImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _shareAchievement() async {
    setState(() => _isGenerating = true);

    try {
      // Capture the widget as an image
      final boundary =
          _shareKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      // Save to temporary file
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/flowfit_achievement.png');
      await file.writeAsBytes(pngBytes);

      // Share the image
      await Share.shareXFiles(
        [XFile(file.path)],
        text:
            '🏃 Just completed a ${_formatDistance(widget.session.currentDistance)} km run with FlowFit! #FlowFit #Running',
      );

      if (mounted) {
        // Navigate back to dashboard after sharing
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/dashboard', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Share Achievement'),
        actions: [
          if (_isGenerating)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(SolarIconsBold.share),
              onPressed: _shareAchievement,
              tooltip: 'Share',
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: RepaintBoundary(
                  key: _shareKey,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: _buildShareableCard(),
                  ),
                ),
              ),
            ),
          ),
          _buildControls(theme),
        ],
      ),
    );
  }

  Widget _buildShareableCard() {
    // Instagram/Facebook Stories format: 1080x1920 (9:16 aspect ratio)
    return Container(
      width: 1080,
      height: 1920,
      decoration: const BoxDecoration(color: Colors.transparent),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background image or gradient
          if (_backgroundImage != null)
            Image.file(_backgroundImage!, fit: BoxFit.cover)
          else
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1E40AF), // Darker blue
                    Color(0xFF3B82F6), // Blue
                    Color(0xFF6366F1), // Indigo
                  ],
                ),
              ),
            ),

          // Dark overlay for better text readability
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.3),
                  Colors.black.withValues(alpha: 0.6),
                ],
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 60.0,
              vertical: 80.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // FlowFit logo at top
                Row(
                  children: [
                    SvgPicture.asset(
                      'assets/flowfit_logo.svg',
                      height: 48,
                      colorFilter: const ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'FlowFit',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),

                // Stats section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatRow(
                      'Distance',
                      '${_formatDistance(widget.session.currentDistance)} km',
                    ),
                    const SizedBox(height: 32),
                    _buildStatRow(
                      'Pace',
                      '${_formatPace(widget.session.avgPace)} /km',
                    ),
                    const SizedBox(height: 32),
                    _buildStatRow(
                      'Time',
                      _formatTime(widget.session.durationSeconds),
                    ),
                  ],
                ),

                // GPS Route Polyline - transparent background, just the route
                if (widget.session.routePoints.isNotEmpty)
                  SizedBox(
                    height: 700,
                    child: CustomPaint(
                      painter: RoutePolylinePainter(
                        routePoints: widget.session.routePoints,
                        polylineColor: const Color(0xFF3B82F6), // Blue color
                        polylineWidth: 8.0,
                      ),
                      child: Container(),
                    ),
                  ),

                // Date and activity type at bottom (no emoji)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Running',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      _formatDate(DateTime.now()),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Widget _buildStatRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 24,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 64,
            fontWeight: FontWeight.bold,
            height: 1.1,
          ),
        ),
      ],
    );
  }

  Widget _buildControls(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Add Image Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(SolarIconsBold.gallery),
              label: Text(
                _backgroundImage != null
                    ? 'Change Background'
                    : 'Add Background Image',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Share Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _isGenerating ? null : _shareAchievement,
              icon: const Icon(SolarIconsBold.share),
              label: const Text(
                'Share Achievement',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter to draw GPS route polyline directly on canvas
class RoutePolylinePainter extends CustomPainter {
  final List<LatLng> routePoints;
  final Color polylineColor;
  final double polylineWidth;

  RoutePolylinePainter({
    required this.routePoints,
    required this.polylineColor,
    required this.polylineWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (routePoints.isEmpty) return;

    // Calculate bounds of the route
    double minLat = routePoints.first.latitude;
    double maxLat = routePoints.first.latitude;
    double minLng = routePoints.first.longitude;
    double maxLng = routePoints.first.longitude;

    for (final point in routePoints) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    // Add padding
    final latRange = maxLat - minLat;
    final lngRange = maxLng - minLng;
    const padding = 0.1; // 10% padding

    minLat -= latRange * padding;
    maxLat += latRange * padding;
    minLng -= lngRange * padding;
    maxLng += lngRange * padding;

    // Convert GPS coordinates to canvas coordinates
    List<Offset> canvasPoints = routePoints.map((point) {
      final x = ((point.longitude - minLng) / (maxLng - minLng)) * size.width;
      final y =
          size.height -
          ((point.latitude - minLat) / (maxLat - minLat)) * size.height;
      return Offset(x, y);
    }).toList();

    // Draw white border (thicker) for better visibility
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..strokeWidth = polylineWidth + 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final borderPath = ui.Path();
    borderPath.moveTo(canvasPoints.first.dx, canvasPoints.first.dy);
    for (int i = 1; i < canvasPoints.length; i++) {
      borderPath.lineTo(canvasPoints[i].dx, canvasPoints[i].dy);
    }
    canvas.drawPath(borderPath, borderPaint);

    // Draw main polyline (blue)
    final polylinePaint = Paint()
      ..color = polylineColor
      ..strokeWidth = polylineWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final polylinePath = ui.Path();
    polylinePath.moveTo(canvasPoints.first.dx, canvasPoints.first.dy);
    for (int i = 1; i < canvasPoints.length; i++) {
      polylinePath.lineTo(canvasPoints[i].dx, canvasPoints[i].dy);
    }
    canvas.drawPath(polylinePath, polylinePaint);

    // Draw start marker (green circle)
    final startMarkerPaint = Paint()
      ..color = const Color(0xFF10B981)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(canvasPoints.first, 12, startMarkerPaint);

    // Draw start marker border
    final startBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(canvasPoints.first, 12, startBorderPaint);

    // Draw end marker (red circle)
    final endMarkerPaint = Paint()
      ..color = const Color(0xFFEF4444)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(canvasPoints.last, 12, endMarkerPaint);

    // Draw end marker border
    final endBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(canvasPoints.last, 12, endBorderPaint);
  }

  @override
  bool shouldRepaint(RoutePolylinePainter oldDelegate) {
    return oldDelegate.routePoints != routePoints ||
        oldDelegate.polylineColor != polylineColor ||
        oldDelegate.polylineWidth != polylineWidth;
  }
}
