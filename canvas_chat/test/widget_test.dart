import 'package:flutter_test/flutter_test.dart';

import 'package:canvas_chat/main.dart';

void main() {
  testWidgets('app builds', (tester) async {
    await tester.pumpWidget(const CanvasChatApp());
    expect(find.text('Canvas Chat — UI coming in M2'), findsOneWidget);
  });
}
