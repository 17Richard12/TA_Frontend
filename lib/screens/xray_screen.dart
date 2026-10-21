import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lungs_assistant_agent/services/xray_service.dart'; // Pastikan path import sesuai

class XrayScreen extends StatefulWidget {
  final String userUid;

  const XrayScreen({super.key, required this.userUid});

  @override
  State<XrayScreen> createState() => _XrayScreenState();
}

class _XrayScreenState extends State<XrayScreen> {
  static const Color primaryBlue = Color(0xFF2F60CC);
  bool _isLoading = true;
  bool _isUploading = false;
  Map<String, dynamic>? _newestXray;
  Map<String, dynamic>? _olderXray;
  String? _aiAnalysis;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final result = await XrayService.getLatestXrayPhotos(widget.userUid);
    if (mounted) {
      if (result['status'] == 'success') {
        final data = result['data'] as Map<String, dynamic>? ?? {};
        final List<dynamic> dataList = data['xrays'] is List
            ? data['xrays'] as List
            : [];

        setState(() {
          _newestXray =
              dataList.isNotEmpty && dataList[0] is Map<String, dynamic>
              ? dataList[0] as Map<String, dynamic>
              : null;
          _olderXray =
              dataList.length > 1 && dataList[1] is Map<String, dynamic>
              ? dataList[1] as Map<String, dynamic>
              : null;

          // Tangkap data analisis AI
          _aiAnalysis = data['analysis'] as String?;
        });
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadXray() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
      );
      if (image == null) return;

      setState(() => _isUploading = true);

      final bytes = await image.readAsBytes();
      final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      final result = await XrayService.uploadXrayPhoto(
        widget.userUid,
        base64Image,
      );
      if (mounted) {
        if (result['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Berhasil upload foto X-Ray'),
              backgroundColor: primaryBlue,
            ),
          );
          _fetchData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Gagal upload'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Widget _buildXrayImage(String title, Map<String, dynamic>? data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        if (data != null && data['timestamp'] != null) ...[
          const SizedBox(height: 4),
          Text(
            _formatTimestamp(data['timestamp']),
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
        const SizedBox(height: 12),
        Container(
          height: 220,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child:
              data == null ||
                  data['foto'] == null ||
                  data['foto'].toString().isEmpty
              ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image, size: 60, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      "Belum ada gambar",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                )
              : _buildImageFromBase64(data['foto']),
        ),
      ],
    );
  }

  Widget _buildImageFromBase64(String base64String) {
    try {
      final String base64Data = base64String.contains(',')
          ? base64String.split(',').last
          : base64String;
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.memory(
          base64Decode(base64Data),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.broken_image, size: 60, color: Colors.grey),
        ),
      );
    } catch (e) {
      return const Icon(Icons.broken_image, size: 60, color: Colors.grey);
    }
  }

  String _formatTimestamp(String iso) {
    if (iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Perbandingan X-Ray',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchData,
              color: primaryBlue,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_aiAnalysis != null && _aiAnalysis!.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: primaryBlue.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: primaryBlue.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(
                                  Icons.auto_awesome,
                                  color: primaryBlue,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Analisis Agent',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: primaryBlue,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _aiAnalysis!,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),
                    _buildXrayImage('Hasil X-Ray Terbaru', _newestXray),
                    const SizedBox(height: 32),
                    _buildXrayImage('Hasil X-Ray Sebelumnya', _olderXray),
                    const SizedBox(height: 48),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isUploading ? null : _uploadXray,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: _isUploading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'Upload X-Ray Terbaru',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }
}
