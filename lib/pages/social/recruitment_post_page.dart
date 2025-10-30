import 'package:flutter/material.dart';

class RecruitmentPostPage extends StatefulWidget {
  const RecruitmentPostPage({super.key});

  @override
  State<RecruitmentPostPage> createState() => _RecruitmentPostPageState();
}

class _RecruitmentPostPageState extends State<RecruitmentPostPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _requirementsController = TextEditingController();

  bool _linkExistingBooking = true;
  String? _selectedBookingId;
  int _desiredMembers = 2;
  String _selectedSkill = 'Trung bình';

  final List<_BookingOption> _bookingOptions = const [
    _BookingOption(
      id: 'booking-101',
      courtName: 'Sân 1 - Nhà thi đấu Q.1',
      date: '12/06/2024',
      timeRange: '18:00 - 19:30',
    ),
    _BookingOption(
      id: 'booking-102',
      courtName: 'Sân 3 - Trung tâm Quận 7',
      date: '14/06/2024',
      timeRange: '19:30 - 21:00',
    ),
  ];

  final List<String> _skillLevels = const [
    'Mới bắt đầu',
    'Trung bình',
    'Khá',
    'Chuyên nghiệp',
  ];

  @override
  void initState() {
    super.initState();
    if (_bookingOptions.isNotEmpty) {
      _selectedBookingId = _bookingOptions.first.id;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _requirementsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng tuyển thành viên'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Tiêu đề bài đăng',
                  hintText: 'Ví dụ: Tuyển thêm 2 thành viên đánh đôi',
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _descriptionController,
                minLines: 4,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Mô tả chi tiết',
                  hintText:
                      'Chia sẻ thời gian, phong cách chơi và thông tin liên hệ của bạn...',
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Switch(
                    value: _linkExistingBooking,
                    onChanged: (value) {
                      setState(() {
                        _linkExistingBooking = value;
                      });
                    },
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _linkExistingBooking
                          ? 'Liên kết với sân đã đặt'
                          : 'Tự chọn số lượng cần tuyển',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 250),
                crossFadeState: _linkExistingBooking
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                firstChild: _buildLinkedBookingCard(colorScheme),
                secondChild: _buildDesiredMemberSelector(colorScheme),
              ),
              const SizedBox(height: 24),
              Text(
                'Trình độ mong muốn',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _skillLevels.map((level) {
                  final bool isSelected = _selectedSkill == level;
                  return ChoiceChip(
                    label: Text(level),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() => _selectedSkill = level);
                    },
                    selectedColor: colorScheme.primaryContainer,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurface,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _requirementsController,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Yêu cầu thêm (không bắt buộc)',
                  hintText:
                      'Ví dụ: Mang vợt riêng, đúng giờ hoặc mức phí chia sẻ...',
                ),
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.send_rounded),
                  label: const Text('Đăng bài'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLinkedBookingCard(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: colorScheme.surfaceVariant.withOpacity(0.4),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chọn sân đã đặt',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedBookingId,
            items: _bookingOptions
                .map(
                  (booking) => DropdownMenuItem(
                    value: booking.id,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.courtName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text('${booking.date} • ${booking.timeRange}'),
                      ],
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedBookingId = value;
              });
            },
            decoration: const InputDecoration(
              labelText: 'Lịch đặt sân',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesiredMemberSelector(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: colorScheme.surfaceVariant.withOpacity(0.4),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bạn muốn tuyển bao nhiêu người?',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              IconButton(
                onPressed: _desiredMembers > 1
                    ? () => setState(() => _desiredMembers--)
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '$_desiredMembers người',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Slider(
                      value: _desiredMembers.toDouble(),
                      min: 1,
                      max: 6,
                      divisions: 5,
                      label: '$_desiredMembers',
                      onChanged: (value) {
                        setState(() {
                          _desiredMembers = value.round();
                        });
                      },
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _desiredMembers < 6
                    ? () => setState(() => _desiredMembers++)
                    : null,
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BookingOption {
  final String id;
  final String courtName;
  final String date;
  final String timeRange;

  const _BookingOption({
    required this.id,
    required this.courtName,
    required this.date,
    required this.timeRange,
  });
}
