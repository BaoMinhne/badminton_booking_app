import 'package:badminton_booking_app/models/chat_contact.dart';
import 'package:badminton_booking_app/models/friend_relation.dart';
import 'package:badminton_booking_app/models/friend_search_result.dart';
import 'package:badminton_booking_app/pages/social/chat/friend_manager.dart';
import 'package:badminton_booking_app/pages/social/chat/widgets/contact_list_tile.dart';
import 'package:badminton_booking_app/pages/user/user_public_profile_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AddFriendPage extends StatefulWidget {
  const AddFriendPage({super.key});

  @override
  State<AddFriendPage> createState() => _AddFriendPageState();
}

class _AddFriendPageState extends State<AddFriendPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FriendManager>().loadFriendSuggestions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final friendManager = context.watch<FriendManager>();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        title: const Text('Add friend'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
          children: [
            Text(
              'Find friends',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildSearchField(cs, friendManager),
            const SizedBox(height: 16),
            if (friendManager.currentQuery.trim().isNotEmpty)
              _buildSearchResults(context, friendManager, theme),
            const SizedBox(height: 24),
            Text(
              'Friend suggestions',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildSuggestions(context, friendManager, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField(ColorScheme cs, FriendManager friendManager) {
    return SizedBox(
      height: 60,
      child: TextField(
        onChanged: friendManager.searchDebounced,
        cursorColor: cs.primary,
        style: TextStyle(
          fontSize: 18,
          color: cs.onSurface,
        ),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 24,
            color: Colors.grey.shade600,
          ),
          hintText: 'Search friends',
          hintStyle: TextStyle(
            fontSize: 18,
            color: Colors.grey.shade600,
          ),
          filled: true,
          fillColor: cs.secondary.withOpacity(0.1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: BorderSide(
              color: cs.outline,
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: BorderSide(
              color: cs.primary,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults(
    BuildContext context,
    FriendManager friendManager,
    ThemeData theme,
  ) {
    if (friendManager.isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (friendManager.error != null) {
      return Text(friendManager.error!, style: theme.textTheme.bodyMedium);
    }

    if (friendManager.searchResults.isEmpty) {
      return Text(
        'No matching users found.',
        style: theme.textTheme.bodyMedium,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Search results',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...friendManager.searchResults.map(
          (result) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ContactListTile.suggestion(
              contact: ChatContact(
                id: result.user.id,
                name: result.displayName,
                avatarText: result.initials,
                statusMessage: result.subtitle.isEmpty ? null : result.subtitle,
              ),
              trailing: _buildTrailingActions(
                context,
                friendManager,
                result,
              ),
              onTap: () => _openProfile(context, result),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestions(
    BuildContext context,
    FriendManager friendManager,
    ThemeData theme,
  ) {
    if (friendManager.isLoadingSuggestions) {
      return const Center(child: CircularProgressIndicator());
    }

    if (friendManager.suggestionsError != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              friendManager.suggestionsError!,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          TextButton(
            onPressed: () => friendManager.loadFriendSuggestions(),
            child: const Text('Retry'),
          ),
        ],
      );
    }

    if (friendManager.friendSuggestions.isEmpty) {
      return Text(
        'No friend suggestions right now.',
        style: theme.textTheme.bodyMedium,
      );
    }

    final visibleSuggestions = friendManager.friendSuggestions
        .take(friendManager.visibleSuggestions)
        .toList();

    return Column(
      children: [
        ...visibleSuggestions.map(
          (result) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ContactListTile.suggestion(
              contact: ChatContact(
                id: result.user.id,
                name: result.displayName,
                avatarText: result.initials,
                statusMessage:
                    result.subtitle.isEmpty ? null : result.subtitle,
              ),
              trailing: _buildTrailingActions(
                context,
                friendManager,
                result,
              ),
              onTap: () => _openProfile(context, result),
            ),
          ),
        ),
        if (friendManager.visibleSuggestions <
            friendManager.friendSuggestions.length)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: friendManager.showMoreSuggestions,
              child: const Text('Show more'),
            ),
          ),
      ],
    );
  }

  Future<void> _handleFriendAction(
    BuildContext context,
    FriendManager friendManager,
    FriendSearchResult result,
  ) async {
    final relation = friendManager.relationFor(result.user.id);
    final isPending = relation.type == FriendRelationType.outgoingRequest;

    if (isPending) {
      final confirmed = await _showConfirmDialog(
        context,
        title: 'Cancel friend request?',
        message:
            'Are you sure you want to cancel the request sent to ${result.displayName}?',
      );
      if (!confirmed) return;
    }

    try {
      if (isPending) {
        await friendManager.cancelPendingRequest(result.user.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Canceled the friend request.')),
          );
        }
      } else if (relation.type == FriendRelationType.none) {
        await friendManager.sendFriendRequest(result);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Friend request sent.')),
          );
        }
      }
    } catch (err) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$err')),
        );
      }
    }
  }

  Future<bool> _showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Back'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  void _openProfile(BuildContext context, FriendSearchResult result) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UserPublicProfilePage(result: result),
      ),
    );
  }

  Widget _buildTrailingActions(
    BuildContext context,
    FriendManager friendManager,
    FriendSearchResult result,
  ) {
    final relation = friendManager.relationFor(result.user.id);
    final isProcessing = friendManager.isActionInProgress(result.user.id);
    final cs = Theme.of(context).colorScheme;

    final actions = <Widget>[];

    switch (relation.type) {
      case FriendRelationType.friends:
        actions.add(
          FilledButton.tonal(
            onPressed: null,
            child: const Text('Friends'),
          ),
        );
        break;
      case FriendRelationType.incomingRequest:
        actions.addAll([
          FilledButton(
            onPressed: isProcessing
                ? null
                : () => _handleAcceptRequest(context, friendManager, result),
            child: const Text('Accept'),
          ),
          FilledButton.tonal(
            onPressed: isProcessing
                ? null
                : () => _handleRejectRequest(context, friendManager, result),
            style: FilledButton.styleFrom(
              backgroundColor: cs.errorContainer,
              foregroundColor: cs.onErrorContainer,
            ),
            child: const Text('Remove'),
          ),
        ]);
        break;
      case FriendRelationType.outgoingRequest:
      case FriendRelationType.none:
        final label = _primaryActionLabel(friendManager, result) ?? 'Add friend';
        actions.add(
          isProcessing
              ? const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(strokeWidth: 2.6),
                )
              : FilledButton(
                  style: relation.type == FriendRelationType.outgoingRequest
                      ? FilledButton.styleFrom(
                          backgroundColor: cs.secondaryContainer,
                          foregroundColor: cs.onSecondaryContainer,
                        )
                      : null,
                  onPressed: () =>
                      _handleFriendAction(context, friendManager, result),
                  child: Text(label),
                ),
        );
        break;
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: actions,
    );
  }

  String? _primaryActionLabel(
    FriendManager friendManager,
    FriendSearchResult result,
  ) {
    final relation = friendManager.relationFor(result.user.id);

    switch (relation.type) {
      case FriendRelationType.none:
        return 'Add friend';
      case FriendRelationType.outgoingRequest:
        return 'Cancel request';
      case FriendRelationType.incomingRequest:
      case FriendRelationType.friends:
        return null;
    }
  }

  Future<void> _handleAcceptRequest(
    BuildContext context,
    FriendManager friendManager,
    FriendSearchResult result,
  ) async {
    try {
      await friendManager.acceptIncomingRequest(result);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You and ${result.displayName} are now friends.'),
          ),
        );
      }
    } catch (err) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$err')),
        );
      }
    }
  }

  Future<void> _handleRejectRequest(
    BuildContext context,
    FriendManager friendManager,
    FriendSearchResult result,
  ) async {
    final confirmed = await _showConfirmDialog(
      context,
      title: 'Delete friend request?',
      message: 'Are you sure you want to delete the request from ${result.displayName}?',
    );

    if (!confirmed) return;

    try {
      await friendManager.rejectIncomingRequest(result);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Deleted the friend request.')),
        );
      }
    } catch (err) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$err')),
        );
      }
    }
  }
}
