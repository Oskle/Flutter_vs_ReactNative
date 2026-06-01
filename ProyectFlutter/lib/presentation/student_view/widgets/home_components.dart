import 'package:flutter/material.dart';

enum Status { open, closed, synced, pending, completed }

String _capitalize(String s) {
  if (s.isEmpty) return s;
  return s[0].toUpperCase() + s.substring(1);
}

class StatusChip extends StatelessWidget {
  final Status status;
  final String? label;
  const StatusChip({Key? key, required this.status, this.label})
    : super(key: key);

  Color _bg() {
    switch (status) {
      case Status.open:
        return const Color(0xFF006FBF);
      case Status.closed:
        return const Color(0xFF999999);
      case Status.synced:
        return const Color(0xFFE5E5E5);
      case Status.pending:
        return const Color(0xFF006FBF);
      case Status.completed:
        return const Color(0xFF46A647);
    }
  }

  Color _fg() {
    switch (status) {
      case Status.synced:
        return const Color(0xFF444444);
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = label ?? _capitalize(status.toString().split('.').last);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _bg(),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: TextStyle(fontSize: 10, color: _fg())),
    );
  }
}

class ListItem extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? metadata;
  final Widget? rightContent;
  final bool showChevron;
  final VoidCallback? onTap;
  const ListItem({
    Key? key,
    required this.title,
    this.subtitle,
    this.metadata,
    this.rightContent,
    this.showChevron = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: Colors.white,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF777777),
                      ),
                    ),
                  ],
                  if (metadata != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      metadata!,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF999999),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (rightContent != null) ...[
              rightContent!,
              const SizedBox(width: 8),
            ],
            if (showChevron)
              const Icon(
                Icons.chevron_right,
                color: Color(0xFF999999),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
