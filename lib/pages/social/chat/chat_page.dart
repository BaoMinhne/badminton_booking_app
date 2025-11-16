import 'dart:async';

import 'package:badminton_booking_app/components/chat_input.dart';
import 'package:badminton_booking_app/models/chat_contact.dart';
import 'package:badminton_booking_app/pages/social/chat/chat_manager.dart';
import 'package:badminton_booking_app/pages/social/chat/widgets/chat_app_bar.dart';
import 'package:badminton_booking_app/pages/social/chat/widgets/chat_message_list.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({
    super.key,
    required this.roomId,
    required this.contact,
  });

  final String roomId;
  final ChatContact contact;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ChatManager>().loadMessages(widget.roomId);
    });
  }

  void _handleSend(String text) {
    if (text.trim().isEmpty) return;
    final manager = context.read<ChatManager>();
    unawaited(
      manager.sendMessage(widget.roomId, text).catchError((error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final contact = widget.contact;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: ChatAppBar(
        name: contact.name,
        isOnline: contact.isOnline,
        avatarText: contact.avatarText,
        onCall: () {},
        onVideoCall: () {},
      ),
      body: Consumer<ChatManager>(
        builder: (context, manager, _) {
          final messages = manager.messagesForRoom(widget.roomId);
          final isLoading = manager.isLoadingMessages(widget.roomId);
          return Column(
            children: [
              Expanded(
                child: isLoading && messages.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : ChatMessageList(
                        messages: messages,
                        peerInitial: contact.avatarText,
                        peerAvatarUrl: contact.avatarUrl,
                      ),
              ),
              ChatInput(
                onSend: _handleSend,
                backgroundColor: cs.background,
              ),
            ],
          );
        },
      ),
    );
  }
}
