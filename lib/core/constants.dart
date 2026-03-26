class CtosConstants {
  CtosConstants._();

  // Hive box names
  static const String boxAppInfo      = 'app_info';
  static const String boxEvents       = 'device_events';
  static const String boxRiskHistory  = 'risk_history';
  static const String boxConnections  = 'network_connections';
  static const String boxBehavior     = 'app_behavior';
  static const String boxPrefs        = 'preferences';

  // Refresh intervals
  static const Duration networkRefresh  = Duration(seconds: 2);
  static const Duration deviceRefresh   = Duration(seconds: 5);
  static const Duration behaviorWindow  = Duration(hours: 24);

  // Risk thresholds
  static const int riskSafe     = 20;
  static const int riskLow      = 40;
  static const int riskModerate = 60;
  static const int riskHigh     = 80;

  // Suspicion weights
  static const Map<String, int> permissionWeights = {
    'android.permission.CAMERA': 8,
    'android.permission.RECORD_AUDIO': 8,
    'android.permission.ACCESS_FINE_LOCATION': 7,
    'android.permission.ACCESS_COARSE_LOCATION': 4,
    'android.permission.READ_CONTACTS': 5,
    'android.permission.READ_CALL_LOG': 7,
    'android.permission.SEND_SMS': 6,
    'android.permission.RECEIVE_SMS': 5,
    'android.permission.READ_SMS': 6,
    'android.permission.SYSTEM_ALERT_WINDOW': 5,
    'android.permission.BIND_ACCESSIBILITY_SERVICE': 9,
    'android.permission.PROCESS_OUTGOING_CALLS': 7,
    'android.permission.READ_PHONE_STATE': 5,
    'android.permission.GET_ACCOUNTS': 4,
    'android.permission.WRITE_SETTINGS': 6,
    'android.permission.CHANGE_NETWORK_STATE': 5,
    'android.permission.PACKAGE_USAGE_STATS': 7,
    'android.permission.RECEIVE_BOOT_COMPLETED': 4,
  };

  // Known datacenter ASNs/ranges (simplified)
  static const List<String> datacenterPrefixes = [
    '13.', '18.', '34.', '35.', '52.', '54.',  // AWS
    '104.196.', '35.186.', '34.64.',             // GCP
    '40.', '20.', '52.1', '13.7',               // Azure
    '162.158.', '172.68.', '104.16.',            // Cloudflare
    '151.101.',                                  // Fastly
  ];

  // Known VPN/proxy ports
  static const List<int> vpnPorts = [
    1194, 1723, 500, 4500,   // OpenVPN, PPTP, IPSec
    1080, 3128, 8080, 8888,  // SOCKS, HTTP proxy
    51820,                   // WireGuard
    443,                     // HTTPS / SSL VPN (ambiguous)
  ];

  // GeoIP API
  static const String geoIpApi = 'http://ip-api.com/json/';

  // Max events to keep in DB
  static const int maxEvents = 500;
  static const int maxRiskHistory = 168; // 7 days @ hourly
}
