import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MyPost extends StatelessWidget {
  final String userName;
  final DateTime time;
  final String? content;
  final List<String> imageUrls;
  final VoidCallback? onLikePressed;

  const MyPost({
    super.key,
    required this.userName,
    required this.time,
    this.content,
    this.imageUrls = const <String>[],
    this.onLikePressed,
  });

  @override
  Widget build(BuildContext context) {
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
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 35,
                        color: Colors.white,
                      ),
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

              if (content != null && content!.isNotEmpty)
                Padding(
                  padding:
                      const EdgeInsets.only(left: 20, right: 20, bottom: 10),
                  child: Text(
                    content!,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 20,
                    ),
                  ),
                ),
              if (imageUrls.isNotEmpty)
                Column(
                  children: imageUrls
                      .map(
                        (url) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(0),
                            child: Image.network(
                              url,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          ),
                        ),
                      )
                      .toList(),
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
                    const SizedBox(width: 8),
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
