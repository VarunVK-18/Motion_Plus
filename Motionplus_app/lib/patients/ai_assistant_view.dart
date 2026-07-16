import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:hugeicons/hugeicons.dart' as hi;

class AIAssistantView extends StatefulWidget {
  final bool showAppBar;
  const AIAssistantView({super.key, this.showAppBar = true});

  @override
  State<AIAssistantView> createState() => _AIAssistantViewState();
}

class _AIAssistantViewState extends State<AIAssistantView> {
  static const Color primaryColor = Color(0xFF5C7C6F);
  static const Color darkSlate = Color(0xFF2F3437);
  static const Color softSlate = Color(0xFF94A3B8);

  // TODO: Replace with your actual Gemini API Key
  final String _apiKey = 'YOUR_API_KEY_HERE';
  
  bool _isLoading = false;
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  ChatSession? _chatSession;
  final List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  void _initializeChat() {
    if (_apiKey.isEmpty) return;
    
    final model = GenerativeModel(
      model: 'gemini-1.5-pro',
      apiKey: _apiKey,
      systemInstruction: Content.system('''You are OLEVEO AI Assistant, an educational physiotherapy companion.
You provide general guidance on topics like back pain, posture, hot/cold packs, stretching, and wellness.

RULES:
- You must NEVER diagnose conditions.
- You must NEVER prescribe treatments.
- You must NEVER recommend personalized treatments.
- You must NEVER replace a therapist's advice.

If a user asks for anything violating these rules, you MUST reply EXACTLY with:
"I can provide general education, but please consult your therapist for personalized advice."'''),
    );
    
    _chatSession = model.startChat();
    
    setState(() {
      _messages.add({
        'isUser': false,
        'text': 'Hello! I am your AI Physio Assistant. How can I help you today?',
      });
    });
  }

  Future<void> _sendMessage() async {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;
    
    if (_chatSession == null) {
      _initializeChat();
      if (_chatSession == null) return;
    }

    setState(() {
      _messages.add({'isUser': true, 'text': text});
      _isLoading = true;
    });
    
    _chatController.clear();
    _scrollToBottom();

    try {
      final response = await _chatSession!.sendMessage(Content.text(text));
      
      if (mounted) {
        setState(() {
          _messages.add({
            'isUser': false,
            'text': response.text ?? 'Sorry, I could not generate a response.',
          });
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({
            'isUser': false,
            'text': 'Error connecting to AI: $e',
          });
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final body = _apiKey.isEmpty
        ? Center(
            child: Text(
              'API Key is missing',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: darkSlate, fontSize: 16),
            ),
          )
        : _buildChatInterface();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: widget.showAppBar
          ? AppBar(
              title: Text(
                'AI Assistant',
                style: GoogleFonts.outfit(
                  color: darkSlate,
                  fontWeight: FontWeight.w600,
                ),
              ),
              backgroundColor: Colors.white,
              elevation: 1,
              iconTheme: const IconThemeData(color: darkSlate),
            )
          : null,
      body: body,
    );
  }

  Widget _buildChatInterface() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final message = _messages[index];
              final isUser = message['isUser'] as bool;
              return _buildMessageBubble(message['text'], isUser);
            },
          ),
        ),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: _TypingIndicator(),
          ),
        _buildMessageInput(),
      ],
    );
  }

  Widget _buildMessageBubble(String text, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 16, left: isUser ? 40.0 : 0.0, right: isUser ? 0.0 : 40.0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser ? primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(12).copyWith(
            bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(12),
            bottomLeft: isUser ? const Radius.circular(12) : const Radius.circular(4),
          ),
          border: isUser ? null : Border.all(color: Colors.grey.withOpacity(0.15)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: isUser
            ? Text(
                text,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              )
            : MarkdownBody(
                data: text,
                styleSheet: MarkdownStyleSheet(
                  p: GoogleFonts.outfit(color: darkSlate, fontSize: 15),
                  strong: GoogleFonts.outfit(color: darkSlate, fontWeight: FontWeight.bold),
                ),
              ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.1))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _chatController,
              decoration: InputDecoration(
                hintText: 'Ask anything...',
                hintStyle: GoogleFonts.outfit(color: softSlate),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryColor.withOpacity(0.5), width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _isLoading ? null : _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _isLoading ? Colors.grey[300] : primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildDot(int index) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        double val = (_controller.value - (index * 0.2)).clamp(0.0, 1.0);
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: const Color(0xFF5C7C6F).withOpacity(0.3 + (val * 0.7)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8, right: 40.0),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomLeft: const Radius.circular(0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDot(0),
            _buildDot(1),
            _buildDot(2),
          ],
        ),
      ),
    );
  }
}
