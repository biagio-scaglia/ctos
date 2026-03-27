import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/ctos_colors.dart';
import '../../data/models/app_info.dart';
import '../../data/models/network_connection.dart';
import '../../services/ollama_service.dart';

/// Hacker-style bottom sheet that streams AI explanations from Ollama Guardian.
/// Usage:
///   showModalBottomSheet(builder: (_) => AiExplainSheet.app(app: app))
///   showModalBottomSheet(builder: (_) => AiExplainSheet.connection(connection: conn))
class AiExplainSheet extends StatefulWidget {
  final AppInfo? app;
  final NetworkConnection? connection;

  const AiExplainSheet.app({super.key, required this.app}) : connection = null;

  const AiExplainSheet.connection({super.key, required this.connection})
      : app = null;

  @override
  State<AiExplainSheet> createState() => _AiExplainSheetState();
}

class _AiExplainSheetState extends State<AiExplainSheet> {
  String _response = '';
  bool _loading = false;
  bool _done = false;
  StreamSubscription<String>? _sub;
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _ask(null);
  }

  @override
  void dispose() {
    _sub?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _ask(String? customQuestion) {
    _sub?.cancel();
    setState(() {
      _response = '';
      _loading = true;
      _done = false;
    });

    final Stream<String> stream;
    if (widget.app != null) {
      stream = OllamaService.explainApp(
        app: widget.app!,
        question: customQuestion ?? 'Devo preoccuparmi di questa app?',
      );
    } else {
      stream = OllamaService.explainConnection(
        conn: widget.connection!,
        question: customQuestion ?? 'Questa connessione è pericolosa?',
      );
    }

    _sub = stream.listen(
      (chunk) {
        setState(() => _response += chunk);
        // Auto-scroll to bottom as text streams in
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 80),
              curve: Curves.easeOut,
            );
          }
        });
      },
      onDone: () => setState(() {
        _loading = false;
        _done = true;
      }),
      onError: (_) => setState(() {
        _loading = false;
        _done = true;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.app?.displayName ?? widget.connection?.remoteIp ?? '';
    final subtitle = widget.app?.packageName ??
        '${widget.connection?.port}/${widget.connection?.protocol}';

    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      decoration: const BoxDecoration(
        color: CtosColors.background,
        border: Border(top: BorderSide(color: CtosColors.cyan, width: 1.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: CtosColors.surface,
              border: Border(bottom: BorderSide(color: CtosColors.cyanDark)),
            ),
            child: Row(
              children: [
                const Icon(Icons.psychology_outlined,
                    color: CtosColors.cyan, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'GUARDIAN AI',
                        style: TextStyle(
                          fontFamily: 'Orbitron',
                          fontSize: 11,
                          color: CtosColors.cyan,
                          letterSpacing: 2.5,
                        ),
                      ),
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'Rajdhani',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: CtosColors.textPrimary,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontFamily: 'ShareTechMono',
                          fontSize: 9,
                          color: CtosColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_loading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: CtosColors.cyan,
                    ),
                  )
                else if (_done)
                  const Icon(Icons.check_circle_outline,
                      color: CtosColors.safe, size: 18),
              ],
            ),
          ),

          // ── Streaming response ────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Prompt echo
                  Text(
                    widget.app != null
                        ? '> devo preoccuparmi di questa app?'
                        : '> questa connessione è pericolosa?',
                    style: const TextStyle(
                      fontFamily: 'ShareTechMono',
                      fontSize: 11,
                      color: CtosColors.cyan,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // AI response
                  if (_response.isEmpty && _loading)
                    const Text(
                      '▌ analisi in corso...',
                      style: TextStyle(
                        fontFamily: 'ShareTechMono',
                        fontSize: 13,
                        color: CtosColors.textMuted,
                      ),
                    ).animate(onPlay: (c) => c.repeat()).shimmer(
                          color: CtosColors.cyan,
                          duration: const Duration(milliseconds: 1200),
                        )
                  else
                    Text(
                      _response + (_loading ? '▌' : ''),
                      style: const TextStyle(
                        fontFamily: 'ShareTechMono',
                        fontSize: 13,
                        color: CtosColors.textSecondary,
                        height: 1.7,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── Custom question input ─────────────────────────────────────────
          if (_done)
            Container(
              decoration: const BoxDecoration(
                color: CtosColors.surface,
                border: Border(top: BorderSide(color: CtosColors.cyanDark)),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Text(
                    '> ',
                    style: TextStyle(
                      fontFamily: 'ShareTechMono',
                      color: CtosColors.cyan,
                      fontSize: 14,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      autofocus: false,
                      style: const TextStyle(
                        fontFamily: 'ShareTechMono',
                        fontSize: 13,
                        color: CtosColors.textPrimary,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'chiedi qualcosa...',
                        hintStyle: TextStyle(
                          fontFamily: 'ShareTechMono',
                          fontSize: 12,
                          color: CtosColors.textMuted,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onSubmitted: _submit,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _submit(_controller.text),
                    child: const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child:
                          Icon(Icons.send, color: CtosColors.cyan, size: 18),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),
        ],
      ),
    );
  }

  void _submit(String q) {
    if (q.trim().isEmpty) return;
    _ask(q.trim());
    _controller.clear();
  }
}
