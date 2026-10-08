import 'generated/sora/core/v1/core_control.pb.dart';

/// Server-name suffixes such as "(main)" or "(запасной)" set failover priority
/// within same-name subscription groups. Without roles, use the fastest
/// reachable member. Names remain compatible with Happ and other clients.
enum Role { main, backup }

/// A server-list entry for one server or a same-name group in a subscription.
class Entry {
  Entry._(this.id, this.name, this.members, this.roles);

  /// The server ID, or `group:<subscription>:<name>` for a group.
  final String id;
  final String name;
  final List<OutboundSpec> members;

  /// Roles parsed from member names; empty when no name specifies a role.
  final Map<String, Role> roles;

  bool get isGroup => members.length > 1;
  bool get ordered => roles.isNotEmpty;

  /// Returns main members first, then backups. Unlabelled members of a group
  /// with roles are treated as backups.
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

/// Splits a trailing role suffix from a server name; returns null for no role.
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

/// Groups subscription servers by name, preserving their list order.
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

/// Finds the entry matching a selection across subscriptions; null if absent.
Entry? entryOf(String choice, Iterable<SubscriptionState> subscriptions) {
  for (final s in subscriptions) {
    for (final e in entriesOf(s)) {
      if (e.id == choice) return e;
    }
  }
  return null;
}
