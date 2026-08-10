import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import 'package:santijet_ana/core/routing/app_routes.dart';
import 'package:santijet_ana/core/theme/theme_colors.dart';
import 'package:santijet_ana/core/theme/theme_provider.dart';
import 'package:santijet_ana/data/providers/app_state_provider.dart';
import 'package:santijet_ana/data/services/workspace_api.dart';
import 'package:santijet_ana/utils/ai_snapshot.dart';

class _ChatMessage {
  const _ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.ts,
  });

  final String id;
  final String role; // user | assistant
  final String content;
  final int ts;
}

/// ŞantiJET Asistan — bulut çalışma alanı + WorkspaceApi.ask.
class AsistanScreen extends ConsumerStatefulWidget {
  const AsistanScreen({super.key});

  @override
  ConsumerState<AsistanScreen> createState() => _AsistanScreenState();
}

class _AsistanScreenState extends ConsumerState<AsistanScreen> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _messages = <_ChatMessage>[];
  var _loading = false;
  String? _error;

  bool get _cloudReady {
    final ws = ref.read(appStateProvider).workspaceInfo;
    return ws != null && !ws.isLocal && (ws.authToken?.isNotEmpty ?? false);
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _loading) return;

    if (!_cloudReady) {
      setState(() {
        _error =
            'Yapay zeka için önce Çalışma Alanı bağlantısı gerek. Ana sayfadan bağlanın.';
      });
      return;
    }

    final userMsg = _ChatMessage(
      id: const Uuid().v4(),
      role: 'user',
      content: trimmed,
      ts: DateTime.now().millisecondsSinceEpoch,
    );

    setState(() {
      _error = null;
      _messages.add(userMsg);
      _loading = true;
      _inputCtrl.clear();
    });
    _scrollToEnd();

    final app = ref.read(appStateProvider);
    final ws = app.workspaceInfo!;
    try {
      final snapshot = buildAiSnapshot(app, app.currentRole);
      final history = _messages
          .where((m) => m.id != userMsg.id)
          .toList()
          .reversed
          .take(10)
          .toList()
          .reversed
          .map((m) => {'role': m.role, 'content': m.content})
          .toList();

      final json = await ref.read(workspaceApiProvider).ask(
            workspace: ws,
            body: {
              'question': trimmed,
              'snapshot': snapshot,
              'history': history,
            },
          );

      final answerRaw = json['answer'];
      final answer = answerRaw is String && answerRaw.trim().isNotEmpty
          ? answerRaw.trim()
          : 'Boş cevap geldi.';

      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(
          id: const Uuid().v4(),
          role: 'assistant',
          content: answer,
          ts: DateTime.now().millisecondsSinceEpoch,
        ));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is WorkspaceApiException ? e.message : e.toString();
        _messages.removeWhere((m) => m.id == userMsg.id);
      });
    } finally {
      if (mounted) setState(() => _loading = false);
      _scrollToEnd();
    }
  }

  Future<void> _clearChat() async {
    if (_messages.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sohbeti Temizle'),
        content: const Text('Tüm mesajlar silinecek. Devam edilsin mi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (ok == true) {
      setState(() {
        _messages.clear();
        _error = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(themeDefinitionProvider).colors;
    final app = ref.watch(appStateProvider);
    final cloudReady =
        app.workspaceInfo != null &&
        !app.workspaceInfo!.isLocal &&
        (app.workspaceInfo!.authToken?.isNotEmpty ?? false);
    final top = MediaQuery.paddingOf(context).top;
    final suggested = getSuggestedQuestions(app);

    return Scaffold(
      backgroundColor: c.background,
      body: Column(
        children: [
          Container(
            color: c.secondary,
            padding: EdgeInsets.fromLTRB(8, top + 12, 8, 14),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go(AppRoutes.home);
                    }
                  },
                  icon: Icon(Icons.arrow_back, color: c.secondaryForeground),
                ),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: c.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.memory, size: 16, color: c.primaryForeground),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'ŞantiJET Asistan',
                    style: TextStyle(
                      color: c.secondaryForeground,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _messages.isEmpty ? null : _clearChat,
                  icon: Icon(Icons.delete_outline, color: c.secondaryForeground),
                ),
              ],
            ),
          ),
          if (!cloudReady)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_off_outlined, size: 48, color: c.mutedForeground),
                    const SizedBox(height: 16),
                    Text(
                      'Bulut çalışma alanı gerekli',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: c.foreground,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Yerel modda asistan kullanılamaz. Ana sayfadan bir çalışma alanına bağlanın veya oluşturun.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: c.mutedForeground,
                        fontSize: 13,
                        height: 1.4,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton(
                      onPressed: () => context.go(AppRoutes.workspaceSetup),
                      child: const Text('Çalışma Alanı'),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            Expanded(
              child: ListView(
                controller: _scrollCtrl,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                children: [
                  if (_messages.isEmpty) ...[
                    Text(
                      'Önerilen sorular',
                      style: TextStyle(
                        color: c.mutedForeground,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final q in suggested) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: ActionChip(
                          label: Text(q, style: const TextStyle(fontSize: 12)),
                          onPressed: () => _send(q),
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                  ],
                  for (final m in _messages) _bubble(c, m),
                  if (_loading)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: c.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Düşünüyor…',
                            style: TextStyle(
                              color: c.mutedForeground,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_error != null)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: c.destructive.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: c.destructive,
                          fontSize: 13,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _inputCtrl,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: _send,
                        decoration: InputDecoration(
                          hintText: 'Soru sorun…',
                          filled: true,
                          fillColor: c.card,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: c.border),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _loading
                          ? null
                          : () => _send(_inputCtrl.text),
                      style: IconButton.styleFrom(backgroundColor: c.primary),
                      icon: Icon(Icons.send, color: c.primaryForeground),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _bubble(ThemeColors c, _ChatMessage m) {
    final isUser = m.role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
        ),
        decoration: BoxDecoration(
          color: isUser ? c.primary : c.card,
          borderRadius: BorderRadius.circular(14),
          border: isUser ? null : Border.all(color: c.border),
        ),
        child: Text(
          m.content,
          style: TextStyle(
            color: isUser ? c.primaryForeground : c.foreground,
            fontSize: 14,
            height: 1.35,
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }
}
