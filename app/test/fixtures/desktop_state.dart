import 'package:fixnum/fixnum.dart';
import 'package:protobuf/well_known_types/google/protobuf/timestamp.pb.dart';
import 'package:sora/src/generated/sora/core/v1/core_control.pb.dart';
import 'package:sora/src/notifications.dart';
import 'package:sora/src/sora.dart';

class DesktopState extends Sora {
  DesktopState(super.settings) {
    phase = Phase.connected;
    serverlessAvailable = true;
    since = DateTime.now().subtract(const Duration(minutes: 14, seconds: 32));
    stats = StatsTick(bytesDown: Int64(482344960), bytesUp: Int64(25270681));
    speedDown = 2516582;
    speedUp = 127926;
    settings.server = 'nl-amsterdam';
    settings.rules = ['direct domain:госуслуги.рф', 'proxy process:telegram-desktop', 'block domain:doubleclick.net'];
    latency.addAll({
      'nl-amsterdam': 42,
      'de-frankfurt': 56,
      'fi-helsinki': 38,
      'pl-warsaw': 64,
      'se-stockholm': 45,
      'fr-paris': 72,
      'gb-london': 86,
      'us-newyork': 131,
      'jp-tokyo': 218,
      'sg-singapore': 186,
      'tr-istanbul': 69,
      'ch-zurich': null,
    });
    history = [
      AppNotification(
        time: DateTime.now().subtract(const Duration(minutes: 14)),
        title: 'Снова подключено',
        body: '🇳🇱 Нидерланды, Амстердам',
      ),
      AppNotification(
        time: DateTime.now().subtract(const Duration(minutes: 15)),
        title: 'Соединение прервалось',
        body: 'Sora переподключается',
        action: 'logs',
        read: true,
      ),
      AppNotification(
        time: DateTime.now().subtract(const Duration(hours: 2)),
        title: 'Подписка',
        body: 'Обновление списка серверов завершено',
        read: true,
      ),
    ];
  }

  final subscription = SubscriptionState(
    settings: SubscriptionSettings(id: 'travel', name: 'Travel', autoUpdate: true),
    displayName: 'Travel',
    info: SubscriptionInfo(
      hasUsage: true,
      uploadBytes: Int64(3221225472),
      downloadBytes: Int64(27917287424),
      totalBytes: Int64(107374182400),
      expire: Timestamp.fromDateTime(DateTime(2026, 12, 20)),
      announce: '**Обновление сети** 🌍\n\nДобавлены *Хельсинки* и Варшава.\n\n- Обновите подписку перед поездкой\n- [Связаться с поддержкой](https://example.org/support)',
    ),
    outbounds: [
      for (final (id, name, protocol) in [
        ('nl-amsterdam', '🇳🇱 Нидерланды, Амстердам', 'vless'),
        ('de-frankfurt', '🇩🇪 Германия, Франкфурт', 'vless'),
        ('fi-helsinki', '🇫🇮 Финляндия, Хельсинки', 'trojan'),
        ('pl-warsaw', '🇵🇱 Польша, Варшава', 'vless'),
        ('se-stockholm', '🇸🇪 Швеция, Стокгольм', 'shadowsocks'),
        ('fr-paris', '🇫🇷 Франция, Париж', 'vless'),
        ('gb-london', '🇬🇧 Великобритания, Лондон', 'trojan'),
        ('us-newyork', '🇺🇸 США, Нью-Йорк', 'vless'),
        ('jp-tokyo', '🇯🇵 Япония, Токио', 'vless'),
        ('sg-singapore', '🇸🇬 Сингапур', 'shadowsocks'),
        ('tr-istanbul', '🇹🇷 Турция, Стамбул', 'vless'),
        ('ch-zurich', '🇨🇭 Швейцария, Цюрих', 'trojan'),
      ])
        OutboundSpec(
          id: id,
          displayName: name,
          protocol: id == 'nl-amsterdam' ? 'xray-profile' : protocol,
          displayProtocol: id == 'nl-amsterdam' ? 'vless' : '',
          transport: protocol == 'vless' ? 'xhttp' : 'tcp',
          security: protocol == 'vless'
              ? 'reality'
              : protocol == 'trojan'
              ? 'tls'
              : 'none',
        ),
    ],
  );

  @override
  List<SubscriptionState> get subscriptions => [subscription];
  @override
  List<OutboundSpec> get servers => subscription.outbounds;
}
