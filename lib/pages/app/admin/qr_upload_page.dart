import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uniparkpay/widgets/app/content_page.dart';
import 'package:uniparkpay/app/qr_manager.dart';
import 'package:uniparkpay/auth/auth_provider.dart';
import 'package:uniparkpay/widgets/image_viewer.dart';
import 'package:provider/provider.dart';

class QRUploadPage extends ContentPage {
  const QRUploadPage({super.key}) : super(title: 'QR Payment Code');

  @override
  State<QRUploadPage> createState() => _QRUploadPageState();
}

class _QRUploadPageState extends State<QRUploadPage> {
  final QRManager qrManager = QRManager();
  final TextEditingController _bankNameController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  
  Uint8List? _selectedImage;
  String? _selectedImageName;
  String? _selectedMimeType;
  bool _isUploading = false;
  String? _uploadError;
  int _refreshKey = 0;

  @override
  void dispose() {
    _bankNameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (image != null) {
      final bytes = await image.readAsBytes();
      final mimeType = image.mimeType ?? 'image/png';
      final fileName = image.name;

      setState(() {
        _selectedImage = bytes;
        _selectedImageName = fileName;
        _selectedMimeType = mimeType;
        _uploadError = null;
      });
    }
  }

  Future<bool> _uploadQR() async {
    if (_selectedImage == null || _bankNameController.text.isEmpty) {
      setState(() {
        _uploadError = 'Please select an image and enter bank name';
      });
      return false;
    }

    setState(() {
      _isUploading = true;
      _uploadError = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.id;
      
      if (userId == null) {
        setState(() {
          _uploadError = 'User not authenticated';
          _isUploading = false;
        });
        return false;
      }

      await qrManager.uploadQR(
        filename: _selectedImageName!,
        bankName: _bankNameController.text,
        imageData: _selectedImage!,
        mimeType: _selectedMimeType!,
        userId: userId,
      );

      // Reset form and trigger rebuild with refresh key
      setState(() {
        _selectedImage = null;
        _selectedImageName = null;
        _selectedMimeType = null;
        _bankNameController.clear();
        _isUploading = false;
        _refreshKey++; // This will trigger FutureBuilder rebuild
      });

      return true;
    } catch (e) {
      setState(() {
        _uploadError = 'Failed to upload QR code: $e';
        _isUploading = false;
      });
      return false;
    }
  }

  Widget _buildCurrentQRDisplay(Map<String, dynamic>? qrData) {
    if (qrData == null || qrData['qr_image'] == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(Icons.qr_code_2, size: 64, color: Colors.grey),
              SizedBox(height: 8),
              Text('No QR code uploaded yet', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    final metadata = {
      'Bank': (qrData['bank_name'] ?? 'Unknown').toString(),
      'Filename': (qrData['filename'] ?? 'Unknown').toString(),
      'Uploaded': (qrData['created_at'] ?? 'Unknown').toString(),
    };

    return ImageViewerWithMetadata(
      imageData: qrData['qr_image'],
      title: 'Current QR Code',
      metadata: metadata,
      imageHeight: 200,
      padding: const EdgeInsets.all(16.0),
    );
  }

  Widget _buildUploadForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Upload New QR Code', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            if (_uploadError != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _uploadError!,
                  style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            if (_selectedImage != null) ...[
              Center(
                child: Image.memory(
                  _selectedImage!,
                  height: 150,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  _selectedImageName ?? 'Selected image',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            ElevatedButton.icon(
              onPressed: _isUploading ? null : _pickImage,
              icon: const Icon(Icons.image),
              label: Text(_selectedImage == null ? 'Select Image' : 'Change Image'),
            ),
            
            const SizedBox(height: 16),
            TextField(
              controller: _bankNameController,
              enabled: !_isUploading,
              decoration: const InputDecoration(
                labelText: 'Bank Name',
                hintText: 'e.g., Maybank, CIMB, RHB',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.account_balance),
              ),
            ),
            
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isUploading ? null : () async {
                  final success = await _uploadQR();
                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('QR code uploaded successfully')),
                    );
                    setState(() {});
                  }
                },
                icon: _isUploading 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.upload),
                label: Text(_isUploading ? 'Uploading...' : 'Upload QR Code'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>?>(
        key: ValueKey(_refreshKey),
        future: qrManager.getCurrentQR(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() => _refreshKey++),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final currentQR = snapshot.data;

          return RefreshIndicator(
            onRefresh: () async => setState(() => _refreshKey++),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildCurrentQRDisplay(currentQR),
                  const SizedBox(height: 16),
                  _buildUploadForm(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}