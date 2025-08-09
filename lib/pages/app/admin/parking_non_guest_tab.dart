import 'package:flutter/material.dart';
import 'package:uniparkpay/app/parking_session_manager.dart';
import 'package:uniparkpay/widgets/map_widget.dart';
import 'package:latlong2/latlong.dart';
import 'package:uniparkpay/utils/date_time_utils.dart';
import 'package:uniparkpay/utils/session_filter_utils.dart';

class ParkingNonGuestTab extends StatefulWidget {
  const ParkingNonGuestTab({super.key});

  @override
  State<ParkingNonGuestTab> createState() => _ParkingNonGuestTabState();
}

class _ParkingNonGuestTabState extends State<ParkingNonGuestTab> {
  final ParkingSessionManager _sessionManager = ParkingSessionManager();
  late Future<List<Map<String, dynamic>>> _nonGuestSessions;
  
  // Filter states
  String _searchQuery = '';
  String _selectedStatus = 'All';
  String _selectedDateRange = 'All Time';
  String _selectedParkingArea = 'All Areas';

  @override
  void initState() {
    super.initState();
    _loadNonGuestSessions();
  }

  void _loadNonGuestSessions() {
    _nonGuestSessions = _sessionManager.getNonGuestSessionsForAdmin();
  }

  void _refreshSessions() {
    setState(() {
      _loadNonGuestSessions();
    });
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'lecturer':
        return Colors.blue;
      case 'student':
        return Colors.purple;
      case 'admin':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showSessionDetails(Map<String, dynamic> session) {
    final latitude = double.tryParse(session['latitude']?.toString() ?? '0.0') ?? 0.0;
    final longitude = double.tryParse(session['longitude']?.toString() ?? '0.0') ?? 0.0;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Session Details - ${session['user_name']}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('User', session['user_name']),
                      const SizedBox(height: 12),
                      _buildDetailRow('ID', session['university_id']),
                      const SizedBox(height: 12),
                      _buildDetailRow('Phone', session['user_phone']),
                      const SizedBox(height: 12),
                      _buildDetailRow('Plate', session['car_plate_no']),
                      const SizedBox(height: 12),
                      _buildDetailRow('Role', session['user_role']?.toUpperCase()),
                      const SizedBox(height: 12),
                      _buildDetailRow('Area', session['parking_area_name']),
                      const SizedBox(height: 12),
                      _buildDetailRow('Start', _formatDateTime(session['start_time'])),
                      const SizedBox(height: 12),
                      _buildDetailRow('End', _formatDateTime(session['end_time'])),
                      const SizedBox(height: 20),
                      const Text('Location:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 12),
                      Container(
                        height: 250,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: MapWidget(
                            center: LatLng(latitude, longitude),
                            zoom: 17,
                            markerTitle: session['car_plate_no'] ?? session['user_name'] ?? 'Unknown',
                            markerColor: _getRoleColor(session['user_role'] ?? 'unknown'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Coordinates: ${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Free Parking - No Payment Required',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null) return 'N/A';
    // Remove trailing .0 from datetime strings
    String cleaned = dateTimeStr.replaceAll('.0', '');
    try {
      final dateTime = DateTime.parse(cleaned);
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
    } catch (e) {
      return cleaned;
    }
  }

  Widget _buildDetailRow(String label, String? value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value ?? 'N/A',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _nonGuestSessions,
      builder: (context, sessionsSnapshot) {
        if (sessionsSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (sessionsSnapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${sessionsSnapshot.error}', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _refreshSessions,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final allSessions = sessionsSnapshot.data ?? [];
        if (allSessions.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.local_parking, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text('No lecturer/student parking sessions found'),
              ],
            ),
          );
        }

        return FutureBuilder<List<String>>(
          future: _sessionManager.getParkingAreas().then((areas) => areas.map((a) => a['name'] as String).toList()),
          builder: (context, areasSnapshot) {
            final parkingAreas = ['All Areas', ...?areasSnapshot.data];
            
            // Apply filters
            final filteredSessions = SessionFilterUtils.applyFilters(
              sessions: allSessions,
              searchQuery: _searchQuery,
              status: _selectedStatus,
              dateRange: _selectedDateRange,
              parkingArea: _selectedParkingArea,
            );

            return Column(
              children: [
                SessionFilterWidget(
                  searchQuery: _searchQuery,
                  selectedStatus: _selectedStatus,
                  selectedDateRange: _selectedDateRange,
                  selectedParkingArea: _selectedParkingArea,
                  parkingAreas: parkingAreas,
                  onSearchChanged: (query) {
                    setState(() {
                      _searchQuery = query;
                    });
                  },
                  onStatusChanged: (status) {
                    setState(() {
                      _selectedStatus = status;
                    });
                  },
                  onDateRangeChanged: (range) {
                    setState(() {
                      _selectedDateRange = range;
                    });
                  },
                  onParkingAreaChanged: (area) {
                    setState(() {
                      _selectedParkingArea = area;
                    });
                  },
                  onRefresh: _refreshSessions,
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async => _refreshSessions(),
                    child: filteredSessions.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_off, size: 48, color: Colors.grey),
                                SizedBox(height: 16),
                                Text('No sessions match your filters'),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: filteredSessions.length,
                            itemBuilder: (context, index) {
                              final session = filteredSessions[index];
                              final role = session['user_role'] ?? 'unknown';
                              
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Row(
                                              children: [
                                                Text(
                                                  session['user_name'] ?? 'Unknown',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                if (SessionFilterUtils.isSessionExpired(session)) ...[
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.red,
                                                      borderRadius: BorderRadius.circular(10),
                                                    ),
                                                    child: const Text(
                                                      'EXPIRED',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getRoleColor(role),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              role.toUpperCase(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text('ID: ${session['university_id'] ?? 'N/A'}'),
                                      Text('Plate: ${session['car_plate_no'] ?? 'N/A'}'),
                                      Text('Area: ${session['parking_area_name'] ?? 'Unknown'}'),
                                      Text('Start: ${_formatDateTime(session['start_time'])}'),
                                      Text('End: ${_formatDateTime(session['end_time'])}'),
                                      if (SessionFilterUtils.isSessionExpired(session))
                                        Text(
                                          'Expired ${DateTime.now().difference(DateTimeUtils.safeParseDateTime(session['end_time'])!).inHours} hours ago',
                                          style: const TextStyle(
                                            color: Colors.red,
                                            fontSize: 12,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          TextButton(
                                            onPressed: () => _showSessionDetails(session),
                                            child: const Text('View Details'),
                                          ),
                                          const Spacer(),
                                          const Text(
                                            'Free Parking - No Payment Required',
                                            style: TextStyle(
                                              fontStyle: FontStyle.italic,
                                              color: Colors.green,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}