import 'package:flutter/material.dart';
import 'medicine.dart';
import 'history_entry.dart';
import 'doctor_visit.dart';

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}

class AiScreen extends StatefulWidget {
  // The real, live medicine list — passed in from HomeScreen so
  // this screen can answer using actual current data, not a copy
  // that could go stale.
  final List<Medicine> medicines;

  const AiScreen({super.key, required this.medicines});

  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> {
  final TextEditingController _controller = TextEditingController();

  final List<ChatMessage> _messages = [
    ChatMessage(
      text: "Hi Mary! Ask me things like \"what medicine should I take now?\", \"did I miss any doses?\", or \"when's my next appointment?\"",
      isUser: false,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
    });
    _controller.clear();

    // The actual "thinking" step — figure out what's being asked
    // and pull a real answer from real data.
    final reply = await _generateReply(text);

    setState(() {
      _messages.add(ChatMessage(text: reply, isUser: false));
    });
  }

  // Very simple keyword matching — not real language understanding,
  // but genuinely reflects the app's actual current data rather
  // than a hardcoded script. This is the honest, achievable version
  // of "AI" without needing a paid LLM API connected.
  Future<String> _generateReply(String question) async {
    final lower = question.toLowerCase();

    // "What medicine should I take now / next?"
    if (lower.contains('medicine') && (lower.contains('now') || lower.contains('next') || lower.contains('take'))) {
      final due = widget.medicines.where((m) => m.isDueToday() && !m.isTaken).toList();
      if (due.isEmpty) {
        return "You've taken everything scheduled for today. Nice work! 🌿";
      }
      final next = due.first;
      return "Next up is ${next.name} — ${next.dosage}, ${next.timing}.";
    }

    // "Did I miss / how many missed doses?"
    if (lower.contains('miss')) {
      final history = await HistoryStorage.loadEntries();
      final missed = history.where((h) => h.status == 'missed').toList();
      if (missed.isEmpty) {
        return "No missed doses in your recent history — you're on track!";
      }
      final mostRecent = missed.first;
      return "You've missed ${missed.length} dose(s) recently. Most recent: ${mostRecent.medicineName} on ${mostRecent.date}.";
    }

    // "Next appointment?"
    if (lower.contains('appointment') || lower.contains('doctor')) {
      final visits = await DoctorVisitStorage.loadVisits();
      if (visits.isEmpty) {
        return "You don't have any doctor visits logged yet.";
      }
      final latest = visits.first;
      return "Your most recent visit was with ${latest.doctorName} on ${latest.date}. No upcoming appointment has been scheduled yet.";
    }

    // "How many medicines / what's my adherence?"
    if (lower.contains('adherence') || lower.contains('how many')) {
      final total = widget.medicines.where((m) => m.isDueToday()).length;
      final taken = widget.medicines.where((m) => m.isDueToday() && m.isTaken).length;
      return "You've taken $taken of $total doses scheduled for today.";
    }

    // Fallback — honest about its limits, rather than pretending
    // to understand everything.
    return "I'm not sure how to answer that yet — I can help with questions about today's medicines, missed doses, or your doctor visits.";
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
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _chatBubble(_messages[index]);
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
                    onSubmitted: (_) => _sendMessage(),
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