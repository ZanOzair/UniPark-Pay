import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gal/gal.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:uniparkpay/app/parking_session_manager.dart';
import 'package:uniparkpay/app/qr_manager.dart';
import 'package:uniparkpay/app/user_role.dart';
import 'package:uniparkpay/auth/auth_provider.dart';
import 'package:uniparkpay/widgets/app/content_page.dart';
import 'package:uniparkpay/widgets/image_viewer.dart';

class ProcessParkingPage extends ContentPage {
  const ProcessParkingPage({super.key}) : super(title: 'Processing Parking');

  @override
  State<ProcessParkingPage> createState() => _ProcessParkingPageState();
}

class _ProcessParkingPageState extends State<ProcessParkingPage> {
  final ParkingSessionManager _sessionManager = ParkingSessionManager();
  final ImagePicker _imagePicker = ImagePicker();
  final QRManager _qrManager = QRManager();
  
  bool _isLoading = false;
  String? _errorMessage;
  Uint8List? _paymentProof;
  String? _proofFilename;
  String? _proofMimeType;

  @override
  void initState() {
    super.initState();
    // Auto-process for non-guest users
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoProcessForNonGuests();
    });
  }

  Future<void> _autoProcessForNonGuests() async {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args == null) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isGuest = authProvider.role == UserRole.guest;
    
    // Only auto-process for non-guest users
    if (!isGuest) {
      await _processParking(args, false);
    }
  }

  Future<Map<String, dynamic>?> _loadQrCode() async {
    try {
      return await _qrManager.getCurrentQR();
    } catch (e) {
      throw Exception('Failed to load QR code: ${e.toString()}');
    }
  }

  Future<void> _downloadQRCode(Map<String, dynamic> qrData) async {
    if (qrData['qr_image'] == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Handle Android 13+ permissions
      PermissionStatus status;
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        if (androidInfo.version.sdkInt >= 33) {
          status = await Permission.photos.request();
        } else {
          status = await Permission.storage.request();
        }
      } else {
        status = await Permission.storage.request();
      }

      if (!status.isGranted) {
        throw Exception('Storage permission denied');
      }

      // Save to gallery using gal package
      final fileName = 'uniparkpay_qr_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await Gal.putImageBytes(
        qrData['qr_image'],
        name: fileName,
        album: 'UniParkPay',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('QR code saved to gallery'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickPaymentProof() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _paymentProof = bytes;
          _proofFilename = image.name;
          _proofMimeType = image.mimeType ?? 'image/jpeg';
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _processParking(Map<String, dynamic> args, bool isGuest) async {
    if (isGuest && _paymentProof == null) {
      setState(() {
        _errorMessage = 'Please upload payment proof';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final session = await _sessionManager.createSession(
        userId: authProvider.id!,
        parkingAreaId: args['parkingAreaId'],
        paymentQrCodeId: '1',
        latitude: args['latitude'],
        longitude: args['longitude'],
        durationHours: args['duration'],
        startTime: DateTime.now(),
        paymentProof: isGuest ? _paymentProof : null,
        proofFilename: isGuest ? _proofFilename : null,
        proofMimeType: isGuest ? _proofMimeType : null,
      );

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Parking session created successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate back to parking page with the created session including parking area name
      final sessionWithAreaName = {
        ...session,
        'parking_area_name': args['parkingAreaName'],
      };
      Navigator.of(context).pop(sessionWithAreaName);
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to create parking session: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    
    if (args == null) {
      return const Center(
        child: Text('Invalid navigation data'),
      );
    }

    final authProvider = Provider.of<AuthProvider>(context);
    final isGuest = authProvider.role == UserRole.guest;
    
    // For non-guest users, show loading screen while auto-processing
    if (!isGuest) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Creating your parking session...',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      );
    }
    
    // For guests, show the upload interface
    return Scaffold(
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Processing your parking session...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  const Icon(
                    Icons.local_parking,
                    size: 80,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Process Parking',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Area: ${args['parkingAreaName']}',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  
                  const Text(
                    'Payment Required',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Scan the QR code below to make payment (RM1 per hour)',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  
                  // QR Code Display with FutureBuilder
                  FutureBuilder<Map<String, dynamic>?>(
                    future: _loadQrCode(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      
                      if (snapshot.hasError) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            border: Border.all(color: Colors.red),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Failed to load QR code: ${snapshot.error}',
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }
                      
                      final qrData = snapshot.data;
                      if (qrData == null) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'No QR code available',
                            style: TextStyle(color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }
                      
                      return Column(
                        children: [
                          ImageViewerWithMetadata(
                            imageData: qrData['qr_image'],
                            title: 'Payment QR Code',
                            subtitle: 'Bank: ${qrData['bank_name'] ?? 'Unknown'}',
                            imageHeight: 200,
                            imageWidth: double.infinity,
                            fit: BoxFit.contain,
                            showBorder: true,
                            padding: const EdgeInsets.all(8),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _isLoading ? null : () => _downloadQRCode(qrData),
                            icon: _isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.download),
                            label: Text(_isLoading ? 'Downloading...' : 'Save QR to Gallery'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  
                  const SizedBox(height: 20),
                  
                  const Text(
                    'After making payment, upload your proof below:',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  
                  if (_paymentProof == null) ...[
                    ElevatedButton.icon(
                      onPressed: _pickPaymentProof,
                      icon: const Icon(Icons.upload),
                      label: const Text('Upload Payment Proof'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.green),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Proof uploaded: ${_proofFilename ?? 'payment_proof.jpg'}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => setState(() {
                              _paymentProof = null;
                              _proofFilename = null;
                              _proofMimeType = null;
                            }),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 30),
                  
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        border: Border.all(color: Colors.red),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  
                  const SizedBox(height: 20),
                  Text(
                    'Duration: ${args['duration']} hour(s)',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Start Time: ${DateTime.now().toString().substring(0, 16)}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 40),
                  
                  ElevatedButton(
                    onPressed: _isLoading ? null : () => _processParking(args, isGuest),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: Text(
                      _paymentProof == null ? 'Upload Proof First' : 'Submit Parking',
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}