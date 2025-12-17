import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

import '../../models/court.dart';
import '../../services/court_service.dart';

class CourtImagesPage extends StatefulWidget {
  const CourtImagesPage({super.key, required this.court});

  final Court court;

  @override
  State<CourtImagesPage> createState() => _CourtImagesPageState();
}

class _CourtImagesPageState extends State<CourtImagesPage> {
  final _service = CourtService();
  final _picker = ImagePicker();

  bool _loading = true;
  bool _uploading = false;
  String? _error;
  List<CourtImageFile> _images = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final images = await _service.listCourtImages(widget.court.id);
      if (mounted) {
        setState(() {
          _images = images;
        });
      }
    } catch (err) {
      if (mounted) {
        setState(() => _error = err.toString());
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickAndUpload() async {
    if (_uploading) return;
    final picked = await _picker.pickMultiImage();
    if (picked.isEmpty) return;

    setState(() => _uploading = true);

    try {
      final files = <http.MultipartFile>[];
      for (final file in picked) {
        final bytes = await file.readAsBytes();
        files.add(
          http.MultipartFile.fromBytes(
            'image',
            bytes,
            filename: p.basename(file.path),
          ),
        );
      }

      await _service.uploadCourtImages(courtId: widget.court.id, files: files);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã thêm hình ảnh cho sân.')),
        );
        await _load();
      }
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _removeImage(CourtImageFile image) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa hình ảnh'),
        content: const Text('Bạn có chắc muốn xóa hình ảnh này khỏi sân?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _service.removeCourtImage(
        recordId: image.recordId,
        fileName: image.fileName,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa hình ảnh.')),
        );
        await _load();
      }
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Hình ảnh sân'),
            Text(
              widget.court.name,
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _uploading ? null : _pickAndUpload,
        icon: _uploading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.add_photo_alternate_outlined),
        label: Text(_uploading ? 'Đang tải lên...' : 'Thêm hình ảnh'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(cs),
      ),
    );
  }

  Widget _buildBody(ColorScheme cs) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.redAccent),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh_outlined),
                  label: const Text('Thử lại'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (_images.isEmpty) {
      return ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.photo_library_outlined, size: 52, color: cs.primary),
                const SizedBox(height: 12),
                Text(
                  'Chưa có hình ảnh nào cho sân này.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _uploading ? null : _pickAndUpload,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: const Text('Thêm hình ảnh'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: _images.length,
      itemBuilder: (context, index) {
        final image = _images[index];
        return _ImageTile(
          image: image,
          onDelete: () => _removeImage(image),
        );
      },
    );
  }
}

class _ImageTile extends StatelessWidget {
  const _ImageTile({required this.image, required this.onDelete});

  final CourtImageFile image;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Ink.image(
            image: NetworkImage(image.url),
            fit: BoxFit.cover,
            child: const SizedBox.shrink(),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Material(
              color: Colors.black54,
              shape: const CircleBorder(),
              child: IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, color: Colors.white),
                tooltip: 'Xóa hình ảnh',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
