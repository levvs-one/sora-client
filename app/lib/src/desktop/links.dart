/// What a link opened from a browser or a messenger asks Sora to do.
sealed class ImportLink {
  const ImportLink();
}

/// Add the subscription at [url], under [name] when the link gives one.
final class AddSubscription extends ImportLink {
  const AddSubscription(this.url, {this.name = ''});

  final Uri url;
  final String name;
}

/// A link Happ encrypted with its own key. Nothing but Happ can read it: the
/// provider has to hand out the plain subscription link.
final class SealedForHapp extends ImportLink {
  const SealedForHapp();
}

/// The schemes Sora registers. The others below are read when a link of
/// theirs is handed to Sora, but Sora does not claim them.
const ownSchemes = ['sora', 'happ'];

/// Reads an import link of Sora or of the clients people move from:
///
/// ```text
/// sora://add/<url>            happ://add/<url>
/// sora://add?url=<url>&name=  v2rayn://install-config?url=<url>
/// clash://install-config?url=<url>&name=<name>
/// hiddify://import/<url>#<name>
/// sing-box://import-remote-profile?url=<url>#<name>
/// ```
///
/// The subscription itself must be http or https. Anything else is null,
/// a broken percent-encoding included: the link comes from anywhere.
ImportLink? parseImportLink(String text) {
  try {
    return _parse(text.trim());
  } on FormatException {
    return null;
  } on ArgumentError {
    return null;
  }
}

ImportLink? _parse(String link) {
  final colon = link.indexOf('://');
  if (colon <= 0) return null;
  final scheme = link.substring(0, colon).toLowerCase();
  final rest = link.substring(colon + 3);

  // The target is pasted after the prefix as it is, with its own "?" and "#",
  // so it is cut out of the text rather than parsed out of a Uri.
  String? after(String prefix) => rest.toLowerCase().startsWith(prefix) ? rest.substring(prefix.length) : null;

  if (scheme == 'happ' && RegExp(r'^crypt\d*/', caseSensitive: false).hasMatch(rest)) {
    return const SealedForHapp();
  }
  final pasted = switch (scheme) {
    'sora' || 'happ' => after('add/'),
    'hiddify' => after('import/'),
    'streisand' => after('import/'),
    _ => null,
  };
  if (pasted != null) {
    // Hiddify puts the name after a "#"; a subscription link has no fragment
    // worth keeping, so the last one is taken as the name.
    final hash = scheme == 'hiddify' ? pasted.lastIndexOf('#') : -1;
    final target = hash < 0 ? pasted : pasted.substring(0, hash);
    final name = hash < 0 ? '' : Uri.decodeComponent(pasted.substring(hash + 1));
    return _subscription(target.contains('://') ? target : Uri.decodeComponent(target), name);
  }

  final uri = Uri.tryParse(link);
  if (uri == null) return null;
  final query = uri.queryParameters;
  final known = switch (scheme) {
    'sora' => uri.host == 'add',
    'v2rayn' || 'v2rayng' || 'clash' || 'clashx' || 'mihomo' => uri.host == 'install-config',
    'sing-box' => uri.host == 'import-remote-profile',
    _ => false,
  };
  final target = query['url'];
  if (!known || target == null) return null;
  final name = query['name'] ?? (uri.fragment.isEmpty ? '' : uri.fragment);
  return _subscription(target, name);
}

ImportLink? _subscription(String target, String name) {
  final url = Uri.tryParse(target.trim());
  if (url == null || !(url.isScheme('https') || url.isScheme('http')) || url.host.isEmpty) return null;
  return AddSubscription(url, name: name.trim());
}
