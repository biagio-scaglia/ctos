import 'dart:math';
import '../../data/models/app_info.dart';

class FakeAppMatch {
  final AppInfo app;
  final String impersonating;
  final String legitimatePackage;
  final int editDistance;
  final String confidence; // HIGH | MEDIUM | LOW

  const FakeAppMatch({
    required this.app,
    required this.impersonating,
    required this.legitimatePackage,
    required this.editDistance,
    required this.confidence,
  });
}

class FakeAppDetector {
  FakeAppDetector._();

  /// Map of known legitimate package names → display name.
  static const Map<String, String> knownPackages = {
    'com.whatsapp': 'WhatsApp',
    'com.whatsapp.w4b': 'WhatsApp Business',
    'com.instagram.android': 'Instagram',
    'com.facebook.katana': 'Facebook',
    'com.facebook.orca': 'Messenger',
    'com.google.android.gm': 'Gmail',
    'com.google.android.youtube': 'YouTube',
    'com.google.android.apps.photos': 'Google Photos',
    'com.google.android.apps.maps': 'Google Maps',
    'com.spotify.music': 'Spotify',
    'org.telegram.messenger': 'Telegram',
    'com.twitter.android': 'Twitter/X',
    'com.tiktok.android': 'TikTok',
    'com.zhiliaoapp.musically': 'TikTok (alt)',
    'com.snapchat.android': 'Snapchat',
    'com.netflix.mediaclient': 'Netflix',
    'com.paypal.android.p2pmobile': 'PayPal',
    'com.ubercab': 'Uber',
    'com.android.chrome': 'Chrome',
    'com.amazon.mShop.android.shopping': 'Amazon',
    'com.microsoft.teams': 'Microsoft Teams',
    'com.microsoft.launcher': 'Microsoft Launcher',
    'com.adobe.reader': 'Adobe Reader',
    'com.linkedin.android': 'LinkedIn',
    'com.pinterest': 'Pinterest',
    'com.reddit.frontpage': 'Reddit',
    'com.discord': 'Discord',
    'com.dropbox.android': 'Dropbox',
    'com.shazam.android': 'Shazam',
    'com.truecaller': 'Truecaller',
    'com.viber.voip': 'Viber',
    'com.skype.raider': 'Skype',
    'com.zoom.videomeetings': 'Zoom',
    'tv.twitch.android.app': 'Twitch',
  };

  /// Returns a list of installed apps that look like typosquats of known apps.
  static List<FakeAppMatch> analyze(List<AppInfo> apps) {
    final results = <FakeAppMatch>[];

    for (final app in apps) {
      // Skip if it IS the real app or is a system app
      if (knownPackages.containsKey(app.packageName)) continue;
      if (app.isSystemApp) continue;

      FakeAppMatch? best;

      for (final entry in knownPackages.entries) {
        final dist = _levenshtein(app.packageName, entry.key);

        // Adaptive threshold: ~15% of the longer string, clamped 2–5
        final maxLen = max(app.packageName.length, entry.key.length);
        final threshold = (maxLen * 0.15).round().clamp(2, 5);

        if (dist > 0 && dist <= threshold) {
          final confidence = dist == 1
              ? 'HIGH'
              : dist <= 2
                  ? 'MEDIUM'
                  : 'LOW';
          final match = FakeAppMatch(
            app: app,
            impersonating: entry.value,
            legitimatePackage: entry.key,
            editDistance: dist,
            confidence: confidence,
          );
          // Keep closest match
          if (best == null || dist < best.editDistance) best = match;
        }
      }

      if (best != null) results.add(best);
    }

    // Sort by severity (lowest edit distance first)
    results.sort((a, b) => a.editDistance.compareTo(b.editDistance));
    return results;
  }

  // ── Levenshtein distance ─────────────────────────────────────────────────

  static int _levenshtein(String a, String b) {
    final m = a.length, n = b.length;
    final dp = List.generate(m + 1, (i) => List.filled(n + 1, 0));
    for (int i = 0; i <= m; i++) { dp[i][0] = i; }
    for (int j = 0; j <= n; j++) { dp[0][j] = j; }
    for (int i = 1; i <= m; i++) {
      for (int j = 1; j <= n; j++) {
        dp[i][j] = a[i - 1] == b[j - 1]
            ? dp[i - 1][j - 1]
            : 1 + [dp[i - 1][j], dp[i][j - 1], dp[i - 1][j - 1]].reduce(min);
      }
    }
    return dp[m][n];
  }
}
