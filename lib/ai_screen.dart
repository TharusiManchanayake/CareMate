import 'package:flutter/material.dart';

// A model for one chat message — who sent it, and the text.
class ChatMessage {
  final String text;
  final bool isUser; // true = Mary sent it, false = the AI sent it

  ChatMessage({required this.text, required this.isUser});
}

class AiScreen extends StatefulWidget {
  const AiScreen({super.key});

  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> {
  // TextEditingController lets us READ whatever the user types into
  // a TextField, and also clear it programmatically after sending.
  final TextEditingController _controller = TextEditingController();

  // Start with a couple of example messages already in the chat.
  final List<ChatMessage> _messages = [
    ChatMessage(text: 'What medicine should I take now?', isUser: true),
    ChatMessage(
      text: "Right now it's time for Amlodipine 5mg — one tablet after breakfast. Want me to mark it as taken?",
      isUser: false,
    ),
  ];

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return; // don't send empty messages

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      // A placeholder canned reply — later this is where we'd call
      // a real AI API instead of hardcoding a response.
      _messages.add(ChatMessage(
        text: "Let me check that for you... (this is a placeholder reply for now)",
        isUser: false,
      ));
    });

    _controller.clear(); // empty the text field after sending
  }

  @override
  void dispose() {
    // Always dispose controllers when the widget is removed, to
    // free up memory — Dart doesn't do this automatically for you.
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ask CareMate',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E4038),
            ),
          ),
          const SizedBox(height: 16),

          // Expanded makes the chat list fill all remaining vertical
          // space, pushing the input field to the bottom.
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _chatBubble(msg);
              },
            ),
          ),

          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: const Color(0xFFE4DDCB)),
                  ),
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Type a question…',
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _sendMessage(), // Enter key sends too
                  ),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: const Color(0xFFE9A23B),
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white, size: 18),
                  onPressed: _sendMessage,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chatBubble(ChatMessage msg) {
    return Align(
      // User messages align right, AI messages align left
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: msg.isUser ? const Color(0xFF1E4038) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: msg.isUser ? null : Border.all(color: const Color(0xFFE4DDCB)),
        ),
        child: Text(
          msg.text,
          style: TextStyle(
            color: msg.isUser ? Colors.white : Colors.black87,
            fontSize: 13.5,
          ),
        ),
      ),
    );
  }
}