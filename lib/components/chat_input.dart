import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ChatInput extends StatefulWidget {
  final Future<void> Function(String text) onSend;
  final Future<void> Function(XFile image)? onPickImage;
  final Color? backgroundColor;

  const ChatInput({
    super.key,
    required this.onSend,
    this.onPickImage,
    this.backgroundColor,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final _controller = TextEditingController();
  bool _isSending = false;

  final _picker = ImagePicker();

  Future<void> _handleSubmit() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;
    setState(() {
      _isSending = true;
    });
    try {
      await widget.onSend(text);
      _controller.clear();
    } finally {
      setState(() {
        _isSending = false;
      });
    }
    // để rebuild nút gửi (enable/disable)
  }

  Future<void> _handlePickImage() async {
    if (_isSending || widget.onPickImage == null) return;

    try {
      final image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      setState(() {
        _isSending = true;
      });

      await widget.onPickImage!(image);
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final primary = cs.primary;
    final bg =
        widget.backgroundColor ?? const Color(0xFF21002D); // nền tối giống hình

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: bg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 14,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // cụm icon trái
            _CircleIconButton(
              icon: Icons.add,
              color: primary,
              onTap: () {},
            ),

            const SizedBox(width: 10),
            _CircleIconButton(
              icon: Icons.image_outlined,
              color: primary,
              onTap: _handlePickImage,
            ),
            const SizedBox(width: 10),
            // ô nhập dài
            Expanded(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: 70,
                ),
                child: TextField(
                  controller: _controller,
                  keyboardType: TextInputType.multiline,
                  enabled: !_isSending,
                  onChanged: (_) => setState(() {}),
                  maxLines: null,
                  minLines: 1,
                  decoration: InputDecoration(
                    hintText: "Aa...",
                    hintStyle: TextStyle(color: Colors.black26),
                    filled: true,
                    fillColor: Color(0xFFececf8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  onSubmitted: (_) => _handleSubmit(),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: GestureDetector(
                onTap:
                    _controller.text.trim().isEmpty || _isSending ? null : _handleSubmit,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  opacity:
                      _controller.text.trim().isEmpty || _isSending ? 0.4 : 1.0,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      size: 25,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Nút tròn dùng nhiều lần
class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _CircleIconButton({
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 25,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// icon trái tim giống hình (có thể bỏ nếu không cần)
class _HeartPill extends StatelessWidget {
  final Color color;

  const _HeartPill({required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.favorite, color: color, size: 20),
        Transform.translate(
          offset: const Offset(-3, -6),
          child: Icon(Icons.favorite, color: color.withOpacity(.7), size: 14),
        ),
      ],
    );
  }
}
