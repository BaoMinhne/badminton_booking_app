import 'dart:convert';

import 'package:badminton_booking_app/models/friend_search_result.dart';
import 'package:badminton_booking_app/models/partner_recommendation.dart';
import 'package:badminton_booking_app/models/user.dart';
import 'package:badminton_booking_app/services/pocketbase_client.dart';
import 'package:badminton_booking_app/services/user_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:pocketbase/pocketbase.dart';

class RecommenderService {
  RecommenderService({http.Client? client})
      : _client = client ?? http.Client(),
        _userDetailsService = UserDetailsService();

  final http.Client _client;
  final UserDetailsService _userDetailsService;

  String get _baseUrl =>
      dotenv.env['RECOMMENDER_BASE_URL'] ?? 'http://10.0.2.2:8000';

  Future<List<PartnerRecommendation>> fetchRecommendations(
      {int limit = 10}) async {
    final pb = await getPocketbaseInstance();
    final currentUserId = pb.authStore.record?.id;
    if (currentUserId == null) {
      throw Exception('Bạn chưa đăng nhập.');
    }

    final uri = Uri.parse('$_baseUrl/recommend/players').replace(
      queryParameters: {
        'user_id': currentUserId,
        'limit': '$limit',
      },
    );

    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Không thể tải gợi ý ghép đôi. Vui lòng thử lại.');
    }

    final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;

    final results = await Future.wait(
      data.map((raw) => _mapCandidate(raw as Map<String, dynamic>, pb)),
    );

    return results;
  }

  Future<List<FriendSearchResult>> fetchFriendSuggestions(
      {int limit = 20}) async {
    final pb = await getPocketbaseInstance();
    final currentUserId = pb.authStore.record?.id;
    if (currentUserId == null) {
      throw Exception('Bạn chưa đăng nhập.');
    }

    final uri = Uri.parse('$_baseUrl/recommend/friends').replace(
      queryParameters: {
        'user_id': currentUserId,
        'limit': '$limit',
      },
    );

    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Không thể tải gợi ý kết bạn. Vui lòng thử lại.');
    }

    final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;

    final results = await Future.wait(
      data.map((raw) => _mapFriendCandidate(raw as Map<String, dynamic>, pb)),
    );

    return results;
  }

  Future<void> logRecommendationsShown(List<String> shownUserIds) async {
    final userId = await _requireCurrentUserId();

    await _postEvent(
      path: '/events/recommendations/shown',
      body: {
        'user_id': userId,
        'shown_user_ids': shownUserIds,
      },
    );
  }

  Future<void> logProfileClicked(String targetUserId) async {
    final userId = await _requireCurrentUserId();

    await _postEvent(
      path: '/events/recommendations/clicked_profile',
      body: {
        'user_id': userId,
        'target_user_id': targetUserId,
      },
    );
  }

  Future<void> logRecommendationAction({
    required String action,
    required String targetUserId,
  }) async {
    final userId = await _requireCurrentUserId();

    await _postEvent(
      path: '/events/recommendations/action',
      body: {
        'user_id': userId,
        'target_user_id': targetUserId,
        'action': action,
      },
    );
  }

  Future<void> logRecommendationOutcome({
    required String outcome,
    required String targetUserId,
  }) async {
    final userId = await _requireCurrentUserId();

    await _postEvent(
      path: '/events/recommendations/outcome',
      body: {
        'user_id': userId,
        'target_user_id': targetUserId,
        'outcome': outcome,
      },
    );
  }

  Future<PartnerRecommendation> _mapCandidate(
    Map<String, dynamic> json,
    PocketBase pb,
  ) async {
    final userJson =
        json['user'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final userId = (userJson['user_id'] ?? '') as String;
    final rawScore = (json['score'] as num?)?.toDouble() ?? 0;

    final details = await _userDetailsService.getByUserIdWithClient(pb, userId);
    final userRecord = await pb.collection('users').getOne(userId);
    final user = User.fromJson(userRecord.toJson());

    return PartnerRecommendation(
      friend: FriendSearchResult(user: user, details: details),
      matchScore: rawScore,
    );
  }

  Future<FriendSearchResult> _mapFriendCandidate(
    Map<String, dynamic> json,
    PocketBase pb,
  ) async {
    final userJson =
        json['user'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final userId = (userJson['user_id'] ?? '') as String;

    final details = await _userDetailsService.getByUserIdWithClient(pb, userId);
    final userRecord = await pb.collection('users').getOne(userId);
    final user = User.fromJson(userRecord.toJson());

    return FriendSearchResult(user: user, details: details);
  }

  Future<void> notifyInvitationSent({
    required String fromUserId,
    required String toUserId,
    String? invitationId,
    String? mode, // 'partner', 'friend', or null
  }) async {
    final uri = Uri.parse('$_baseUrl/events/invitations/sent');

    final body = jsonEncode({
      'from_user_id': fromUserId,
      'to_user_id': toUserId,
      'invitation_id': invitationId,
      'mode': mode,
    });

    final res = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (res.statusCode != 200) {
      throw Exception(
        'notifyInvitationSent failed: ${res.statusCode} -> ${res.body}',
      );
    }
  }

// ============================================================================
// NOTIFY: Accepted invitation
// ============================================================================
  Future<void> notifyInvitationAccepted({
    required String fromUserId, // người gửi invite
    required String toUserId, // người accept invite
    String? invitationId,
    String? mode,
  }) async {
    final uri = Uri.parse('$_baseUrl/events/invitations/accepted');

    final body = jsonEncode({
      'from_user_id': fromUserId,
      'to_user_id': toUserId,
      'invitation_id': invitationId,
      'mode': mode,
    });

    final res = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (res.statusCode != 200) {
      throw Exception(
        'notifyInvitationAccepted failed: ${res.statusCode} -> ${res.body}',
      );
    }
  }

  Future<String> _requireCurrentUserId() async {
    final pb = await getPocketbaseInstance();
    final currentUserId = pb.authStore.record?.id;
    if (currentUserId == null) {
      throw Exception('Bạn chưa đăng nhập.');
    }
    return currentUserId;
  }

  Future<void> _postEvent({
    required String path,
    required Map<String, dynamic> body,
  }) async {
    final uri = Uri.parse('$_baseUrl$path');
    final res = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (res.statusCode != 200) {
      throw Exception('Event $path failed: ${res.statusCode} -> ${res.body}');
    }
  }
}
