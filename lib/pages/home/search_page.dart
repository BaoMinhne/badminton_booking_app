import 'package:badminton_booking_app/components/my_court.dart';
import 'package:badminton_booking_app/components/my_text_field.dart';
import 'package:flutter/material.dart';

class SearchPage extends StatelessWidget {
  SearchPage({super.key});

  final TextEditingController searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tìm kiếm sân',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [cs.primary, cs.primary.withOpacity(0.85)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MyTextfield(
                hintText: "Tìm kiếm sân...",
                controller: searchController,
                prefixIcon: Icon(Icons.search_rounded, color: cs.primary),
                suffixIcon: IconButton(
                  icon: Icon(Icons.tune_rounded, color: cs.primary),
                  onPressed: () {
                    // Thêm logic filter nếu cần, hiện tại giữ nguyên
                  },
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  children: [
                    // Nội dung list sân (giữ nguyên rỗng như code cũ)
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
