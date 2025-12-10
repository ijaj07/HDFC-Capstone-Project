import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'main.dart'; 

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  List<dynamic> _messages = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchInbox();
  }

  Future<void> _fetchInbox() async {
    try {
      
      final res = await http.get(Uri.parse('$BACKEND_BASE/inbox/demo_user'));
      
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _messages = data['messages'];
          _loading = false;
        });
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  // Helper to choose icon based on channel
  Widget _getIcon(String channel) {
    if (channel == 'WHATSAPP') return const Icon(Icons.chat_bubble, color: Colors.green);
    if (channel == 'PUSH') return const Icon(Icons.notifications_active, color: Color(0xFF1E3A8A));
    if (channel == 'SMS' || channel == 'SMS_BINDING') return const Icon(Icons.message, color: Colors.blue);
    if (channel == 'IN_APP') return const Icon(Icons.flash_on, color: Colors.amber);
    return const Icon(Icons.info, color: Colors.grey);
  }

  String _formatDate(String iso) {
    if (iso.isEmpty) return 'Just now';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return "${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text("Secure Inbox", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading 
        ? const Center(child: CircularProgressIndicator())
        : _messages.isEmpty 
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text("No secured messages yet.", style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final channel = msg['chosen_channel'] ?? 'UNKNOWN';
                final time = _formatDate(msg['sent_ts']);
                final type = msg['event_type'] ?? 'Alert';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))
                    ],
                    
                    border: const Border(left: BorderSide(color: Colors.green, width: 5))
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
                      child: _getIcon(channel),
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(type, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text(time, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        Text("Delivered via: $channel", style: const TextStyle(fontSize: 12, color: Colors.black87)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.verified, size: 14, color: Colors.green),
                            const SizedBox(width: 4),
                            const Text("Verified by Bank", style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}