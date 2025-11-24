import 'package:badminton_booking_app/components/chat_input.dart';
import 'package:badminton_booking_app/models/chat_contact.dart';
import 'package:badminton_booking_app/pages/social/chat/widgets/chat_app_bar.dart';
import 'package:badminton_booking_app/pages/social/chat/widgets/chat_message_list.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'chat_conversation_manager.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({
    super.key,
    required this.contact,
  });

  final ChatContact contact;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ChatConversationManager>().initialize();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final manager = context.watch<ChatConversationManager>();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: ChatAppBar(
        name: widget.contact.name,
        isOnline: widget.contact.isOnline,
        avatarText: widget.contact.avatarText,
        onCall: () {},
        onVideoCall: () {},
      ),
      body: Column(
        children: [
          Expanded(
            child: manager.isLoading
                ? const Center(child: CircularProgressIndicator())
                : manager.error != null && manager.messages.isEmpty
                    ? Center(
                        child: Text(manager.error!),
                      )
                    : ChatMessageList(
                        messages: manager.messages,
                      ),
          ),
          ChatInput(
            onSend: manager.sendMessage,
            backgroundColor: cs.background,
          ),
        ],
      ),
    );
  }
}
