import 'dart:io';

/// The action applied to traffic matching a rule.
enum RuleTarget { direct, proxy, block }

/// A user routing rule with a target and a core-contract destination.
class UserRule {
  const UserRule(this.target, this.destination);

  final RuleTarget target;

  /// For example "domain:bank.ru", "203.0.113.0/24" or "process:telegram".
  final String destination;

  /// Parses a stored rule; returns null for unsupported or invalid formats,
  /// including those from newer releases.
  static UserRule? parse(String stored) {
    final space = stored.indexOf(' ');
    if (space <= 0) return null;
    final target = RuleTarget.values.where((t) => t.name == stored.substring(0, space)).firstOrNull;
    final destination = stored.substring(space + 1).trim();
    if (target == null || destination.isEmpty) return null;
    return UserRule(target, destination);
  }

  String get stored => '${target.name} $destination';

  /// The destination text with its core-contract prefix removed.
  String get shown => destination.replaceFirst(RegExp(r'^(domain|full|process):'), '');

  /// Converts input to a core destination: IPs and CIDRs become networks,
  /// dotted names match domains and subdomains, and bare names match processes.
  /// URLs use their host; invalid input returns null.
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
    // Recognize Windows .exe process names before treating dotted names as
    // domains.
    if (RegExp(r'^[A-Za-z0-9._+-]{1,64}\.exe$', caseSensitive: false).hasMatch(text)) return 'process:$text';
    text = text.replaceFirst(RegExp(r'^\*?\.'), '').toLowerCase();
    if (text.contains('.')) {
      return RegExp(r'^[a-z0-9-]+(\.[a-z0-9-]+)+$').hasMatch(text) ? 'domain:$text' : null;
    }
    return RegExp(r'^[A-Za-z0-9._+-]{1,64}$').hasMatch(input.trim()) ? 'process:${input.trim()}' : null;
  }
}
