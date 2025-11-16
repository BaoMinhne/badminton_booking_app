import 'package:flutter/material.dart';

@immutable
class ChatContact {
  const ChatContact({
    required this.id,
    required this.name,
    required this.avatarText,
    this.avatarUrl,
    this.roomId,
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
  final String? roomId;
  final String? statusMessage;
  final String? lastMessage;
  final String? lastMessageTimeLabel;
  final int unreadCount;
  final bool isOnline;

  bool get hasUnreadMessages => unreadCount > 0;

  ChatContact copyWith({
    String? id,
    String? name,
    String? avatarText,
    String? avatarUrl,
    String? roomId,
    String? statusMessage,
    String? lastMessage,
    String? lastMessageTimeLabel,
    int? unreadCount,
    bool? isOnline,
  }) {
    return ChatContact(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarText: avatarText ?? this.avatarText,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      roomId: roomId ?? this.roomId,
      statusMessage: statusMessage ?? this.statusMessage,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTimeLabel: lastMessageTimeLabel ?? this.lastMessageTimeLabel,
      unreadCount: unreadCount ?? this.unreadCount,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}
