import 'package:flowfit/screens/landing/widgets/landing_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LandingDevicePreview extends StatelessWidget {
  const LandingDevicePreview({super.key});

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 520;

    // The device mock shows fabricated metrics ("72 BPM", "Active minutes 42").
    // Exclude the whole subtree from semantics so assistive tech does not
    // announce the placeholder numbers as the user's real health data.
    return ExcludeSemantics(
      child: AspectRatio(
        aspectRatio: isCompact ? 0.76 : 1.04,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Flowy peeks out from behind the panel so the buddy — the
            // product's core idea — is visible before the first scroll.
            // Painted beneath the card, head above its top edge. Static on
            // purpose: landing tests pumpAndSettle, so no animations here.
            Positioned(
              right: 30,
              top: -54,
              child: SvgPicture.asset(
                'assets/flowy.svg',
                width: 96,
                height: 96,
                fit: BoxFit.contain,
                semanticsLabel: 'Flowy, the FlowFit buddy',
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFC8DAF1)),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A174EA6),
                      blurRadius: 30,
                      offset: Offset(0, 18),
                    ),
                  ],
                ),
                child: const Padding(
                  padding: EdgeInsets.all(22),
                  child: LandingProgressPanel(),
                ),
              ),
            ),
            const Positioned(right: -8, bottom: 18, child: LandingWatchFace()),
            Positioned(
              left: 22,
              bottom: -18,
              child: Container(
                width: 178,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: LandingPalette.ink,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.favorite_rounded, color: LandingPalette.red),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '72 BPM synced',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'GeneralSans',
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LandingProgressPanel extends StatelessWidget {
  const LandingProgressPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.directions_run_rounded, color: LandingPalette.blue),
            SizedBox(width: 8),
            Text(
              'Today',
              style: TextStyle(
                color: LandingPalette.ink,
                fontFamily: 'GeneralSans',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const LandingMetricRow(
          label: 'Active minutes',
          value: '42',
          percent: 0.72,
          color: LandingPalette.blue,
        ),
        const SizedBox(height: 18),
        const LandingMetricRow(
          label: 'Workout effort',
          value: '6.8',
          percent: 0.58,
          color: LandingPalette.red,
        ),
        const SizedBox(height: 18),
        const LandingMetricRow(
          label: 'Recovery check',
          value: 'Good',
          percent: 0.82,
          color: LandingPalette.green,
        ),
        const Spacer(),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 86,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7D6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  color: LandingPalette.yellow,
                  size: 38,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 86,
                decoration: BoxDecoration(
                  color: const Color(0xFFE9F8EF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.park_rounded,
                  color: LandingPalette.green,
                  size: 36,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class LandingMetricRow extends StatelessWidget {
  const LandingMetricRow({
    super.key,
    required this.label,
    required this.value,
    required this.percent,
    required this.color,
  });

  final String label;
  final String value;
  final double percent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: LandingPalette.muted,
                  fontFamily: 'GeneralSans',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: LandingPalette.ink,
                fontFamily: 'GeneralSans',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 8,
            color: color,
            backgroundColor: const Color(0xFFE6EDF7),
          ),
        ),
      ],
    );
  }
}

class LandingWatchFace extends StatelessWidget {
  const LandingWatchFace({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 126,
      height: 126,
      decoration: BoxDecoration(
        color: LandingPalette.ink,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 6),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24102033),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_rounded, color: LandingPalette.red, size: 24),
          SizedBox(height: 6),
          Text(
            '72',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'GeneralSans',
              fontSize: 34,
              fontWeight: FontWeight.w800,
              height: 1,
              letterSpacing: 0,
            ),
          ),
          SizedBox(height: 2),
          Text(
            'BPM',
            style: TextStyle(
              color: Color(0xFFB7C8DD),
              fontFamily: 'GeneralSans',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}
