import 'package:flutter/material.dart';

@immutable
class ChatContact {
  const ChatContact({
    required this.id,
    required this.name,
    required this.avatarText,
    this.avatarUrl,
    this.statusMessage,
    this.lastMessage,
    this.lastMessageTimeLabel,
    this.unreadCount = 0,
    this.isOnline = false,
  });

  final String id;
  final String name;
  final String avatarText;
  final String? avatarUrl;
  final String? statusMessage;
  final String? lastMessage;
  final String? lastMessageTimeLabel;
  final int unreadCount;
  final bool isOnline;

  bool get hasUnreadMessages => unreadCount > 0;
}
