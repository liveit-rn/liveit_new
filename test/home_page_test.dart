import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveit_new/features/home/presentation/pages/home_page.dart';
import 'package:liveit_new/features/home/presentation/widget/devotional_card.dart';
import 'package:liveit_new/features/home/presentation/widget/gamification_highlight_card.dart';
import 'package:liveit_new/features/home/presentation/widget/habit_groups_section.dart';

void main() {
  testWidgets('HomePage menampilkan modul utama homepage', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomePage()));
    await tester.pumpAndSettle();

    final Finder scrollable = find.byType(Scrollable);

    expect(find.byType(HabitGroupsSection), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byType(DevotionalCard),
      200,
      scrollable: scrollable,
    );
    expect(find.byType(DevotionalCard), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byType(GamificationHighlightCard),
      200,
      scrollable: scrollable,
    );
    expect(find.byType(GamificationHighlightCard), findsOneWidget);
  });

  testWidgets('Check-in memindahkan habit ke grup selesai', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomePage()));
    await tester.pumpAndSettle();

    final Finder firstCompleteButton = find.widgetWithText(
      TextButton,
      'Selesai',
    );
    expect(firstCompleteButton, findsWidgets);

    await tester.tap(firstCompleteButton.first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Selesai Hari Ini'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextButton, 'Undo'), findsWidgets);
  });
}
