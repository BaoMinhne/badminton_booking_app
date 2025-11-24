import 'package:flutter/foundation.dart';

enum FriendRelationType {
  none,
  outgoingRequest,
  incomingRequest,
  friends,
}

@immutable
class FriendRelationStatus {
  const FriendRelationStatus({
    required this.type,
    this.requestId,
  });

  const FriendRelationStatus.none()
      : type = FriendRelationType.none,
        requestId = null;

  final FriendRelationType type;
  final String? requestId;

  bool get isPending =>
      type == FriendRelationType.outgoingRequest ||
      type == FriendRelationType.incomingRequest;
}
