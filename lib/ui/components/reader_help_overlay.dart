import 'package:flutter/material.dart';
import 'package:openlib/l10n/app_localizations.dart';

/// First-run help for the EPUB reader. Lists only controls that exist:
/// edge tap zones, page keys, volume keys (when [volumeKeys] is on), the
/// text size buttons and the table of contents drawer.
class ReaderHelpOverlay extends StatelessWidget {
  final VoidCallback onDismiss;

  /// Whether the volume keys turn pages right now (Android, setting on).
  final bool volumeKeys;

  const ReaderHelpOverlay({
    super.key,
    required this.onDismiss,
    this.volumeKeys = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Material(
      color: Colors.black.withValues(alpha: 0.85),
      child: InkWell(
        onTap: onDismiss,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Content: centred, scrolls on short screens. Only positioned
            // children, so the overlay covers the whole reader.
            Positioned.fill(
              child: Center(
              child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 16),
              child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.menu_book, color: Colors.white, size: 60),
                const SizedBox(height: 20),
                Text(
                  l10n.readerHelpTitle,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 40),

                // Controls Grid
                Wrap(
                  spacing: 40,
                  runSpacing: 30,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildHelpItem(
                      context,
                      icon: Icons.touch_app,
                      title: l10n.readerHelpTapTitle,
                      subtitle: l10n.readerHelpTapBody,
                    ),
                    _buildHelpItem(
                      context,
                      icon: Icons.keyboard,
                      title: l10n.readerHelpKeysTitle,
                      subtitle: l10n.readerHelpKeysBody,
                    ),
                    if (volumeKeys)
                      _buildHelpItem(
                        context,
                        icon: Icons.volume_up,
                        title: l10n.readerHelpVolumeTitle,
                        subtitle: l10n.readerHelpVolumeBody,
                      ),
                    _buildHelpItem(
                      context,
                      icon: Icons.format_size,
                      title: l10n.readerHelpTextSizeTitle,
                      subtitle: l10n.readerHelpTextSizeBody,
                    ),
                    _buildHelpItem(
                      context,
                      icon: Icons.list,
                      title: l10n.readerHelpContentsTitle,
                      subtitle: l10n.readerHelpContentsBody,
                    ),
                  ],
                ),

                const SizedBox(height: 50),
                OutlinedButton(
                  onPressed: onDismiss,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 15),
                  ),
                  child: Text(l10n.gotIt),
                ),
              ],
            ),
            ),
              ),
            ),

            // Close hint (last, so it stays on top of the content)
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: onDismiss,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpItem(BuildContext context,
      {required IconData icon,
      required String title,
      required String subtitle}) {
    return SizedBox(
      width: 150,
      child: Column(
        children: [
          Icon(icon, color: Colors.white70, size: 40),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
