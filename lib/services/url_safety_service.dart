import 'dart:convert';
import 'package:http/http.dart' as http;

enum UrlRisk { safe, suspicious, malicious, phishing, unknown }

class UrlSafetyResult {
  final String url;
  final UrlRisk risk;
  final String verdict;
  final List<String> flags;
  final int score; // 0-100

  const UrlSafetyResult({
    required this.url,
    required this.risk,
    required this.verdict,
    required this.flags,
    required this.score,
  });

  bool get isDangerous => risk == UrlRisk.malicious || risk == UrlRisk.phishing;
}

class UrlSafetyService {
  // Heuristic-based URL analysis (no external API needed)
  static UrlSafetyResult analyze(String url) {
    final uri = Uri.tryParse(url.startsWith('http') ? url : 'https://$url');
    if (uri == null) {
      return UrlSafetyResult(
        url: url,
        risk: UrlRisk.unknown,
        verdict: 'Invalid URL format',
        flags: [],
        score: 50,
      );
    }

    final flags = <String>[];
    int score = 0;

    final host = uri.host.toLowerCase();
    final path = uri.path.toLowerCase();
    final fullUrl = url.toLowerCase();

    // ── Heuristic checks ──────────────────────────────────────────────

    // 1. HTTP (not HTTPS)
    if (uri.scheme == 'http') {
      flags.add('NO HTTPS');
      score += 20;
    }

    // 2. IP address instead of domain
    final ipRegex = RegExp(r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$');
    if (ipRegex.hasMatch(host)) {
      flags.add('RAW IP ADDRESS');
      score += 25;
    }

    // 3. Suspicious TLDs
    const suspiciousTlds = [
      '.xyz', '.tk', '.ml', '.ga', '.cf', '.gq', '.pw',
      '.top', '.click', '.download', '.loan', '.win', '.bid',
    ];
    if (suspiciousTlds.any((tld) => host.endsWith(tld))) {
      flags.add('SUSPICIOUS TLD');
      score += 20;
    }

    // 4. Typosquatting — known brand names with extra chars
    const brands = ['google', 'facebook', 'apple', 'microsoft', 'amazon',
        'paypal', 'netflix', 'instagram', 'whatsapp', 'twitter'];
    for (final brand in brands) {
      if (host.contains(brand) && !host.endsWith('.$brand.com') &&
          host != '$brand.com' && !host.endsWith('.$brand.it')) {
        flags.add('POSSIBLE TYPOSQUATTING: $brand');
        score += 30;
        break;
      }
    }

    // 5. Phishing keywords in path/params
    const phishingKeywords = [
      'login', 'signin', 'account', 'verify', 'update',
      'confirm', 'banking', 'secure', 'password', 'credential',
    ];
    final phishFound = phishingKeywords.where((kw) => path.contains(kw) || fullUrl.contains(kw));
    if (phishFound.length >= 2) {
      flags.add('PHISHING PATTERN');
      score += 25;
    }

    // 6. Excessive subdomains
    final parts = host.split('.');
    if (parts.length > 4) {
      flags.add('EXCESSIVE SUBDOMAINS');
      score += 15;
    }

    // 7. Very long URL
    if (url.length > 200) {
      flags.add('VERY LONG URL');
      score += 10;
    }

    // 8. URL shortener
    const shorteners = ['bit.ly', 'tinyurl.com', 'goo.gl', 't.co', 'ow.ly',
        'short.link', 'rb.gy', 'cutt.ly', 'is.gd'];
    if (shorteners.any((s) => host == s || host.endsWith('.$s'))) {
      flags.add('URL SHORTENER (hidden destination)');
      score += 15;
    }

    // 9. Suspicious file extensions in path
    const dangerousExt = ['.exe', '.apk', '.bat', '.cmd', '.vbs', '.ps1', '.dmg'];
    if (dangerousExt.any((ext) => path.endsWith(ext))) {
      flags.add('DIRECT EXECUTABLE DOWNLOAD');
      score += 35;
    }

    // ── Determine risk level ──────────────────────────────────────────
    score = score.clamp(0, 100);

    final risk = switch (score) {
      < 15 => UrlRisk.safe,
      < 35 => UrlRisk.suspicious,
      < 60 => flags.contains('PHISHING PATTERN') ? UrlRisk.phishing : UrlRisk.suspicious,
      _ => flags.contains('PHISHING PATTERN') ? UrlRisk.phishing : UrlRisk.malicious,
    };

    final verdict = switch (risk) {
      UrlRisk.safe => 'URL appears safe',
      UrlRisk.suspicious => 'URL has suspicious characteristics',
      UrlRisk.phishing => 'Possible PHISHING page — do not enter credentials',
      UrlRisk.malicious => 'URL is likely MALICIOUS',
      UrlRisk.unknown => 'Cannot evaluate this URL',
    };

    return UrlSafetyResult(
      url: url,
      risk: risk,
      verdict: verdict,
      flags: flags,
      score: score,
    );
  }

  // Optional: check against URLhaus public feed (no API key needed)
  static Future<bool?> checkUrlhaus(String url) async {
    try {
      final response = await http.post(
        Uri.parse('https://urlhaus-api.abuse.ch/v1/url/'),
        body: {'url': url},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return data['query_status'] == 'is_host';
      }
    } catch (_) {}
    return null;
  }
}
