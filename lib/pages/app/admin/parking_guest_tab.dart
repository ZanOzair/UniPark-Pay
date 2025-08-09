import 'package:flutter/material.dart';
import 'package:uniparkpay/app/parking_session_manager.dart';
import 'package:uniparkpay/widgets/map_widget.dart';
import 'package:uniparkpay/widgets/image_viewer.dart';
import 'package:latlong2/latlong.dart';
import 'package:uniparkpay/utils/date_time_utils.dart';
import 'package:uniparkpay/utils/session_filter_utils.dart';

class ParkingGuestTab extends StatefulWidget {
  const ParkingGuestTab({super.key});

  @override
  State<ParkingGuestTab> createState() => _ParkingGuestTabState();
}

class _ParkingGuestTabState extends State<ParkingGuestTab> {
  final ParkingSessionManager _sessionManager = ParkingSessionManager();
  late Future<List<Map<String, dynamic>>> _sessionsFuture;
  String? _lastActionMessage;
  
  // Filter states
  String _searchQuery = '';
  String _selectedStatus = 'All';
  String _selectedDateRange = 'All Time';
  String _selectedParkingArea = 'All Areas';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _sessionsFuture = _sessionManager.getGuestSessionsForAdmin();
  }

  void _refreshSessions() {
    setState(() {
      _loadData();
      _lastActionMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _sessionsFuture,
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
                Text('No guest parking sessions found'),
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
                if (_lastActionMessage != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    color: _lastActionMessage!.contains('Success') ? Colors.green : Colors.red,
                    child: Text(
                      _lastActionMessage!,
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
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
                            padding: const EdgeInsets.all(8),
                            itemCount: filteredSessions.length,
                            itemBuilder: (context, index) {
                              final session = filteredSessions[index];
                              return _buildSessionCard(session);
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

  Widget _buildSessionCard(Map<String, dynamic> session) {
    final status = session['status'] ?? 'unverified';
    final endTime = DateTimeUtils.safeParseDateTime(session['end_time']);
    final isExpired = SessionFilterUtils.isSessionExpired(session);
    
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
                      if (isExpired) ...[
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
                _buildStatusChip(status),
              ],
            ),
            const SizedBox(height: 8),
            Text('Phone: ${session['user_phone'] ?? 'N/A'}'),
            Text('Plate: ${session['car_plate_no'] ?? 'N/A'}'),
            Text('Area: ${session['parking_area_name'] ?? 'Unknown'}'),
            Text('Start: ${_formatDateTime(session['start_time'])}'),
            Text('End: ${_formatDateTime(session['end_time'])}'),
            if (isExpired)
              Text(
                'Expired ${DateTime.now().difference(endTime!).inHours} hours ago',
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
                if (session['payment_proof'] != null)
                  TextButton(
                    onPressed: () => _showPaymentProof(session),
                    child: const Text('View Payment Proof'),
                  ),
                const Spacer(),
                if (status != 'approved')
                  ElevatedButton(
                    onPressed: () => _handleStatusUpdate(session['id'], 'approved'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: const Text('Approve'),
                  ),
                const SizedBox(width: 8),
                if (status != 'rejected')
                  ElevatedButton(
                    onPressed: () => _handleStatusUpdate(session['id'], 'rejected'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: const Text('Reject'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'approved':
        color = Colors.green;
        break;
      case 'rejected':
        color = Colors.red;
        break;
      case 'unverified':
      default:
        color = Colors.orange;
        break;
    }
    
    return Chip(
      label: Text(
        status.toUpperCase(),
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: color,
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );
  }

  void _showPaymentProof(Map<String, dynamic> session) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.95,
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              // Rounded header
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Payment Proof',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              ),
              // Image display area with zoom
              Expanded(
                child: session['payment_proof'] != null
                    ? InteractiveViewer(
                        panEnabled: true,
                        boundaryMargin: const EdgeInsets.all(20),
                        minScale: 0.5,
                        maxScale: 4.0,
                        child: Center(
                          child: ImageViewer(
                            imageData: session['payment_proof'],
                            fit: BoxFit.contain,
                          ),
                        ),
                      )
                    : const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('No payment proof available'),
                          ],
                        ),
                      ),
              ),
              // Footer with metadata
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(16),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Bank: ${session['bank_name'] ?? 'Unknown'}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'File: ${session['proof_filename'] ?? 'Unknown'}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Uploaded: ${_formatDateTime(session['created_at'])}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
                      _buildDetailRow('Phone', session['user_phone']),
                      const SizedBox(height: 12),
                      _buildDetailRow('Plate', session['car_plate_no']),
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
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Coordinates: ${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      if (session['payment_proof'] != null) ...[
                        const SizedBox(height: 20),
                        const Text('Payment Proof:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                        Center(
                          child: TextButton(
                            onPressed: () => _showPaymentProof(session),
                            child: const Text('View Payment Proof'),
                          ),
                        ),
                      ],
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

  void _handleStatusUpdate(String sessionId, String status) {
    // Update the status and refresh the list
    setState(() {
      _sessionsFuture = _sessionManager.updateSessionStatus(sessionId, status).then((success) {
        _lastActionMessage = success
            ? 'Session ${status.toUpperCase()} successfully'
            : 'Failed to update session status';
        return _sessionManager.getGuestSessionsForAdmin();
      });
    });
  }
}