import 'dart:async';

import 'package:badminton_booking_app/components/my_court.dart';
import 'package:badminton_booking_app/components/my_text_field.dart';
import 'package:badminton_booking_app/models/court.dart';
import 'package:badminton_booking_app/services/court_service.dart';
import 'package:flutter/material.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController searchController = TextEditingController();
  final _courtService = CourtService();

  Timer? _debounce;
  bool _isLoading = false;
  String? _errorMessage;
  List<Court> _courts = const [];

  @override
  void initState() {
    super.initState();
    _fetchCourts();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _fetchCourts(query: value);
    });
  }

  Future<void> _fetchCourts({String? query}) async {
    final searchText = query ?? searchController.text;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final filter = _buildFilter(searchText);
      final result = await _courtService.listCourts(filter: filter);
      setState(() {
        _courts = result;
      });
    } catch (error) {
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String? _buildFilter(String raw) {
    final query = raw.trim();
    if (query.isEmpty) return null;

    final escaped = query.replaceAll("'", "\\'");
    return "name~'$escaped' || location~'$escaped'";
  }

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
                  onPressed: () {},
                ),
                onChanged: _onSearchChanged,
              ),
              const SizedBox(height: 20),
              Expanded(child: _buildResultList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => _fetchCourts(),
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            )
          ],
        ),
      );
    }

    if (_courts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.search_off_rounded, size: 48, color: Colors.black45),
            SizedBox(height: 12),
            Text(
              'Không tìm thấy sân phù hợp. Hãy thử từ khoá khác!',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemBuilder: (_, index) => MyCourt(court: _courts[index]),
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemCount: _courts.length,
    );
  }
}
