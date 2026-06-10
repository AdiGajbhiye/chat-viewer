import 'dart:convert';

import 'package:flutter/material.dart';

import '../data/db/database.dart';

/// Shows the warnings recorded by the most recent import run (M5 import
/// warnings UI). Reads the latest `imports` row; absent/corrupt warning JSON
/// degrades to "no warnings".
Future<void> showImportWarningsDialog(
  BuildContext context,
  AppDatabase db,
) async {
  final latest = await db.latestImport();
  if (!context.mounted) return;

  var warnings = const <String>[];
  if (latest != null) {
    try {
      final decoded = jsonDecode(latest.warningsJson);
      if (decoded is List) {
        warnings = [for (final w in decoded) w.toString()];
      }
    } on FormatException {
      // Corrupt persisted JSON → treat as no warnings.
    }
  }

  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        warnings.isEmpty
            ? 'Import warnings'
            : 'Import warnings (${warnings.length})',
      ),
      content: SizedBox(
        width: 480,
        child: latest == null
            ? const Text('Nothing has been imported yet.')
            : warnings.isEmpty
                ? const Text('The last import finished without warnings.')
                : ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 400),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: warnings.length,
                      separatorBuilder: (_, _) => const Divider(height: 12),
                      itemBuilder: (context, index) => Text(
                        warnings[index],
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}
