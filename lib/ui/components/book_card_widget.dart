import 'package:openlib/core/book_language.dart';
import 'package:openlib/l10n/app_localizations.dart';
// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports:
import 'package:openlib/features/eink/eink.dart' show EinkColors, EinkColorX;
import 'package:openlib/state/state.dart'
    show checkIdExists, resultCoverProvider;
import 'package:openlib/ui/extensions.dart';
import 'package:openlib/ui/components/cover_image.dart';

/// Ebook and archive extensions the providers return in `info`.
const _knownFormats = {
  'pdf', 'epub', 'mobi', 'azw', 'azw3', 'azw4', 'kfx', 'fb2', 'fbz',
  'djvu', 'djv', 'cbr', 'cbz', 'cb7', 'cbt', 'txt', 'rtf', 'doc', 'docx',
  'odt', 'lit', 'lrf', 'chm', 'pdb', 'prc', 'htm', 'html', 'htmlz',
  'mht', 'zip', 'rar', '7z', 'tar', 'gz', 'xps', 'oxps', 'ps', 'tex',
  'md', 'snb', 'tcr', 'rb', 'ibooks', 'iba', 'mp3', 'm4a', 'm4b',
};

final _sizePattern = RegExp(
    r'^\d+(?:[.,]\d+)?\s*(?:bytes?|[kmgt]i?b|[kmgt]o)$',
    caseSensitive: false);
final _yearPattern = RegExp(r'^(?:1[5-9]\d{2}|20\d{2})$');
final _upperTokenPattern = RegExp(r'^[A-Z0-9]{2,6}$');

/// Format, size and year parsed out of a result's `info` string.
///
/// Providers join language, extension, size and year with commas
/// ("Spanish, EPUB, 3.83 MB, 1991"); Anna's Archive adds more free-form
/// pieces. Unknown pieces are ignored.
class BookMeta {
  const BookMeta({this.format, this.size, this.year, this.language});

  /// Upper-case extension such as "EPUB" or "DJVU".
  final String? format;

  /// Size as the provider wrote it, e.g. "3.83 MB".
  final String? size;
  final String? year;
  final String? language;

  factory BookMeta.parse(String? info) {
    if (info == null || info.trim().isEmpty) return const BookMeta();
    String? format;
    String? size;
    String? year;
    for (final raw in info.split(RegExp(r'[,·|]'))) {
      final token = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
      if (token.isEmpty) continue;
      final bare = token.startsWith('.') ? token.substring(1) : token;
      if (size == null && _sizePattern.hasMatch(token)) {
        size = token;
      } else if (year == null && _yearPattern.hasMatch(token)) {
        year = token;
      } else if (format == null &&
          (_knownFormats.contains(bare.toLowerCase()) ||
              (_upperTokenPattern.hasMatch(bare) &&
                  !RegExp(r'^\d+$').hasMatch(bare) &&
                  bookLanguageName(bare) == null))) {
        format = bare.toUpperCase();
      }
    }
    return BookMeta(
        format: format,
        size: size,
        year: year,
        language: bookLanguageName(info));
  }
}

/// Upper-case file extension from a result's `info` string, any format.
String? getFileType(String? info) => BookMeta.parse(info).format;

String? getLanguage(String? info) => bookLanguageName(info);

/// Same-host Referer for libgen cover URLs, null for everything else.
/// libgen mirrors serve /covers/ only with an ads.php Referer from the
/// same host; the host is read from the cover URL itself so the app
/// hardcodes no mirror address.
Map<String, String>? _coverHeaders(String? coverUrl) {
  if (coverUrl == null || !coverUrl.contains('libgen')) return null;
  final origin = Uri.tryParse(coverUrl)?.origin;
  if (origin == null) return null;
  return {'Referer': '$origin/ads.php?md5=cover-lookup'};
}

/// WCAG 2 contrast ratio between two opaque colours (1 to 21).
double wcagContrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

/// [color] darkened until white text on it reaches 4.5:1, so a chip can
/// keep its hue (the red source chip) and still be legible.
Color chipFillForWhiteText(Color color) {
  var hsl = HSLColor.fromColor(color.withValues(alpha: 1));
  while (wcagContrast(Colors.white, hsl.toColor()) < 4.5 &&
      hsl.lightness > 0) {
    hsl = hsl.withLightness((hsl.lightness - 0.02).clamp(0.0, 1.0));
  }
  return hsl.toColor();
}

/// Neutral fill of the format chip; white on it is about 6:1.
const _formatChipFill = Color(0xFF616161);

class BookInfoCard extends ConsumerWidget {
  const BookInfoCard({
    super.key,
    required this.title,
    required this.author,
    required this.publisher,
    required this.thumbnail,
    required this.info,
    required this.link,
    required this.onClick,
    this.onLongPress,
    this.md5,
    this.source,
  });

  final String title;
  final String author;
  final String publisher;
  final String? thumbnail;
  final String? info;
  final String link;
  final VoidCallback onClick;
  final VoidCallback? onLongPress;
  final String? md5;

  /// Catalog name this result came from; shown as a small chip.
  final String? source;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final eink = EinkColors.of(context);
    final meta = BookMeta.parse(info);
    final language = meta.language;
    final authorText =
        author.trim().isEmpty || author.trim().toLowerCase() == 'unknown'
            ? l10n.unknown
            : author.trim();
    final hasSource = source != null && source!.isNotEmpty;
    final details = [meta.size, meta.year].whereType<String>().join(' · ');

    // Check if book is downloaded (only if md5 is provided)
    final isDownloaded = md5 != null
        ? ref.watch(checkIdExists(md5!))
        : const AsyncValue<bool>.data(false);
    final downloaded = isDownloaded.valueOrNull == true;

    // LibGen search rows ship without covers; resolve one lazily from
    // the book's ads.php page (it carries the cover URL).
    final hasThumbnail = thumbnail != null && thumbnail!.isNotEmpty;
    final lazyCover =
        hasThumbnail ? null : ref.watch(resultCoverProvider(link)).valueOrNull;
    final coverUrl = hasThumbnail ? thumbnail : lazyCover;

    // One spoken summary instead of six loose fragments.
    final semanticLabel = [
      l10n.cardTitleByAuthor(title, authorText),
      if (meta.format != null) meta.format!,
      if (meta.size != null) meta.size!,
      if (meta.year != null) meta.year!,
      if (language != null) '${l10n.languageSetting}: $language',
      if (hasSource) l10n.cardSource(source!),
      if (downloaded) l10n.cardDownloadedBadge,
    ].join(', ');

    final placeholder = coverPlaceholderColor(context, "#F8C0C8".toColor());
    final chipText = Colors.white.einkBg(context);
    const chipStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.5,
    );

    Widget chip(String label, Color fill) => Container(
          decoration: BoxDecoration(
            color: fill.einkFg(context),
            borderRadius: BorderRadius.circular(2.5),
          ),
          padding: const EdgeInsets.fromLTRB(4, 1, 4, 1),
          child: Text(
            label,
            style: chipStyle.copyWith(color: chipText),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        container: true,
        button: true,
        label: semanticLabel,
        excludeSemantics: true,
        onTap: onClick,
        onLongPress: onLongPress,
        child: Material(
          color: scheme.tertiaryContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
            side: eink.outline,
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onClick,
            onLongPress: onLongPress,
            child: ConstrainedBox(
              // Grows with the text; the minimum keeps room for the cover.
              constraints: const BoxConstraints(minHeight: 140),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Book thumbnail with download indicator
                  Stack(
                    children: [
                      CachedNetworkImage(
                        height: 140,
                        width: 90,
                        memCacheWidth: coverCacheWidth(context, 90),
                        imageUrl: coverUrl ?? "",
                        // libgen mirrors serve /covers/ only with a same-host
                        // ads.php Referer; without it the response is 200 but
                        // empty. The host comes from the cover URL itself, so
                        // no mirror address is baked into the app.
                        httpHeaders: _coverHeaders(coverUrl),
                        imageBuilder: (context, imageProvider) => Container(
                          decoration: BoxDecoration(
                            borderRadius:
                                const BorderRadius.all(Radius.circular(5)),
                            image: DecorationImage(
                              image: imageProvider,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        placeholder: (context, url) => Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            color: placeholder,
                            border: eink.border,
                          ),
                          height: 140,
                          width: 90,
                        ),
                        errorWidget: (context, url, error) {
                          return Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                              color: placeholder,
                              border: eink.border,
                            ),
                            height: 140,
                            width: 90,
                            child: Center(
                              child: Icon(Icons.image_rounded,
                                  color: scheme.onSurfaceVariant),
                            ),
                          );
                        },
                      ),
                      // Downloaded checkmark indicator
                      if (downloaded)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.green.einkFg(context),
                              borderRadius: BorderRadius.circular(12),
                              // Keeps the black badge visible on a dark cover.
                              border: eink.monochrome
                                  ? Border.all(
                                      color: eink.background, width: 1.5)
                                  : null,
                            ),
                            child: Icon(
                              Icons.check,
                              color: Colors.white.einkBg(context),
                              size: 16,
                              semanticLabel: l10n.cardDownloadedBadge,
                            ),
                          ),
                        ),
                    ],
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: scheme.tertiary,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 3,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            authorText,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                          if (publisher.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              '${l10n.publisher}: $publisher',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: theme.textTheme.headlineMedium?.color,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                          const SizedBox(height: 2),
                          Text(
                            '${l10n.languageSetting}: ${language ?? l10n.unknown}',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: scheme.tertiary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (hasSource)
                                chip(source!,
                                    chipFillForWhiteText(scheme.secondary)),
                              if (meta.format != null)
                                chip(meta.format!, _formatChipFill),
                              if (details.isNotEmpty)
                                Text(
                                  details,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
