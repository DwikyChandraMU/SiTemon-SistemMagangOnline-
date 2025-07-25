import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For FilteringTextInputFormatter
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:sitemon/models/auth_services.dart'; // Ensure this path is correct
import 'package:file_picker/file_picker.dart'; // Import for file picking
// import 'package:open_filex/open_filex.dart'; // Uncomment if you want to open files after upload

// Import other navigation pages (for BottomNavigationBar)
import 'package:sitemon/screens/pembimbing/home_screen_pembimbing.dart';
import 'package:sitemon/screens/pembimbing/manajemen_tugas.dart';
import 'package:sitemon/screens/pembimbing/penilaian_feedback.dart';
import 'package:sitemon/screens/pembimbing/riwayat_absensi.dart';
import 'package:sitemon/screens/pembimbing/profile_pembimbing.dart';

class PenilaianAkhirPage extends StatefulWidget {
  const PenilaianAkhirPage({super.key});

  @override
  _PenilaianAkhirPageState createState() => _PenilaianAkhirPageState();
}

class _PenilaianAkhirPageState extends State<PenilaianAkhirPage> {
  List<Map<String, dynamic>> _siswaList = [];
  bool _isLoading = true;
  String? _errorMessage;
  int? _currentPembimbingId;

  // Pastikan ini adalah IP yang dapat diakses oleh emulator/perangkat Anda
  // UNTUK ANDROID EMULATOR, gunakan 192.168.50.189 untuk mengakses localhost PC Anda.
  // Jika menggunakan perangkat fisik, gunakan IP lokal PC Anda (misal 192.168.1.XXX)
  final String _baseUrl =
      'http://192.168.50.189/sitemon_api/pembimbing/penilaian_akhir'; // Changed to 192.168.50.189 for emulator consistency

  // Map to store text editing controllers for each student's component scores
  final Map<int, TextEditingController> _nilaiKompetensiControllers = {};
  final Map<int, TextEditingController> _nilaiDisiplinKerjaControllers = {};
  final Map<int, TextEditingController> _nilaiKerjasamaControllers = {};
  final Map<int, TextEditingController> _nilaiInisiatifControllers = {};
  final Map<int, TextEditingController> _nilaiKerajinanControllers = {};
  final Map<int, TextEditingController> _nilaiTanggungJawabControllers = {};
  final Map<int, TextEditingController> _nilaiSopanSantunControllers = {};
  final Map<int, TextEditingController> _nilaiKehadiranControllers = {};

  final Map<int, TextEditingController> _komentarAkhirControllers = {};
  final Map<int, bool> _layakSertifikatStatus = {};
  final Map<int, String?> _uploadedFilename =
      {}; // To store the uploaded filename

  @override
  void initState() {
    super.initState();
    _loadPembimbingIdAndFetchSiswa();
  }

  @override
  void dispose() {
    // Dispose all controllers to prevent memory leaks
    _nilaiKompetensiControllers.forEach(
      (id, controller) => controller.dispose(),
    );
    _nilaiDisiplinKerjaControllers.forEach(
      (id, controller) => controller.dispose(),
    );
    _nilaiKerjasamaControllers.forEach(
      (id, controller) => controller.dispose(),
    );
    _nilaiInisiatifControllers.forEach(
      (id, controller) => controller.dispose(),
    );
    _nilaiKerajinanControllers.forEach(
      (id, controller) => controller.dispose(),
    );
    _nilaiTanggungJawabControllers.forEach(
      (id, controller) => controller.dispose(),
    );
    _nilaiSopanSantunControllers.forEach(
      (id, controller) => controller.dispose(),
    );
    _nilaiKehadiranControllers.forEach(
      (id, controller) => controller.dispose(),
    );
    _komentarAkhirControllers.forEach((id, controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _loadPembimbingIdAndFetchSiswa() async {
    int? id = await AuthService.getUserId();
    if (!mounted) return;

    setState(() {
      _currentPembimbingId = id;
    });

    if (_currentPembimbingId != null) {
      await _fetchSiswaForPenilaian();
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = "ID Pembimbing tidak ditemukan. Harap login ulang.";
      });
    }
  }

  Future<void> _fetchSiswaForPenilaian() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (_currentPembimbingId == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Pembimbing ID tidak tersedia.";
      });
      return;
    }

    final url = Uri.parse(
      '$_baseUrl/get_siswa_for_penilaian.php?pembimbing_id=$_currentPembimbingId',
    );
    print('DEBUG FETCH: Mengambil data siswa untuk penilaian dari: $url');

    try {
      final response = await http.get(url);

      if (!mounted) return;

      print('DEBUG FETCH: Raw response status code: ${response.statusCode}');
      print('DEBUG FETCH: Raw response body: ${response.body}');

      if (response.statusCode == 200) {
        if (response.body.isEmpty || !response.body.trim().startsWith('{')) {
          _showSnackBar(
            "Respons server tidak valid atau kosong (bukan JSON). Cek log PHP.",
          );
          setState(() {
            _isLoading = false;
            _errorMessage = "Respons server tidak valid atau kosong.";
          });
          return;
        }

        final Map<String, dynamic> responseBody = jsonDecode(response.body);

        if (responseBody['status'] == true) {
          if (responseBody['data'] != null && responseBody['data'] is List) {
            List<Map<String, dynamic>> data =
                (responseBody['data'] as List<dynamic>)
                    .map((item) => item as Map<String, dynamic>)
                    .toList();

            // Clear existing controllers and states before re-populating
            _nilaiKompetensiControllers.clear();
            _nilaiDisiplinKerjaControllers.clear();
            _nilaiKerjasamaControllers.clear();
            _nilaiInisiatifControllers.clear();
            _nilaiKerajinanControllers.clear();
            _nilaiTanggungJawabControllers.clear();
            _nilaiSopanSantunControllers.clear();
            _nilaiKehadiranControllers.clear();
            _komentarAkhirControllers.clear();
            _layakSertifikatStatus.clear();
            _uploadedFilename.clear(); // Clear uploaded filename map

            for (var siswa in data) {
              int userId = siswa['user_id'];

              // Initialize controllers with existing data or empty string if null
              _nilaiKompetensiControllers[userId] = TextEditingController(
                text: (siswa['nilai_kompetensi'] as num?)?.toString() ?? '',
              );
              _nilaiDisiplinKerjaControllers[userId] = TextEditingController(
                text: (siswa['nilai_disiplin_kerja'] as num?)?.toString() ?? '',
              );
              _nilaiKerjasamaControllers[userId] = TextEditingController(
                text: (siswa['nilai_kerjasama'] as num?)?.toString() ?? '',
              );
              _nilaiInisiatifControllers[userId] = TextEditingController(
                text: (siswa['nilai_inisiatif'] as num?)?.toString() ?? '',
              );
              _nilaiKerajinanControllers[userId] = TextEditingController(
                text: (siswa['nilai_kerajinan'] as num?)?.toString() ?? '',
              );
              _nilaiTanggungJawabControllers[userId] = TextEditingController(
                text: (siswa['nilai_tanggung_jawab'] as num?)?.toString() ?? '',
              );
              _nilaiSopanSantunControllers[userId] = TextEditingController(
                text: (siswa['nilai_sopan_santun'] as num?)?.toString() ?? '',
              );
              _nilaiKehadiranControllers[userId] = TextEditingController(
                text: (siswa['nilai_kehadiran'] as num?)?.toString() ?? '',
              );

              _komentarAkhirControllers[userId] = TextEditingController(
                text: siswa['komentar_akhir']?.toString() ?? '',
              );
              _layakSertifikatStatus[userId] =
                  siswa['layak_sertifikat'] ?? false;
              // Initialize uploaded filename
              _uploadedFilename[userId] =
                  siswa['nilai_file_path']; // Ensure PHP returns this field
            }

            setState(() {
              _siswaList = data;
            });
            print(
              'DEBUG FETCH: Data siswa untuk penilaian berhasil dimuat. Jumlah: ${_siswaList.length}',
            );
          } else {
            _showSnackBar("Format data siswa tidak valid dari server.");
            setState(() {
              _siswaList = [];
              _errorMessage = responseBody['message'] ??
                  "Format data tidak valid dari server.";
            });
          }
        } else {
          _showSnackBar(
            "Gagal memuat daftar siswa: ${responseBody['message'] ?? 'Pesan tidak diketahui'}",
          );
          setState(() {
            _siswaList = [];
            _errorMessage =
                responseBody['message'] ?? "Terjadi kesalahan pada server.";
          });
        }
      } else {
        _showSnackBar(
          "Gagal memuat daftar siswa: Server mengembalikan status ${response.statusCode}. Cek log debug untuk detail.",
        );
        setState(() {
          _errorMessage =
              "Server error: ${response.statusCode}. Body: ${response.body}";
        });
      }
    } catch (e) {
      if (mounted) {
        if (e is FormatException) {
          _showSnackBar(
            "Koneksi gagal: Respons server bukan JSON. Cek log PHP. Detail: ${e.message}",
          );
          print("DEBUG FETCH: FormatException detail: ${e.message}");
        } else {
          _showSnackBar("Koneksi gagal: Tidak dapat terhubung ke server. $e");
        }
      }
      print("DEBUG FETCH: Error saat _fetchSiswaForPenilaian: $e");
      setState(() {
        _errorMessage = "Koneksi gagal: $e";
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Helper function to get predikat based on score
  String _getPredikat(double score) {
    if (score >= 90) {
      return "Sangat Baik";
    } else if (score >= 80) {
      return "Baik";
    } else if (score >= 70) {
      return "Cukup";
    } else if (score >= 60) {
      return "Kurang";
    } else {
      return "Sangat Kurang";
    }
  }

  // Calculates the final score based on image's structure
  // Returns a map with 'rata_rata_nilai_sikap', 'rata_rata_nilai_kompetensi', 'total_nilai_akhir'
  Map<String, double> _calculateFinalScores(int userId) {
    // KOMPONEN SIKAP (7 komponen)
    double nilaiDisiplinKerja =
        double.tryParse(_nilaiDisiplinKerjaControllers[userId]?.text ?? '') ??
            0.0;
    double nilaiKerjasama =
        double.tryParse(_nilaiKerjasamaControllers[userId]?.text ?? '') ?? 0.0;
    double nilaiInisiatif =
        double.tryParse(_nilaiInisiatifControllers[userId]?.text ?? '') ?? 0.0;
    double nilaiKerajinan =
        double.tryParse(_nilaiKerajinanControllers[userId]?.text ?? '') ?? 0.0;
    double nilaiTanggungJawab =
        double.tryParse(_nilaiTanggungJawabControllers[userId]?.text ?? '') ??
            0.0;
    double nilaiSopanSantun =
        double.tryParse(_nilaiSopanSantunControllers[userId]?.text ?? '') ??
            0.0;
    double nilaiKehadiran =
        double.tryParse(_nilaiKehadiranControllers[userId]?.text ?? '') ?? 0.0;

    // Rata-rata Nilai Sikap (A)
    double rataRataNilaiSikap = (nilaiDisiplinKerja +
            nilaiKerjasama +
            nilaiInisiatif +
            nilaiKerajinan +
            nilaiTanggungJawab +
            nilaiSopanSantun +
            nilaiKehadiran) /
        7.0; // Rata-rata dari 7 komponen sikap
    rataRataNilaiSikap = double.parse(rataRataNilaiSikap.toStringAsFixed(2));

    // Rata-rata Nilai Kompetensi (B) - Hanya 1 komponen ini
    double rataRataNilaiKompetensi =
        double.tryParse(_nilaiKompetensiControllers[userId]?.text ?? '') ?? 0.0;
    rataRataNilaiKompetensi = double.parse(
      rataRataNilaiKompetensi.toStringAsFixed(2),
    );

    // Nilai Rata-rata Akhir (A+B)/2
    double totalNilaiAkhir =
        (rataRataNilaiSikap + rataRataNilaiKompetensi) / 2.0;
    totalNilaiAkhir = double.parse(totalNilaiAkhir.toStringAsFixed(2));

    return {
      'rata_rata_nilai_sikap': rataRataNilaiSikap,
      'rata_rata_nilai_kompetensi': rataRataNilaiKompetensi,
      'total_nilai_akhir': totalNilaiAkhir,
    };
  }

  Future<void> _submitPenilaianAkhir(int userId) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true; // Activate loading indicator at the very beginning
    });

    if (_currentPembimbingId == null) {
      _showSnackBar("ID Pembimbing tidak ditemukan. Harap login ulang.");
      setState(() {
        _isLoading = false; // Deactivate loading indicator on error
      });
      return;
    }

    // Retrieve and validate all component scores
    double nilaiKompetensi =
        double.tryParse(_nilaiKompetensiControllers[userId]?.text ?? '') ?? 0.0;
    double nilaiDisiplinKerja =
        double.tryParse(_nilaiDisiplinKerjaControllers[userId]?.text ?? '') ??
            0.0;
    double nilaiKerjasama =
        double.tryParse(_nilaiKerjasamaControllers[userId]?.text ?? '') ?? 0.0;
    double nilaiInisiatif =
        double.tryParse(_nilaiInisiatifControllers[userId]?.text ?? '') ?? 0.0;
    double nilaiKerajinan =
        double.tryParse(_nilaiKerajinanControllers[userId]?.text ?? '') ?? 0.0;
    double nilaiTanggungJawab =
        double.tryParse(_nilaiTanggungJawabControllers[userId]?.text ?? '') ??
            0.0;
    double nilaiSopanSantun =
        double.tryParse(_nilaiSopanSantunControllers[userId]?.text ?? '') ??
            0.0;
    double nilaiKehadiran =
        double.tryParse(_nilaiKehadiranControllers[userId]?.text ?? '') ?? 0.0;

    final String komentarAkhir =
        _komentarAkhirControllers[userId]?.text.trim() ?? '';
    final bool layakSertifikat = _layakSertifikatStatus[userId] ?? false;

    // Validate that all component scores are between 0 and 100
    List<double> scoresToValidate = [
      nilaiKompetensi,
      nilaiDisiplinKerja,
      nilaiKerjasama,
      nilaiInisiatif,
      nilaiKerajinan,
      nilaiTanggungJawab,
      nilaiSopanSantun,
      nilaiKehadiran,
    ];

    for (var score in scoresToValidate) {
      if (score < 0 || score > 100) {
        _showSnackBar("Semua nilai komponen harus angka antara 0 dan 100.");
        setState(() {
          _isLoading =
              false; // Deactivate loading indicator on validation error
        });
        return;
      }
    }

    // Calculate final scores based on the new logic
    final Map<String, double> calculatedScores = _calculateFinalScores(userId);
    final double totalNilaiAkhir = calculatedScores['total_nilai_akhir']!;

    final url = Uri.parse('$_baseUrl/submit_penilaian_akhir.php');
    print('DEBUG SUBMIT: Mengirim penilaian akhir ke URL: $url');
    print(
      'DEBUG SUBMIT: Data dikirim: {user_id: $userId, pembimbing_id: $_currentPembimbingId, '
      'nilai_kompetensi: $nilaiKompetensi, nilai_disiplin_kerja: $nilaiDisiplinKerja, '
      'nilai_kerjasama: $nilaiKerjasama, nilai_inisiatif: $nilaiInisiatif, '
      'nilai_kerajinan: $nilaiKerajinan, nilai_tanggung_jawab: $nilaiTanggungJawab, '
      'nilai_sopan_santun: $nilaiSopanSantun, nilai_kehadiran: $nilaiKehadiran, '
      'total_nilai_akhir: $totalNilaiAkhir, layak_sertifikat: $layakSertifikat, '
      'komentar_akhir: "$komentarAkhir"}',
    );

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": userId,
          "pembimbing_id": _currentPembimbingId,
          "nilai_kompetensi": nilaiKompetensi,
          "nilai_disiplin_kerja": nilaiDisiplinKerja,
          "nilai_kerjasama": nilaiKerjasama,
          "nilai_inisiatif": nilaiInisiatif,
          "nilai_kerajinan": nilaiKerajinan,
          "nilai_tanggung_jawab": nilaiTanggungJawab,
          "nilai_sopan_santun": nilaiSopanSantun,
          "nilai_kehadiran": nilaiKehadiran,
          "total_nilai_akhir":
              totalNilaiAkhir, // Send the calculated total score
          "layak_sertifikat": layakSertifikat,
          "komentar_akhir": komentarAkhir,
        }),
      );

      if (!mounted) return;

      print('DEBUG SUBMIT: Raw response status code: ${response.statusCode}');
      print('DEBUG SUBMIT: Raw response body: ${response.body}');

      if (response.statusCode == 200) {
        if (response.body.isEmpty || !response.body.trim().startsWith('{')) {
          _showSnackBar(
            "Respons server tidak valid atau kosong (bukan JSON). Cek log PHP.",
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }

        final resBody = jsonDecode(response.body);
        if (resBody['status'] == true) {
          _showSnackBar("Penilaian akhir berhasil disimpan!");
          _fetchSiswaForPenilaian(); // Refresh data after successful submission
        } else {
          _showSnackBar(
            "Gagal menyimpan penilaian akhir: ${resBody['message'] ?? 'Pesan tidak diketahui'}",
          );
        }
      } else {
        _showSnackBar(
          "Gagal menyimpan penilaian akhir: Server mengembalikan status ${response.statusCode}. Cek log debug untuk detail.",
        );
      }
    } catch (e) {
      if (mounted) {
        if (e is FormatException) {
          _showSnackBar(
            "Koneksi gagal saat menyimpan penilaian akhir: Respons server bukan JSON. Cek log PHP. Detail: ${e.message}",
          );
          print("DEBUG SUBMIT: FormatException detail: ${e.message}");
        } else {
          _showSnackBar("Koneksi gagal saat menyimpan penilaian akhir: $e");
        }
      }
      print("DEBUG SUBMIT: Error saat _submitPenilaianAkhir: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // Deactivate loading indicator
        });
      }
    }
  }

  // --- NEW: Function to handle file upload ---
  Future<void> _uploadNilaiFile(int userId, String studentName) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'pdf',
        'csv',
        'xlsx',
        'doc',
        'docx',
      ], // Allowed file types
    );

    if (result != null) {
      PlatformFile file = result.files.first;

      bool dialogIsOpen = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
              'Mengunggah File Nilai',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            content: Row(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 20),
                Expanded(
                  child: Text(
                    'Mengunggah file nilai untuk $studentName...',
                    style: GoogleFonts.poppins(),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        },
      ).then((_) {
        dialogIsOpen = false;
      });

      try {
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('$_baseUrl/upload_nilai_file.php'), // NEW PHP ENDPOINT
        );
        request.fields['user_id'] = userId.toString();
        request.fields['pembimbing_id'] =
            _currentPembimbingId.toString(); // Send pembimbing_id
        request.files.add(
          await http.MultipartFile.fromPath(
            'nilai_file', // Name of the file field in PHP
            file.path!,
            filename: file.name,
          ),
        );

        var response = await request.send().timeout(
              const Duration(seconds: 60),
            );
        var responseBody = await response.stream.bytesToString();
        final decodedResponse = json.decode(responseBody);

        if (dialogIsOpen && mounted) {
          Navigator.pop(context); // Close loading dialog
        }

        if (decodedResponse['status'] == true ||
            decodedResponse['status'] == 'success') {
          _showSnackBar(decodedResponse['message']);
          _fetchSiswaForPenilaian(); // Refresh data to show uploaded filename
        } else {
          _showSnackBar(
            'Gagal mengunggah file nilai: ${decodedResponse['message'] ?? 'Pesan tidak diketahui'}',
          );
        }
      } catch (e) {
        if (dialogIsOpen && mounted) {
          Navigator.pop(context); // Close loading dialog if error
        }
        _showSnackBar('Error saat mengunggah file nilai: $e');
        print('Error uploading file: $e');
      }
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(10),
        ),
      );
    }
  }

  // Helper widget to build input fields for scores with Predikat
  Widget _buildScoreInputFieldWithPredikat(
    TextEditingController controller,
    String label, {
    int?
        userId, // userId is needed to get and update the correct controller in setState
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}$')),
          ],
          decoration: InputDecoration(
            labelText: label,
            labelStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
            filled: true,
            fillColor: Colors.blue.shade50.withOpacity(0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          style: GoogleFonts.poppins(fontSize: 15),
          onChanged: (text) {
            // Trigger setState for the specific card to update its calculated values
            // This is generally safe as it rebuilds only the affected Card.
            if (userId != null) {
              setState(() {}); // Rebuild to update predikat and total score
            }
          },
        ),
        // Menampilkan predikat di bawah input angka
        if (double.tryParse(controller.text) != null &&
            double.parse(controller.text) >= 0 &&
            double.parse(controller.text) <= 100)
          Padding(
            padding: const EdgeInsets.only(top: 4.0, left: 8.0),
            child: Text(
              'Predikat: ${_getPredikat(double.parse(controller.text))}',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        const SizedBox(height: 8), // Sedikit ruang antara input dan predikat
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        backgroundColor: Colors.blue.shade800,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "PENILAIAN AKHIR",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade800, Colors.blue.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        toolbarHeight: 40,
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.blue.shade700),
                  const SizedBox(height: 16),
                  Text(
                    "Memuat daftar siswa...",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, color: Colors.red, size: 60),
                        const SizedBox(height: 15),
                        Text(
                          "Terjadi Kesalahan:",
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _errorMessage!,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.grey.shade700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 30),
                        ElevatedButton.icon(
                          onPressed: _loadPembimbingIdAndFetchSiswa,
                          icon: const Icon(Icons.refresh),
                          label:
                              Text("Coba Lagi", style: GoogleFonts.poppins()),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : _siswaList.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(30.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.group_off_outlined,
                              size: 80,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "Tidak ada siswa bimbingan yang perlu dinilai.",
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: _loadPembimbingIdAndFetchSiswa,
                              icon: const Icon(Icons.refresh),
                              label: Text(
                                "Refresh Data",
                                style: GoogleFonts.poppins(),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade600,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80, top: 12),
                      itemCount: _siswaList.length,
                      itemBuilder: (context, index) {
                        final siswa = _siswaList[index];
                        final int userId = siswa['user_id'];

                        final Map<String, double> currentCalculatedScores =
                            _calculateFinalScores(userId);
                        final double currentRataRataSikap =
                            currentCalculatedScores['rata_rata_nilai_sikap']!;
                        final double currentRataRataKompetensi =
                            currentCalculatedScores[
                                'rata_rata_nilai_kompetensi']!;
                        final double currentTotalNilaiAkhir =
                            currentCalculatedScores['total_nilai_akhir']!;

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 16,
                          ),
                          elevation: 6,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  siswa['nama_siswa'] ??
                                      'Nama Siswa Tidak Diketahui',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 20,
                                    color: Colors.blue.shade800,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const Divider(height: 25, thickness: 1),

                                // Bagian Penilaian SIKAP
                                Text(
                                  "A. SIKAP",
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                _buildScoreInputFieldWithPredikat(
                                  _nilaiDisiplinKerjaControllers[userId]!,
                                  "1. Disiplin Kerja",
                                  userId: userId,
                                ),
                                _buildScoreInputFieldWithPredikat(
                                  _nilaiKerjasamaControllers[userId]!,
                                  "2. Kerjasama",
                                  userId: userId,
                                ),
                                _buildScoreInputFieldWithPredikat(
                                  _nilaiInisiatifControllers[userId]!,
                                  "3. Inisiatif",
                                  userId: userId,
                                ),
                                _buildScoreInputFieldWithPredikat(
                                  _nilaiKerajinanControllers[userId]!,
                                  "4. Kerajinan",
                                  userId: userId,
                                ),
                                _buildScoreInputFieldWithPredikat(
                                  _nilaiTanggungJawabControllers[userId]!,
                                  "5. Tanggung Jawab",
                                  userId: userId,
                                ),
                                _buildScoreInputFieldWithPredikat(
                                  _nilaiSopanSantunControllers[userId]!,
                                  "6. Sopan Santun",
                                  userId: userId,
                                ),
                                _buildScoreInputFieldWithPredikat(
                                  _nilaiKehadiranControllers[userId]!,
                                  "7. Kehadiran",
                                  userId: userId,
                                ),
                                // Rata-rata Nilai Sikap
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.lightBlue.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.lightBlue.shade300,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Label for Sikap
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          "Rata-rata Nilai Sikap:",
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                            color: Colors.blue.shade700,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 8,
                                      ), // Spacing between label and value
                                      // Value for Sikap
                                      Text(
                                        currentRataRataSikap.toStringAsFixed(2),
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                          color: Colors.blue.shade700,
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 8,
                                      ), // Spacing between value and predikat
                                      // Predikat for Sikap
                                      Expanded(
                                        flex: 1,
                                        child: Text(
                                          _getPredikat(currentRataRataSikap),
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                            color: Colors.blue.shade700,
                                          ),
                                          textAlign: TextAlign
                                              .end, // Align to end for better look
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 25),

                                // Bagian Penilaian KOMPETENSI
                                Text(
                                  "B. KOMPETENSI:",
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                _buildScoreInputFieldWithPredikat(
                                  _nilaiKompetensiControllers[userId]!,
                                  "Rata-rata Nilai Kompetensi (sesuai dengan program studinya yang ada di jurnal siswa)",
                                  userId: userId,
                                ),
                                const SizedBox(height: 18),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.lightBlue.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.lightBlue.shade300,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Label for Kompetensi
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          "Rata-rata Nilai Kompetensi:",
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                            color: Colors.blue.shade700,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Value for Kompetensi
                                      Text(
                                        currentRataRataKompetensi
                                            .toStringAsFixed(2),
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                          color: Colors.blue.shade700,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Predikat for Kompetensi
                                      Expanded(
                                        flex: 1,
                                        child: Text(
                                          _getPredikat(
                                              currentRataRataKompetensi),
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                            color: Colors.blue.shade700,
                                          ),
                                          textAlign: TextAlign.end,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 25),

                                // Display Total Final Score (A+B)/2
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color:
                                        Colors.blue.shade100.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(12),
                                    border:
                                        Border.all(color: Colors.blue.shade300),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Label for Total
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          "Nilai Rata-rata (A + B) / 2:",
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 18,
                                            color: Colors.blue.shade900,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Value for Total
                                      Text(
                                        currentTotalNilaiAkhir.toStringAsFixed(
                                          2,
                                        ), // Display with 2 decimal places
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 18,
                                          color: Colors.blue.shade900,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Predikat for Total
                                      Expanded(
                                        flex: 1,
                                        child: Text(
                                          _getPredikat(currentTotalNilaiAkhir),
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 18,
                                            color: Colors.blue.shade900,
                                          ),
                                          textAlign: TextAlign.end,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 18),

                                // Final Comment Input
                                TextField(
                                  controller: _komentarAkhirControllers[userId],
                                  maxLines: 4,
                                  decoration: InputDecoration(
                                    labelText: "Komentar Penilaian Akhir",
                                    labelStyle: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade700,
                                    ),
                                    alignLabelWithHint: true,
                                    filled: true,
                                    fillColor:
                                        Colors.blue.shade50.withOpacity(0.5),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.blue.shade700,
                                        width: 2,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                        width: 1,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                  style: GoogleFonts.poppins(fontSize: 15),
                                ),
                                const SizedBox(height: 18),

                                // Certificate Eligibility Checkbox
                                Row(
                                  children: [
                                    Checkbox(
                                      value: _layakSertifikatStatus[userId],
                                      onChanged: (bool? newValue) {
                                        setState(() {
                                          _layakSertifikatStatus[userId] =
                                              newValue ?? false;
                                        });
                                      },
                                      activeColor: Colors.green.shade700,
                                    ),
                                    Expanded(
                                      child: Text(
                                        "Siswa Layak Mendapatkan Sertifikat",
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 25),

                                // --- NEW: Upload File Section ---
                                Text(
                                  "Unggah File Nilai (Opsional)",
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18,
                                    color: Colors.purple.shade700,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                if (_uploadedFilename[userId] != null &&
                                    _uploadedFilename[userId]!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Text(
                                      'File terunggah: ${_uploadedFilename[userId]!.split('/').last}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Colors.green.shade700,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _isLoading
                                        ? null
                                        : () => _uploadNilaiFile(
                                              userId,
                                              siswa['nama_siswa'],
                                            ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.purple.shade600,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 15,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      elevation: 5,
                                    ),
                                    icon: const Icon(Icons.attach_file),
                                    label: Text(
                                      _uploadedFilename[userId] != null &&
                                              _uploadedFilename[userId]!
                                                  .isNotEmpty
                                          ? "Ganti Form Nilai Siswa"
                                          : "Upload Form Nilai Siswa",
                                      style: GoogleFonts.poppins(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 25),

                                // Save Assessment Button
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _isLoading
                                        ? null
                                        : () => _submitPenilaianAkhir(userId),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue.shade700,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 15,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      elevation: 5,
                                    ),
                                    icon: _isLoading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(Icons.save),
                                    label: Text(
                                      _isLoading
                                          ? "Menyimpan..."
                                          : "Simpan Penilaian",
                                      style: GoogleFonts.poppins(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
      // --- Bottom Navigation Bar (Ensure correct indexing across all relevant pages) ---
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.blue,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.black,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        currentIndex: 4,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const HomeScreenPembimbing(),
                ),
              );
              break;
            case 1:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const ManajemenTugasPage(),
                ),
              );
              break;
            case 2:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const PenilaianFeedbackPage(),
                ),
              );
              break;
            case 3:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const RiwayatAbsensiMahasiswaPage(),
                ),
              );
              break;
            case 4:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const PenilaianAkhirPage(),
                ),
              );
              break;
            case 5:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfilePagePembimbing(),
                ),
              );
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home, size: 30),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined, size: 30),
            label: "Tugas",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle_outline, size: 30),
            label: "Feedback",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_toggle_off_outlined, size: 30),
            label: "History Attendance",
          ),
          BottomNavigationBarItem(
            // This is the new item for Final Assessment
            icon: Icon(Icons.star_half, size: 30),
            label: "Final Grade",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person, size: 30),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}
