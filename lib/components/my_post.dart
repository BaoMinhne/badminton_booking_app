import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MyPost extends StatelessWidget {
  final String content;
  final String userName;
  final DateTime time;
  final List<String> imageUrls;
  final String? userAvatarUrl;
  final VoidCallback? onLikePressed;

  const MyPost({
    super.key,
    required this.content,
    required this.userName,
    required this.time,
    this.imageUrls = const [],
    this.userAvatarUrl,
    this.onLikePressed,
  });

  @override
  Widget build(BuildContext context) {
    final hasImages = imageUrls.isNotEmpty;
    final primaryImage = hasImages ? imageUrls.first : null;
    final trimmedContent = content.trim();
    final hasContent = trimmedContent.isNotEmpty;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(25),
        child: Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: cs.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.only(
                    top: 15, bottom: 15, left: 15, right: 15),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      backgroundImage:
                          userAvatarUrl != null ? NetworkImage(userAvatarUrl!) : null,
                      child: userAvatarUrl == null
                          ? const Icon(
                              Icons.person,
                              size: 28,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    const SizedBox(width: 15),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                        ),
                        Text(
                          DateFormat('dd-MM-yyyy HH:mm').format((time)),
                          style: const TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w400,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    const Icon(Icons.more_vert, color: Colors.grey, size: 30),
                  ],
                ),
              ),

              // Post message
              if (hasContent)
                Padding(
                  padding: const EdgeInsets.only(left: 20, top: 10, bottom: 10),
                  child: Text(
                    trimmedContent,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 18,
                    ),
                  ),
                ),
              if (primaryImage != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(0),
                  child: Center(
                    child: Image.network(
                      primaryImage,
                      fit: BoxFit.cover,
                      width: MediaQuery.of(context).size.width,
                    ),
                  ),
                ),

              // Action bar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: onLikePressed,
                      child: Icon(
                        Icons.favorite_border,
                        color: Colors.grey,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '100',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w400,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      icon: const Icon(Icons.comment_outlined,
                          color: Colors.grey, size: 30),
                      onPressed: () {},
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.send_outlined,
                        color: Colors.grey, size: 30),
                    const Spacer(),
                    const Icon(Icons.bookmark_border,
                        color: Colors.grey, size: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
