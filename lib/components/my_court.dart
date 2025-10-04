import 'package:badminton_booking_app/models/court.dart';
import 'package:badminton_booking_app/pages/court/court_detail.dart';
import 'package:flutter/material.dart';

class MyCourt extends StatefulWidget {
  const MyCourt({super.key, required this.court});

  final Court court;

  @override
  State<MyCourt> createState() => _MyCourtState();
}

class _MyCourtState extends State<MyCourt> {
  bool _isFavorite = false;

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final colorSchema = Theme.of(context).colorScheme;
    final court = widget.court;
    final courtName = court.name.isNotEmpty ? court.name : 'Sân không tên';
    final location =
        court.location.isNotEmpty ? court.location : 'Địa chỉ chưa cập nhật';
    final quantityText = court.courtQuantity > 0
        ? '${court.courtQuantity} sân'
        : 'Chưa rõ số sân';
    final courtPhone = court.phone.isNotEmpty ? court.phone : 'Chưa có số ĐT';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CourtDetail(court: court),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: screenWidth - 24,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colorSchema.outline, width: 1),
            ),
            child: Column(
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      child: _buildCoverImage(screenWidth),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: GestureDetector(
                        onTap: _toggleFavorite,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white70,
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Icon(
                            _isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: _isFavorite ? Colors.red : Colors.black54,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(50),
                          image: DecorationImage(
                            image: court.coverImageUrl != null
                                ? NetworkImage(court.coverImageUrl!)
                                    as ImageProvider
                                : const AssetImage(
                                    "assets/images/badminton_logo.jpg",
                                  ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              courtName,
                              style: const TextStyle(
                                color: Color(0xFF0E5A3A),
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    location,
                                    style: const TextStyle(
                                      color: Colors.black54,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      height: 1.2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                const Icon(Icons.sports_tennis,
                                    size: 16, color: Colors.black87),
                                const SizedBox(width: 6),
                                Text(
                                  quantityText,
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 7),
                                Text(
                                  '-',
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 7),
                                const Icon(Icons.phone, size: 15),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    courtPhone,
                                    style: TextStyle(
                                      color: colorSchema.primary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorSchema.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "ĐẶT LỊCH",
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCoverImage(double screenWidth) {
    final court = widget.court;
    final placeholder = Image.asset(
      'assets/images/court_cover.jpg',
      width: screenWidth,
      height: 150,
      fit: BoxFit.cover,
    );

    final coverImageUrl = court.coverImageUrl;
    if (coverImageUrl == null || coverImageUrl.isEmpty) {
      return placeholder;
    }

    return Image.network(
      coverImageUrl,
      width: screenWidth,
      height: 150,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return SizedBox(
          width: screenWidth,
          height: 150,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return placeholder;
      },
    );
  }
}
