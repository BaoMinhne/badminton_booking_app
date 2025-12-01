// lib/components/my_court_time.dart
import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/booking.dart';

class CourtTimelineRow {
  const CourtTimelineRow({
    required this.id,
    required this.label,
  });

  final String id;
  final String label;
}

/// Visual state for each cell in the time grid.
enum CourtSlotStatus {
  available,
  lockedPast,
  heldByMe,
  heldByOther,
  pendingApprovalMine, // mapped from awaiting_payment (mine)
  pendingApproval, // mapped from awaiting_payment (others)
  confirmed,
}

class CourtTimeline extends StatefulWidget {
  const CourtTimeline({
    super.key,
    required this.rows,
    required this.date,
    this.startHour = 6,
    this.endHour = 22,
    this.slotDuration = const Duration(hours: 1),
    this.slotWidth = 80,
    this.rowHeight = 70,
    this.leftColumnWidth = 90,
    this.headerHeight = 56.0,
    this.headerLeadingInset = 24.0,
    this.bookings = const [],
    this.selectedSlots = const {},
    this.currentUserId,
    this.onSlotTap,
  }) : assert(endHour > startHour, 'endHour must be greater than startHour');

  final List<CourtTimelineRow> rows;
  final DateTime date;
  final int startHour;
  final int endHour; // exclusive
  final Duration slotDuration;
  final double slotWidth;
  final double rowHeight;
  final double leftColumnWidth;
  final double headerHeight;
  final double headerLeadingInset;
  final List<CourtBooking> bookings;
  final Set<SelectedSlot> selectedSlots;
  final String? currentUserId;
  final void Function(SelectedSlot slot, bool shouldSelect)? onSlotTap;

  @override
  State<CourtTimeline> createState() => _CourtTimelineState();
}

class _CourtTimelineState extends State<CourtTimeline> {
  late final ScrollController _headerCtrl;
  final ScrollController _gridCtrl = ScrollController();
  late final ScrollController _leftColumnCtrl;
  final ScrollController _gridVerticalCtrl = ScrollController();

  bool _horizontalSyncing = false;
  bool _verticalSyncing = false;

  late Map<String, int> _rowIndexById;
  late List<List<CourtSlotStatus>> _statusMatrix;
  late DateTime _nowLocal;
  late DateTime _todayLocal;
  Timer? _clockTicker;

  _DragOperation _currentDragOp = _DragOperation.none;
  final Set<_CellCoordinate> _draggedCells = <_CellCoordinate>{};

  int get _slotCount {
    final totalMinutes = (widget.endHour - widget.startHour) * 60;
    final slotMinutes = widget.slotDuration.inMinutes;
    if (slotMinutes <= 0) {
      return 0;
    }
    return totalMinutes ~/ slotMinutes;
  }

  double get _totalWidth => _slotCount * widget.slotWidth;

  @override
  void initState() {
    super.initState();
    _headerCtrl =
        ScrollController(initialScrollOffset: widget.headerLeadingInset);
    _leftColumnCtrl = ScrollController();
    _rowIndexById = _buildRowIndexMap(widget.rows);
    _nowLocal = DateTime.now();
    _todayLocal = DateTime(_nowLocal.year, _nowLocal.month, _nowLocal.day);
    _statusMatrix = _buildStatusMatrix();
    _startClockTicker();

    _headerCtrl.addListener(_handleHeaderScroll);
    _gridCtrl.addListener(_handleGridHorizontalScroll);
    _leftColumnCtrl.addListener(_handleLeftVerticalScroll);
    _gridVerticalCtrl.addListener(_handleGridVerticalScroll);
  }

  @override
  void didUpdateWidget(covariant CourtTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.rows, widget.rows)) {
      _rowIndexById = _buildRowIndexMap(widget.rows);
    }

    if (!listEquals(oldWidget.bookings, widget.bookings) ||
        oldWidget.currentUserId != widget.currentUserId ||
        oldWidget.date != widget.date ||
        oldWidget.startHour != widget.startHour ||
        oldWidget.endHour != widget.endHour) {
      _nowLocal = DateTime.now();
      _todayLocal =
          DateTime(_nowLocal.year, _nowLocal.month, _nowLocal.day);
      _statusMatrix = _buildStatusMatrix();
    }
  }

  @override
  void dispose() {
    _headerCtrl
      ..removeListener(_handleHeaderScroll)
      ..dispose();
    _gridCtrl
      ..removeListener(_handleGridHorizontalScroll)
      ..dispose();
    _leftColumnCtrl
      ..removeListener(_handleLeftVerticalScroll)
      ..dispose();
    _gridVerticalCtrl
      ..removeListener(_handleGridVerticalScroll)
      ..dispose();
    _clockTicker?.cancel();
    super.dispose();
  }

  void _startClockTicker() {
    _clockTicker?.cancel();
    _clockTicker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted) return;
      setState(() {
        _nowLocal = DateTime.now();
        _todayLocal =
            DateTime(_nowLocal.year, _nowLocal.month, _nowLocal.day);
        _statusMatrix = _buildStatusMatrix();
      });
    });
  }

  void _handleHeaderScroll() {
    if (_horizontalSyncing) return;
    if (!_gridCtrl.hasClients) return;
    _horizontalSyncing = true;
    final mapped = (_headerCtrl.offset - widget.headerLeadingInset)
        .clamp(0.0, _totalWidth);
    _gridCtrl.jumpTo(mapped);
    _horizontalSyncing = false;
  }

  void _handleGridHorizontalScroll() {
    if (_horizontalSyncing) return;
    if (!_headerCtrl.hasClients) return;
    _horizontalSyncing = true;
    final mapped = (_gridCtrl.offset + widget.headerLeadingInset)
        .clamp(0.0, _totalWidth + widget.headerLeadingInset);
    _headerCtrl.jumpTo(mapped);
    _horizontalSyncing = false;
  }

  void _handleLeftVerticalScroll() {
    if (_verticalSyncing) return;
    if (!_gridVerticalCtrl.hasClients) return;
    _verticalSyncing = true;
    final offset = _leftColumnCtrl.offset
        .clamp(0.0, _gridVerticalCtrl.position.maxScrollExtent);
    _gridVerticalCtrl.jumpTo(offset);
    _verticalSyncing = false;
  }

  void _handleGridVerticalScroll() {
    if (_verticalSyncing) return;
    if (!_leftColumnCtrl.hasClients) return;
    _verticalSyncing = true;
    final offset = _gridVerticalCtrl.offset
        .clamp(0.0, _leftColumnCtrl.position.maxScrollExtent);
    _leftColumnCtrl.jumpTo(offset);
    _verticalSyncing = false;
  }

  Map<String, int> _buildRowIndexMap(List<CourtTimelineRow> rows) {
    final map = <String, int>{};
    for (var i = 0; i < rows.length; i++) {
      map[rows[i].id] = i;
    }
    return map;
  }

  List<List<CourtSlotStatus>> _buildStatusMatrix() {
    final matrix = List.generate(
      widget.rows.length,
      (_) => List<CourtSlotStatus>.filled(
        _slotCount,
        CourtSlotStatus.available,
        growable: false,
      ),
      growable: false,
    );

    if (widget.bookings.isEmpty || _slotCount == 0) {
      return _applyPastLocks(matrix);
    }

    final now = DateTime.now().toUtc();
    for (final booking in widget.bookings) {
      final rowIndex = _rowIndexById[booking.courtUnitId];
      if (rowIndex == null) continue;
      final status = _mapBookingToStatus(booking, now);
      if (status == CourtSlotStatus.available) continue;

      final startIndex = _indexFromDate(booking.startTime);
      final endIndex = _indexFromDate(booking.endTime);
      for (var column = startIndex; column < endIndex; column++) {
        if (column < 0 || column >= _slotCount) continue;
        final current = matrix[rowIndex][column];
        if (_statusPriority(status) >= _statusPriority(current)) {
          matrix[rowIndex][column] = status;
        }
      }
    }
    return _applyPastLocks(matrix);
  }

  List<List<CourtSlotStatus>> _applyPastLocks(
      List<List<CourtSlotStatus>> matrix) {
    final selectedDay = DateTime(
      widget.date.year,
      widget.date.month,
      widget.date.day,
    );

    if (selectedDay.isAfter(_todayLocal)) {
      return matrix;
    }

    final lockAll = selectedDay.isBefore(_todayLocal);
    for (var row = 0; row < matrix.length; row++) {
      for (var column = 0; column < matrix[row].length; column++) {
        if (matrix[row][column] != CourtSlotStatus.available) continue;
        if (lockAll || _isPastColumn(column)) {
          matrix[row][column] = CourtSlotStatus.lockedPast;
        }
      }
    }
    return matrix;
  }

  bool _isPastColumn(int column) {
    final slotStart = _slotStartAtColumn(column);
    return !slotStart.isAfter(_nowLocal);
  }

  DateTime _slotStartAtColumn(int column) {
    final base = DateTime(
      widget.date.year,
      widget.date.month,
      widget.date.day,
      widget.startHour,
    );
    return base.add(Duration(minutes: column * widget.slotDuration.inMinutes));
  }

  /// Map BookingStatus (DB) -> CourtSlotStatus (UI)
  CourtSlotStatus _mapBookingToStatus(CourtBooking booking, DateTime nowUtc) {
    switch (booking.status) {
      case BookingStatus.held:
        // Nếu hết hạn lock thì hiển thị available
        if (!booking.isActiveLock ||
            (booking.lockedUntil != null &&
                booking.lockedUntil!.isBefore(nowUtc))) {
          return CourtSlotStatus.available;
        }
        if (widget.currentUserId != null &&
            booking.userId == widget.currentUserId) {
          return CourtSlotStatus.heldByMe;
        }
        return CourtSlotStatus.heldByOther;

      case BookingStatus.awaitingPayment:
        // "Chờ thanh toán" (map sang pending* để tái dùng palette UI)
        if (widget.currentUserId != null &&
            booking.userId == widget.currentUserId) {
          return CourtSlotStatus.pendingApprovalMine;
        }
        return CourtSlotStatus.pendingApproval;

      case BookingStatus.confirmed:
        return CourtSlotStatus.confirmed;

      case BookingStatus.cancelled:
      case BookingStatus.expired:
        return CourtSlotStatus.available;
    }
  }

  int _statusPriority(CourtSlotStatus status) {
    // Ưu tiên cao hơn sẽ ghi đè cell (vd: confirmed > pending > held > available)
    switch (status) {
      case CourtSlotStatus.available:
        return 0;
      case CourtSlotStatus.lockedPast:
        return 1;
      case CourtSlotStatus.heldByMe:
        return 4;
      case CourtSlotStatus.pendingApprovalMine:
        return 5;
      case CourtSlotStatus.heldByOther:
        return 6;
      case CourtSlotStatus.pendingApproval:
        return 7;
      case CourtSlotStatus.confirmed:
        return 8;
    }
  }

  int _indexFromDate(DateTime dateTime) {
    final local = dateTime.toLocal();
    final dayStart = DateTime(
        widget.date.year, widget.date.month, widget.date.day, widget.startHour);
    final diffMinutes = local.difference(dayStart).inMinutes;
    final slotMinutes = widget.slotDuration.inMinutes;
    if (slotMinutes <= 0) return 0;
    return (diffMinutes / slotMinutes).floor();
  }

  SelectedSlot? _slotFromCell(int rowIndex, int column) {
    if (rowIndex < 0 || rowIndex >= widget.rows.length) return null;
    if (column < 0 || column >= _slotCount) return null;
    final base = DateTime(
        widget.date.year, widget.date.month, widget.date.day, widget.startHour);
    final start =
        base.add(Duration(minutes: column * widget.slotDuration.inMinutes));
    final end = start.add(widget.slotDuration);
    return SelectedSlot(
      courtUnitId: widget.rows[rowIndex].id,
      startTime: start,
      endTime: end,
    );
  }

  int? _columnFromDx(double dx) {
    if (dx.isNaN) return null;
    if (dx < 0) return null;
    final column = dx ~/ widget.slotWidth;
    if (column >= _slotCount) return null;
    return column;
  }

  bool _canSelect(CourtSlotStatus status) {
    // Có thể chọn khi ô còn trống hoặc đang do mình giữ
    return status == CourtSlotStatus.available ||
        status == CourtSlotStatus.heldByMe;
  }

  void _handleTap(int rowIndex, Offset position) {
    if (widget.onSlotTap == null) return;
    final column = _columnFromDx(position.dx);
    if (column == null) return;
    final slot = _slotFromCell(rowIndex, column);
    if (slot == null) return;

    final status = _statusMatrix[rowIndex][column];
    final isSelected = widget.selectedSlots.contains(slot);

    if (isSelected) {
      widget.onSlotTap!.call(slot, false);
    } else if (_canSelect(status)) {
      widget.onSlotTap!.call(slot, true);
    }
  }

  void _handlePanStart(int rowIndex, Offset position) {
    if (widget.onSlotTap == null) return;
    final column = _columnFromDx(position.dx);
    if (column == null) return;
    final slot = _slotFromCell(rowIndex, column);
    if (slot == null) return;
    final status = _statusMatrix[rowIndex][column];
    final isSelected = widget.selectedSlots.contains(slot);

    if (!isSelected && !_canSelect(status)) {
      _currentDragOp = _DragOperation.none;
      return;
    }

    _currentDragOp = isSelected ? _DragOperation.remove : _DragOperation.add;
    _draggedCells.clear();
    _applyDrag(rowIndex, column, slot);
  }

  void _handlePanUpdate(int rowIndex, Offset position) {
    if (widget.onSlotTap == null) return;
    if (_currentDragOp == _DragOperation.none) return;
    final column = _columnFromDx(position.dx);
    if (column == null) return;
    final slot = _slotFromCell(rowIndex, column);
    if (slot == null) return;
    _applyDrag(rowIndex, column, slot);
  }

  void _handlePanEnd() {
    _currentDragOp = _DragOperation.none;
    _draggedCells.clear();
  }

  void _applyDrag(int rowIndex, int column, SelectedSlot slot) {
    final cell = _CellCoordinate(rowIndex, column);
    if (_draggedCells.contains(cell)) return;

    final status = _statusMatrix[rowIndex][column];
    final isSelected = widget.selectedSlots.contains(slot);

    switch (_currentDragOp) {
      case _DragOperation.add:
        if (_canSelect(status) && !isSelected) {
          widget.onSlotTap?.call(slot, true);
        }
        break;
      case _DragOperation.remove:
        if (isSelected) {
          widget.onSlotTap?.call(slot, false);
        }
        break;
      case _DragOperation.none:
        break;
    }

    _draggedCells.add(cell);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dividerColor = cs.outlineVariant
        .withOpacity(0.5); // Softer divider for better aesthetics
    final colors = _SlotColors.fromColorScheme(cs);

    return Column(
      children: [
        Container(
          height: widget.headerHeight,
          decoration: BoxDecoration(
            color: const Color(0xFFBDEFFF),
            border: Border(
                bottom: BorderSide(
                    color: dividerColor,
                    width: 1.5)), // Thicker border for emphasis
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8)), // Rounded top corners
          ),
          child: Row(
            children: [
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
                        width: _totalWidth +
                            widget.headerLeadingInset +
                            20, // Extra padding to prevent label cutoff
                        height: widget.headerHeight,
                        child: CustomPaint(
                          painter: _TimeHeaderPainterHalfHour(
                            startHour: widget.startHour,
                            endHour: widget.endHour,
                            slotWidth: widget.slotWidth,
                            leadingInset: widget.headerLeadingInset,
                            hourTickColor: const Color(0xFFFFB300),
                            halfTickColor: const Color(0xFFFFB300)
                                .withOpacity(0.7), // Softer half tick
                            hourTickStroke: 2.5,
                            halfTickStroke: 2.0,
                            hourTickHeight: 18, // Slightly taller ticks
                            halfTickHeight: 14,
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
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: widget.leftColumnWidth,
                decoration: BoxDecoration(
                  color: const Color(0xFFE7FFF0),
                  border: Border(
                      right: BorderSide(
                          color: dividerColor,
                          width: 1.5)), // Right border for separation
                  borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(8)), // Rounded bottom corners
                ),
                child: Scrollbar(
                  controller: _leftColumnCtrl,
                  child: ListView.separated(
                    controller: _leftColumnCtrl,
                    padding: EdgeInsets.zero,
                    itemCount: widget.rows.length,
                    itemBuilder: (_, index) => Container(
                      height: widget.rowHeight,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(
                          horizontal:
                              16), // Increased padding for better spacing
                      child: Text(
                        widget.rows[index].label,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15, // Slightly larger font for readability
                          color:
                              Color(0xFF123B28), // Matching header text color
                        ),
                      ),
                    ),
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: dividerColor),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: dividerColor,
                        width: 1.5,
                      ),
                    ),
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(8)), // Rounded bottom corners
                  ),
                  child: Scrollbar(
                    controller: _gridCtrl,
                    thumbVisibility: false,
                    child: SingleChildScrollView(
                      controller: _gridCtrl,
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width:
                            _totalWidth + 20, // Extra width to prevent cutoff
                        child: Scrollbar(
                          controller: _gridVerticalCtrl,
                          child: ListView.separated(
                            controller: _gridVerticalCtrl,
                            padding: EdgeInsets.zero,
                            itemCount: widget.rows.length,
                            itemBuilder: (_, row) {
                              final rowStatuses = _statusMatrix[row];
                              final selectedColumns = widget.selectedSlots
                                  .where((slot) =>
                                      slot.courtUnitId == widget.rows[row].id)
                                  .map((slot) => _indexFromDate(slot.startTime))
                                  .where((column) =>
                                      column >= 0 && column < _slotCount)
                                  .toSet();

                              return SizedBox(
                                height: widget.rowHeight,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTapDown: (details) =>
                                      _handleTap(row, details.localPosition),
                                  onPanStart: (details) => _handlePanStart(
                                      row, details.localPosition),
                                  onPanUpdate: (details) => _handlePanUpdate(
                                      row, details.localPosition),
                                  onPanEnd: (_) => _handlePanEnd(),
                                  onPanCancel: _handlePanEnd,
                                  child: CustomPaint(
                                    painter: _CourtRowPainter(
                                      slotWidth: widget.slotWidth,
                                      slotCount: _slotCount,
                                      rowHeight: widget.rowHeight,
                                      statuses: rowStatuses,
                                      selectedColumns: selectedColumns,
                                      colors: colors,
                                    ),
                                  ),
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
    final totalWidth = slotCount * slotWidth;

    final bottom = size.height - 6.0;
    final tp = TextPainter(textDirection: ui.TextDirection.ltr);

    for (int i = 0; i <= slotCount; i++) {
      final baseX = i * slotWidth;
      final hourX =
          (i == slotCount) ? leadingInset + totalWidth : leadingInset + baseX;

      final hourPaint = Paint()
        ..color = hourTickColor
        ..strokeWidth = hourTickStroke;
      final hourTop = bottom - hourTickHeight;
      canvas.drawLine(Offset(hourX, hourTop), Offset(hourX, bottom), hourPaint);

      final hourVal = startHour + i;
      final labelHour =
          DateFormat('H:00').format(DateTime(2000, 1, 1, hourVal));
      tp.text = TextSpan(text: labelHour, style: textStyle);
      tp.layout();
      double hourTx = hourX - tp.width / 2;
      final hourTy = hourTop - tp.height - 2;

      // Adjust last label to prevent cutoff
      if (i == slotCount && hourTx + tp.width > size.width) {
        hourTx = size.width - tp.width - 4; // Align to right with small padding
      }

      tp.paint(canvas, Offset(hourTx, hourTy));

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

class _CourtRowPainter extends CustomPainter {
  _CourtRowPainter({
    required this.slotWidth,
    required this.slotCount,
    required this.rowHeight,
    required this.statuses,
    required this.selectedColumns,
    required this.colors,
  }) : assert(statuses.length == slotCount,
            'Status length must equal slot count');

  final double slotWidth;
  final int slotCount;
  final double rowHeight;
  final List<CourtSlotStatus> statuses;
  final Set<int> selectedColumns;
  final _SlotColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    for (var column = 0; column < slotCount; column++) {
      final rect = Rect.fromLTWH(
        column * slotWidth,
        0,
        slotWidth,
        rowHeight,
      );
      final status = statuses[column];
      var fillColor = colors.forStatus(status);
      if (selectedColumns.contains(column)) {
        fillColor = colors.selectedOverlay;
      }
      canvas.drawRect(rect, Paint()..color = fillColor);
    }

    final line = Paint()
      ..color = colors.gridLine
      ..strokeWidth = 1;
    for (int i = 0; i <= slotCount; i++) {
      final dx = (i == slotCount) ? slotCount * slotWidth : i * slotWidth;
      canvas.drawLine(Offset(dx, 0), Offset(dx, rowHeight), line);
    }
  }

  @override
  bool shouldRepaint(covariant _CourtRowPainter oldDelegate) {
    return oldDelegate.slotWidth != slotWidth ||
        oldDelegate.rowHeight != rowHeight ||
        !listEquals(oldDelegate.statuses, statuses) ||
        !setEquals(oldDelegate.selectedColumns, selectedColumns) ||
        oldDelegate.colors != colors;
  }
}

class _SlotColors {
  _SlotColors({
    required this.available,
    required this.lockedPast,
    required this.heldByMe,
    required this.heldByOther,
    required this.pendingMine,
    required this.pending,
    required this.confirmed,
    required this.selectedOverlay,
    required this.gridLine,
  });

  factory _SlotColors.fromColorScheme(ColorScheme cs) {
    return _SlotColors(
      available: cs.surface,
      lockedPast: cs.onSurface.withOpacity(0.08),
      heldByMe: cs.secondaryContainer.withOpacity(0.7),
      heldByOther: cs.errorContainer.withOpacity(0.9),
      pendingMine: cs.tertiaryContainer.withOpacity(0.9),
      pending: cs.tertiary.withOpacity(0.6),
      confirmed: cs.primaryContainer.withOpacity(0.9),
      selectedOverlay: cs.secondary.withOpacity(0.35),
      gridLine: const Color(0x33000000),
    );
  }

  final Color available;
  final Color lockedPast;
  final Color heldByMe;
  final Color heldByOther;
  final Color pendingMine;
  final Color pending;
  final Color confirmed;
  final Color selectedOverlay;
  final Color gridLine;

  Color forStatus(CourtSlotStatus status) {
    switch (status) {
      case CourtSlotStatus.available:
        return available;
      case CourtSlotStatus.lockedPast:
        return lockedPast;
      case CourtSlotStatus.heldByMe:
        return heldByMe;
      case CourtSlotStatus.heldByOther:
        return heldByOther;
      case CourtSlotStatus.pendingApprovalMine:
        return pendingMine;
      case CourtSlotStatus.pendingApproval:
        return pending;
      case CourtSlotStatus.confirmed:
        return confirmed;
    }
  }

  @override
  bool operator ==(Object other) {
    return other is _SlotColors &&
        other.available == available &&
        other.lockedPast == lockedPast &&
        other.heldByMe == heldByMe &&
        other.heldByOther == heldByOther &&
        other.pendingMine == pendingMine &&
        other.pending == pending &&
        other.confirmed == confirmed &&
        other.selectedOverlay == selectedOverlay &&
        other.gridLine == gridLine;
  }

  @override
  int get hashCode => Object.hash(
      available,
      lockedPast,
      heldByMe,
      heldByOther,
      pendingMine,
      pending,
      confirmed,
      selectedOverlay,
      gridLine);
}

class _CellCoordinate {
  const _CellCoordinate(this.row, this.column);

  final int row;
  final int column;

  @override
  bool operator ==(Object other) {
    return other is _CellCoordinate &&
        other.row == row &&
        other.column == column;
  }

  @override
  int get hashCode => Object.hash(row, column);
}

enum _DragOperation { none, add, remove }
