import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io'; // Import for SocketException
import 'dart:async'; // Import for TimeoutException

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController namaController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool _isPasswordVisible = false; // State for password visibility
  bool _isConfirmPasswordVisible =
      false; // State for confirm password visibility
  bool _isLoading = false; // State for loading indicator

  @override
  void dispose() {
    namaController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  // Helper function to show user-friendly error messages
  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        duration:
            const Duration(seconds: 4), // Increase duration for readability
      ),
    );
  }

  Future<void> register() async {
    // Basic validation for empty fields
    if (namaController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty ||
        confirmPasswordController.text.trim().isEmpty) {
      _showSnackBar("Harap isi semua kolom yang diperlukan.");
      return;
    }

    // Email format validation (simple check)
    if (!RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
        .hasMatch(emailController.text.trim())) {
      _showSnackBar("Format email tidak valid. Contoh: nama@example.com");
      return;
    }

    // Password length validation
    if (passwordController.text.length < 6) {
      _showSnackBar("Password minimal harus 6 karakter.");
      return;
    }

    // Password mismatch validation
    if (passwordController.text != confirmPasswordController.text) {
      _showSnackBar("Konfirmasi password tidak cocok dengan password.");
      return;
    }

    final String url = "http://192.168.50.189/sitemon_api/register.php";

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "nama": namaController.text.trim(),
              "email": emailController.text.trim(),
              "password": passwordController.text.trim(),
              "role": "user", // Default role for new registrations
            }),
          )
          .timeout(const Duration(
              seconds: 10)); // Add a timeout for network requests

      // Check HTTP status code first
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['status'] == "success") {
          _showSnackBar(
              responseData['message'] ?? "Registrasi berhasil! Silakan login.",
              isError: false);
          // Clear text fields after successful registration
          namaController.clear();
          emailController.clear();
          passwordController.clear();
          confirmPasswordController.clear();
          Navigator.pop(context); // Go back to login screen
        } else {
          // API returned 'status: fail' or similar
          final errorMessage =
              responseData['message'] ?? "Registrasi gagal. Coba lagi.";
          _showSnackBar(errorMessage);
        }
      } else if (response.statusCode == 409) {
        // Conflict, often used for email already exists
        _showSnackBar(
            "Email ini sudah terdaftar. Silakan gunakan email lain atau login.");
      } else if (response.statusCode >= 500) {
        _showSnackBar(
            "Terjadi masalah pada server. Mohon coba lagi nanti. (Kode: ${response.statusCode})");
      } else {
        _showSnackBar(
            "Terjadi kesalahan saat registrasi. Kode: ${response.statusCode}.");
      }
    } on SocketException {
      _showSnackBar(
          "Tidak dapat terhubung ke server. Periksa koneksi internet Anda atau pastikan alamat server benar.");
    } on TimeoutException {
      _showSnackBar(
          "Permintaan registrasi memakan waktu terlalu lama. Periksa koneksi internet Anda.");
    } on FormatException {
      _showSnackBar(
          "Respons dari server tidak valid. Silakan coba lagi atau hubungi administrator.");
    } catch (e) {
      // Catch any other unexpected errors
      _showSnackBar(
          "Terjadi kesalahan tak terduga: ${e.toString().split(':')[0]}. Mohon coba lagi.");
      print("Sign Up Error: $e"); // For detailed debugging in console
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
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  Hero(
                    tag: 'logo',
                    child: Image.asset('assets/images/logo.png', height: 120),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Sign Up",
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: const [
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
                          label: "Nama Lengkap",
                          hintText: "Masukkan Nama Lengkap Anda",
                          controller: namaController,
                        ),
                        const SizedBox(height: 15),
                        _buildTextField(
                          label: "Email",
                          hintText: "Masukkan Email Anda",
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 15),
                        // Password TextField with toggle
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Password",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            TextField(
                              controller: passwordController,
                              obscureText: !_isPasswordVisible,
                              decoration: InputDecoration(
                                hintText: "Buat Password (min. 6 karakter)",
                                hintStyle:
                                    TextStyle(color: Colors.grey.shade600),
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
                              style: const TextStyle(color: Colors.black87),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        // Confirm Password TextField with toggle
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Konfirmasi Password",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            TextField(
                              controller: confirmPasswordController,
                              obscureText: !_isConfirmPasswordVisible,
                              decoration: InputDecoration(
                                hintText: "Ulangi Password Anda",
                                hintStyle:
                                    TextStyle(color: Colors.grey.shade600),
                                filled: true,
                                fillColor: Colors.grey.shade100,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isConfirmPasswordVisible
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isConfirmPasswordVisible =
                                          !_isConfirmPasswordVisible;
                                    });
                                  },
                                ),
                              ),
                              style: const TextStyle(color: Colors.black87),
                            ),
                          ],
                        ),
                        const SizedBox(height: 25),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : register, // Disable button when loading
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orangeAccent,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 40,
                                vertical: 12,
                              ),
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
                                    "Daftar",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      "Sudah memiliki akun? Login",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Image.asset(
                    'assets/images/ilustrasi_signup.png',
                    height: 160,
                  ),
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
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey.shade600),
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
          style: const TextStyle(color: Colors.black87),
        ),
      ],
    );
  }
}
