class scheduleVisitingRequestModel {
  final String day;
  final bool isOpen;
  final List<TimeSlot> timeSlots;

  scheduleVisitingRequestModel({
    required this.day,
    required this.isOpen,
    required this.timeSlots,
  });

  Map<String, dynamic> toJson() => {
    'day': day,
    'isOpen': isOpen,
    'timeSlots': timeSlots.map((e) => e.toJson()).toList(),
  };
}

class TimeSlot {
  final String startTime;
  final String endTime;

  const TimeSlot({required this.startTime, required this.endTime});

  Map<String, dynamic> toJson() =>
      {'startTime': startTime, 'endTime': endTime};
}