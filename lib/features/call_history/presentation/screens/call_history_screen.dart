import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dialer_app_poc/providers.dart';
import 'package:dialer_app_poc/features/call_history/domain/entities/call_history_entity.dart';
import 'package:dialer_app_poc/features/call_history/presentation/screens/widgets/call_history_tile.dart';
import 'package:dialer_app_poc/features/call_history/presentation/screens/call_history_details_screen.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:uuid/uuid.dart';
import 'package:dialer_app_poc/core/constants/app_constants.dart';

class CallHistoryScreen extends ConsumerWidget {
  const CallHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(callHistoryProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Call History'),
        surfaceTintColor: Colors.transparent,
      ),
      body: RefreshIndicator(
        color: const Color(0xFF6366F1),
        onRefresh: () => ref.read(callHistoryProvider.notifier).loadCalls(),
        child: _buildList(context, ref, state.calls),
      ),
    );
  }

  /// Groups calls by phone number, sorted newest first. Returns a list of groups
  /// where each group is a list of calls for the same contact (sorted newest→oldest).
  List<List<CallHistoryEntity>> _groupCalls(List<CallHistoryEntity> calls) {
    final Map<String, List<CallHistoryEntity>> grouped = {};
    for (final call in calls) {
      grouped.putIfAbsent(call.phoneNumber, () => []).add(call);
    }

    // Each group is already newest-first since the provider sorts before passing here.
    // Sort groups so that the most recent call across all groups comes first.
    final groups = grouped.values.toList();
    groups.sort((a, b) => b.first.callTime.compareTo(a.first.callTime));
    return groups;
  }

  Widget _buildList(
      BuildContext context, WidgetRef ref, List<CallHistoryEntity> calls) {
    if (calls.isEmpty) {
      return const Center(child: Text('No call history.'));
    }

    final groups = _groupCalls(calls);

    return ListView.builder(
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        // The first entry is the most recent call for this number.
        final latest = group.first;

        // Find the latest note across the entire group.
        String? latestNote;
        for (final c in group) {
          if (c.notes != null && c.notes!.trim().isNotEmpty) {
            latestNote = c.notes;
            break;
          }
        }

        return GestureDetector(
          // Tapping anywhere on the tile body → initiate call
          onTap: () => _handleCall(context, ref, latest),
          child: CallHistoryTile(
            call: latest,
            count: group.length,
            latestNote: latestNote,
            // Info icon tap → open grouped details screen
            onInfo: () {
              // Stop the GestureDetector from also firing onTap
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      CallHistoryDetailsScreen(historyGroup: group),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _handleCall(
      BuildContext context, WidgetRef ref, CallHistoryEntity call) async {
    final phoneNumber = call.phoneNumber;
    final callHistory = CallHistoryEntity(
      id: const Uuid().v4(),
      contactName: call.contactName,
      phoneNumber: phoneNumber,
      callTime: DateTime.now(),
      status: AppConstants.statusPending,
    );

    // 1. Save new pending call log
    await ref.read(callHistoryProvider.notifier).saveCall(callHistory);

    // 2. Launch phone call
    final res = await FlutterPhoneDirectCaller.callNumber(phoneNumber);

    if (res == false && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not initiate callback')),
      );
    }
  }
}
