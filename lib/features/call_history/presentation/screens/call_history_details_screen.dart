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
  final CallHistoryEntity call;

  const CallHistoryDetailsScreen({super.key, required this.call});

  @override
  ConsumerState<CallHistoryDetailsScreen> createState() => _CallHistoryDetailsScreenState();
}

class _CallHistoryDetailsScreenState extends ConsumerState<CallHistoryDetailsScreen> {
  late TextEditingController _notesController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.call.notes);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveNotes() async {
    setState(() => _isSaving = true);
    await ref.read(callHistoryProvider.notifier).updateNotes(
          widget.call.id,
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
            icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFF43F5E)),
            onPressed: () => _confirmDelete(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            // Header: Avatar & Info
            _buildHeader(),
            const SizedBox(height: 48),
            // Note Editor Section
            _buildNoteSection(),
            const SizedBox(height: 40),
            // Call Details List
            _buildCallInfoList(),
            const SizedBox(height: 40),
            // Action Button
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
                widget.call.contactName.isNotEmpty ? widget.call.contactName[0].toUpperCase() : '?',
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
                  widget.call.contactName,
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.call.phoneNumber,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    color: const Color(0xFF94A3B8),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6366F1)),
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
        ],
      ),
    );
  }

  Widget _buildCallInfoList() {
    final dateStr = DateFormat('EEEE, MMMM d, y').format(widget.call.callTime);
    final timeStr = DateFormat('h:mm a').format(widget.call.callTime);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LOG DETAILS',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF475569),
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.calendar_today_rounded, 'Date', dateStr),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.access_time_rounded, 'Time', timeStr),
          const SizedBox(height: 16),
          _buildInfoRow(
            widget.call.status == AppConstants.statusCompleted ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded,
            'Status', 
            widget.call.status.toUpperCase(),
            valueColor: widget.call.status == AppConstants.statusCompleted ? const Color(0xFF22C55E) : const Color(0xFFF43F5E),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF334155)),
        const SizedBox(width: 16),
        Text(
          label,
          style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 15),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.outfit(
            color: valueColor ?? Colors.white, 
            fontSize: 15, 
            fontWeight: FontWeight.w600,
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
          label: Text('CALL BACK', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, letterSpacing: 1)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF22C55E),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 0,
          ),
        ),
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text('Delete Log', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to remove this call history record?', 
          style: TextStyle(color: Color(0xFF94A3B8))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          TextButton(
            onPressed: () {
              ref.read(callHistoryProvider.notifier).deleteCall(widget.call.id);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close details screen
            },
            child: const Text('Delete', style: TextStyle(color: Color(0xFFF43F5E))),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCallBack() async {
    final callHistory = CallHistoryEntity(
      id: const Uuid().v4(),
      contactName: widget.call.contactName,
      phoneNumber: widget.call.phoneNumber,
      callTime: DateTime.now(),
      status: AppConstants.statusPending,
    );

    await ref.read(callHistoryProvider.notifier).saveCall(callHistory);
    final res = await FlutterPhoneDirectCaller.callNumber(widget.call.phoneNumber);
    
    if (res == false && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not initiate callback')),
      );
    }
  }
}
