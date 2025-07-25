// lib/screens/pembimbing/riwayat_absensi.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sitemon/models/auth_services.dart';
import 'package:sitemon/screens/pembimbing/home_screen_pembimbing.dart';
import 'package:sitemon/screens/pembimbing/penilaian_feedback.dart';
import 'package:sitemon/screens/pembimbing/profile_pembimbing.dart';
import 'package:sitemon/screens/pembimbing/manajemen_tugas.dart';
import 'package:sitemon/screens/pembimbing/penilaian_akhir_siswa.dart';

class RiwayatAbsensiMahasiswaPage extends StatefulWidget {
  const RiwayatAbsensiMahasiswaPage({super.key});

  @override
  _RiwayatAbsensiMahasiswaPageState createState() =>
      _RiwayatAbsensiMahasiswaPageState();
}

class _RiwayatAbsensiMahasiswaPageState
    extends State<RiwayatAbsensiMahasiswaPage> {
  // Mengelompokkan berdasarkan tanggal, lalu di dalamnya per mahasiswa
  // dan membedakan antara absen masuk dan pulang.
  Map<String, Map<String, Map<String, dynamic>>>
      _groupedAbsensiByDateAndStudent = {};
  bool _isLoading = true;
  String? _errorMessage;
  int? _currentPembimbingId;

  final String _baseUrl =
      'http://192.168.50.189/sitemon_api/pembimbing/absensi';
  final String _uploadBaseUrl =
      'http://192.168.50.189/sitemon_api/uploads'; // Lokasi root folder uploads (di server)
  final String _absenPhotoSubDir = 'absen/'; // Subdirektori untuk foto absen

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null).then((_) {
      _loadPembimbingIdAndFetchAbsensi();
    }).catchError((e) {
      debugPrint("Error initializing date formatting: $e");
      setState(() {
        _isLoading = false;
        _errorMessage = "Gagal menginisialisasi data tanggal. Error: $e";
      });
    });
  }

  Future<void> _loadPembimbingIdAndFetchAbsensi() async {
    int? id = await AuthService.getUserId();
    if (!mounted) return;

    setState(() {
      _currentPembimbingId = id;
    });

    if (_currentPembimbingId != null) {
      await _fetchAbsensi();
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = "ID Pembimbing tidak ditemukan. Harap login ulang.";
      });
    }
  }

  Future<void> _fetchAbsensi() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _groupedAbsensiByDateAndStudent.clear(); // Bersihkan data sebelumnya
    });

    if (_currentPembimbingId == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Pembimbing ID tidak tersedia untuk memuat absensi.";
      });
      return;
    }

    final url = Uri.parse(
      '$_baseUrl/get_absensi.php?pembimbing_id=$_currentPembimbingId',
    );
    debugPrint("DEBUG: Mengakses URL: $url");

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 15));

      debugPrint("DEBUG: Status Code: ${response.statusCode}");
      debugPrint("DEBUG: Response Body: ${response.body}");

      if (!mounted) return;

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);

        if (responseBody['status'] == true) {
          if (responseBody['data'] != null && responseBody['data'] is List) {
            List<dynamic> data = responseBody['data'];
            Map<String, Map<String, Map<String, dynamic>>> tempGroupedAbsensi =
                {};

            if (data.isEmpty) {
              _showSnackBar(
                "Tidak ada data absensi yang diterima dari server.",
              );
              debugPrint(
                "DEBUG: Response body 'data' is empty from get_absensi.php",
              );
              setState(() {
                _groupedAbsensiByDateAndStudent = {};
              });
              return;
            }

            for (var record in data) {
              if (record['tanggal'] != null &&
                  record['tanggal'].isNotEmpty &&
                  record['nama_mahasiswa'] != null &&
                  record['status'] != null) {
                DateTime dateTime = DateTime.parse(record['tanggal']);
                String dateKey = DateFormat(
                  'EEEE, dd MMMM yyyy', // Format ini lebih aman dan lengkap
                  'id_ID',
                ).format(dateTime);
                String namaMahasiswa = record['nama_mahasiswa'];
                String statusAbsen = record['status']; // 'masuk' atau 'pulang'

                if (!tempGroupedAbsensi.containsKey(dateKey)) {
                  tempGroupedAbsensi[dateKey] = {};
                }
                if (!tempGroupedAbsensi[dateKey]!.containsKey(namaMahasiswa)) {
                  tempGroupedAbsensi[dateKey]![namaMahasiswa] = {};
                }
                // Simpan record berdasarkan status (masuk/pulang)
                tempGroupedAbsensi[dateKey]![namaMahasiswa]![statusAbsen] =
                    Map<String, dynamic>.from(record);
              } else {
                debugPrint(
                  "DEBUG: Record absensi tanpa tanggal, nama mahasiswa, atau status yang valid: $record",
                );
              }
            }

            setState(() {
              _groupedAbsensiByDateAndStudent = tempGroupedAbsensi;
              debugPrint(
                "DEBUG: Data absensi berhasil dimuat. Jumlah tanggal unik: ${_groupedAbsensiByDateAndStudent.length}",
              );
            });
          } else {
            _errorMessage = responseBody['message'] ??
                "Format data 'data' tidak valid dari server.";
            _showSnackBar(_errorMessage!);
            debugPrint(
              "DEBUG: Response body 'data' is null or not a List: ${response.body}",
            );
          }
        } else {
          _errorMessage =
              responseBody['message'] ?? 'Terjadi kesalahan pada server.';
          _showSnackBar(_errorMessage!);
          debugPrint("DEBUG: Status PHP false: ${response.body}");
        }
      } else {
        _errorMessage =
            "Gagal memuat absensi: Server mengembalikan status ${response.statusCode}. Body: ${response.body}";
        _showSnackBar(_errorMessage!);
        debugPrint(
          "DEBUG: Gagal memuat absensi. Status: ${response.statusCode}, Body: ${response.body}",
        );
      }
    } on http.ClientException catch (e) {
      _errorMessage =
          "Koneksi gagal: Tidak dapat terhubung ke server. Pastikan IP dan koneksi Anda benar. Error: ${e.message}";
      _showSnackBar(_errorMessage!);
      debugPrint("DEBUG: Error koneksi HTTP: $e");
    } on FormatException catch (e) {
      _errorMessage =
          "Gagal memproses data absensi: Format JSON tidak valid. Error: ${e.message}";
      _showSnackBar(_errorMessage!);
      debugPrint("DEBUG: Error decoding JSON: $e");
    } on Exception catch (e) {
      _errorMessage =
          "Terjadi kesalahan tidak terduga saat mengambil data absensi: $e";
      _showSnackBar(_errorMessage!);
      debugPrint("DEBUG: Error umum saat fetching absensi: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsInvalid(int absenId, bool isValid) async {
    final url = Uri.parse('$_baseUrl/update_absensi.php');
    debugPrint(
      "DEBUG: Mengirim update absensi untuk ID: $absenId, isValid: $isValid",
    );

    try {
      final response = await http
          .post(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "absen_id": absenId,
              "is_valid": isValid ? 1 : 0,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final resBody = jsonDecode(response.body);
      debugPrint("DEBUG: Respon update absensi: $resBody");

      if (!mounted) return;

      if (resBody['status'] == true) {
        _showSnackBar("Status absensi berhasil diperbarui.");
        _fetchAbsensi(); // Muat ulang data setelah update
      } else {
        _showSnackBar(
          "Gagal memperbarui status absensi: ${resBody['message'] ?? 'Pesan tidak tersedia'}",
        );
      }
    } on Exception catch (e) {
      _showSnackBar("Terjadi kesalahan saat memperbarui status absensi: $e");
      debugPrint("DEBUG: Error saat memperbarui status absensi: $e");
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: Colors.blue.shade700,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showPhotoPreview(String? photoPath) {
    if (photoPath == null || photoPath.isEmpty) {
      _showSnackBar("Tidak ada foto yang tersedia untuk ditampilkan.");
      return;
    }

    final String fullImageUrl = '$_uploadBaseUrl/$_absenPhotoSubDir$photoPath';
    debugPrint("DEBUG: Mencoba menampilkan foto dari URL: $fullImageUrl");

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(10),
          child: GestureDetector(
            onTap: () => Navigator.pop(context), // Tutup dialog saat disentuh
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  fullImageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        color: Colors.white,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    debugPrint(
                      "DEBUG: Gagal memuat gambar dari URL: $fullImageUrl, Error: $error",
                    );
                    return Container(
                      color: Colors.grey.shade300,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.broken_image,
                              size: 80,
                              color: Colors.red.shade700,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "Gagal Memuat Foto",
                              style: GoogleFonts.poppins(
                                color: Colors.red.shade700,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              "Pastikan URL valid atau foto ada di server.",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                color: Colors.red.shade500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    List<String> sortedDates = _groupedAbsensiByDateAndStudent.keys.toList()
      ..sort((a, b) {
        DateTime dateA = DateFormat('EEEE, dd MMMM yyyy', 'id_ID').parse(a);
        DateTime dateB = DateFormat('EEEE, dd MMMM yyyy', 'id_ID').parse(b);
        return dateB.compareTo(dateA);
      });

    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade800, Colors.blue.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text(
          "RIWAYAT ABSENSI",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
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
                    "Memuat riwayat absensi...",
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
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red.shade700,
                          size: 60,
                        ),
                        const SizedBox(height: 15),
                        Text(
                          "Terjadi Kesalahan:",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.red[700],
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 30),
                        ElevatedButton.icon(
                          onPressed: _loadPembimbingIdAndFetchAbsensi,
                          icon: const Icon(Icons.refresh),
                          label:
                              Text("Coba Lagi", style: GoogleFonts.poppins()),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 25,
                              vertical: 12,
                            ),
                            elevation: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : sortedDates.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(30.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event_note_outlined,
                              size: 100,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              "Tidak ada riwayat absensi untuk mahasiswa bimbingan Anda saat ini.",
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: _loadPembimbingIdAndFetchAbsensi,
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
                      itemCount: sortedDates.length,
                      itemBuilder: (context, index) {
                        String date = sortedDates[index];
                        Map<String, Map<String, dynamic>>
                            absensiPerMahasiswaPadaTanggalIni =
                            _groupedAbsensiByDateAndStudent[date]!;

                        List<String> sortedMahasiswaNames =
                            absensiPerMahasiswaPadaTanggalIni.keys.toList()
                              ..sort(); // Urutkan nama mahasiswa secara alfabetis

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 16,
                          ),
                          elevation: 6,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: ExpansionTile(
                            tilePadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            title: Text(
                              date,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                                color: Colors.blue.shade800,
                              ),
                            ),
                            children: sortedMahasiswaNames.map((namaMhs) {
                              Map<String, dynamic> absensiRecordUntukMahasiswa =
                                  absensiPerMahasiswaPadaTanggalIni[namaMhs]!;

                              Map<String, dynamic>? absenMasuk =
                                  absensiRecordUntukMahasiswa['masuk'];
                              Map<String, dynamic>? absenPulang =
                                  absensiRecordUntukMahasiswa['pulang'];

                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20.0,
                                  vertical: 10.0,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Divider(
                                      color: Colors.grey[300],
                                      thickness: 1,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "Mahasiswa: $namaMhs",
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    if (absenMasuk != null)
                                      _buildAbsenDetailCard(
                                          absenMasuk, "Masuk"),
                                    const SizedBox(height: 8),
                                    if (absenPulang != null)
                                      _buildAbsenDetailCard(
                                          absenPulang, "Pulang"),
                                    if (absenMasuk == null &&
                                        absenPulang == null)
                                      Text(
                                        "Tidak ada data absensi masuk atau pulang untuk mahasiswa ini pada tanggal ini.",
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontStyle: FontStyle.italic,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    const SizedBox(height: 8),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        );
                      },
                    ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.blue,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.black,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        currentIndex: 3,
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
              // Sudah di halaman ini
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

  // Widget baru untuk menampilkan detail absensi (masuk/pulang)
  Widget _buildAbsenDetailCard(Map<String, dynamic> absensi, String type) {
    String waktuAbsen = 'Tidak Diketahui';
    // Ambil jam_masuk atau jam_pulang sesuai dengan 'type'
    String? jam =
        type == "Masuk" ? absensi['jam_masuk'] : absensi['jam_pulang'];

    if (jam != null && jam.isNotEmpty) {
      waktuAbsen = jam.substring(0, 8); // Ambil hanya HH:MM:SS
    }

    String catatan = absensi['catatan'] ?? 'Tidak ada catatan';
    String? fotoPath = absensi['foto'];
    bool isValid = absensi['is_valid'] == true;
    int? absenId = int.tryParse(absensi['absen_id'].toString());

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Absen $type",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: type == "Masuk"
                    ? Colors.blue.shade700
                    : Colors.indigo.shade700,
              ),
            ),
            const SizedBox(height: 6),
            _buildInfoRow(
              Icons.access_time,
              "Jam $type",
              waktuAbsen,
            ),
            _buildInfoRow(
              Icons.notes,
              "Catatan",
              catatan,
            ),
            if (fotoPath != null && fotoPath.isNotEmpty)
              GestureDetector(
                onTap: () => _showPhotoPreview(fotoPath),
                child: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.image_outlined,
                        color: Colors.blue.shade700,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Lihat Foto",
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          color: Colors.blue.shade700,
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Status Verifikasi:",
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isValid ? Colors.green.shade100 : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isValid ? 'Valid' : 'Tidak Valid',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color:
                          isValid ? Colors.green.shade700 : Colors.red.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (absenId != null) {
                    _markAsInvalid(absenId, !isValid); // Toggle status
                  } else {
                    _showSnackBar("ID absensi tidak valid.");
                    debugPrint(
                      "DEBUG: absensi['absen_id'] is not a valid integer: ${absensi['absen_id']}",
                    );
                  }
                },
                icon: Icon(
                  isValid ? Icons.close_rounded : Icons.check_rounded,
                  size: 18,
                  color: Colors.white,
                ),
                label: Text(
                  isValid ? "Tandai Tidak Valid" : "Tandai Valid",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isValid ? Colors.red.shade600 : Colors.green.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                  ),
                  elevation: 3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blue.shade600, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
                children: [
                  TextSpan(
                    text: "$label: ",
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
