import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/providers.dart';
import 'canvas/canvas_view.dart';
import 'conversation_list_pane.dart';

/// Two-pane home: conversation sidebar + detail (DESIGN.md §6
/// "Sidebar / home"). M3 puts the navigate-mode canvas in the detail pane;
/// read mode returns as an overlay on top of it in M4.
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
                : CanvasView(
                    key: ValueKey(selectedId),
                    conversationId: selectedId,
                  ),
          ),
        ],
      ),
    );
  }
}
