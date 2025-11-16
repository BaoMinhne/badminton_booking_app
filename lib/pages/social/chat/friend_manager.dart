import 'package:flutter/foundation.dart';

import '../../../models/chat_contact.dart';
import '../../../models/friend_request.dart';
import '../../../models/friendship.dart';
import '../../../models/user_summary.dart';
import '../../../services/friend_service.dart';
import '../../../services/user_service.dart';

class FriendManager with ChangeNotifier {
  FriendManager()
      : _friendService = FriendService(),
        _userService = UserDetailsService();

  final FriendService _friendService;
  final UserDetailsService _userService;

  List<Friendship> _friends = [];
  List<FriendRequest> _incomingRequests = [];
  List<FriendRequest> _outgoingRequests = [];
  bool _isLoadingFriends = false;
  bool _isLoadingRequests = false;
  String? _currentUserId;
  String? _error;

  List<Friendship> get friends => _friends;
  List<FriendRequest> get incomingRequests => _incomingRequests;
  List<FriendRequest> get outgoingRequests => _outgoingRequests;
  bool get isLoadingFriends => _isLoadingFriends;
  bool get isLoadingRequests => _isLoadingRequests;
  String? get errorMessage => _error;

  Future<void> loadInitial() async {
    await Future.wait([
      refreshFriends(),
      refreshRequests(),
    ]);
  }

  Future<void> refreshFriends() async {
    _isLoadingFriends = true;
    notifyListeners();
    try {
      _currentUserId ??= await _userService.getCurrentUserId();
      _friends = await _friendService.fetchFriends();
      _error = null;
    } catch (error) {
      _error = error.toString();
    } finally {
      _isLoadingFriends = false;
      notifyListeners();
    }
  }

  Future<void> refreshRequests() async {
    _isLoadingRequests = true;
    notifyListeners();
    try {
      _currentUserId ??= await _userService.getCurrentUserId();
      final results = await Future.wait([
        _friendService.fetchIncomingRequests(),
        _friendService.fetchOutgoingRequests(),
      ]);
      _incomingRequests = results[0];
      _outgoingRequests = results[1];
      _error = null;
    } catch (error) {
      _error = error.toString();
    } finally {
      _isLoadingRequests = false;
      notifyListeners();
    }
  }

  List<ChatContact> get friendContacts {
    return _friends
        .map((friendship) => friendship.toChatContact(_currentUserId))
        .whereType<ChatContact>()
        .toList(growable: false);
  }

  Future<void> sendFriendRequest(String targetUserId) async {
    try {
      final request = await _friendService.sendFriendRequest(targetUserId);
      _outgoingRequests = [request, ..._outgoingRequests];
      _error = null;
      notifyListeners();
    } catch (error) {
      _error = error.toString();
      rethrow;
    }
  }

  Future<void> cancelRequest(String requestId) async {
    await _friendService.cancelFriendRequest(requestId);
    _outgoingRequests =
        _outgoingRequests.where((req) => req.id != requestId).toList();
    notifyListeners();
  }

  Future<void> rejectRequest(String requestId) async {
    await _friendService.rejectFriendRequest(requestId);
    _incomingRequests =
        _incomingRequests.where((req) => req.id != requestId).toList();
    notifyListeners();
  }

  Future<void> acceptRequest(String requestId) async {
    final friendship = await _friendService.acceptFriendRequest(requestId);
    _incomingRequests =
        _incomingRequests.where((req) => req.id != requestId).toList();
    _friends = [friendship, ..._friends];
    notifyListeners();
  }

  Future<void> unfriend(String friendUserId) async {
    await _friendService.unfriend(friendUserId);
    _friends = _friends
        .where((friendship) =>
            friendship.userAId != friendUserId &&
            friendship.userBId != friendUserId)
        .toList();
    notifyListeners();
  }

  ChatContact? contactFromSummary(UserSummary? summary) {
    if (summary == null) return null;
    return ChatContact(
      id: summary.id,
      name: summary.displayName,
      avatarText: summary.initials,
      avatarUrl: summary.avatarUrl,
    );
  }
}
