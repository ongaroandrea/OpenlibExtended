// User-friendly error display widget with solutions
// Handles network errors, Cloudflare blocks, connectivity issues

// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:openlib/l10n/app_localizations.dart';

// Package imports:
import 'package:flutter_svg/svg.dart';
import 'package:url_launcher/url_launcher.dart';

// Project imports:
import 'package:openlib/services/network_error.dart';
import 'package:openlib/services/logger.dart';
import 'package:openlib/services/platform_utils.dart';
import 'package:openlib/ui/challenge_solver_page.dart';

/// Localized, user-facing copy for a [NetworkError].
///
/// The service layer has no BuildContext, so its English
/// [NetworkError.userMessage]/[NetworkError.solution] stay as log text;
/// screens show these instead.
extension NetworkErrorText on NetworkError {
  bool get _allSourcesFailed =>
      type == NetworkErrorType.serverUnavailable && failedSources.isNotEmpty;

  String title(AppLocalizations l10n) {
    if (_allSourcesFailed) return l10n.errorSourcesFailedTitle;
    switch (type) {
      case NetworkErrorType.noInternet:
        return l10n.errorNoInternetTitle;
      case NetworkErrorType.cloudflareBlock:
        return l10n.errorBlockedTitle;
      case NetworkErrorType.serverUnavailable:
        return l10n.errorServerUnavailableTitle;
      case NetworkErrorType.timeout:
        return l10n.errorTimeoutTitle;
      case NetworkErrorType.forbidden:
        return l10n.errorForbiddenTitle;
      case NetworkErrorType.rateLimited:
        return l10n.errorRateLimitedTitle;
      case NetworkErrorType.sslError:
        return l10n.errorSslTitle;
      case NetworkErrorType.dnsError:
        return l10n.errorDnsTitle;
      case NetworkErrorType.unknown:
        return l10n.errorUnknownTitle;
    }
  }

  String advice(AppLocalizations l10n) {
    if (_allSourcesFailed) {
      return l10n.errorSourcesFailedBody(failedSources.join(', '));
    }
    switch (type) {
      case NetworkErrorType.noInternet:
        return l10n.errorNoInternetBody;
      case NetworkErrorType.cloudflareBlock:
        return l10n.errorBlockedBody;
      case NetworkErrorType.serverUnavailable:
        return l10n.errorServerUnavailableBody;
      case NetworkErrorType.timeout:
        return l10n.errorTimeoutBody;
      case NetworkErrorType.forbidden:
        return l10n.errorForbiddenBody;
      case NetworkErrorType.rateLimited:
        return l10n.errorRateLimitedBody;
      case NetworkErrorType.sslError:
        return l10n.errorSslBody;
      case NetworkErrorType.dnsError:
        return l10n.errorDnsBody;
      case NetworkErrorType.unknown:
        return l10n.errorUnknownBody;
    }
  }
}

/// Converts any error into a [NetworkError] (classification logs once).
NetworkError toNetworkError(Object error) {
  if (error is NetworkError) return error;
  // Legacy socket exception marker
  if (error.toString().contains("socketException")) {
    return NetworkError(
      type: NetworkErrorType.noInternet,
      userMessage: "Unable to access the internet",
      solution:
          "Check your internet connection. Make sure WiFi or mobile data is enabled.",
    );
  }
  return NetworkError.fromException(error);
}

class CustomErrorWidget extends StatefulWidget {
  final Object error;
  final StackTrace stackTrace;
  final VoidCallback? onRefresh;

  const CustomErrorWidget({
    super.key,
    required this.error,
    required this.stackTrace,
    this.onRefresh,
  });

  @override
  State<CustomErrorWidget> createState() => _CustomErrorWidgetState();
}

class _CustomErrorWidgetState extends State<CustomErrorWidget> {
  late NetworkError _networkError;

  Object get error => widget.error;
  VoidCallback? get onRefresh => widget.onRefresh;

  // Logged and classified once per distinct error - not on every
  // rebuild (theme, locale or text-scale changes rebuild this widget).
  void _adopt() {
    AppLogger().error(
      "Error displayed to user",
      tag: "ErrorWidget",
      error: widget.error,
      stackTrace: widget.stackTrace,
    );
    _networkError = toNetworkError(widget.error);
  }

  @override
  void initState() {
    super.initState();
    _adopt();
  }

  @override
  void didUpdateWidget(CustomErrorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.error, widget.error)) _adopt();
  }

  @override
  Widget build(BuildContext context) {
    final networkError = _networkError;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),
            _buildErrorIcon(context, networkError.type),
            const SizedBox(height: 24),
            _buildErrorTitle(context, networkError),
            const SizedBox(height: 16),
            _buildSolutionCard(context, networkError),
            const SizedBox(height: 24),
            if (onRefresh != null) _buildRefreshButton(context),
            const SizedBox(height: 16),
            if (networkError.rawResponseBody != null)
              _buildShowDetailsButton(context, networkError),
            if (networkError.type == NetworkErrorType.cloudflareBlock)
              _buildOpenBrowserButton(context),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Build appropriate icon based on error type
  Widget _buildErrorIcon(BuildContext context, NetworkErrorType type) {
    String assetPath;
    Color? iconColor;

    switch (type) {
      case NetworkErrorType.noInternet:
      case NetworkErrorType.dnsError:
        assetPath = "assets/no_internet.svg";
        break;
      case NetworkErrorType.cloudflareBlock:
      case NetworkErrorType.forbidden:
        assetPath = "assets/error_fixing_bugs.svg";
        iconColor = Colors.orange;
        break;
      case NetworkErrorType.timeout:
      case NetworkErrorType.serverUnavailable:
        assetPath = "assets/error_fixing_bugs.svg";
        break;
      default:
        assetPath = "assets/error_fixing_bugs.svg";
    }

    return Center(
      child: SvgPicture.asset(
        assetPath,
        width: 180,
        height: 180,
        colorFilter: iconColor != null
            ? ColorFilter.mode(iconColor, BlendMode.srcIn)
            : null,
      ),
    );
  }

  // Build error title with icon indicator
  Widget _buildErrorTitle(BuildContext context, NetworkError networkError) {
    IconData iconData;
    Color iconColor;

    switch (networkError.type) {
      case NetworkErrorType.noInternet:
        iconData = Icons.wifi_off_rounded;
        iconColor = Colors.red;
        break;
      case NetworkErrorType.cloudflareBlock:
        iconData = Icons.shield_rounded;
        iconColor = Colors.orange;
        break;
      case NetworkErrorType.forbidden:
        iconData = Icons.block_rounded;
        iconColor = Colors.red;
        break;
      case NetworkErrorType.timeout:
        iconData = Icons.timer_off_rounded;
        iconColor = Colors.amber;
        break;
      case NetworkErrorType.serverUnavailable:
        iconData = Icons.cloud_off_rounded;
        iconColor = Colors.grey;
        break;
      case NetworkErrorType.rateLimited:
        iconData = Icons.speed_rounded;
        iconColor = Colors.orange;
        break;
      case NetworkErrorType.dnsError:
        iconData = Icons.dns_rounded;
        iconColor = Colors.purple;
        break;
      case NetworkErrorType.sslError:
        iconData = Icons.lock_open_rounded;
        iconColor = Colors.red;
        break;
      default:
        iconData = Icons.error_outline_rounded;
        iconColor = Colors.red;
    }

    return Column(
      children: [
        Icon(iconData, size: 48, color: iconColor),
        const SizedBox(height: 12),
        Text(
          networkError.title(AppLocalizations.of(context)),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  // Build solution card with actionable advice
  Widget _buildSolutionCard(BuildContext context, NetworkError networkError) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.grey[850]
            : _getBackgroundColorForType(networkError.type),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getBorderColorForType(networkError.type),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline_rounded,
                color: _getAccentColorForType(networkError.type),
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context).errorWhatToDo,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _getAccentColorForType(networkError.type),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            networkError.advice(AppLocalizations.of(context)),
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: isDark ? Colors.grey[300] : Colors.grey[800],
            ),
          ),
          // Challenge solving failed invisibly on this device: point at
          // the background-verification toggle in settings.
          if (networkError.type == NetworkErrorType.cloudflareBlock) ...[
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context).backgroundVerificationFix,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: isDark ? Colors.orange[200] : Colors.orange[800],
              ),
            ),
          ],
          // Show VPN recommendation prominently for blocked content
          if (networkError.type == NetworkErrorType.cloudflareBlock ||
              networkError.type == NetworkErrorType.dnsError ||
              networkError.type == NetworkErrorType.forbidden) ...[
            const SizedBox(height: 16),
            _buildVpnRecommendation(context),
          ],
        ],
      ),
    );
  }

  // Build VPN recommendation banner
  Widget _buildVpnRecommendation(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withAlpha(80)),
      ),
      child: Row(
        children: [
          const Icon(Icons.vpn_key_rounded, color: Colors.blue, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).tryUsingVpn,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.of(context).errorVpnHint,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.blue[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Build refresh button
  Widget _buildRefreshButton(BuildContext context) {
    return Center(
      child: ElevatedButton.icon(
        onPressed: onRefresh,
        icon: const Icon(Icons.refresh_rounded),
        label: Text(AppLocalizations.of(context).tryAgain),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.secondary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
      ),
    );
  }

  // Build show details button for advanced users
  Widget _buildShowDetailsButton(
      BuildContext context, NetworkError networkError) {
    return Center(
      child: TextButton.icon(
        onPressed: () => _showDetailsDialog(context, networkError),
        icon: const Icon(Icons.info_outline_rounded, size: 18),
        label: Text(
            AppLocalizations.of(context).showBlockedContent),
        style: TextButton.styleFrom(
          foregroundColor: Colors.grey[600],
        ),
      ),
    );
  }

  // Build open in browser button for DDoS/Captcha challenges
  Widget _buildOpenBrowserButton(BuildContext context) {
    return Center(
      child: ElevatedButton.icon(
        onPressed: () => _openInBrowser(context),
        icon: const Icon(Icons.open_in_browser_rounded),
        label: Text(AppLocalizations.of(context).verifyInBrowser),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  // Open browser to allow user to manually solve captcha/verification
  void _openInBrowser(BuildContext context) {
    final networkError = _networkError;
    final targetUrl = networkError.blockedUrl;
    
    // Show dialog with embedded and system browser options
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.security_rounded, color: Colors.orange),
            const SizedBox(width: 12),
            Text(AppLocalizations.of(context)
                .manualVerificationRequired),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).errorVerifyIntro,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_rounded, color: Colors.blue[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context).errorVerifyReturnHint,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          if (targetUrl != null)
            OutlinedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                final uri = Uri.parse(targetUrl);
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              },
              icon: const Icon(Icons.language),
              label: Text(
                  AppLocalizations.of(context).systemBrowser),
            ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              // Trigger webview for verification
              _triggerBrowserVerification(context);
            },
            icon: const Icon(Icons.open_in_browser),
            label: Text(
                AppLocalizations.of(context).embeddedBrowser),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  // Trigger browser verification. On mobile the in-app solver page loads the
  // blocked URL, waits for the challenge to clear and captures the rendered
  // HTML. On desktop the in-app webview plugin is unavailable, so the system
  // browser is the only manual fallback.
  void _triggerBrowserVerification(BuildContext context) {
    final networkError = _networkError;
    final targetUrl = networkError.blockedUrl;

    if (targetUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)
              .unableToOpenVerification),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    if (PlatformUtils.isMobile) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChallengeSolverPage(url: targetUrl),
        ),
      ).then((solved) {
        if (solved == true && onRefresh != null && context.mounted) {
          onRefresh!();
        }
      });
    } else {
      launchUrl(Uri.parse(targetUrl),
          mode: LaunchMode.externalApplication);
    }
  }

  // Show dialog with raw response for debugging
  void _showDetailsDialog(BuildContext context, NetworkError networkError) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.code_rounded, size: 24),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context)
                .blockedPageContent),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (networkError.technicalDetails != null) ...[
                  Text(
                    AppLocalizations.of(context)
                        .errorLabel(networkError.technicalDetails!),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    _formatResponseBody(context,
                        networkError.rawResponseBody ??
                            AppLocalizations.of(context).errorNoContent),
                    style: const TextStyle(
                      fontFamily: "monospace",
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(
                text: networkError.rawResponseBody ?? "",
              ));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(
                        AppLocalizations.of(context).copiedToClipboard)),
              );
            },
            child: Text(AppLocalizations.of(context).copy),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).close),
          ),
        ],
      ),
    );
  }

  // Format response body for display
  String _formatResponseBody(BuildContext context, String body) {
    // Limit length for display
    if (body.length > 3000) {
      return "${body.substring(0, 3000)}\n\n"
          "${AppLocalizations.of(context).errorTruncated(body.length)}";
    }
    return body;
  }

  // Get background color based on error type
  Color _getBackgroundColorForType(NetworkErrorType type) {
    switch (type) {
      case NetworkErrorType.cloudflareBlock:
      case NetworkErrorType.forbidden:
        return Colors.orange.withAlpha(25);
      case NetworkErrorType.noInternet:
      case NetworkErrorType.dnsError:
        return Colors.red.withAlpha(20);
      case NetworkErrorType.timeout:
      case NetworkErrorType.rateLimited:
        return Colors.amber.withAlpha(25);
      case NetworkErrorType.serverUnavailable:
        return Colors.grey.withAlpha(30);
      default:
        return Colors.grey.withAlpha(25);
    }
  }

  // Get border color based on error type
  Color _getBorderColorForType(NetworkErrorType type) {
    switch (type) {
      case NetworkErrorType.cloudflareBlock:
      case NetworkErrorType.forbidden:
        return Colors.orange.withAlpha(60);
      case NetworkErrorType.noInternet:
      case NetworkErrorType.dnsError:
        return Colors.red.withAlpha(50);
      case NetworkErrorType.timeout:
      case NetworkErrorType.rateLimited:
        return Colors.amber.withAlpha(60);
      default:
        return Colors.grey.withAlpha(50);
    }
  }

  // Get accent color based on error type
  Color _getAccentColorForType(NetworkErrorType type) {
    switch (type) {
      case NetworkErrorType.cloudflareBlock:
      case NetworkErrorType.forbidden:
        return Colors.orange[700]!;
      case NetworkErrorType.noInternet:
      case NetworkErrorType.dnsError:
        return Colors.red[700]!;
      case NetworkErrorType.timeout:
      case NetworkErrorType.rateLimited:
        return Colors.amber[800]!;
      default:
        return Colors.grey[700]!;
    }
  }
}

// Simple error snackbar for quick inline errors
class ErrorSnackbar {
  static void show(BuildContext context, Object error,
      {VoidCallback? onRetry}) {
    final networkError = toNetworkError(error);
    final l10n = AppLocalizations.of(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              networkError.title(l10n),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              networkError.advice(l10n),
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        action: onRetry != null
            ? SnackBarAction(
                label: l10n.retry,
                onPressed: onRetry,
              )
            : null,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
