import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dialer_app_poc/providers.dart';
import 'package:dialer_app_poc/features/call_history/domain/entities/call_history_entity.dart';
import 'package:intl/intl.dart';
import 'package:dialer_app_poc/core/constants/app_constants.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:uuid/uuid.dart';

class CallHistoryDetailsScreen extends ConsumerStatefulWidget {
  /// All call history records for this contact/number, sorted newest→oldest.
  final List<CallHistoryEntity> historyGroup;

  const CallHistoryDetailsScreen({super.key, required this.historyGroup});

  @override
  ConsumerState<CallHistoryDetailsScreen> createState() =>
      _CallHistoryDetailsScreenState();
}

class _CallHistoryDetailsScreenState
    extends ConsumerState<CallHistoryDetailsScreen> {
  late TextEditingController _notesController;
  bool _isSaving = false;
  bool _showMoreNotes = false;

  /// The most recent call record in the group.
  CallHistoryEntity get _latestCall => widget.historyGroup.first;

  /// All calls in the group that have notes (could be empty).
  List<_NoteEntry> get _allNoteEntries {
    final List<_NoteEntry> entries = [];
    for (final call in widget.historyGroup) {
      if (call.notes != null && call.notes!.trim().isNotEmpty) {
        entries.add(_NoteEntry(callId: call.id, note: call.notes!, callTime: call.callTime));
      }
    }
    return entries;
  }

  @override
  void initState() {
    super.initState();
    // Load the latest saved note into the editor
    final latestNote = _allNoteEntries.isNotEmpty ? _allNoteEntries.first.note : '';
    _notesController = TextEditingController(text: latestNote);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveNotes() async {
    setState(() => _isSaving = true);
    // Always save the note against the most recent call
    await ref.read(callHistoryProvider.notifier).updateNotes(
          _latestCall.id,
          _notesController.text.trim(),
        );
    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notes updated successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                color: Color(0xFFF43F5E)),
            onPressed: () => _confirmDelete(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _buildHeader(),
            const SizedBox(height: 32),
            _buildNoteSection(),
            const SizedBox(height: 40),
            _buildCallLogList(),
            const SizedBox(height: 40),
            _buildCallBackButton(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFF2C2C2E)),
            ),
            child: Center(
              child: Text(
                _latestCall.contactName.isNotEmpty
                    ? _latestCall.contactName[0].toUpperCase()
                    : '?',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF6366F1),
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _latestCall.contactName,
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _latestCall.phoneNumber,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
                if (widget.historyGroup.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: const Color(0xFF6366F1).withOpacity(0.4)),
                      ),
                      child: Text(
                        '${widget.historyGroup.length} calls',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF818CF8),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteSection() {
    final noteEntries = _allNoteEntries;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CRM NOTES',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF475569),
                  letterSpacing: 1.5,
                ),
              ),
              if (_isSaving)
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Color(0xFF6366F1)),
                )
              else
                GestureDetector(
                  onTap: _saveNotes,
                  child: Text(
                    'SAVE',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF6366F1),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Editable field for the LATEST note
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF2C2C2E)),
            ),
            child: TextField(
              controller: _notesController,
              maxLines: 6,
              style: GoogleFonts.outfit(color: Colors.white, height: 1.5),
              decoration: InputDecoration(
                hintText: 'Add details about this conversation...',
                hintStyle: GoogleFonts.outfit(color: const Color(0xFF475569)),
                border: InputBorder.none,
              ),
            ),
          ),

          // Show More button — only visible if there are past notes beyond the first
          if (noteEntries.length > 1) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => setState(() => _showMoreNotes = !_showMoreNotes),
              child: Row(
                children: [
                  Text(
                    _showMoreNotes
                        ? 'Hide past notes'
                        : 'Show ${noteEntries.length - 1} past note${noteEntries.length - 1 > 1 ? 's' : ''}',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF6366F1),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _showMoreNotes
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xFF6366F1),
                    size: 18,
                  ),
                ],
              ),
            ),

            // Past notes list — shown if expanded
            if (_showMoreNotes)
              Column(
                children: noteEntries.skip(1).map((entry) {
                  final dateStr = DateFormat('MMM d, y · h:mm a')
                      .format(entry.callTime);
                  return Container(
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141416),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF2C2C2E)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateStr,
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF475569),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          entry.note,
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF94A3B8),
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildCallLogList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CALL LOG',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF475569),
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          ...widget.historyGroup.asMap().entries.map((entry) {
            final idx = entry.key;
            final call = entry.value;
            final dateStr =
                DateFormat('EEE, MMM d · h:mm a').format(call.callTime);
            final isOutgoing =
                call.status == AppConstants.statusCompleted ||
                    call.status == AppConstants.statusPending;

            return Padding(
              padding: EdgeInsets.only(bottom: idx < widget.historyGroup.length - 1 ? 12 : 0),
              child: _buildLogRow(isOutgoing, call.status, dateStr),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLogRow(bool isOutgoing, String status, String dateStr) {
    final statusColor = isOutgoing
        ? const Color(0xFF22C55E)
        : const Color(0xFFF43F5E);

    return Row(
      children: [
        Icon(
          isOutgoing ? Icons.call_made_rounded : Icons.call_received_rounded,
          size: 18,
          color: statusColor,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            dateStr,
            style: GoogleFonts.outfit(
              color: const Color(0xFF94A3B8),
              fontSize: 14,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            status.toUpperCase(),
            style: GoogleFonts.outfit(
              color: statusColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCallBackButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: SizedBox(
        width: double.infinity,
        height: 64,
        child: ElevatedButton.icon(
          onPressed: _handleCallBack,
          icon: const Icon(Icons.call_rounded),
          label: Text('CALL BACK',
              style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w800, letterSpacing: 1)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF22C55E),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            elevation: 0,
          ),
        ),
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete History',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.historyGroup.length > 1
                  ? 'This will permanently delete all ${widget.historyGroup.length} call records for ${_latestCall.contactName}.'
                  : 'This will permanently delete this call record.',
              style: GoogleFonts.outfit(
                color: const Color(0xFF94A3B8),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF43F5E).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFFF43F5E).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: Color(0xFFF43F5E), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'All notes will also be cleared and cannot be recovered.',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFF43F5E),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel',
                style: GoogleFonts.outfit(color: const Color(0xFF94A3B8))),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final ids = widget.historyGroup.map((c) => c.id).toList();
              await ref
                  .read(callHistoryProvider.notifier)
                  .deleteMultipleCalls(ids);
              if (mounted) Navigator.pop(context);
            },
            child: Text('Delete All',
                style: GoogleFonts.outfit(
                  color: const Color(0xFFF43F5E),
                  fontWeight: FontWeight.w700,
                )),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCallBack() async {
    final callHistory = CallHistoryEntity(
      id: const Uuid().v4(),
      contactName: _latestCall.contactName,
      phoneNumber: _latestCall.phoneNumber,
      callTime: DateTime.now(),
      status: AppConstants.statusPending,
    );

    await ref.read(callHistoryProvider.notifier).saveCall(callHistory);
    final res =
        await FlutterPhoneDirectCaller.callNumber(_latestCall.phoneNumber);

    if (res == false && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not initiate callback')),
      );
    }
  }
}

/// Small helper model to carry note data for the "Show More" section.
class _NoteEntry {
  final String callId;
  final String note;
  final DateTime callTime;

  const _NoteEntry({
    required this.callId,
    required this.note,
    required this.callTime,
  });
}
