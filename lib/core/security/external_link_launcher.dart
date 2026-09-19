import 'package:relay/core/security/https_url.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens links outside the app. Only `https` URLs are ever launched.
abstract interface class ExternalLinkLauncher {
  /// Returns `false` when [url] is missing, not https, or cannot be opened.
  Future<bool> open(Uri? url);
}

final class UrlLauncherExternalLinks implements ExternalLinkLauncher {
  const UrlLauncherExternalLinks();

  @override
  Future<bool> open(Uri? url) async {
    final safe = parseHttpsUrl(url?.toString());
    if (safe == null) return false;
    try {
      return await launchUrl(safe, mode: LaunchMode.externalApplication);
    } on Object {
      return false;
    }
  }
}
