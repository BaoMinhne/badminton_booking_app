import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MyPost extends StatelessWidget {
  final String message;
  final String userName;
  final DateTime time;
  final VoidCallback? onLikePressed;

  const MyPost({
    super.key,
    required this.message,
    required this.userName,
    required this.time,
    this.onLikePressed,
  });

  @override
  Widget build(BuildContext context) {
    final isImage = message.startsWith('http') ||
        message.startsWith('https') &&
            (message.contains('.jpg') ||
                message.contains('.png') ||
                message.contains('cloudinary'));
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

              // Post message
              isImage
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(0),
                      child: Center(
                        child: Image.network(
                          message,
                          fit: BoxFit.cover,
                          width: MediaQuery.of(context).size.width,
                        ),
                      ),
                    )
                  : Padding(
                      padding:
                          const EdgeInsets.only(left: 20, top: 10, bottom: 10),
                      child: Text(
                        message,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 20,
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
