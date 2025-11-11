import 'package:flutter/material.dart';

import '../models/post_comment.dart';
import '../pages/social/social_manager.dart';

class PostCommentsSheet extends StatefulWidget {
  const PostCommentsSheet({
    super.key,
    required this.postId,
    required this.manager,
  });

  final String postId;
  final SocialManager manager;

  @override
  State<PostCommentsSheet> createState() => _PostCommentsSheetState();
}

class _PostCommentsSheetState extends State<PostCommentsSheet> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadComments();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    try {
      await widget.manager.loadComments(widget.postId, forceRefresh: true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      return;
    }

    try {
      await widget.manager.addComment(widget.postId, text);
      if (!mounted) return;
      _controller.clear();
      _focusNode.requestFocus();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final height = media.size.height * 0.65;
    final bottomInset = media.viewInsets.bottom;

    return SafeArea(
      top: false,
      child: AnimatedBuilder(
        animation: widget.manager,
        builder: (context, _) {
          final comments = widget.manager.commentsFor(widget.postId);
          final isLoading = widget.manager.isLoadingComments(widget.postId);
          final isSubmitting = widget.manager.isSubmittingComment(widget.postId);

          return Container(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomInset),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SizedBox(
              height: height,
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  Expanded(
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : comments.isEmpty
                            ? const Center(child: Text('Chưa có bình luận nào.'))
                            : ListView.separated(
                                padding: EdgeInsets.zero,
                                itemCount: comments.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 16),
                                itemBuilder: (_, index) {
                                  final comment = comments[index];
                                  return _CommentTile(comment: comment);
                                },
                              ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _submit(),
                          decoration: const InputDecoration(
                            hintText: 'Viết bình luận...',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: isSubmitting ? null : _submit,
                        child: isSubmitting
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2.2),
                              )
                            : const Icon(Icons.send_rounded, size: 20),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment});

  final PostComment comment;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor:
              comment.authorAvatarUrl == null ? cs.primary : Colors.transparent,
          backgroundImage: comment.authorAvatarUrl != null
              ? NetworkImage(comment.authorAvatarUrl!)
              : null,
          child: comment.authorAvatarUrl == null
              ? Text(
                  comment.authorName.isNotEmpty
                      ? comment.authorName[0].toUpperCase()
                      : 'U',
                  style: TextStyle(
                    color: cs.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                comment.authorName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(comment.content),
              const SizedBox(height: 6),
              Text(
                _timeAgo(comment.createdAt),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _timeAgo(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    final weeks = (diff.inDays / 7).floor();
    if (weeks < 5) return '$weeks tuần trước';
    final months = (diff.inDays / 30).floor();
    if (months < 12) return '$months tháng trước';
    final years = (diff.inDays / 365).floor();
    return '$years năm trước';
  }
}
