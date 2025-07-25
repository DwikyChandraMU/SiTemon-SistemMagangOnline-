// main.dart

// Hak Cipta (c) 2025 Dwiky Chandra Mulyo Utomo & Gilang Setiawan.
// Semua hak dilindungi undang-undang.
// Aplikasi ini adalah properti intelektual dari Dwiky Chandra Mulyo Utomo dan Gilang Setiawan,
// mahasiswa magang UNISSULA. Dilarang mendistribusikan, memodifikasi, atau menggunakan tanpa izin tertulis.

import 'package:sitemon/screens/login_screen.dart';
import 'package:sitemon/screens/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:io';
import 'dart:convert'; // Import untuk Base64

// ENCODED Base64 string dari "Dibuat oleh Dwiky Chandra Mulyo Utomo & Gilang Setiawan (Mahasiswa Magang UNISSULA 2025)."
const String _kEncodedCopyrightText =
    "RGlidWF0IG9sZWggRHdpa3kgQ2hhbmRyYSBNdWx5byBVdG9tbyAmIEdpbGFuZyBTZXRpYXdhbiAoTWFoYXNpc3dhIE1hZ2FuZyBVTklTU1VMQSAyMDI1KS4=";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', ''), Locale('id', '')],
      home: const WelcomeScreen(),
    );
  }
}

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  // Fungsi utilitas untuk mendekode string Base64
  String _decodeBase64(String encodedString) {
    List<int> bytes = base64.decode(encodedString);
    return utf8.decode(bytes);
  }

  @override
  void initState() {
    super.initState();
    // Memanggil _checkCopyright() di awal aplikasi
    _checkCopyright();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Fungsi untuk memeriksa integritas teks copyright yang sudah di-obfuscate
  void _checkCopyright() {
    // Dekode string asli yang tersembunyi
    final String actualDisplayedCopyright =
        _decodeBase64(_kEncodedCopyrightText);

    // Untuk memastikan integritas, kita bisa membandingkan string yang didekode
    // dengan hash dari string itu sendiri, atau bahkan lebih sederhana,
    // memiliki salinan tersembunyi lain yang juga didekode.
    // Namun, cara paling umum untuk deteksi tampering sederhana adalah
    // membandingkan string yang diharapkan dengan string yang "diproses"
    // atau mencoba memicu error jika string _kEncodedCopyrightText diubah.

    // PENTING: Logika ini mendeteksi jika _kEncodedCopyrightText itu sendiri diubah.
    // Jika _kEncodedCopyrightText diubah/dihapus, maka _decodeBase64 akan gagal
    // atau menghasilkan string yang berbeda, yang bisa kita deteksi.
    // Namun, untuk contoh ini, kita akan membuat validasi yang lebih kuat
    // yang tidak hanya mengandalkan nilai _kEncodedCopyrightText itu sendiri,
    // melainkan sebuah "signature" yang juga tersembunyi.

    // Untuk lebih paten, kita bisa menambahkan "signature" tersembunyi lain.
    // Misalnya, sebuah hash dari string copyright yang sudah di-encode.
    // Ini adalah demonstrasi sederhana.

    // Contoh: Asumsikan kita punya hash SHA-256 dari _kEncodedCopyrightText
    // "RGlidWF0IG9sZWggRHdpa3kgQ2hhbmRyYSBNdWx5byBVdG9tbyAmIEdpbGFuZyBTZXRpYXdhbiAoTWFoYXNpc3dhIE1hZ2FuZyBVTklTU1VMQSAyMDI1KS4="
    // SHA-256 Hash-nya adalah:
    // 6a4f8d2b9e6c7a0d9f8e7c6b5a4d3c2b1a0f9e8d7c6b5a4d3c2b1a0f9e8d7c6b (ini hanyalah contoh, hash asli harus dihitung)
    // Untuk mendapatkan hash asli, Anda bisa menggunakan package 'crypto'

    // Untuk tujuan demonstrasi dan perbaikan error 'undefined_identifier',
    // kita akan membandingkan string yang didekode dengan konstanta string literal.
    // Ini bukan praktik terbaik untuk keamanan tingkat tinggi, tapi memperbaiki error.
    final String expectedCopyright =
        "Dibuat oleh Dwiky Chandra Mulyo Utomo & Gilang Setiawan (Mahasiswa Magang UNISSULA 2025).";

    if (actualDisplayedCopyright != expectedCopyright) {
      _showTamperWarning();
    }
  }

  void _showTamperWarning() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Peringatan Keamanan"),
          content: const Text(
            "Aplikasi telah dimodifikasi secara tidak sah. Aplikasi akan ditutup.",
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
                exit(0);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade900, Colors.blue.shade400],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FadeTransition(
                  opacity: _animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, -0.5),
                      end: Offset.zero,
                    ).animate(_controller),
                    child: Column(
                      children: [
                        Text(
                          "SiTemon",
                          style: GoogleFonts.poppins(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: Colors.yellowAccent,
                            shadows: [
                              Shadow(
                                blurRadius: 10.0,
                                color: Colors.black.withOpacity(0.3),
                                offset: const Offset(3.0, 3.0),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          "(Sistem Magang Online)",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Hero(
                  tag: 'logo',
                  child: Image.asset(
                    'assets/images/logo.png',
                    height: 180,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/images/female.png', height: 120),
                    const SizedBox(width: 30),
                    Image.asset('assets/images/male.png', height: 120),
                  ],
                ),
                const SizedBox(height: 40),
                FadeTransition(
                  opacity: _animation,
                  child: Column(
                    children: [
                      _buildAuthButton(
                        text: "LOGIN",
                        color: Colors.orange,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => LoginScreen()),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildAuthButton(
                        text: "SIGN-UP",
                        color: Colors.green,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => SignUpScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 50),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    // Menampilkan teks copyright yang sudah didekode
                    _decodeBase64(_kEncodedCopyrightText),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAuthButton({
    required String text,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 250,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 10,
          shadowColor: color.withOpacity(0.5),
        ),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }
}
