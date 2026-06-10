import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/providers.dart';
import 'conversation_list_pane.dart';
import 'read_view.dart';

/// Two-pane home: conversation sidebar + detail (DESIGN.md §6
/// "Sidebar / home"). M2 shows the bare read mode in the detail pane; the
/// canvas takes its place in M3.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedId = ref.watch(selectedConversationIdProvider);
    return Scaffold(
      body: Row(
        children: [
          const SizedBox(width: 320, child: ConversationListPane()),
          const VerticalDivider(width: 1),
          Expanded(
            child: selectedId == null
                ? const Center(child: Text('Select a conversation'))
                : ReadView(
                    key: ValueKey(selectedId),
                    conversationId: selectedId,
                  ),
          ),
        ],
      ),
    );
  }
}
