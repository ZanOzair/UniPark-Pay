import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:uniparkpay/app/location_service.dart';
import 'package:uniparkpay/app/parking_session_manager.dart';
import 'package:uniparkpay/app/user_role.dart';
import 'package:uniparkpay/auth/auth_provider.dart';
import 'package:uniparkpay/database/db_manager.dart';
import 'package:uniparkpay/utils/date_time_utils.dart';
import 'package:uniparkpay/utils/validation_utils.dart';
import 'package:uniparkpay/widgets/app/content_page.dart';
import 'package:uniparkpay/widgets/map_widget.dart';

class ParkingPage extends ContentPage {
  const ParkingPage({super.key}) : super(title: 'Parking');

  @override
  State<ParkingPage> createState() => _ParkingPageState();
}

class _ParkingPageState extends State<ParkingPage> {
  final LocationService _locationService = LocationService();
  final Distance _distance = const Distance();
  final ParkingSessionManager _sessionManager = ParkingSessionManager();
  
  final TextEditingController _durationController = TextEditingController(text: '1');
  final int _ratePerHour = 1; // RM1 per hour for guests
  Map<String, dynamic>? _currentParkingArea;
  String _areaDisplayText = 'Loading...';
  Color _areaDisplayColor = Colors.blueAccent;
  Map<String, dynamic>? _currentSession;

  @override
  void initState() {
    super.initState();
    _loadCurrentSession();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkForPassedSession();
  }

  @override
  void dispose() {
    _durationController.dispose();
    super.dispose();
  }

  // Detect parking area with name and coordinates
  Future<Map<String, dynamic>?> _detectParkingArea(LatLng userLocation) async {
    try {
      final db = DatabaseManager();
      final areas = await db.execute('SELECT * FROM PARKING_AREA');
      
      for (final area in areas) {
        final double areaLat = double.parse(area['latitude'].toString());
        final double areaLng = double.parse(area['longitude'].toString());
        final double radius = double.parse(area['radius'].toString());
        
        final LatLng areaCenter = LatLng(areaLat, areaLng);
        final double distanceInMeters = _distance.as(LengthUnit.Meter, userLocation, areaCenter);
        
        if (distanceInMeters <= radius) {
          return {
            'id': area['id'],
            'name': area['name'],
            'latitude': areaLat,
            'longitude': areaLng,
            'asset_name': area['asset_name'],
          };
        }
      }
      
      return null; // Not in any parking area
    } catch (e) {
      debugPrint('Error detecting parking area: $e');
      return null;
    }
  }

  // Check for session passed from ProcessParkingPage
  void _checkForPassedSession() {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is Map<String, dynamic> && args.containsKey('session')) {
      setState(() {
        _currentSession = args['session'];
      });
    }
  }

  // Load current active session from database
  Future<void> _loadCurrentSession() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.id == null) return;

    try {
      final session = await _sessionManager.getActiveSession(int.parse(authProvider.id!));
      if (session != null) {
        // Check if session has valid duration (not 00:00:00)
        final startTime = DateTime.parse(session['start_time']);
        final endTime = DateTime.parse(session['end_time']);
        final duration = endTime.difference(startTime);
        
        // Skip sessions with zero or negative duration
        if (duration.inSeconds <= 0) {
          if (mounted) {
            setState(() {
              _currentSession = null;
            });
          }
          return;
        }

        // Load parking area details
        final db = DatabaseManager();
        final areaResult = await db.executePrepared(
          'SELECT name FROM PARKING_AREA WHERE id = ?',
          [session['parking_area_id']]
        );
        
        if (areaResult.isNotEmpty) {
          session['parking_area_name'] = areaResult.first['name'];
        }
      }
      
      if (mounted) {
        setState(() {
          _currentSession = session;
        });
      }
    } catch (e) {
      debugPrint('Error loading current session: $e');
      if (mounted) {
        setState(() {
          _currentSession = null;
        });
      }
    }
  }

  // Show warning dialog for existing session
  Future<void> _showSessionWarningDialog() async {
    final shouldProceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Active Parking Session'),
        content: const Text(
          'Your current parking session will be terminated if you start a new one. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (shouldProceed == true) {
      _navigateToProcessParking();
    }
  }

  void _navigateToProcessParking() {
    if (_currentParkingArea == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a valid parking area first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final duration = int.tryParse(_durationController.text) ?? 1;
    if (duration <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid duration'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.of(context).pushNamed(
      '/process-parking',
      arguments: {
        'parkingAreaId': _currentParkingArea!['id'],
        'parkingAreaName': _currentParkingArea!['name'],
        'latitude': _currentParkingArea!['latitude'],
        'longitude': _currentParkingArea!['longitude'],
        'duration': duration,
      },
    ).then((result) {
      if (result != null && result is Map<String, dynamic>) {
        setState(() {
          _currentSession = result;
        });
      }
    });
  }

  // Handle start parking button press
  void _handleStartParking() {
    if (_currentSession != null) {
      _showSessionWarningDialog();
    } else {
      _navigateToProcessParking();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final bool isGuest = authProvider.role == UserRole.guest;
        
        return SingleChildScrollView(
          child: Column(
            children: [
              // Current Date and Time
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        'Current Date & Time',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      StreamBuilder<DateTime>(
                        stream: Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now()),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const CircularProgressIndicator();
                          return Text(
                            '${snapshot.data!.day}/${snapshot.data!.month}/${snapshot.data!.year} ${snapshot.data!.hour.toString().padLeft(2, '0')}:${snapshot.data!.minute.toString().padLeft(2, '0')}:${snapshot.data!.second.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontFamily: 'monospace',
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Active Parking Session Display
              if (_currentSession != null) ...[
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.blue.shade50,
                          Colors.blue.shade100,
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.local_parking, color: Colors.blue, size: 24),
                              SizedBox(width: 8),
                              Text(
                                'Current Parking Session',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Real-time countdown
                          StreamBuilder<String>(
                            stream: Stream.periodic(
                              const Duration(seconds: 1),
                              (_) => DateTimeUtils.formatTimeRemaining(_currentSession!['end_time']),
                            ),
                            builder: (context, snapshot) {
                              final timeLeft = snapshot.data ?? DateTimeUtils.formatTimeRemaining(_currentSession!['end_time']);
                              
                              // Hide session when time reaches 00:00:00
                              if (timeLeft == '00:00:00') {
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  setState(() {
                                    _currentSession = null;
                                  });
                                });
                                return const SizedBox.shrink();
                              }
                              
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Time Left:',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.blueGrey,
                                    ),
                                  ),
                                  Text(
                                    timeLeft,
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: timeLeft.startsWith('-') ? Colors.red : Colors.blue,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          // Parking area and start time
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.location_on, size: 16, color: Colors.blueGrey),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Row(
                                      children: [
                                        // Load asset for current session area
                                        FutureBuilder<Map<String, dynamic>?>(
                                          future: (() async {
                                            try {
                                              final db = DatabaseManager();
                                              final areaResult = await db.executePrepared(
                                                'SELECT asset_name FROM PARKING_AREA WHERE name = ?',
                                                [_currentSession!['parking_area_name'] ?? _currentSession!['parkingAreaName'] ?? '']
                                              );
                                              if (areaResult.isNotEmpty) {
                                                return areaResult.first;
                                              }
                                            } catch (e) {
                                              debugPrint('Error loading area asset: $e');
                                            }
                                            return null;
                                          })(),
                                          builder: (context, assetSnapshot) {
                                            final assetName = assetSnapshot.data?['asset_name'];
                                            if (assetName != null) {
                                              return Row(
                                                children: [
                                                  ClipRRect(
                                                    borderRadius: BorderRadius.circular(6),
                                                    child: Image.asset(
                                                      'assets/images/$assetName',
                                                      width: 24,
                                                      height: 24,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context, error, stackTrace) {
                                                        return const SizedBox.shrink();
                                                      },
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                ],
                                              );
                                            }
                                            return const SizedBox.shrink();
                                          },
                                        ),
                                        Text(
                                          'Area: ${_currentSession!['parking_area_name'] ?? _currentSession!['parkingAreaName'] ?? 'Unknown'}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.blueGrey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.access_time, size: 16, color: Colors.blueGrey),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Started: ${DateTimeUtils.formatSessionTime(_currentSession!['start_time'])}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.blueGrey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              
              // Map Display with continuous area detection
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        'Location Map',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      StreamBuilder<LatLng>(
                        stream: _locationService.getLocationStream(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Text(
                              'Error: ${snapshot.error}',
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            );
                          }
                          
                          if (!snapshot.hasData) {
                            return const Column(
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 8),
                                Text('Getting location...'),
                              ],
                            );
                          }
                          
                          final currentLatLng = snapshot.data!;
                          
                          // Continuously update area detection
                          return FutureBuilder<Map<String, dynamic>?>(
                            future: _detectParkingArea(currentLatLng),
                            builder: (context, areaSnapshot) {
                              if (areaSnapshot.hasData) {
                                final newArea = areaSnapshot.data;
                                if (newArea?['id'] != _currentParkingArea?['id']) {
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    setState(() {
                                      _currentParkingArea = newArea;
                                      _areaDisplayText = newArea != null ? newArea['name'] : 'Not in any parking area';
                                      _areaDisplayColor = newArea != null ? Colors.green : Colors.orange;
                                    });
                                  });
                                }
                              }

                              return Column(
                                children: [
                                  SizedBox(
                                    height: 300,
                                    child: MapWidget(
                                      center: currentLatLng,
                                      markerTitle: 'You are here',
                                      zoom: 16.0,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (_currentParkingArea?['asset_name'] != null) ...[
                                        ClipRRect(
                                          child: Image.asset(
                                            'assets/images/${_currentParkingArea!['asset_name']}',
                                            height: 28,
                                            fit: BoxFit.contain,
                                            errorBuilder: (context, error, stackTrace) {
                                              return const SizedBox.shrink();
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                      Text(
                                        _areaDisplayText,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: _areaDisplayColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              // Parking Duration and Price - tracks _currentParkingArea
              if (_currentParkingArea != null) ...[
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 20.0,vertical: 10.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          'Parking in ${_currentParkingArea!['name']}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Parking Duration (hours)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _durationController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Enter hours',
                          ),
                          onEditingComplete: () {
                            // Validate and dismiss keyboard
                            final normalized = ValidationUtils.validateAndNormalizeDuration(_durationController.text);
                            _durationController.text = normalized;
                            FocusScope.of(context).unfocus(); // Close keyboard
                          },
                        ),
                        // Show price only for guests
                        if (isGuest) ...[
                          const SizedBox(height: 16),
                          const Text(
                            'Total Price',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'RM${(int.tryParse(_durationController.text) ?? 1) * _ratePerHour}.00',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
              
              // Start Parking Button
              if (_currentParkingArea != null) ...[
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0,vertical: 10.0),
                  child: ElevatedButton(
                    onPressed: _handleStartParking,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: Text(
                      isGuest ? 'Start Parking (Payment Required)' : 'Start Parking (Free)',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
              
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}