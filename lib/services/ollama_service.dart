import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../data/models/app_info.dart';
import '../data/models/network_connection.dart';
import '../core/utils/suspicion_calculator.dart';

/// Ollama base URL.
/// - Emulator  → http://10.0.2.2:11434
/// - Real device on same WiFi → http://<PC_LOCAL_IP>:11434
///   (start Ollama with: OLLAMA_HOST=0.0.0.0 ollama serve)
const ollamaBaseUrl = 'http://10.0.2.2:11434';
const ollamaModel = 'gpt120oss';

class OllamaService {
  static final _client = http.Client();

  // ── App explanation ──────────────────────────────────────────────────────

  static Stream<String> explainApp({
    required AppInfo app,
    String question = 'Devo preoccuparmi di questa app?',
  }) {
    final reasons = SuspicionCalculator.reasons(app);

    final context = '''
App: ${app.displayName} (${app.packageName})
Versione: ${app.versionName ?? 'sconosciuta'}
Punteggio sospetto: ${app.suspicionScore}/100
App di sistema: ${app.isSystemApp ? 'sì' : 'no'}
Permessi sensibili: ${app.permissions.length} permessi
CPU: ${app.cpuUsage.toStringAsFixed(1)}%
RAM: ${app.ramUsageMb.toStringAsFixed(0)} MB
Traffico rete: ${app.networkTrafficMb.toStringAsFixed(0)} MB
Wake locks: ${app.wakeLocksCount}
Avvio automatico: ${app.startsOnBoot ? 'sì' : 'no'}
Accessibility service: ${app.hasAccessibilityService ? 'sì' : 'no'}
Connette a datacenter: ${app.connectsToDatacenter ? 'sì' : 'no'}

Motivi segnalati:
${reasons.isEmpty ? 'Nessuna anomalia rilevata.' : reasons.map((r) => '• $r').join('\n')}
''';

    return _chat(
      systemPrompt: _systemPrompt,
      userMessage: 'CONTESTO:\n$context\n\nDOMANDA: $question',
    );
  }

  // ── Connection explanation ───────────────────────────────────────────────

  static Stream<String> explainConnection({
    required NetworkConnection conn,
    String question = 'Questa connessione è pericolosa?',
  }) {
    final context = '''
Connessione TCP rilevata:
IP remoto: ${conn.remoteIp}
Hostname: ${conn.hostname.isNotEmpty ? conn.hostname : 'sconosciuto'}
Porta: ${conn.port} (${conn.protocol})
Paese: ${conn.country ?? '?'} (${conn.countryCode ?? '?'})
Provider: ${conn.provider ?? 'sconosciuto'}
Datacenter noto: ${conn.isKnownDatacenter ? 'sì' : 'no'}
Punteggio sospetto: ${conn.suspicionScore}/100
Flag: ${conn.flags.isEmpty ? 'nessuna' : conn.flags.join(', ')}
Traffico: ${conn.trafficKbps.toStringAsFixed(0)} Kbps
''';

    return _chat(
      systemPrompt: _systemPrompt,
      userMessage: 'CONTESTO:\n$context\n\nDOMANDA: $question',
    );
  }

  // ── Generic question (free form) ─────────────────────────────────────────

  static Stream<String> ask(String question) =>
      _chat(systemPrompt: _systemPrompt, userMessage: question);

  // ── Internal ─────────────────────────────────────────────────────────────

  static const _systemPrompt = '''
Sei GUARDIAN, il motore di analisi AI di CTOS Companion.
Rispondi SEMPRE in italiano. Sii diretto e conciso (massimo 4 frasi).
Non essere eccessivamente allarmistico: distingui tra comportamenti normali e genuinamente sospetti.
Dai sempre un consiglio pratico alla fine.
''';

  static Stream<String> _chat({
    required String systemPrompt,
    required String userMessage,
  }) async* {
    try {
      final uri = Uri.parse('$ollamaBaseUrl/api/chat');
      final request = http.Request('POST', uri)
        ..headers['Content-Type'] = 'application/json'
        ..body = jsonEncode({
          'model': ollamaModel,
          'stream': true,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': userMessage},
          ],
        });

      final streamed = await _client
          .send(request)
          .timeout(const Duration(seconds: 15));

      await for (final line in streamed.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
        if (line.isEmpty) continue;
        try {
          final json = jsonDecode(line) as Map<String, dynamic>;
          final content =
              (json['message'] as Map<String, dynamic>?)?['content'] as String?;
          if (content != null && content.isNotEmpty) yield content;
          if (json['done'] == true) break;
        } catch (_) {}
      }
    } catch (_) {
      yield '\n[GUARDIAN offline — avvia Ollama con OLLAMA_HOST=0.0.0.0]';
    }
  }
}
