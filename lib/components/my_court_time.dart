// lib/components/my_court_time.dart
import 'package:badminton_booking_app/models/slot_reservation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;

typedef SlotStateResolver = SlotCellState? Function(
    int courtIndex, int slotIndex);

class SlotCellState {
  const SlotCellState({
    required this.status,
    this.holdUntil,
    this.note,
  });

  final SlotReservationStatus status;
  final DateTime? holdUntil;
  final String? note;
}

Color slotStatusBackground(
    SlotReservationStatus? status, ColorScheme _) {
  switch (status) {
    case SlotReservationStatus.holding:
      return const Color(0xFFFFF3CD); // vàng nhạt
    case SlotReservationStatus.awaitingApproval:
      return const Color(0xFFD6E4FF); // xanh dương nhạt
    case SlotReservationStatus.booked:
      return const Color(0xFFFFCDD2); // đỏ nhạt
    case SlotReservationStatus.locked:
      return const Color(0xFFEEEEEE); // xám nhạt
    case SlotReservationStatus.heldByOthers:
      return const Color(0xFFFFEBEE);
    case null:
      return Colors.white;
  }
}

Color slotStatusBorder(SlotReservationStatus? status, ColorScheme _) {
  switch (status) {
    case SlotReservationStatus.holding:
      return const Color(0xFFFFB300);
    case SlotReservationStatus.awaitingApproval:
      return const Color(0xFF3F51B5);
    case SlotReservationStatus.booked:
    case SlotReservationStatus.heldByOthers:
      return const Color(0xFFE53935);
    case SlotReservationStatus.locked:
      return const Color(0xFF9E9E9E);
    case null:
      return const Color(0xFFE0E0E0);
  }
}

/// Header kiểu “timeline” với vạch giờ & vạch 30’:
/// - Mỗi ô (grid) = 1 giờ.
/// - Header có LEADING INSET bên trái để label mốc đầu không bị cắt.
/// - Scroll đồng bộ: header = grid + inset.
class CourtTimeline extends StatefulWidget {
  const CourtTimeline({
    super.key,
    this.startHour = 6, // inclusive
    this.endHour = 22, // exclusive
    this.slotWidth = 80, // bề rộng 1 ô (1 giờ)
    this.rowHeight = 70,
    this.courts = const ['Sân 1', 'Sân 2'],
    this.leftColumnWidth = 90, // cột tên sân (cố định)
    this.headerHeight = 56.0,
    this.headerLeadingInset = 24.0, // khoảng trống trái của HEADER
    this.slotStateResolver,
    this.onSlotTap,
    this.slotInnerPadding = const EdgeInsets.all(4),
  });

  final int startHour;
  final int endHour; // exclusive
  final double slotWidth;
  final double rowHeight;
  final List<String> courts;
  final double leftColumnWidth;
  final double headerHeight;
  final double headerLeadingInset;
  final SlotStateResolver? slotStateResolver;
  final void Function(int courtIndex, int slotIndex)? onSlotTap;
  final EdgeInsets slotInnerPadding;

  @override
  State<CourtTimeline> createState() => _CourtTimelineState();
}

class _CourtTimelineState extends State<CourtTimeline> {
  // Controller: header có offset khởi tạo = inset
  late final ScrollController _headerCtrl;
  final ScrollController _gridCtrl = ScrollController();

  bool _syncing = false;

  // số ô (giờ)
  int get _slotCount => widget.endHour - widget.startHour + 1;

  // tổng bề rộng phần NỘI DUNG (lưới)
  double get _totalWidth => _slotCount * widget.slotWidth;

  @override
  void initState() {
    super.initState();
    // Header bắt đầu ở vị trí = inset để thấy trọn label mốc đầu
    _headerCtrl =
        ScrollController(initialScrollOffset: widget.headerLeadingInset);

    // Đồng bộ header -> grid (trừ inset)
    _headerCtrl.addListener(() {
      if (_syncing) return;
      _syncing = true;
      final mapped = (_headerCtrl.offset - widget.headerLeadingInset)
          .clamp(0.0, _totalWidth);
      _gridCtrl.jumpTo(mapped);
      _syncing = false;
    });

    // Đồng bộ grid -> header (cộng inset)
    _gridCtrl.addListener(() {
      if (_syncing) return;
      _syncing = true;
      final mapped = (_gridCtrl.offset + widget.headerLeadingInset)
          .clamp(0.0, _totalWidth + widget.headerLeadingInset);
      _headerCtrl.jumpTo(mapped);
      _syncing = false;
    });
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    _gridCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dividerColor = cs.outline;

    return Column(
      children: [
        // ===================== HEADER =====================
        Container(
          height: widget.headerHeight,
          decoration: BoxDecoration(
            color: const Color(0xFFBDEFFF),
            border: Border(bottom: BorderSide(color: dividerColor)),
          ),
          child: Row(
            children: [
              // Phần header cuộn ngang
              Expanded(
                child: Scrollbar(
                  controller: _headerCtrl,
                  thumbVisibility: false,
                  child: SingleChildScrollView(
                    controller: _headerCtrl,
                    scrollDirection: Axis.horizontal,
                    child: Padding(
                      padding: EdgeInsets.only(left: widget.leftColumnWidth),
                      child: SizedBox(
                        width: _totalWidth + widget.headerLeadingInset,
                        height: widget.headerHeight,
                        child: CustomPaint(
                          painter: _TimeHeaderPainterHalfHour(
                            startHour: widget.startHour,
                            endHour: widget.endHour,
                            slotWidth: widget.slotWidth,
                            leadingInset: widget
                                .headerLeadingInset, // DỊCH vạch sang phải
                            // style giống ảnh mẫu
                            hourTickColor: const Color(0xFFFFB300),
                            halfTickColor: const Color(0xFFFFB300),
                            hourTickStroke: 2.5,
                            halfTickStroke: 2.0,
                            hourTickHeight: 16,
                            halfTickHeight: 12,
                            textStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF123B28),
                            ),
                            showHalf: false,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ===================== LƯỚI THỜI GIAN =====================
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cột trái: tên sân (cố định)
              SizedBox(
                width: widget.leftColumnWidth,
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: widget.courts.length,
                  itemBuilder: (_, i) => Container(
                    height: widget.rowHeight,
                    color: const Color(0xFFE7FFF0),
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(widget.courts[i],
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: dividerColor),
                ),
              ),

              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.black,
                        width: 2, // độ dày
                      ),
                    ),
                  ),
                  child: Scrollbar(
                    controller: _gridCtrl,
                    thumbVisibility: false,
                    child: SingleChildScrollView(
                      controller: _gridCtrl,
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: _totalWidth,
                        child: ListView.separated(
                          padding: EdgeInsets.zero,
                          itemCount: widget.courts.length,
                          itemBuilder: (_, row) => SizedBox(
                            height: widget.rowHeight,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                CustomPaint(
                                  painter: _GridRowPainter(
                                    totalSlots: _slotCount,
                                    slotWidth: widget.slotWidth,
                                    lineColor: const Color(0x33000000),
                                    background: Colors.white,
                                  ),
                                  child: const SizedBox.expand(),
                                ),
                                if (_totalWidth > 0)
                                  _SlotOverlay(
                                    row: row,
                                    slotCount: _slotCount,
                                    slotWidth: widget.slotWidth,
                                    startHour: widget.startHour,
                                    slotStateResolver: widget.slotStateResolver,
                                    onSlotTap: widget.onSlotTap,
                                    padding: widget.slotInnerPadding,
                                  ),
                              ],
                            ),
                          ),
                          separatorBuilder: (_, __) =>
                              Divider(height: 1, color: dividerColor),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SlotOverlay extends StatelessWidget {
  const _SlotOverlay({
    required this.row,
    required this.slotCount,
    required this.slotWidth,
    required this.startHour,
    required this.slotStateResolver,
    required this.onSlotTap,
    required this.padding,
  });

  final int row;
  final int slotCount;
  final double slotWidth;
  final int startHour;
  final SlotStateResolver? slotStateResolver;
  final void Function(int courtIndex, int slotIndex)? onSlotTap;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final cells = List.generate(slotCount, (index) {
      final state = slotStateResolver?.call(row, index);
      final background =
          slotStatusBackground(state?.status, Theme.of(context).colorScheme);
      final border =
          slotStatusBorder(state?.status, Theme.of(context).colorScheme);
      final canTap = onSlotTap != null &&
          (state == null || state.status == SlotReservationStatus.holding);

      return SizedBox(
        width: slotWidth,
        child: Padding(
          padding: padding,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: canTap ? () => onSlotTap!(row, index) : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: border, width: 1.4),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: _SlotCellContent(
                hourLabel: '${startHour + index}:00',
                state: state,
              ),
            ),
          ),
        ),
      );
    });

    return IgnorePointer(
      ignoring: onSlotTap == null,
      child: SizedBox(
        width: slotCount * slotWidth,
        child: Row(children: cells),
      ),
    );
  }
}

class _SlotCellContent extends StatelessWidget {
  const _SlotCellContent({required this.hourLabel, this.state});

  final String hourLabel;
  final SlotCellState? state;

  @override
  Widget build(BuildContext context) {
    final texts = <String>[hourLabel];
    final status = state?.status;
    final holdUntil = state?.holdUntil;
    final note = state?.note;

    if (status != null) {
      switch (status) {
        case SlotReservationStatus.holding:
          if (holdUntil != null) {
            texts.add('Giữ đến ${DateFormat('HH:mm').format(holdUntil)}');
          } else {
            texts.add('Đang giữ chỗ');
          }
          break;
        case SlotReservationStatus.awaitingApproval:
          texts.add('Chờ admin duyệt');
          break;
        case SlotReservationStatus.booked:
          texts.add('Đã đặt');
          break;
        case SlotReservationStatus.locked:
          texts.add('Đã khóa');
          break;
        case SlotReservationStatus.heldByOthers:
          texts.add('Người khác đang giữ');
          break;
      }
    }

    if (note != null && note.isNotEmpty) {
      texts.add(note);
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: texts
          .map((text) => Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: text == hourLabel
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
              ))
          .toList(),
    );
  }
}

class _TimeHeaderPainterHalfHour extends CustomPainter {
  _TimeHeaderPainterHalfHour({
    required this.startHour,
    required this.endHour,
    required this.slotWidth,
    required this.textStyle,
    required this.hourTickColor,
    required this.halfTickColor,
    required this.hourTickStroke,
    required this.halfTickStroke,
    required this.hourTickHeight,
    required this.halfTickHeight,
    this.leadingInset = 0,
    this.showHalf = true,
  });

  final int startHour;
  final int endHour; // exclusive
  final double slotWidth;
  final TextStyle textStyle;
  final Color hourTickColor;
  final Color halfTickColor;
  final double hourTickStroke;
  final double halfTickStroke;
  final double hourTickHeight;
  final double halfTickHeight;
  final double leadingInset;
  final bool showHalf;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFFBDEFFF);
    canvas.drawRect(Offset.zero & size, bg);

    final slotCount = endHour - startHour;
    final totalWidth = slotCount * slotWidth; // phần nội dung (không gồm inset)

    final bottom = size.height - 6.0;
    final tp = TextPainter(textDirection: ui.TextDirection.ltr);

    for (int i = 0; i <= slotCount; i++) {
      final baseX = i * slotWidth;
      final hourX =
          (i == slotCount) ? leadingInset + totalWidth : leadingInset + baseX;

      // Vạch GIỜ
      final hourPaint = Paint()
        ..color = hourTickColor
        ..strokeWidth = hourTickStroke;
      final hourTop = bottom - hourTickHeight;
      canvas.drawLine(Offset(hourX, hourTop), Offset(hourX, bottom), hourPaint);

      // Label GIỜ nằm TRÊN vạch, canh giữa
      final hourVal = startHour + i;
      final labelHour =
          DateFormat('H:00').format(DateTime(2000, 1, 1, hourVal));
      tp.text = TextSpan(text: labelHour, style: textStyle);
      tp.layout();
      final hourTx = hourX - tp.width / 2;
      final hourTy = hourTop - tp.height - 2;
      tp.paint(canvas, Offset(hourTx, hourTy));

      // Vạch 30’ ở giữa ô (nếu bật)
      if (showHalf && i < slotCount) {
        final halfX = leadingInset + baseX + slotWidth / 2;
        final halfPaint = Paint()
          ..color = halfTickColor
          ..strokeWidth = halfTickStroke;
        final halfTop = bottom - halfTickHeight;
        canvas.drawLine(
            Offset(halfX, halfTop), Offset(halfX, bottom), halfPaint);

        final labelHalf =
            DateFormat('H:30').format(DateTime(2000, 1, 1, hourVal));
        tp.text = TextSpan(
            text: labelHalf,
            style: textStyle.copyWith(fontSize: textStyle.fontSize));
        tp.layout();
        final halfTx = halfX - tp.width / 2;
        final halfTy = halfTop - tp.height - 2;
        tp.paint(canvas, Offset(halfTx, halfTy));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TimeHeaderPainterHalfHour old) {
    return old.startHour != startHour ||
        old.endHour != endHour ||
        old.slotWidth != slotWidth ||
        old.textStyle != textStyle ||
        old.hourTickColor != hourTickColor ||
        old.halfTickColor != halfTickColor ||
        old.hourTickStroke != hourTickStroke ||
        old.halfTickStroke != halfTickStroke ||
        old.hourTickHeight != hourTickHeight ||
        old.halfTickHeight != halfTickHeight ||
        old.leadingInset != leadingInset ||
        old.showHalf != showHalf;
  }
}

/// Lưới theo ô 1 giờ: đường dọc tại mép ô (x = i * slotWidth)
class _GridRowPainter extends CustomPainter {
  _GridRowPainter({
    required this.totalSlots,
    required this.slotWidth,
    required this.lineColor,
    required this.background,
  });

  final int totalSlots;
  final double slotWidth;
  final Color lineColor;
  final Color background;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = background;
    canvas.drawRect(Offset.zero & size, bg);

    final line = Paint()
      ..color = lineColor
      ..strokeWidth = 1;

    final totalWidth = totalSlots * slotWidth;
    for (int i = 0; i <= totalSlots; i++) {
      final dx = (i == totalSlots) ? totalWidth : i * slotWidth;
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), line);
    }
  }

  @override
  bool shouldRepaint(covariant _GridRowPainter old) {
    return old.totalSlots != totalSlots ||
        old.slotWidth != slotWidth ||
        old.lineColor != lineColor ||
        old.background != background;
  }
}
