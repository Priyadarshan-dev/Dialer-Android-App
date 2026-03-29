import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dialer_app_poc/providers.dart';
import 'package:dialer_app_poc/features/contacts/domain/entities/contact_entity.dart';
import 'package:dialer_app_poc/features/contacts/presentation/screens/widgets/add_contact_dialog.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:dialer_app_poc/features/call_history/domain/entities/call_history_entity.dart';
import 'package:uuid/uuid.dart';
import 'package:dialer_app_poc/core/constants/app_constants.dart';
import 'package:intl/intl.dart';

class ContactDetailsScreen extends ConsumerWidget {
  final String contactId;

  const ContactDetailsScreen({super.key, required this.contactId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch contacts list to get the latest data automatically
    final contactsState = ref.watch(contactsProvider);
    final contact = contactsState.contacts.where((c) => c.id == contactId).firstOrNull;

    // If contact is not found (e.g., deleted), show a placeholder or pop
    if (contact == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Watch call history to show recent calls for this contact
    final callHistoryState = ref.watch(callHistoryProvider);
    final contactCalls = callHistoryState.calls.where((c) {
      // Simple 10-digit matching for the activity feed
      final phone1 = c.phoneNumber.replaceAll(RegExp(r'\D'), '');
      final phone2 = contact.phoneNumbers.first.replaceAll(RegExp(r'\D'), '');
      return phone1.endsWith(phone2.substring(phone2.length > 10 ? phone2.length - 10 : 0)) ||
             phone2.endsWith(phone1.substring(phone1.length > 10 ? phone1.length - 10 : 0));
    }).toList();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.white70),
            onPressed: () => _editContact(context, contact),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFF43F5E)),
            onPressed: () => _confirmDelete(context, ref, contact),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Hero section
            _buildHero(contact),
            const SizedBox(height: 32),
            // Quick Actions
            _buildQuickActions(context, ref),
            const SizedBox(height: 40),
            // Contact Info
            _buildInfoSection(),
            const SizedBox(height: 40),
            // Activity Feed (Call History for this contact)
            _buildActivityFeed(contactCalls),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // Inside build, the update to calls to sub-widgets
  // Helper for the widget building to use the watched contact
  Widget _buildContent(BuildContext context, WidgetRef ref, ContactEntity contact, List<CallHistoryEntity> contactCalls) {
    return Column(...) // This is just a thought, I'll just update where contact is used directly in build
  }

  Widget _buildHero(ContactEntity contact) {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF818CF8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Center(
            child: Text(
              contact.displayName.isNotEmpty ? contact.displayName[0].toUpperCase() : '?',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          contact.displayName,
          style: GoogleFonts.outfit(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'CRM LEAD',
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF6366F1),
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ActionButton(
          icon: Icons.call_rounded,
          label: 'Call',
          color: const Color(0xFF22C55E),
          onTap: () => _handleCall(context, ref, contact),
        ),
        const SizedBox(width: 40),
        _ActionButton(
          icon: Icons.message_rounded,
          label: 'Message',
          color: const Color(0xFF6366F1),
          onTap: () {
            // Simplified SMS placeholder for the POC
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Messaging integration coming soon')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildInfoSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CONTACT INFORMATION',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF475569),
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.phone_iphone_rounded, color: Color(0xFF94A3B8), size: 24),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.phoneNumbers.first,
                      style: GoogleFonts.outfit(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Mobile',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: const Color(0xFF64748B),
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

  Widget _buildActivityFeed(List<CallHistoryEntity> calls) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RECENT ACTIVITY',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF475569),
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          if (calls.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF2C2C2E)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.history_rounded, color: Color(0xFF334155), size: 40),
                  const SizedBox(height: 12),
                  Text(
                    'No interaction history yet',
                    style: GoogleFonts.outfit(color: const Color(0xFF64748B)),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: calls.take(5).length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final call = calls[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1E),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        call.status == AppConstants.statusCompleted 
                            ? Icons.call_made_rounded 
                            : Icons.call_missed_rounded,
                        size: 18,
                        color: call.status == AppConstants.statusCompleted 
                            ? const Color(0xFF22C55E) 
                            : const Color(0xFFF43F5E),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              call.notes?.isNotEmpty == true ? call.notes! : 'Interactive call session',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('MMM d, h:mm a').format(call.callTime),
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  void _editContact(BuildContext context, ContactEntity contact) {
    showDialog(
      context: context,
      builder: (context) => AddContactDialog(contact: contact),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, ContactEntity contact) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text('Delete Contact', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to delete ${contact.displayName}? This will also remove their caller identification.', 
          style: const TextStyle(color: Color(0xFF94A3B8))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          TextButton(
            onPressed: () {
              ref.read(contactsProvider.notifier).deleteContact(contact.id);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close details screen
            },
            child: const Text('Delete', style: TextStyle(color: Color(0xFFF43F5E))),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCall(BuildContext context, WidgetRef ref, ContactEntity contact) async {
    final phoneNumber = contact.phoneNumbers.first;
    final callHistory = CallHistoryEntity(
      id: const Uuid().v4(),
      contactName: contact.displayName,
      phoneNumber: phoneNumber,
      callTime: DateTime.now(),
      status: AppConstants.statusPending,
    );

    await ref.read(callHistoryProvider.notifier).saveCall(callHistory);
    final res = await FlutterPhoneDirectCaller.callNumber(phoneNumber);
    
    if (res == false && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not initiate call')),
      );
    }
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
