import 'package:flutter/material.dart';
import 'package:dialer_app_poc/features/call_history/domain/entities/call_history_entity.dart';
import 'package:dialer_app_poc/core/utils/date_formatter.dart';
import 'package:google_fonts/google_fonts.dart';

class CallHistoryTile extends StatelessWidget {
  /// The representative (latest) call entry in the group.
  final CallHistoryEntity call;

  /// Total call count for this contact/number group.
  final int count;

  /// The latest note across the entire group (may differ from call.notes).
  final String? latestNote;

  /// Tapping info icon → open details screen.
  final VoidCallback onInfo;

  const CallHistoryTile({
    super.key,
    required this.call,
    required this.count,
    required this.onInfo,
    this.latestNote,
  });

  @override
  Widget build(BuildContext context) {
    final name = call.contactName;
    final timeStr = DateFormatter.formatCallTime(call.callTime);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF2C2C2E)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Leading Icon based on status
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF000000),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Icon(
                        (call.status == 'completed' || call.status == 'pending')
                            ? Icons.call_made_rounded
                            : Icons.call_received_rounded,
                        color: (call.status == 'completed' || call.status == 'pending')
                            ? const Color(0xFF22C55E)
                            : const Color(0xFFF43F5E),
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Name, Number, and call count badge
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (count > 1) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6366F1).withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFF6366F1).withOpacity(0.5),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  '$count',
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFF818CF8),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          call.phoneNumber,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF64748B),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Time and Info Button (tap here → go to details)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        timeStr,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF475569),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onInfo,
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: const Icon(
                            Icons.info_outline_rounded,
                            color: Color(0xFF6366F1),
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Latest note preview
            if (latestNote != null && latestNote!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 14),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.07),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: const Color(0xFF6366F1).withOpacity(0.15)),
                  ),
                  child: Text(
                    latestNote!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF94A3B8),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
