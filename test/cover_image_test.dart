import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openlib/l10n/app_localizations.dart';
import 'package:openlib/state/state.dart';
import 'package:openlib/ui/components/book_card_widget.dart';
import 'package:openlib/ui/components/cover_image.dart';

void main() {
  test('decode width is box width x DPR rounded up to 50 px', () {
    expect(coverDecodeWidth(90, 1.0), 100);
    expect(coverDecodeWidth(90, 2.0), 200);
    expect(coverDecodeWidth(90, 2.75), 250); // 247.5 -> 248 -> 250
    expect(coverDecodeWidth(90, 3.0), 300);
    expect(coverDecodeWidth(100, 2.0), 200); // exact multiple stays
    expect(coverDecodeWidth(170, 3.0), 550); // 510 -> 550
    expect(coverDecodeWidth(0, 3.0), coverDecodeStep);
  });

  testWidgets('book card cover is decoded at its displayed width',
      (tester) async {
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(ProviderScope(
        overrides: [
          resultCoverProvider.overrideWith((ref, url) async => null),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: BookInfoCard(
                title: 'Title',
                author: 'Author',
                publisher: 'Publisher',
                thumbnail: 'https://example.com/cover.jpg',
                info: 'English, EPUB, 1 MB',
                link: 'https://example.com/book',
                onClick: () {}),
          ),
        )));
    final image =
        tester.widget<CachedNetworkImage>(find.byType(CachedNetworkImage));
    expect(image.memCacheWidth, isNotNull);
    expect(image.memCacheWidth, 300); // 90 logical px x 3.0
    expect(image.memCacheHeight, isNull);
  });
}
