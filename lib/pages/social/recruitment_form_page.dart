import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RecruitmentFormPage extends StatefulWidget {
  const RecruitmentFormPage({super.key});

  @override
  State<RecruitmentFormPage> createState() => _RecruitmentFormPageState();
}

class _RecruitmentFormPageState extends State<RecruitmentFormPage> {
  final TextEditingController _noteController = TextEditingController();
  bool _hasBookedCourt = true;
  int _memberCount = 3;
  String _skillLevel = 'Trung bình khá';
  String? _selectedCourt;
  DateTime _selectedDateTime = DateTime.now().add(const Duration(hours: 2));

  final List<String> _availableCourts = const [
    'Sân Quận 7 - Court A',
    'Sân Quận 1 - Court B',
    'Sân Phú Nhuận - Court C',
  ];

  final List<String> _skillLevels = const [
    'Mới chơi',
    'Trung bình',
    'Trung bình khá',
    'Nâng cao',
    'Chuyên nghiệp',
  ];

  @override
  void initState() {
    super.initState();
    _selectedCourt = _availableCourts.first;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );
    if (time == null) return;

    setState(() {
      _selectedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo bài tuyển thành viên'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildIntroCard(cs, textTheme),
              const SizedBox(height: 24),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Tôi đã đặt sân trước'),
                value: _hasBookedCourt,
                onChanged: (value) => setState(() => _hasBookedCourt = value),
              ),
              const SizedBox(height: 16),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: _hasBookedCourt
                    ? _buildCourtInfo(cs, textTheme)
                    : _buildRecruitmentInfo(cs, textTheme),
              ),
              const SizedBox(height: 24),
              Text('Trình độ mong muốn', style: textTheme.titleMedium),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _skillLevels.map(
                  (level) {
                    final isSelected = _skillLevel == level;
                    return ChoiceChip(
                      label: Text(level),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _skillLevel = level),
                      selectedColor: cs.primaryContainer,
                      labelStyle: textTheme.bodyMedium?.copyWith(
                        color: isSelected ? cs.primary : cs.onSurface,
                        fontWeight: isSelected ? FontWeight.bold : null,
                      ),
                    );
                  },
                ).toList(),
              ),
              const SizedBox(height: 24),
              Text('Ghi chú cho thành viên', style: textTheme.titleMedium),
              const SizedBox(height: 12),
              TextField(
                controller: _noteController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText:
                      'Ví dụ: Mang theo vợt cá nhân, đến sớm 10 phút để khởi động...',
                  filled: true,
                  fillColor: cs.surfaceVariant.withOpacity(0.6),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.send_rounded),
                label: const Text('Đăng bài tuyển thành viên'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  textStyle: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntroCard(ColorScheme cs, TextTheme textTheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: cs.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(12),
            child: Icon(Icons.groups_2_rounded, color: cs.onPrimary, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gom đội nhanh chóng',
                  style: textTheme.titleMedium?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tạo bài đăng để tuyển thành viên phù hợp. Bạn có thể đính kèm thông tin sân đã đặt hoặc chỉ định số lượng cần tuyển.',
                  style: textTheme.bodyMedium?.copyWith(color: cs.onPrimaryContainer),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourtInfo(ColorScheme cs, TextTheme textTheme) {
    return Column(
      key: const ValueKey('court-info'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Thông tin sân đã đặt', style: textTheme.titleMedium),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _selectedCourt,
          decoration: _inputDecoration(cs, 'Chọn sân đã đặt'),
          items: _availableCourts
              .map(
                (court) => DropdownMenuItem(
                  value: court,
                  child: Text(court),
                ),
              )
              .toList(),
          onChanged: (value) => setState(() => _selectedCourt = value),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _pickDateTime,
          child: InputDecorator(
            decoration: _inputDecoration(cs, 'Giờ đánh dự kiến'),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(DateFormat('HH:mm - dd/MM/yyyy').format(_selectedDateTime)),
                const Icon(Icons.calendar_month_outlined),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildMemberCounter(cs, textTheme),
      ],
    );
  }

  Widget _buildRecruitmentInfo(ColorScheme cs, TextTheme textTheme) {
    return Column(
      key: const ValueKey('recruitment-info'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Số lượng thành viên cần tuyển', style: textTheme.titleMedium),
        const SizedBox(height: 12),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            valueIndicatorColor: cs.primary,
          ),
          child: Slider(
            min: 1,
            max: 8,
            divisions: 7,
            label: '$_memberCount người',
            value: _memberCount.toDouble(),
            onChanged: (value) => setState(() => _memberCount = value.round()),
          ),
        ),
        _buildMemberCounter(cs, textTheme),
      ],
    );
  }

  Widget _buildMemberCounter(ColorScheme cs, TextTheme textTheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(0.6),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: cs.primary,
            child: Icon(Icons.group_add, color: cs.onPrimary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cần tuyển thêm $_memberCount thành viên',
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Nhấn đăng bài để cộng đồng cùng tham gia.',
                  style: textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(ColorScheme cs, String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: cs.surfaceVariant.withOpacity(0.6),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }
}
