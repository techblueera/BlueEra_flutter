import 'package:flutter/material.dart';

class CustomDateSelection extends StatefulWidget {
  final Function(DateTime?) onDateSelected;
  final DateTime? initialDate;
  final List<DateTime>? availableDates;
  final String? label;

  const CustomDateSelection({
    Key? key,
    required this.onDateSelected,
    this.initialDate,
    this.availableDates,
    this.label,
  }) : super(key: key);

  @override
  State<CustomDateSelection> createState() => _CustomDateSelectionState();
}

class _CustomDateSelectionState extends State<CustomDateSelection> {
  int? selectedDay;
  int? selectedMonth;
  int? selectedYear;
  
  List<int> days = [];
  List<int> months = List.generate(12, (index) => index + 1);
  List<int> years = [];

  @override
  void initState() {
    super.initState();
    _initializeYears();
    if (widget.initialDate != null) {
      selectedDay = widget.initialDate!.day;
      selectedMonth = widget.initialDate!.month;
      selectedYear = widget.initialDate!.year;
      _updateDays();
    }
  }

  void _initializeYears() {
    final currentYear = DateTime.now().year;
    years = List.generate(10, (index) => currentYear + index);
  }

  void _updateDays() {
    if (selectedMonth != null && selectedYear != null) {
      final daysInMonth = DateTime(selectedYear!, selectedMonth! + 1, 0).day;
      days = List.generate(daysInMonth, (index) => index + 1);
      
      // If selected day is greater than days in month, reset it
      if (selectedDay != null && selectedDay! > daysInMonth) {
        selectedDay = null;
      }
    } else {
      days = [];
      selectedDay = null;
    }
    setState(() {});
  }

  void _onDateChanged() {
    if (selectedDay != null && selectedMonth != null && selectedYear != null) {
      final selectedDate = DateTime(selectedYear!, selectedMonth!, selectedDay!);
      
      // Check if the selected date is in available dates (if provided)
      if (widget.availableDates != null) {
        final isAvailable = widget.availableDates!.any((date) => 
          date.year == selectedDate.year && 
          date.month == selectedDate.month && 
          date.day == selectedDate.day
        );
        
        if (!isAvailable) {
          widget.onDateSelected(null);
          return;
        }
      }
      
      widget.onDateSelected(selectedDate);
    } else {
      widget.onDateSelected(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.black,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 8),
        ],
        Row(
          children: [
            // Day Dropdown
            Expanded(
              child: _buildDropdown(
                value: selectedDay,
                hint: "DD",
                items: days,
                onChanged: (value) {
                  setState(() {
                    selectedDay = value;
                  });
                  _onDateChanged();
                },
              ),
            ),
            SizedBox(width: 12),
            // Month Dropdown
            Expanded(
              child: _buildDropdown(
                value: selectedMonth,
                hint: "MM",
                items: months,
                onChanged: (value) {
                  setState(() {
                    selectedMonth = value;
                    selectedDay = null; // Reset day when month changes
                  });
                  _updateDays();
                  _onDateChanged();
                },
              ),
            ),
            SizedBox(width: 12),
            // Year Dropdown
            Expanded(
              child: _buildDropdown(
                value: selectedYear,
                hint: "YYYY",
                items: years,
                onChanged: (value) {
                  setState(() {
                    selectedYear = value;
                    selectedDay = null; // Reset day when year changes
                  });
                  _updateDays();
                  _onDateChanged();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required int? value,
    required String hint,
    required List<int> items,
    required ValueChanged<int?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: value,
          hint: Text(
            hint,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600, size: 20),
          items: items.map((item) {
            return DropdownMenuItem<int>(
              value: item,
              child: Text(
                item.toString().padLeft(hint.length, '0'),
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
