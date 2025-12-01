import 'package:flutter/material.dart';

@immutable
class ChatContact {
  const ChatContact({
    required this.name,
    required this.avatarText,
    this.id,
    this.chatId,
    this.userId,
    this.avatarUrl,
    this.statusMessage,
    this.lastMessage,
    this.lastMessageTimeLabel,
    this.unreadCount = 0,
    this.isOnline = false,
  });

  final String? id;
  final String? chatId;
  final String? userId;
  final String name;
  final String avatarText;
  final String? avatarUrl;
  final String? statusMessage;
  final String? lastMessage;
  final String? lastMessageTimeLabel;
  final int unreadCount;
  final bool isOnline;

  bool get hasUnreadMessages => unreadCount > 0;

  ChatContact copyWith({
    String? id,
    String? chatId,
    String? userId,
    String? name,
    String? avatarText,
    String? avatarUrl,
    String? statusMessage,
    String? lastMessage,
    String? lastMessageTimeLabel,
    int? unreadCount,
    bool? isOnline,
  }) {
    return ChatContact(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      avatarText: avatarText ?? this.avatarText,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      statusMessage: statusMessage ?? this.statusMessage,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTimeLabel: lastMessageTimeLabel ?? this.lastMessageTimeLabel,
      unreadCount: unreadCount ?? this.unreadCount,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}
