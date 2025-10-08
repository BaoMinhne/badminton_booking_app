// lib/components/my_court_time.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;

import '../models/court_booking.dart';

class CourtTimelineReservation {
  CourtTimelineReservation({
    required this.courtUnitId,
    required this.start,
    required this.end,
    required this.status,
    this.lockedUntil,
    this.isMine = false,
  });

  final String courtUnitId;
  final DateTime start;
  final DateTime end;
  final CourtBookingStatus status;
  final DateTime? lockedUntil;
  final bool isMine;

  bool get _isLockActive {
    if (status != CourtBookingStatus.locked) return false;
    final until = lockedUntil;
    if (until == null) return false;
    return until.isAfter(DateTime.now());
  }

  bool get blocksSelection {
    switch (status) {
      case CourtBookingStatus.pending:
      case CourtBookingStatus.confirmed:
        return true;
      case CourtBookingStatus.locked:
        return _isLockActive;
      case CourtBookingStatus.cancelled:
        return false;
    }
  }

  bool overlaps(DateTime slotStart, DateTime slotEnd) {
    return start.isBefore(slotEnd) && end.isAfter(slotStart);
  }
}

class CourtTimelineSlotTap {
  CourtTimelineSlotTap({
    required this.courtIndex,
    required this.courtUnitId,
    required this.start,
    required this.end,
  });

  final int courtIndex;
  final String courtUnitId;
  final DateTime start;
  final DateTime end;
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
    this.reservations = const [],
    this.onSlotTap,
    this.slotDuration = const Duration(hours: 1),
    this.courtUnitIds,
    this.day,
  });

  final int startHour;
  final int endHour; // exclusive
  final double slotWidth;
  final double rowHeight;
  final List<String> courts;
  final List<String>? courtUnitIds;
  final double leftColumnWidth;
  final double headerHeight;
  final double headerLeadingInset;
  final List<CourtTimelineReservation> reservations;
  final Duration slotDuration;
  final ValueChanged<CourtTimelineSlotTap>? onSlotTap;
  final DateTime? day;

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

  List<String> get _resolvedCourtUnitIds {
    final units = widget.courtUnitIds;
    if (units != null && units.length == widget.courts.length) {
      return units;
    }
    return List<String>.generate(widget.courts.length, (index) => '${index + 1}');
  }

  Map<String, List<CourtTimelineReservation>> get _reservationsByUnit {
    final map = <String, List<CourtTimelineReservation>>{};
    for (final reservation in widget.reservations) {
      map.putIfAbsent(reservation.courtUnitId, () => []).add(reservation);
    }
    return map;
  }

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
                          itemBuilder: (_, row) {
                            final unitId = _resolvedCourtUnitIds[row];
                            final reservations = _reservationsByUnit[unitId] ??
                                const <CourtTimelineReservation>[];
                            return SizedBox(
                              height: widget.rowHeight,
                              child: _TimelineRow(
                                totalSlots: _slotCount,
                                slotWidth: widget.slotWidth,
                                dividerColor: dividerColor,
                                reservations: reservations,
                                rowIndex: row,
                                unitId: unitId,
                                slotDuration: widget.slotDuration,
                                startHour: widget.startHour,
                                onSlotTap: widget.onSlotTap,
                                day: widget.day,
                              ),
                            );
                          },
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

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.totalSlots,
    required this.slotWidth,
    required this.dividerColor,
    required this.reservations,
    required this.rowIndex,
    required this.unitId,
    required this.slotDuration,
    required this.startHour,
    required this.onSlotTap,
    required this.day,
  });

  final int totalSlots;
  final double slotWidth;
  final Color dividerColor;
  final List<CourtTimelineReservation> reservations;
  final int rowIndex;
  final String unitId;
  final Duration slotDuration;
  final int startHour;
  final ValueChanged<CourtTimelineSlotTap>? onSlotTap;
  final DateTime? day;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GridRowPainter(
        totalSlots: totalSlots,
        slotWidth: slotWidth,
        lineColor: const Color(0x33000000),
        background: Colors.white,
      ),
      child: Row(
        children: List.generate(totalSlots, (index) {
          final slotStart = _buildSlotStart(index);
          final slotEnd = slotStart.add(slotDuration);
          final reservation = _findReservation(slotStart, slotEnd);
          final blocked = reservation?.blocksSelection ?? false;
          final tapHandler = onSlotTap;
          final color = _resolveColor(reservation);
          final label = _resolveLabel(reservation);

          return SizedBox(
            width: slotWidth,
            height: double.infinity,
            child: GestureDetector(
              onTap: tapHandler != null && !blocked
                  ? () => tapHandler(
                        CourtTimelineSlotTap(
                          courtIndex: rowIndex,
                          courtUnitId: unitId,
                          start: slotStart,
                          end: slotEnd,
                        ),
                      )
                  : null,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  border: Border(
                    right: BorderSide(color: dividerColor, width: 0.5),
                  ),
                ),
                alignment: Alignment.center,
                child: label == null
                    ? null
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0E5A3A),
                          ),
                        ),
                      ),
              ),
            ),
          );
        }),
      ),
    );
  }

  DateTime _buildSlotStart(int index) {
    final base = day ?? DateTime.now();
    return DateTime(base.year, base.month, base.day, startHour + index);
  }

  CourtTimelineReservation? _findReservation(
    DateTime slotStart,
    DateTime slotEnd,
  ) {
    for (final reservation in reservations) {
      if (reservation.overlaps(slotStart, slotEnd)) {
        return reservation;
      }
    }
    return null;
  }

  Color _resolveColor(CourtTimelineReservation? reservation) {
    if (reservation == null) {
      return Colors.white;
    }

    switch (reservation.status) {
      case CourtBookingStatus.pending:
      case CourtBookingStatus.confirmed:
        return const Color(0xFFFFCDD2);
      case CourtBookingStatus.locked:
        return reservation.isMine
            ? const Color(0xFFB0BEC5)
            : const Color(0xFFCFD8DC);
      case CourtBookingStatus.cancelled:
        return Colors.white;
    }
  }

  String? _resolveLabel(CourtTimelineReservation? reservation) {
    if (reservation == null) return null;
    switch (reservation.status) {
      case CourtBookingStatus.pending:
        return 'Chờ duyệt';
      case CourtBookingStatus.confirmed:
        return 'Đã đặt';
      case CourtBookingStatus.locked:
        return reservation.isMine ? 'Bạn giữ' : 'Giữ chỗ';
      case CourtBookingStatus.cancelled:
        return null;
    }
  }
}
