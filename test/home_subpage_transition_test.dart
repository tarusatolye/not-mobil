import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:saber/data/flavor_config.dart';
import 'package:saber/data/prefs.dart';
import 'package:saber/data/routes.dart';
import 'package:saber/main.dart';
import 'package:saber/pages/home/home.dart';
import 'package:saber/tarus/tarus_ikon.dart';

void main() {
  group('Home subpage transition', () {
    for (final brightness in Brightness.values)
      testWidgets(brightness.name, (tester) async {
        FlavorConfig.setup();
        stows.sentryConsent.value = .granted;
        stows.layoutSize.value = .phone;

        final router = GoRouter(
          initialLocation: App.initialLocation,
          routes: [
            GoRoute(
              path: RoutePaths.home,
              builder: (context, state) => HomePage(
                subpage:
                    state.pathParameters['subpage'] ?? HomePage.recentSubpage,
                path: state.uri.queryParameters['path'],
              ),
            ),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          MaterialApp.router(
            title: 'Saber',
            routeInformationProvider: router.routeInformationProvider,
            routeInformationParser: router.routeInformationParser,
            routerDelegate: router.routerDelegate,
          ),
        );

        await tester.tap(find.byIcon(TarusIkon.ayarlar));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 150));

        expect(
          [find.text('No notes yet'), find.text('Sync is off')],
          [findsOneWidget, findsOneWidget],
        );
      });
  });
}
