import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../styles.dart';
import 'brand_logo.dart';

class VitalMapHeroCard extends StatelessWidget {
  const VitalMapHeroCard({
    super.key,
    this.trailing,
    this.bottom,
    this.compact = false,
    this.title = 'VitalMap',
    this.subtitle = 'Organ Health Risk Indicator',
    this.description =
        'Enter health details once. Get personalized screening insights.',
  });

  final Widget? trailing;
  final Widget? bottom;
  final bool compact;
  final String title;
  final String subtitle;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF08264A), Color(0xFF0E5D7C), Color(0xFF24D1D1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0E5D7C).withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _PulsePatternPainter()),
          ),
          Padding(
            padding: EdgeInsets.all(compact ? 14 : 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final content = Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        BrandLogoMark(size: compact ? 42 : 52, glow: true),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                subtitle,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.84),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                description,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.72),
                                  height: 1.25,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                    if (trailing == null || constraints.maxWidth < 620) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          content,
                          if (trailing != null) ...[
                            const SizedBox(height: 16),
                            trailing!,
                          ],
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: content),
                        const SizedBox(width: 16),
                        trailing!,
                      ],
                    );
                  },
                ),
                if (bottom != null) ...[
                  const SizedBox(height: 16),
                  bottom!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PremiumProgressChips extends StatelessWidget {
  const PremiumProgressChips({
    super.key,
    required this.labels,
    this.activeIndex = 0,
  });

  final List<String> labels;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < labels.length; i++)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: i == activeIndex
                  ? Colors.white.withValues(alpha: 0.22)
                  : Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withValues(alpha: 0.26)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  i <= activeIndex
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  size: 14,
                  color: Colors.white
                      .withValues(alpha: i <= activeIndex ? 0.95 : 0.62),
                ),
                const SizedBox(width: 6),
                Text(
                  labels[i],
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class GradientActionButton extends StatelessWidget {
  const GradientActionButton({
    super.key,
    required this.onPressed,
    required this.label,
    required this.icon,
    this.loading = false,
  });

  final VoidCallback? onPressed;
  final String label;
  final IconData icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: enabled
            ? const LinearGradient(
                colors: [Color(0xFF0E86C8), Color(0xFF23D6C8)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
            : null,
        color: enabled ? null : AppStyles.border,
        borderRadius: BorderRadius.circular(14),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: AppStyles.primary.withValues(alpha: 0.25),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        ),
        icon: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(icon),
        label: Text(label),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final HealthStatusStyle status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: status.badgeBackground,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: status.border),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: status.text,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class OverallInsightRing extends StatelessWidget {
  const OverallInsightRing({
    super.key,
    required this.status,
    required this.calculatedCount,
    required this.moreDataCount,
    this.compact = false,
  });

  final HealthStatusStyle status;
  final int calculatedCount;
  final int moreDataCount;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final total = math.max(calculatedCount + moreDataCount, 1);
    final progress = calculatedCount / total;
    final size = compact ? 112.0 : 138.0;
    return Container(
      padding: EdgeInsets.all(compact ? 10 : 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: Size.square(size),
                  painter: _RingPainter(
                    progress: progress,
                    color: status.accent,
                    trackColor: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      calculatedCount.toString(),
                      style: TextStyle(
                        color: compact ? Colors.white : status.text,
                        fontSize: compact ? 24 : 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'indexes',
                      style: TextStyle(
                        color: compact
                            ? Colors.white.withValues(alpha: 0.72)
                            : AppStyles.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: compact ? 170 : 220),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Overall Health Insight',
                  style: TextStyle(
                    color: compact ? Colors.white : AppStyles.text,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                compact
                    ? _HeroStatusBadge(label: status.label)
                    : StatusBadge(status: status),
                const SizedBox(height: 8),
                Text(
                  '$moreDataCount needing more data',
                  style: TextStyle(
                    color: compact
                        ? Colors.white.withValues(alpha: 0.76)
                        : AppStyles.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OverallInsightCard extends StatelessWidget {
  const OverallInsightCard({
    super.key,
    required this.overallRisk,
    required this.calculatedCount,
    required this.moreDataCount,
    this.lastChecked,
  });

  final String overallRisk;
  final int calculatedCount;
  final int moreDataCount;
  final DateTime? lastChecked;

  @override
  Widget build(BuildContext context) {
    final status = AppStyles.statusStyle(overallRisk);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, status.background],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: status.border),
        boxShadow: [
          BoxShadow(
            color: status.accent.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final ring = OverallInsightRing(
            status: status,
            calculatedCount: calculatedCount,
            moreDataCount: moreDataCount,
          );
          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Overall Health Insight',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              StatusBadge(status: status),
              const SizedBox(height: 10),
              Text(
                '$calculatedCount indexes calculated',
                style:
                    TextStyle(color: status.text, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                '$moreDataCount needing more data',
                style:
                    TextStyle(color: status.text, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Last checked: ${lastChecked == null ? 'Not checked yet' : _formatDate(lastChecked!)}',
                style: const TextStyle(color: AppStyles.muted),
              ),
              const SizedBox(height: 10),
              Text(
                _overallExplanation(status.label, calculatedCount),
                style: TextStyle(
                  color: status.text,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );
          if (constraints.maxWidth < 620) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [ring, const SizedBox(height: 14), details],
            );
          }
          return Row(
            children: [
              ring,
              const SizedBox(width: 18),
              Expanded(child: details),
            ],
          );
        },
      ),
    );
  }
}

class OrganInsightSummaryBar extends StatelessWidget {
  const OrganInsightSummaryBar({super.key, required this.counts});

  final Map<String, int> counts;

  @override
  Widget build(BuildContext context) {
    final items = [
      _SummarySegment(AppStyles.lowConcernStatus, counts['Low Concern'] ?? 0),
      _SummarySegment(AppStyles.monitorStatus, counts['Monitor'] ?? 0),
      _SummarySegment(
          AppStyles.attentionStatus, counts['Attention Needed'] ?? 0),
      _SummarySegment(
          AppStyles.moreDataStatus, counts['More Data Needed'] ?? 0),
    ];
    final total =
        items.fold<int>(0, (sum, item) => sum + math.max(item.count, 0));
    final segments = total == 0
        ? [_SummarySegment(AppStyles.moreDataStatus, 1)]
        : items.where((item) => item.count > 0).toList();
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppStyles.border),
        boxShadow: [
          BoxShadow(
            color: AppStyles.primary.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Organ Insight Summary',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 16,
              child: Row(
                children: [
                  for (final segment in segments)
                    Expanded(
                      flex: segment.count <= 0 ? 1 : segment.count,
                      child: ColoredBox(color: segment.status.accent),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              for (final item in items)
                _LegendChip(status: item.status, count: item.count),
            ],
          ),
        ],
      ),
    );
  }
}

class ContributorMiniGraph extends StatelessWidget {
  const ContributorMiniGraph({super.key, required this.counts});

  final Map<String, int> counts;

  @override
  Widget build(BuildContext context) {
    final items = [
      _ContributorMiniItem(
        title: 'Lifestyle',
        count: counts['Lifestyle'] ?? 0,
        style: AppStyles.lifestyleContributor,
      ),
      _ContributorMiniItem(
        title: 'Food Habits',
        count: counts['Food Habits'] ?? 0,
        style: AppStyles.foodContributor,
      ),
      _ContributorMiniItem(
        title: 'Environment',
        count: counts['Environment'] ?? 0,
        style: AppStyles.environmentContributor,
      ),
    ];
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppStyles.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('General Health Pattern',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          const SizedBox(height: 6),
          const Text(
            'These factors may contribute to risk indicators.',
            style: TextStyle(color: AppStyles.muted),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth > 720 ? 3 : 1;
              final width =
                  (constraints.maxWidth - (12 * (columns - 1))) / columns;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final item in items) SizedBox(width: width, child: item),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class ScoreGauge extends StatelessWidget {
  const ScoreGauge({
    super.key,
    required this.status,
    required this.scoreText,
    this.size = 74,
  });

  final HealthStatusStyle status;
  final String scoreText;
  final double size;

  @override
  Widget build(BuildContext context) {
    final progress = switch (AppStyles.statusRank(status.label)) {
      3 => 0.9,
      2 => 0.62,
      1 => 0.34,
      _ => 0.18,
    };
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _RingPainter(
              progress: progress,
              color: status.accent,
              trackColor: status.border.withValues(alpha: 0.55),
              strokeWidth: 8,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: FittedBox(
              child: Text(
                scoreText,
                style: TextStyle(
                  color: status.text,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContributorMiniItem extends StatelessWidget {
  const _ContributorMiniItem({
    required this.title,
    required this.count,
    required this.style,
  });

  final String title;
  final int count;
  final ContributorStyle style;

  @override
  Widget build(BuildContext context) {
    final level = count >= 3
        ? 'High'
        : count >= 1
            ? 'Moderate'
            : 'Low';
    final progress = count >= 3
        ? 1.0
        : count >= 1
            ? 0.62
            : 0.28;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: style.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(style.icon, color: style.accent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style:
                      TextStyle(color: style.text, fontWeight: FontWeight.w900),
                ),
              ),
              Text(
                level,
                style:
                    TextStyle(color: style.text, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 9,
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.68),
              color: style.accent,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            count == 0
                ? 'No major items noted'
                : '$count item${count == 1 ? '' : 's'} noted',
            style: TextStyle(color: style.text, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

String _overallExplanation(String status, int calculatedCount) {
  if (calculatedCount == 0) {
    return 'Add available report values to generate organ-wise screening insights.';
  }
  if (status == AppStyles.attentionStatus.label) {
    return 'Some available values need review if they persist or are linked with symptoms.';
  }
  if (status == AppStyles.monitorStatus.label) {
    return 'Some available values should be monitored over time.';
  }
  if (status == AppStyles.lowConcernStatus.label) {
    return 'Available values look reassuring within this screening context.';
  }
  return 'More data can improve this screening insight.';
}

class _HeroStatusBadge extends StatelessWidget {
  const _HeroStatusBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({required this.status, required this.count});

  final HealthStatusStyle status;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: status.accent,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '${status.label}: $count',
          style: const TextStyle(
            color: AppStyles.muted,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _SummarySegment {
  const _SummarySegment(this.status, this.count);

  final HealthStatusStyle status;
  final int count;
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    this.strokeWidth = 10,
  });

  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final inset = strokeWidth / 2;
    final arcRect = rect.deflate(inset);
    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final active = Paint()
      ..shader = SweepGradient(
        colors: [color.withValues(alpha: 0.55), color],
      ).createShader(arcRect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(arcRect, -math.pi / 2, math.pi * 2, false, track);
    canvas.drawArc(
      arcRect,
      -math.pi / 2,
      math.pi * 2 * progress.clamp(0.0, 1.0).toDouble(),
      false,
      active,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return progress != oldDelegate.progress ||
        color != oldDelegate.color ||
        trackColor != oldDelegate.trackColor ||
        strokeWidth != oldDelegate.strokeWidth;
  }
}

class _PulsePatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    for (var y = 22.0; y < size.height; y += 34) {
      final path = Path()..moveTo(size.width * 0.42, y);
      path.lineTo(size.width * 0.50, y);
      path.lineTo(size.width * 0.53, y - 10);
      path.lineTo(size.width * 0.57, y + 13);
      path.lineTo(size.width * 0.61, y - 5);
      path.lineTo(size.width * 0.66, y);
      path.lineTo(size.width - 18, y);
      canvas.drawPath(path, paint);
    }
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.055)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var x = 18.0; x < size.width; x += 42) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
