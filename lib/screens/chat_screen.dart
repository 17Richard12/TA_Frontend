import 'dart:convert';
import 'dart:async';
import 'package:agent_doctor/constants.dart';
import 'package:agent_doctor/services/chat_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;

class ChatScreen extends StatefulWidget {
  final String userUid;
  final String? sessionId;
  final String sessionName;
  final VoidCallback? onNewSession;

  const ChatScreen({
    super.key,
    required this.userUid,
    this.sessionId,
    this.sessionName = 'New Chat',
    this.onNewSession,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  static const Color responseBubble = Color(0xFF2563EB);

  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  String? _activeSessionId;

  @override
  void initState() {
    super.initState();
    _activeSessionId = widget.sessionId;
    if (_activeSessionId != null) _loadExistingChat();
  }

  Future<void> _loadExistingChat() async {
    setState(() => _isLoading = true);
    try {
      final result = await ChatService.getChatBySession(_activeSessionId!);
      if (result['status'] == 'success' && mounted) {
        // Struktur baru: messages adalah list of {role, response, timestamp}
        final messages = result['data']['messages'] as List<dynamic>? ?? [];
        for (final msg in messages) {
          final role = msg['role'] as String? ?? '';
          final response = msg['response'] as String? ?? '';
          if (response.isEmpty) continue;
          _messages.add({'text': response, 'isUser': role == 'user'});
        }
        setState(() {});
        _scrollToBottom();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    // Tambah pesan user
    setState(() {
      _messages.add({'text': text, 'isUser': true});
      // Tambah bubble kosong untuk AI (akan diisi streaming)
      _messages.add({'text': '', 'isUser': false});
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    // Index bubble AI yang sedang di-stream
    final aiIndex = _messages.length - 1;

    try {
      final request = http.Request(
        'POST',
        Uri.parse('${AppConstants.baseUrl}/api/chats/stream'),
      );
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode({
        'user_uid': widget.userUid,
        'session_id': _activeSessionId,
        'message': text,
      });

      final streamedResponse = await request.send();

      // Buffer untuk menampung data SSE yang belum lengkap
      final StringBuffer buffer = StringBuffer();

      await for (final chunk in streamedResponse.stream.transform(
        utf8.decoder,
      )) {
        buffer.write(chunk);
        final raw = buffer.toString();

        // Proses semua event SSE yang sudah lengkap (diakhiri \n\n)
        final events = raw.split('\n\n');

        // Event terakhir mungkin belum lengkap, simpan kembali ke buffer
        buffer.clear();
        buffer.write(events.last);

        // Proses semua event kecuali yang terakhir (belum tentu lengkap)
        for (int i = 0; i < events.length - 1; i++) {
          final event = events[i].trim();
          if (event.isEmpty) continue;

          // Gabungkan semua baris dalam satu event yang diawali "data: "
          final lines = event.split('\n');
          final dataLines = lines
              .where((l) => l.startsWith('data: '))
              .map((l) => l.substring(6))
              .join('\n');

          if (dataLines.isEmpty) continue;

          if (dataLines.startsWith('[SESSION]')) {
            _activeSessionId ??= dataLines.substring(9);
          } else if (dataLines == '[DONE]') {
            break;
          } else if (dataLines.startsWith('[ERROR]')) {
            if (mounted) {
              setState(
                () => _messages[aiIndex] = {
                  'text': 'Error: ${dataLines.substring(7)}',
                  'isUser': false,
                },
              );
            }
            break;
          } else {
            // Decode JSON string agar \n, bold, dll tampil benar
            String decoded = dataLines;
            try {
              decoded = jsonDecode(dataLines) as String;
            } catch (_) {
              decoded = dataLines;
            }
            if (mounted) {
              setState(() {
                final current = _messages[aiIndex]['text'] as String;
                _messages[aiIndex] = {
                  'text': current + decoded,
                  'isUser': false,
                };
              });
              _scrollToBottom();
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _messages[aiIndex] = {'text': 'Error: $e', 'isUser': false},
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _startNewSession() {
    if (_isLoading) return;
    setState(() {
      _messages.clear();
      _activeSessionId = null;
    });
    widget.onNewSession?.call();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _activeSessionId == null ? 'New Chat' : widget.sessionName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: _startNewSession,
                    icon: const Icon(Icons.add_circle_outline, color: Colors.black87),
                    tooltip: 'Sesi Baru',
                  ),
                ],
              ),
            ),

            // Chat Area
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.center,
                      child: Opacity(
                        opacity: 0.18,
                        child: Image.asset(
                          'assets/logo.png',
                          fit: BoxFit.contain,
                          width: double.infinity,
                        ),
                      ),
                    ),
                  ),
                  ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final text = msg['text'] as String;
                      final isUser = msg['isUser'] as bool;

                      // Tampilkan loading dots hanya saat bubble AI masih kosong
                      if (!isUser && text.isEmpty && _isLoading) {
                        return _buildLoadingBubble();
                      }
                      return _buildChatBubble(text: text, isUser: isUser);
                    },
                  ),
                ],
              ),
            ),

            // Input Area
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: Colors.black87, width: 1.5),
                      ),
                      child: TextField(
                        controller: _controller,
                        enabled: !_isLoading,
                        minLines: 1,
                        maxLines: 5,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        style: const TextStyle(fontSize: 15),
                        decoration: InputDecoration(
                          hintText: _isLoading
                              ? 'Menunggu respons...'
                              : 'Ketik pesan...',
                          hintStyle: const TextStyle(color: Colors.black45),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _isLoading ? null : _sendMessage,
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: _isLoading ? Colors.grey : responseBubble,
                        shape: BoxShape.circle,
                      ),
                      child: _isLoading
                          ? const Padding(
                              padding: EdgeInsets.all(14),
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Icon(
                              Icons.send,
                              color: Colors.white,
                              size: 22,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatBubble({required String text, required bool isUser}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.80,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            decoration: BoxDecoration(
              color: isUser ? Colors.white : responseBubble,
              borderRadius: BorderRadius.circular(28),
              border: isUser
                  ? Border.all(color: Colors.black87, width: 1.5)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.07),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: isUser
                ? Text(
                    text,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                : MarkdownBody(
                    data: text,
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      strong: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      em: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontStyle: FontStyle.italic,
                      ),
                      listBullet: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                      ),
                      code: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        backgroundColor: Color(0x33FFFFFF),
                      ),
                      h1: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      h2: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      h3: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingBubble() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
            decoration: BoxDecoration(
              color: responseBubble,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                3,
                (i) => _DotPulse(delay: Duration(milliseconds: i * 200)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DotPulse extends StatefulWidget {
  final Duration delay;
  const _DotPulse({required this.delay});

  @override
  State<_DotPulse> createState() => _DotPulseState();
}

class _DotPulseState extends State<_DotPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 3),
        child: CircleAvatar(radius: 4, backgroundColor: Colors.white),
      ),
    );
  }
}
