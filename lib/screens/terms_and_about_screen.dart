import 'package:flutter/material.dart';
import 'package:lungs_assistant_agent/screens/main_screen.dart';
import 'package:lungs_assistant_agent/screens/onboarding_screen.dart';

class TermsAndAboutScreen extends StatefulWidget {
  // Parameter ini diperlukan agar setelah klik "Simpan",
  // kita bisa meneruskannya ke MainScreen
  final String uid;
  final String name;
  final String role;

  const TermsAndAboutScreen({
    super.key,
    required this.uid,
    required this.name,
    required this.role,
  });

  @override
  State<TermsAndAboutScreen> createState() => _TermsAndAboutScreenState();
}

class _TermsAndAboutScreenState extends State<TermsAndAboutScreen> {
  bool _isAgreed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A8C), // Warna tema aplikasi Anda
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Area
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lungs Assistant',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Informasi & Ketentuan Layanan',
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            ),

            // White Card Content
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(36),
                    topRight: Radius.circular(36),
                  ),
                ),
                child: Column(
                  children: [
                    // Area teks yang bisa di-scroll
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(28.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // === ABOUT US ===
                            const Text(
                              'Tentang Kami (About Us)',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A1A8C),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Lungs Assistant Agent adalah aplikasi pemantauan '
                              'kesehatan paru-paru dan aktivitas harian. '
                              'Aplikasi ini dirancang untuk membantu pengguna '
                              'melacak tingkat oksigen, mencatat rutinitas, '
                              'dan mengurangi kebiasaan merokok melalui panduan '
                              'dan artikel kesehatan terpercaya.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                                height: 1.5,
                              ),
                            ),

                            const SizedBox(height: 32),

                            // === TERMS & AGREEMENTS ===
                            const Text(
                              'Syarat dan Ketentuan (Terms & Agreements)',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A1A8C),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F6FF),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Text(
                                '1. Penggunaan Data: Kami menjaga privasi data '
                                'kesehatan Anda dan hanya menggunakannya untuk '
                                'keperluan analisis personal di dalam aplikasi.\n\n'
                                '2. Bukan Nasihat Medis Pengganti: Aplikasi ini '
                                'bertindak sebagai alat bantu (asisten) dan BUKAN '
                                'pengganti diagnosis, saran, atau perawatan dari '
                                'dokter profesional.\n\n'
                                '3. Akurasi Sensor: Data oksigen dan detak jantung '
                                'yang ditampilkan bergantung pada izin dan sensor '
                                'perangkat Anda.\n\n'
                                '4. Tanggung Jawab Pengguna: Anda bertanggung '
                                'jawab penuh atas keputusan medis apa pun yang '
                                'diambil berdasarkan informasi dari aplikasi ini.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade800,
                                  height: 1.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Area Checkbox & Tombol di bagian bawah (tetap/sticky)
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            offset: const Offset(0, -4),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Checkbox
                          Row(
                            children: [
                              Checkbox(
                                value: _isAgreed,
                                activeColor: const Color(0xFF2E3192),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    _isAgreed = value ?? false;
                                  });
                                },
                              ),
                              const Expanded(
                                child: Text(
                                  'Saya telah membaca dan menyetujui Syarat '
                                  'serta Ketentuan yang berlaku.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Tombol Save / Lanjutkan
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              // Tombol akan mati (null) jika _isAgreed bernilai false
                              onPressed: _isAgreed
                                  ? () {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              OnboardingScreen(
                                                uid: widget.uid,
                                                name: widget.name,
                                                role: widget.role,
                                              ),
                                        ),
                                      );
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2E3192),
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Colors.grey.shade300,
                                disabledForegroundColor: Colors.grey.shade600,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'SIMPAN & LANJUTKAN',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
