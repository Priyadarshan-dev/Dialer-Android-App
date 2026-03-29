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

  Widget _buildList(BuildContext context, WidgetRef ref, List<CallHistoryEntity> calls) {
    if (calls.isEmpty) {
      return const Center(child: Text('No call history.'));
    }

    return ListView.builder(
      itemCount: calls.length,
      itemBuilder: (context, index) {
        final call = calls[index];
        return InkWell(
          onTap: () => _handleCall(context, ref, call),
          child: CallHistoryTile(
            call: call,
            onInfo: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CallHistoryDetailsScreen(call: call),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _handleCall(BuildContext context, WidgetRef ref, CallHistoryEntity call) async {
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

  // Old popup dialogs removed in favor of the full detail screen.
}
