import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lungs_assistant_agent/services/xray_service.dart';

class XrayScreen extends StatefulWidget {
  final String userUid;

  const XrayScreen({super.key, required this.userUid});

  @override
  State<XrayScreen> createState() => _XrayScreenState();
}

class _XrayScreenState extends State<XrayScreen> {
  static const Color primaryBlue = Color(0xFF2F60CC);
  static const Color primaryDark = Color(0xFF1A1A8C);
  bool _isLoading = true;
  bool _isUploading = false;
  bool _isAnalyzing = false;
  Map<String, dynamic>? _newestXray;
  Map<String, dynamic>? _olderXray;
  bool _isPickerActive = false;
  String? _aiAnalysis;

  final ImagePicker _picker = ImagePicker();

  static const Set<String> _allowedExtensions = {'jpg', 'jpeg', 'png', 'webp'};
  static const int _maxFileBytes = 5 * 1024 * 1024; // 5 MB

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

          final rawAnalysis = (data['analysis'] as String?)?.trim() ?? '';
          _aiAnalysis = rawAnalysis.isNotEmpty ? rawAnalysis : null;
        });
      }
      setState(() => _isLoading = false);
    }
  }

  void _showValidationErrorDialog(String message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                color: Colors.redAccent,
                size: 34,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Gambar Ditolak',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Mengerti',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAnalysisBottomSheet(String analysisText) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryBlue.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: primaryBlue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Hasil Analisis AI — Perbandingan X-Ray',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryBlue.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: primaryBlue.withValues(alpha: 0.25)),
              ),
              child: Text(
                analysisText,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryDark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Tutup',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadXray() async {
    if (_isPickerActive || _isUploading) return;
    _isPickerActive = true;

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (image == null) {
        _isPickerActive = false;
        return;
      }

      // Pre-processing client-side: validasi ekstensi & ukuran file
      final ext = image.name.split('.').last.toLowerCase();
      if (!_allowedExtensions.contains(ext)) {
        _isPickerActive = false;
        if (mounted) {
          _showValidationErrorDialog(
            'Format file .$ext tidak didukung. Silakan unggah gambar X-Ray berformat JPG, PNG, atau WEBP.',
          );
        }
        return;
      }

      final bytes = await image.readAsBytes();
      if (bytes.length > _maxFileBytes) {
        _isPickerActive = false;
        if (mounted) {
          _showValidationErrorDialog(
            'Ukuran gambar melebihi batas maksimal 5 MB. Silakan pilih file yang lebih kecil.',
          );
        }
        return;
      }

      setState(() => _isUploading = true);

      final mimeType = ext == 'png'
          ? 'image/png'
          : (ext == 'webp' ? 'image/webp' : 'image/jpeg');
      final base64Image = 'data:$mimeType;base64,${base64Encode(bytes)}';

      final result = await XrayService.uploadXrayPhoto(
        widget.userUid,
        base64Image,
      );
      if (mounted) {
        if (result['status'] == 'success') {
          await _fetchData();
        } else {
          _showValidationErrorDialog(
            result['message'] ??
                'Gambar yang diunggah bukan kategori gambar medis X-Ray.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showValidationErrorDialog('Gagal mengunggah gambar: $e');
      }
    } finally {
      _isPickerActive = false;
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _startAnalysis() async {
    if (_isAnalyzing) return;
    if (_newestXray == null || _olderXray == null) {
      _showValidationErrorDialog(
        'Dibutuhkan minimal 2 gambar X-Ray (Terbaru & Sebelumnya) untuk menjalankan perbandingan AI. Silakan unggah gambar terlebih dahulu.',
      );
      return;
    }

    setState(() => _isAnalyzing = true);
    try {
      final res = await XrayService.startXrayAnalysis(widget.userUid);
      if (!mounted) return;
      if (res['status'] == 'success') {
        final analysis = res['analysis']?.toString() ?? '';
        setState(() => _aiAnalysis = analysis);
        _showAnalysisBottomSheet(analysis);
      } else {
        _showValidationErrorDialog(
          res['message'] ?? 'Gagal menjalankan analisis X-Ray.',
        );
      }
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  Widget _buildXrayImage(
    String title,
    Map<String, dynamic>? data, {
    bool isClickable = true,
  }) {
    final bool hasImage =
        data != null &&
        data['foto'] != null &&
        data['foto'].toString().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isClickable)
              TextButton.icon(
                onPressed: _isUploading ? null : _uploadXray,
                icon: const Icon(Icons.upload_file, size: 16),
                label: Text(
                  hasImage ? 'Ganti / Upload Baru' : 'Klik untuk Upload',
                ),
                style: TextButton.styleFrom(
                  foregroundColor: primaryBlue,
                  visualDensity: VisualDensity.compact,
                ),
              ),
          ],
        ),
        if (data != null && data['timestamp'] != null) ...[
          const SizedBox(height: 2),
          Text(
            _formatTimestamp(data['timestamp']),
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
        const SizedBox(height: 10),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isClickable && !_isUploading ? _uploadXray : null,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isClickable
                      ? primaryBlue.withValues(alpha: 0.4)
                      : Colors.grey.shade300,
                  width: 1.5,
                ),
              ),
              child: !hasImage
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 56,
                          color: isClickable ? primaryBlue : Colors.grey,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isClickable
                              ? 'Ketuk area ini untuk mengunggah foto X-Ray'
                              : 'Belum ada gambar sebelumnya',
                          style: TextStyle(
                            color: isClickable ? primaryBlue : Colors.grey,
                            fontWeight: isClickable
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    )
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildImageFromBase64(data['foto']),
                        if (isClickable)
                          Positioned(
                            right: 12,
                            bottom: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.touch_app,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Ketuk untuk upload baru',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
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
        borderRadius: BorderRadius.circular(15),
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
    final bool canAnalyze = _newestXray != null && _olderXray != null;
    final bool hasSavedAnalysis =
        _aiAnalysis != null &&
        _aiAnalysis!.isNotEmpty &&
        !_aiAnalysis!.startsWith('Belum ada') &&
        !_aiAnalysis!.startsWith('Upload satu');

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
                    _buildXrayImage(
                      'Hasil X-Ray Terbaru',
                      _newestXray,
                      isClickable: true,
                    ),
                    const SizedBox(height: 28),
                    _buildXrayImage(
                      'Hasil X-Ray Sebelumnya',
                      _olderXray,
                      isClickable: true,
                    ),
                    const SizedBox(height: 32),

                    // Tombol Upload X-Ray Terbaru
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: _isUploading ? null : _uploadXray,
                        icon: _isUploading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: primaryBlue,
                                ),
                              )
                            : const Icon(Icons.cloud_upload_outlined),
                        label: Text(
                          _isUploading
                              ? 'Mengunggah & Memvalidasi...'
                              : 'Upload X-Ray Terbaru',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryBlue,
                          side: const BorderSide(
                            color: primaryBlue,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Tombol Manual Start Analysis
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: (_isAnalyzing || _isUploading)
                            ? null
                            : _startAnalysis,
                        icon: _isAnalyzing
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Icon(Icons.auto_awesome),
                        label: Text(
                          _isAnalyzing
                              ? 'AI Sedang Menganalisis...'
                              : 'Start Analysis',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: canAnalyze
                              ? primaryDark
                              : Colors.grey.shade400,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),

                    if (hasSavedAnalysis) ...[
                      const SizedBox(height: 14),
                      Center(
                        child: TextButton.icon(
                          onPressed: () =>
                              _showAnalysisBottomSheet(_aiAnalysis!),
                          icon: const Icon(Icons.visibility_outlined, size: 18),
                          label: const Text('Lihat Hasil Analisis Terakhir'),
                          style: TextButton.styleFrom(
                            foregroundColor: primaryBlue,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }
}
