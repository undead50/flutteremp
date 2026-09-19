import 'package:flutter/material.dart';
import 'package:relay/core/assets/app_assets.dart';
import 'package:relay/core/security/https_url.dart';
import 'package:relay/core/theme/app_palette.dart';
import 'package:relay/core/theme/app_typography.dart';
import 'package:relay/core/utils/formatters.dart';

/// Circular profile photo with an initials fallback.
///
/// [source] is either `asset:<path>` (mock data only) or an `https` URL. Any
/// other scheme is ignored, so a hostile payload can't make the app fetch
/// `http://`, `file://` or `data:` resources.
class RelayAvatar extends StatelessWidget {
  const RelayAvatar({
    super.key,
    required this.source,
    required this.name,
    required this.size,
    this.semanticLabel,
  });

  final String? source;
  final String name;
  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final avatar = SizedBox.square(
      dimension: size,
      child: ClipOval(child: _photo(context) ?? _initials(context)),
    );
    if (semanticLabel == null) return ExcludeSemantics(child: avatar);
    return Semantics(
      label: semanticLabel,
      image: true,
      child: ExcludeSemantics(child: avatar),
    );
  }

  Widget? _photo(BuildContext context) {
    final value = source;
    if (value == null || value.isEmpty) return null;

    if (value.startsWith(AppImages.assetScheme)) {
      return Image.asset(
        value.substring(AppImages.assetScheme.length),
        fit: BoxFit.cover,
        errorBuilder: (context, _, _) => _initials(context),
      );
    }
    final uri = parseHttpsImageUrl(value);
    if (uri == null) return null;
    return Image.network(
      uri.toString(),
      fit: BoxFit.cover,
      errorBuilder: (context, _, _) => _initials(context),
      loadingBuilder: (context, child, progress) => progress == null ? child : _initials(context),
    );
  }

  Widget _initials(BuildContext context) {
    return ColoredBox(
      color: context.palette.mint,
      child: Center(
        child: Text(
          Formatters.initials(name),
          style: AppTypography.caption.copyWith(
            color: context.palette.onMint,
            fontSize: size * 0.36,
          ),
        ),
      ),
    );
  }
}
