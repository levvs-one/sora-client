/// An action requested by a browser or messenger import link.
sealed class ImportLink {
  const ImportLink();
}

/// A request to add [url] with the optional subscription [name].
final class AddSubscription extends ImportLink {
  const AddSubscription(this.url, {this.name = ''});

  final Uri url;
  final String name;
}

/// A Happ-encrypted link that only Happ can decrypt. Import requires the
/// provider's plain subscription URL.
final class SealedForHapp extends ImportLink {
  const SealedForHapp();
}

/// Registered schemes. Other supported import schemes are parsed when passed to
/// Sora, without registering them.
const ownSchemes = ['sora', 'happ'];

/// Parses add, install-config, import and import-remote-profile links from
/// Sora, Happ, v2rayn, Clash, Hiddify and sing-box. Requires an HTTP(S)
/// subscription URL; returns null for invalid links or percent-encoding.
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

  // Extract the embedded URL verbatim to preserve its own query and fragment
  // instead of parsing them as part of the import URI.
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
    // Hiddify stores the name after the last "#"; subscription URL fragments
    // are not needed.
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
