import 'generated/sora/core/v1/core_control.pb.dart';

/// A provider steers Sora through the names of its servers, the one field
/// every panel lets it set and every client shows as it is. Servers of one
/// subscription with the same name are one entry in Sora: the fastest that
/// answers carries the traffic. A name ending in a role — "Netherlands
/// (main)", "Нидерланды · запасной" — orders them instead: the main ones
/// first, the backups when the main ones fail. Happ and others show the same
/// names, which read naturally there too.
enum Role { main, backup }

/// One line of the server list: a server, or the servers sharing a name.
class Entry {
  Entry._(this.id, this.name, this.members, this.roles);

  /// A server's own id, or `group:<subscription>:<name>` for several.
  final String id;
  final String name;
  final List<OutboundSpec> members;

  /// The role each member's name carries; empty when none carries one.
  final Map<String, Role> roles;

  bool get isGroup => members.length > 1;
  bool get ordered => roles.isNotEmpty;

  /// Members in the order they are tried when the names carry roles: the main
  /// ones, then the rest. A member without a role in an ordered group is a
  /// backup: the provider named the main ones.
  List<OutboundSpec> get byRole => [
    for (final o in members)
      if (roles[o.id] == Role.main) o,
    for (final o in members)
      if (roles[o.id] != Role.main) o,
  ];
}

const groupPrefix = 'group:';

final _role = RegExp(
  r'\s*[\(\[\-–—·|:,]?\s*(основн(?:ой|ая|ое)|главн(?:ый|ая|ое)|запасн(?:ой|ая|ое)|резерв(?:ный|ная|ное)?|main|primary|backup|reserve|fallback)\s*[\)\]]?\s*$',
  caseSensitive: false,
  unicode: true,
);

/// The name without its role, and the role, if it ends in one.
(String, Role?) splitRole(String name) {
  final m = _role.firstMatch(name);
  if (m == null || m.start == 0) return (name.trim(), null);
  final word = m.group(1)!.toLowerCase();
  final role =
      word.startsWith('запас') || word.startsWith('резерв') || const {'backup', 'reserve', 'fallback'}.contains(word)
      ? Role.backup
      : Role.main;
  return (name.substring(0, m.start).trim(), role);
}

/// The entries of one subscription, in the order of its servers.
List<Entry> entriesOf(SubscriptionState subscription) {
  final byName = <String, List<OutboundSpec>>{};
  final roles = <String, Role>{};
  for (final o in subscription.outbounds) {
    final (name, role) = splitRole(o.displayName);
    byName.putIfAbsent(name, () => []).add(o);
    if (role != null) roles[o.id] = role;
  }
  return [
    for (final MapEntry(key: name, value: members) in byName.entries)
      members.length == 1
          ? Entry._(members.single.id, members.single.displayName, members, const {})
          : Entry._('$groupPrefix${subscription.settings.id}:$name', name, members, {
              for (final o in members)
                if (roles[o.id] != null) o.id: roles[o.id]!,
            }),
  ];
}

/// The entry a choice names, among every subscription.
Entry? entryOf(String choice, Iterable<SubscriptionState> subscriptions) {
  for (final s in subscriptions) {
    for (final e in entriesOf(s)) {
      if (e.id == choice) return e;
    }
  }
  return null;
}
