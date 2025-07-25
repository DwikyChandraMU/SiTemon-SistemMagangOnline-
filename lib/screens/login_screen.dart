// LoginScreen.dart
import 'dart:convert';
import 'dart:io'; // Import for SocketException
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async'; // Import for TimeoutException

import 'package:sitemon/screens/admin/home_screen_admin.dart';
import 'package:sitemon/screens/pembimbing/home_screen_pembimbing.dart';
import 'package:sitemon/screens/users/pendaftaran_magang.dart';
import 'package:sitemon/screens/signup_screen.dart';
import 'package:sitemon/screens/lupa_password.dart'; // Import the new screen

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false; // State for password visibility

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // Helper function to show user-friendly error messages
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700, // Make error messages stand out
        duration:
            const Duration(seconds: 4), // Increase duration for readability
      ),
    );
  }

  Future<void> login() async {
    // Basic validation for empty fields
    if (emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      _showErrorSnackBar("Email dan password tidak boleh kosong.");
      return;
    }

    // Replace with your actual API URL
    // Pastikan IP address ini dapat diakses dari perangkat yang menjalankan aplikasi Flutter.
    // Jika menggunakan emulator, pastikan emulator bisa mengakses IP ini.
    // Jika menggunakan perangkat fisik, pastikan perangkat berada di jaringan yang sama.
    final String url = "http://192.168.50.189/sitemon_api/login.php";

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "email": emailController.text.trim(),
              "password": passwordController.text.trim(),
            }),
          )
          .timeout(const Duration(
              seconds: 10)); // Add a timeout for network requests

      // Check HTTP status code first
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData["status"] == "success") {
          final user = responseData["user"];
          final userId = int.tryParse(user["id"].toString());
          final role = user["role"];

          if (userId == null || role == null) {
            _showErrorSnackBar(
                "Data pengguna tidak lengkap. Silakan coba lagi atau hubungi administrator.");
            throw Exception(
                "Data user tidak lengkap dari API."); // For internal logging
          }

          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('user_id', userId);
          await prefs.setString('role', role);

          Widget nextScreen;
          switch (role) {
            case "user":
              nextScreen =
                  PendaftaranMagang(); // Or HomeScreenUsers() if it exists
              break;
            case "pembimbing":
              nextScreen = HomeScreenPembimbing();
              break;
            case "admin":
              nextScreen = HomeScreenAdmin();
              break;
            default:
              _showErrorSnackBar(
                  "Peran pengguna tidak dikenali. Silakan hubungi administrator.");
              setState(() {
                _isLoading = false;
              });
              return;
          }

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => nextScreen),
          );
        } else {
          // API returned 'status: fail' or similar
          final errorMessage = responseData["message"] ??
              "Login gagal. Email atau password mungkin salah.";
          _showErrorSnackBar(errorMessage);
        }
      } else if (response.statusCode == 401) {
        _showErrorSnackBar("Login gagal. Email atau password salah.");
      } else if (response.statusCode >= 500) {
        _showErrorSnackBar(
            "Terjadi masalah pada server. Mohon coba lagi nanti. (Kode: ${response.statusCode})");
      } else {
        _showErrorSnackBar(
            "Terjadi kesalahan saat login. Kode: ${response.statusCode}.");
      }
    } on SocketException {
      _showErrorSnackBar(
          "Tidak dapat terhubung ke server. Periksa koneksi internet Anda atau pastikan alamat server benar.");
    } on TimeoutException {
      _showErrorSnackBar(
          "Permintaan login memakan waktu terlalu lama. Periksa koneksi internet Anda.");
    } on FormatException {
      _showErrorSnackBar(
          "Respons dari server tidak valid. Silakan coba lagi atau hubungi administrator.");
    } catch (e) {
      // Catch any other unexpected errors
      _showErrorSnackBar(
          "Terjadi kesalahan tak terduga: ${e.toString().split(':')[0]}. Mohon coba lagi.");
      print("Login Error: $e"); // For detailed debugging in console
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 80),
                  Hero(
                    tag: 'logo',
                    child: Image.asset('assets/images/logo.png', height: 120),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Login',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildTextField(
                          label: "Email",
                          hintText: "Masukkan Email",
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 15),
                        // Password TextField with toggle
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Password",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            TextField(
                              controller: passwordController,
                              obscureText: !_isPasswordVisible,
                              decoration: InputDecoration(
                                hintText: "Masukkan Password",
                                hintStyle: const TextStyle(color: Colors.grey),
                                filled: true,
                                fillColor: Colors.grey.shade100,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordVisible
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isPasswordVisible = !_isPasswordVisible;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 25),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : login,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              backgroundColor: Colors.orangeAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                              elevation: 6,
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text(
                                    "Login",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ForgotPasswordScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      "Lupa Password?",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10), // Added some space
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SignUpScreen()),
                      );
                    },
                    child: const Text(
                      "Belum punya akun? Sign Up",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Image.asset('assets/images/ilustrasi_login.png', height: 150),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper function for building common text fields (excluding password with toggle)
  Widget _buildTextField({
    required String label,
    required String hintText,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
