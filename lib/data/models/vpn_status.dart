enum VpnState { unknown, connected, disconnected }

class VpnStatus {
  final VpnState state;
  final String? serverIp;
  final String? serverCountry;
  final String? provider;
  final String? interfaceName; // e.g. tun0, ppp0
  final DateTime detectedAt;

  const VpnStatus({
    required this.state,
    this.serverIp,
    this.serverCountry,
    this.provider,
    this.interfaceName,
    required this.detectedAt,
  });

  bool get isActive => state == VpnState.connected;

  static VpnStatus unknown() => VpnStatus(
        state: VpnState.unknown,
        detectedAt: DateTime.now(),
      );
}
