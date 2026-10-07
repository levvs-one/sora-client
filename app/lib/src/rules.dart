import 'dart:io';

/// Where a rule sends what it matches.
enum RuleTarget { direct, proxy, block }

/// One rule of the person's own: what it matches, in the contract's
/// destination form, and where it goes.
class UserRule {
  const UserRule(this.target, this.destination);

  final RuleTarget target;

  /// For example "domain:bank.ru", "203.0.113.0/24" or "process:telegram".
  final String destination;

  /// Reads a stored rule; null for one written by a newer release.
  static UserRule? parse(String stored) {
    final space = stored.indexOf(' ');
    if (space <= 0) return null;
    final target = RuleTarget.values.where((t) => t.name == stored.substring(0, space)).firstOrNull;
    final destination = stored.substring(space + 1).trim();
    if (target == null || destination.isEmpty) return null;
    return UserRule(target, destination);
  }

  String get stored => '${target.name} $destination';

  /// What the person typed, without the contract's prefix.
  String get shown => destination.replaceFirst(RegExp(r'^(domain|full|process):'), '');

  /// Turns what a person types into a destination: an address or a network
  /// stays a network, something with a dot is a site and everything under it,
  /// and a bare word is a program. A pasted link gives its site. Null when the
  /// text is none of these.
  static String? destinationOf(String input) {
    var text = input.trim();
    if (text.isEmpty || text.contains(RegExp(r'\s'))) return null;
    final link = Uri.tryParse(text);
    if (link != null && link.hasScheme && link.host.isNotEmpty) text = link.host;
    if (text.contains('/')) {
      final [address, bits] = [...text.split('/'), ''].take(2).toList();
      final ip = InternetAddress.tryParse(address);
      final n = int.tryParse(bits);
      final max = ip?.type == InternetAddressType.IPv6 ? 128 : 32;
      return ip != null && n != null && n >= 0 && n <= max ? '${ip.address}/$n' : null;
    }
    final ip = InternetAddress.tryParse(text);
    if (ip != null) return '${ip.address}/${ip.type == InternetAddressType.IPv6 ? 128 : 32}';
    // Windows names programs with their extension.
    if (RegExp(r'^[A-Za-z0-9._+-]{1,64}\.exe$', caseSensitive: false).hasMatch(text)) return 'process:$text';
    text = text.replaceFirst(RegExp(r'^\*?\.'), '').toLowerCase();
    if (text.contains('.')) {
      return RegExp(r'^[a-z0-9-]+(\.[a-z0-9-]+)+$').hasMatch(text) ? 'domain:$text' : null;
    }
    return RegExp(r'^[A-Za-z0-9._+-]{1,64}$').hasMatch(input.trim()) ? 'process:${input.trim()}' : null;
  }
}
