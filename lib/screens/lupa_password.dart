// forgot_password_screen.dart
import 'dart:convert';
import 'dart:io'; // Import for SocketException
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async'; // Import for TimeoutException

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmNewPasswordController =
      TextEditingController();
  bool _isLoading = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    emailController.dispose();
    newPasswordController.dispose();
    confirmNewPasswordController.dispose();
    super.dispose();
  }

  // Helper function to show user-friendly messages (error or success)
  void _showSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isSuccess ? Colors.green.shade700 : Colors.red.shade700,
        duration:
            const Duration(seconds: 4), // Increase duration for readability
      ),
    );
  }

  Future<void> resetPassword() async {
    // Basic validation for empty fields
    if (emailController.text.trim().isEmpty ||
        newPasswordController.text.trim().isEmpty ||
        confirmNewPasswordController.text.trim().isEmpty) {
      _showSnackBar(
          "Semua kolom (Email, Password Baru, Konfirmasi Password) wajib diisi!");
      return;
    }

    // Email format validation (simple check)
    if (!RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
        .hasMatch(emailController.text.trim())) {
      _showSnackBar("Format email tidak valid. Contoh: nama@example.com");
      return;
    }

    // Password length validation
    if (newPasswordController.text.length < 6) {
      _showSnackBar("Password baru harus minimal 6 karakter.");
      return;
    }

    // Password mismatch validation
    if (newPasswordController.text != confirmNewPasswordController.text) {
      _showSnackBar("Konfirmasi password tidak cocok dengan password baru.");
      return;
    }

    // Replace with your actual API URL
    final String url = "http://192.168.50.189/sitemon_api/lupa_password.php";

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
              "new_password": newPasswordController.text.trim(),
            }),
          )
          .timeout(const Duration(
              seconds: 10)); // Add a timeout for network requests

      // Check HTTP status code first
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData["status"] == "success") {
          _showSnackBar(
              responseData["message"] ??
                  "Password berhasil direset! Silakan login dengan password baru.",
              isSuccess: true);
          // Clear text fields after successful reset
          emailController.clear();
          newPasswordController.clear();
          confirmNewPasswordController.clear();
          Navigator.pop(context); // Go back to login screen
        } else {
          // API returned 'status: fail' or similar
          final errorMessage = responseData["message"] ??
              "Gagal mereset password. Email mungkin tidak terdaftar atau ada masalah lain.";
          _showSnackBar(errorMessage);
        }
      } else if (response.statusCode == 404) {
        // Not Found, often for email not registered
        _showSnackBar(
            "Email ini tidak terdaftar. Pastikan Anda memasukkan email yang benar.");
      } else if (response.statusCode >= 500) {
        _showSnackBar(
            "Terjadi masalah pada server. Mohon coba lagi nanti. (Kode: ${response.statusCode})");
      } else {
        _showSnackBar(
            "Terjadi kesalahan saat mereset password. Kode: ${response.statusCode}.");
      }
    } on SocketException {
      _showSnackBar(
          "Tidak dapat terhubung ke server. Periksa koneksi internet Anda atau pastikan alamat server benar.");
    } on TimeoutException {
      _showSnackBar(
          "Permintaan reset password memakan waktu terlalu lama. Periksa koneksi internet Anda.");
    } on FormatException {
      _showSnackBar(
          "Respons dari server tidak valid. Silakan coba lagi atau hubungi administrator.");
    } catch (e) {
      // Catch any other unexpected errors
      _showSnackBar(
          "Terjadi kesalahan tak terduga: ${e.toString().split(':')[0]}. Mohon coba lagi.");
      print("Reset Password Error: $e"); // For detailed debugging in console
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
                  const SizedBox(height: 50),
                  const Text(
                    'Reset Password Anda',
                    textAlign: TextAlign.center,
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
                          label: "Email Anda",
                          hintText: "Masukkan Email",
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 15),
                        _buildPasswordTextField(
                          label: "Password Baru",
                          hintText: "Masukkan Password Baru (min. 6 karakter)",
                          controller: newPasswordController,
                          isVisible: _isNewPasswordVisible,
                          onToggle: () {
                            setState(() {
                              _isNewPasswordVisible = !_isNewPasswordVisible;
                            });
                          },
                        ),
                        const SizedBox(height: 15),
                        _buildPasswordTextField(
                          label: "Konfirmasi Password Baru",
                          hintText: "Konfirmasi Password Baru",
                          controller: confirmNewPasswordController,
                          isVisible: _isConfirmPasswordVisible,
                          onToggle: () {
                            setState(() {
                              _isConfirmPasswordVisible =
                                  !_isConfirmPasswordVisible;
                            });
                          },
                        ),
                        const SizedBox(height: 25),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : resetPassword,
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
                                    "Reset Password",
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
                  const SizedBox(height: 30),
                  // Optionally add an image or other elements here if desired
                  // Example: Image.asset('assets/images/ilustrasi_reset_password.png', height: 150),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper function for building general text fields
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

  // Helper function for building password text fields with toggle
  Widget _buildPasswordTextField({
    required String label,
    required String hintText,
    required TextEditingController controller,
    required bool isVisible,
    required VoidCallback onToggle,
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
          obscureText: !isVisible,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                isVisible ? Icons.visibility : Icons.visibility_off,
                color: Colors.grey,
              ),
              onPressed: onToggle,
            ),
          ),
        ),
      ],
    );
  }
}
