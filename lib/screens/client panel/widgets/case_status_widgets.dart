import 'package:flutter/material.dart';

// ─── Case Detail Row ──────────────────────────────────────────────────────────

class CaseDetailRow extends StatelessWidget {
  final String label;
  final String value;
  const CaseDetailRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 52,
          child: Text(
            label,
            style: const TextStyle(color: Color(0xFF6B6B6B), fontSize: 12),
          ),
        ),
        const Text(
          ':  ',
          style: TextStyle(color: Color(0xFF6B6B6B), fontSize: 12),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xFFDDDDDD),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Timeline Components ──────────────────────────────────────────────────────

enum TimelineStatus { done, active, pending }

class TimelineStep {
  final String date;
  final String title;
  final TimelineStatus status;
  final String subtitle;
  const TimelineStep({
    required this.date,
    required this.title,
    required this.status,
    required this.subtitle,
  });
}

class TimelineTile extends StatelessWidget {
  final TimelineStep step;
  final bool isLast;
  const TimelineTile({super.key, required this.step, required this.isLast});

  @override
  Widget build(BuildContext context) {
    Color dotColor;
    IconData dotIcon;
    switch (step.status) {
      case TimelineStatus.done:
        dotColor = const Color(0xFF059669);
        dotIcon = Icons.check_circle;
        break;
      case TimelineStatus.active:
        dotColor = const Color(0xFFFFB800);
        dotIcon = Icons.radio_button_checked;
        break;
      case TimelineStatus.pending:
        dotColor = const Color(0xFF3A3A3A);
        dotIcon = Icons.radio_button_unchecked;
        break;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 54,
            child: Text(
              step.date,
              style: const TextStyle(color: Color(0xFF6B6B6B), fontSize: 11),
            ),
          ),
          Column(
            children: [
              Icon(dotIcon, color: dotColor, size: 20),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: const Color(0xFF252525),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: TextStyle(
                      color: step.status == TimelineStatus.pending
                          ? const Color(0xFF6B6B6B)
                          : Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    step.subtitle,
                    style: const TextStyle(
                      color: Color(0xFF6B6B6B),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Hearing Update Card ──────────────────────────────────────────────────────

class HearingUpdateCard extends StatelessWidget {
  final String date;
  final String title;
  final String subtitle;
  final bool isRecent;

  const HearingUpdateCard({
    super.key,
    required this.date,
    required this.title,
    required this.subtitle,
    required this.isRecent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isRecent
              ? const Color(0xFFFF6B00).withValues(alpha: 0.3)
              : const Color(0xFF252525),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isRecent
                  ? const Color(0xFFFF6B00).withValues(alpha: 0.12)
                  : const Color(0xFF252525),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isRecent ? Icons.gavel : Icons.history,
              color: isRecent
                  ? const Color(0xFFFF6B00)
                  : const Color(0xFF6B6B6B),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: TextStyle(
                    color: isRecent
                        ? const Color(0xFFFF6B00)
                        : const Color(0xFF6B6B6B),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF9E9E9E),
                    fontSize: 11,
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

// ─── Document Chip ────────────────────────────────────────────────────────────

class DocumentChip extends StatelessWidget {
  final String name;
  final IconData icon;
  final Color color;
  const DocumentChip({
    super.key,
    required this.name,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Opening $name...'), backgroundColor: color),
        );
      },
      child: Container(
        width: 85,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF252525)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 6),
            Text(
              name,
              style: const TextStyle(
                color: Color(0xFFCCCCCC),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Quick Action Button ──────────────────────────────────────────────────────

class QuickActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const QuickActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
