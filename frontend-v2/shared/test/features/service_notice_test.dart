import 'package:autolinky/app/app.dart';
import 'package:autolinky/core/notice/service_notice.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

const _notice = {
  'en': {'title': "We're making Autolinky better", 'body': "We're updating our services right now."},
  'ar': {'title': 'نعمل على تحسين Autolinky', 'body': 'نقوم الآن بتحديث خدماتنا.'},
};

void main() {
  late FakeAuth auth;

  setUp(() => auth = FakeAuth());
  tearDown(() => auth.dispose());

  Future<void> openApp(WidgetTester tester, NoticeReader notice, {bool signedIn = false}) async {
    if (signedIn) auth.session = testSession();
    usePhoneSize(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: await baseOverrides(auth: auth, notice: notice),
        retry: (_, _) => null,
        child: const AutolinkyApp(),
      ),
    );
    await settle(tester);
  }

  testWidgets('the notice shows on the sign-in screen as soon as the app opens, and goes with Got it', (tester) async {
    await openApp(tester, () async => _notice);
    expect(find.text("We're making Autolinky better"), findsOneWidget);
    await tester.tap(find.text('Got it'));
    await settle(tester);
    expect(find.text("We're making Autolinky better"), findsNothing);
  });

  testWidgets('signed in: the notice shows over the app too', (tester) async {
    await openApp(tester, () async => _notice, signedIn: true);
    expect(find.text("We're updating our services right now."), findsOneWidget);
  });

  testWidgets('no notice: nothing is shown', (tester) async {
    await openApp(tester, () async => null);
    expect(find.text('Got it'), findsNothing);
  });

  testWidgets('the API unreachable: nothing is shown', (tester) async {
    await openApp(tester, () async => throw Exception('offline'));
    expect(find.text("We're making Autolinky better"), findsNothing);
  });

  test('the text in the language of the app, else English; nothing usable: no notice', () {
    expect(ServiceNotice.fromJson(_notice, 'ar')!.title, 'نعمل على تحسين Autolinky');
    expect(ServiceNotice.fromJson(_notice, 'fr')!.title, "We're making Autolinky better");
    expect(ServiceNotice.fromJson(null, 'en'), isNull);
    expect(
      ServiceNotice.fromJson({
        'en': {'title': ' ', 'body': 'x'},
      }, 'en'),
      isNull,
    );
  });
}
