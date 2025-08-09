import 'package:flutter/material.dart';
import 'package:uniparkpay/utils/date_time_utils.dart';

class SessionFilterUtils {
  /// Checks if a session is expired based on end_time
  static bool isSessionExpired(Map<String, dynamic> session) {
    final endTime = DateTimeUtils.safeParseDateTime(session['end_time']);
    if (endTime == null) return false;
    return endTime.isBefore(DateTime.now());
  }

  /// Checks if a session is active (not expired)
  static bool isSessionActive(Map<String, dynamic> session) {
    return !isSessionExpired(session);
  }

  /// Filters sessions based on search query
  static List<Map<String, dynamic>> filterBySearch(
    List<Map<String, dynamic>> sessions,
    String searchQuery,
  ) {
    if (searchQuery.isEmpty) return sessions;
    
    final query = searchQuery.toLowerCase();
    return sessions.where((session) {
      final name = (session['user_name'] ?? '').toString().toLowerCase();
      final phone = (session['user_phone'] ?? '').toString().toLowerCase();
      final plate = (session['car_plate_no'] ?? '').toString().toLowerCase();
      
      // Check basic fields
      bool matches = name.contains(query) ||
                     phone.contains(query) ||
                     plate.contains(query);
      
      // Check time and date in various formats
      if (!matches) {
        final startTime = DateTimeUtils.safeParseDateTime(session['start_time']);
        final endTime = DateTimeUtils.safeParseDateTime(session['end_time']);
        
        if (startTime != null && endTime != null) {
          // Time formats (HH:MM)
          final startTimeStr = '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
          final endTimeStr = '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
          
          // Date formats (YYYY-MM-DD)
          final startDateStr = '${startTime.year}-${startTime.month.toString().padLeft(2, '0')}-${startTime.day.toString().padLeft(2, '0')}';
          final endDateStr = '${endTime.year}-${endTime.month.toString().padLeft(2, '0')}-${endTime.day.toString().padLeft(2, '0')}';
          
          // Combined date-time formats
          final startDateTimeStr = '$startDateStr $startTimeStr';
          final endDateTimeStr = '$endDateStr $endTimeStr';
          
          matches = startTimeStr.contains(query) ||
                   endTimeStr.contains(query) ||
                   startDateStr.contains(query) ||
                   endDateStr.contains(query) ||
                   startDateTimeStr.contains(query) ||
                   endDateTimeStr.contains(query);
        }
      }
      
      return matches;
    }).toList();
  }

  /// Filters sessions by parking area
  static List<Map<String, dynamic>> filterByParkingArea(
    List<Map<String, dynamic>> sessions,
    String parkingArea,
  ) {
    if (parkingArea == 'All Areas') return sessions;
    
    return sessions.where((session) {
      final areaName = (session['parking_area_name'] ?? '').toString();
      return areaName == parkingArea;
    }).toList();
  }

  /// Filters sessions by status
  static List<Map<String, dynamic>> filterByStatus(
    List<Map<String, dynamic>> sessions,
    String status,
  ) {
    if (status == 'All') return sessions;
    if (status == 'Active') return sessions.where(isSessionActive).toList();
    if (status == 'Expired') return sessions.where(isSessionExpired).toList();
    
    return sessions.where((session) => 
      (session['status'] ?? '').toString().toLowerCase() == status.toLowerCase()
    ).toList();
  }

  /// Filters sessions by date range - FIXED VERSION using start_time and end_time
  static List<Map<String, dynamic>> filterByDateRange(
    List<Map<String, dynamic>> sessions,
    String dateRange,
  ) {
    if (dateRange == 'All Time') return sessions;
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    
    switch (dateRange) {
      case 'Today':
        return sessions.where((session) {
          final startTime = DateTimeUtils.safeParseDateTime(session['start_time']);
          final endTime = DateTimeUtils.safeParseDateTime(session['end_time']);
          
          if (startTime == null || endTime == null) return false;
          
          // Check if session overlaps with today
          // Session is today if it starts today OR ends today OR spans across today
          return (startTime.isAfter(today) && startTime.isBefore(tomorrow)) ||  // Starts today
                 (endTime.isAfter(today) && endTime.isBefore(tomorrow)) ||      // Ends today
                 (startTime.isBefore(today) && endTime.isAfter(tomorrow));      // Spans across today
        }).toList();
        
      case 'This Week':
        return sessions.where((session) {
          final startTime = DateTimeUtils.safeParseDateTime(session['start_time']);
          if (startTime == null) return false;
          
          // Calculate week start (Monday) and end (Sunday)
          final daysSinceMonday = now.weekday - 1;
          final weekStart = today.subtract(Duration(days: daysSinceMonday));
          final weekEnd = weekStart.add(const Duration(days: 7));
          
          // Check if session starts within this week
          return !startTime.isBefore(weekStart) && startTime.isBefore(weekEnd);
        }).toList();
        
      case 'This Month':
        return sessions.where((session) {
          final startTime = DateTimeUtils.safeParseDateTime(session['start_time']);
          if (startTime == null) return false;
          
          // Check if session starts within this month
          return startTime.year == now.year && startTime.month == now.month;
        }).toList();
        
      default:
        return sessions;
    }
  }

  /// Combined filtering method
  static List<Map<String, dynamic>> applyFilters({
    required List<Map<String, dynamic>> sessions,
    String searchQuery = '',
    String status = 'All',
    String dateRange = 'All Time',
    String parkingArea = 'All Areas',
  }) {
    var filtered = sessions;
    
    // Apply search filter
    filtered = filterBySearch(filtered, searchQuery);
    
    // Apply status filter
    filtered = filterByStatus(filtered, status);
    
    // Apply date range filter
    filtered = filterByDateRange(filtered, dateRange);
    
    // Apply parking area filter
    filtered = filterByParkingArea(filtered, parkingArea);
    
    return filtered;
  }
}

/// Filter widget for session filtering
class SessionFilterWidget extends StatelessWidget {
  final String searchQuery;
  final String selectedStatus;
  final String selectedDateRange;
  final String selectedParkingArea;
  final List<String> parkingAreas;
  final Function(String) onSearchChanged;
  final Function(String) onStatusChanged;
  final Function(String) onDateRangeChanged;
  final Function(String) onParkingAreaChanged;
  final VoidCallback onRefresh;

  const SessionFilterWidget({
    super.key,
    required this.searchQuery,
    required this.selectedStatus,
    required this.selectedDateRange,
    required this.selectedParkingArea,
    required this.parkingAreas,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onDateRangeChanged,
    required this.onParkingAreaChanged,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          // Search Bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Search by name, phone, plate, time, or date...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onChanged: onSearchChanged,
          ),
          const SizedBox(height: 8),
          // Filter Row 1 - Status and Date Range
          Row(
            children: [
              // Status Filter
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('All')),
                    DropdownMenuItem(value: 'Active', child: Text('Active')),
                    DropdownMenuItem(value: 'Expired', child: Text('Expired')),
                    DropdownMenuItem(value: 'approved', child: Text('Approved')),
                    DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                    DropdownMenuItem(value: 'unverified', child: Text('Unverified')),
                  ],
                  onChanged: (value) {
                    if (value != null) onStatusChanged(value);
                  },
                ),
              ),
              const SizedBox(width: 8),
              // Date Range Filter
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: selectedDateRange,
                  decoration: const InputDecoration(
                    labelText: 'Date Range',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'All Time', child: Text('All Time')),
                    DropdownMenuItem(value: 'Today', child: Text('Today')),
                    DropdownMenuItem(value: 'This Week', child: Text('This Week')),
                    DropdownMenuItem(value: 'This Month', child: Text('This Month')),
                  ],
                  onChanged: (value) {
                    if (value != null) onDateRangeChanged(value);
                  },
                ),
              ),
              const SizedBox(width: 8),
              // Refresh Button
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: onRefresh,
                tooltip: 'Refresh',
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Filter Row 2 - Parking Area
          DropdownButtonFormField<String>(
            value: selectedParkingArea,
            decoration: const InputDecoration(
              labelText: 'Parking Area',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: [
              const DropdownMenuItem(value: 'All Areas', child: Text('All Areas')),
              ...parkingAreas.where((area) => area != 'All Areas').map((area) => DropdownMenuItem(
                value: area,
                child: Text(area),
              )),
            ],
            onChanged: (value) {
              if (value != null) onParkingAreaChanged(value);
            },
          ),
        ],
      ),
    );
  }
}