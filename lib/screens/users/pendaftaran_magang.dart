// lib/screens/users/home_screen_users.dart (Revisi)
import 'package:sitemon/data/daftar_magang.dart';
import 'package:sitemon/data/lengkapi_data.dart';
import 'package:sitemon/data/seleksi_berkas.dart';
import 'package:sitemon/models/auth_services.dart';
import 'package:sitemon/screens/users/home_screen_users.dart'; // Pastikan ini mengarah ke Home Screen yang benar
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PengajuanMagang {
  final String status;
  final List<String> riwayat;

  PengajuanMagang({required this.status, required this.riwayat});
}

class PendaftaranMagang extends StatefulWidget {
  @override
  _PendaftaranMagangState createState() => _PendaftaranMagangState();
}

class _PendaftaranMagangState extends State<PendaftaranMagang> {
  PengajuanMagang pengajuanMagang = PengajuanMagang(
    status: "Menunggu",
    riwayat: [],
  );

  String? loggedInUser;
  int? userId;
  String? userRole;

  bool _isDataDiriCompleted = false;
  bool _hasDaftarMagangApplication = false;
  String _daftarMagangStatus = "Menunggu";
  bool _isBerkasMagangCompleted = false;
  bool _isMagangAccepted = false;
  bool _isMagangRejected = false;

  // NEW: State variable for kategori kegiatan
  String? _kategoriKegiatan;

  final String _apiBaseUrl =
      "http://192.168.50.189/sitemon_api/users/pendaftaran_magang"; // Perbaikan: Hapus trailing slash jika tidak diperlukan
  final String _apiGetKategoriUrl =
      'http://192.168.50.189/sitemon_api/users/get_kategori_kegiatan.php'; // NEW API endpoint for kategori

  @override
  void initState() {
    super.initState();
    _getLoggedInUserAndStatuses();
  }

  Future<void> _getLoggedInUserAndStatuses() async {
    String? user = await AuthService.getLoggedInUser();
    int? id = await AuthService.getUserId();
    String? role = await AuthService.getUserRole();

    setState(() {
      loggedInUser = user;
      userId = id;
      userRole = role;
    });

    if (userId != null) {
      await _checkDataDiriStatus();
      await _checkDaftarMagangStatus();
      // NEW: Fetch kategori kegiatan before checking berkas status
      await _fetchKategoriKegiatan();
      await _checkBerkasMagangStatus();

      if (_isMagangAccepted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreenUsers()),
          );
        });
      }
    } else {
      // Handle case where userId is null initially
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("User ID tidak ditemukan. Harap login kembali."),
          ),
        );
      });
    }
  }

  // NEW: Function to fetch kategori kegiatan, similar to seleksi_berkas.dart
  Future<void> _fetchKategoriKegiatan() async {
    try {
      final response = await http.get(
        Uri.parse('$_apiGetKategoriUrl?user_id=$userId'),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _kategoriKegiatan = data['kategori_kegiatan'];
          });
          print(
            "Kategori kegiatan fetched in PendaftaranMagang: $_kategoriKegiatan",
          );
        } else {
          print(
            "Failed to get kategori kegiatan in PendaftaranMagang: ${data['message']}",
          );
          setState(() {
            _kategoriKegiatan = null; // Set null if not found
          });
        }
      } else {
        print(
          "Error fetching kategori kegiatan in PendaftaranMagang: ${response.statusCode}",
        );
      }
    } catch (e) {
      print("Exception fetching kategori kegiatan in PendaftaranMagang: $e");
    }
  }

  // --- API Calls to PHP Backend (tidak berubah dari sebelumnya) ---

  Future<void> _checkDataDiriStatus() async {
    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/get_data_diri_status.php?user_id=$userId'),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _isDataDiriCompleted = data['is_completed'];
          });
        } else {
          print("Failed to get data diri status: ${data['message']}");
        }
      } else {
        print("Error: ${response.statusCode}");
      }
    } catch (e) {
      print("Exception when checking data diri status: $e");
    }
  }

  Future<void> _checkDaftarMagangStatus() async {
    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/get_daftar_magang_status.php?user_id=$userId'),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _hasDaftarMagangApplication = data['has_application'];
            _daftarMagangStatus = data['status'] ?? "Menunggu";
            _isMagangAccepted = (_daftarMagangStatus == "Diterima");
            _isMagangRejected = (_daftarMagangStatus == "Ditolak");

            pengajuanMagang = PengajuanMagang(
              status: _daftarMagangStatus,
              riwayat: List<String>.from(data['riwayat'] ?? []),
            );
          });
        } else {
          print("Failed to get daftar magang status: ${data['message']}");
        }
      } else {
        print("Error: ${response.statusCode}");
      }
    } catch (e) {
      print("Exception when checking daftar magang status: $e");
    }
  }

  Future<void> _checkBerkasMagangStatus() async {
    try {
      // Determine if files are optional based on _kategoriKegiatan
      bool areFilesOptional =
          _kategoriKegiatan == "penelitian" || _kategoriKegiatan == "skripsi";

      if (areFilesOptional) {
        // If files are optional, consider them "completed" for the purpose of the checklist
        setState(() {
          _isBerkasMagangCompleted = true;
        });
        print("Berkas Magang deemed completed as category is optional.");
        return; // Exit early as no need to check PHP for completion
      }

      // If not optional, proceed with checking actual completion from PHP
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/get_berkas_magang_status.php?user_id=$userId'),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _isBerkasMagangCompleted = data['is_completed'];
          });
        } else {
          print("Failed to get berkas magang status: ${data['message']}");
        }
      } else {
        print("Error: ${response.statusCode}");
      }
    } catch (e) {
      print("Exception when checking berkas magang status: $e");
    }
  }

  void _showStatusDialog(BuildContext context, String status) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Status Pengajuan Magang"),
        content: Text("Status pengajuan Anda saat ini: $status"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("Tutup"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String step5Title;
    String step5Description;
    Color step5Color;
    bool step5IsCompleted = false;

    if (_isMagangAccepted) {
      step5Title = "Diterima";
      step5Description =
          "Anda dinyatakan diterima untuk mengikuti program magang";
      step5Color = Colors.green;
      step5IsCompleted = true;
    } else if (_isMagangRejected) {
      step5Title = "Ditolak";
      step5Description = "Semoga ada kesempatan di lain waktu";
      step5Color = Colors.red;
      step5IsCompleted = true;
    } else {
      step5Title = "Menunggu";
      step5Description = "Pendaftaran anda sedang diproses";
      step5Color = Colors.blue.shade900;
      step5IsCompleted = false;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade900, Colors.blue.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text(
          "DAFTAR MAGANG",
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            if (loggedInUser != null)
              Text(
                "Selamat datang, $loggedInUser!",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    blurRadius: 5,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Text(
                "Informasi",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              ),
            ),
            SizedBox(height: 30),
            _buildStep(
              "1",
              "Registrasi Dan Login",
              "Registrasi akun dan Login untuk menambah data usulan magang",
              Colors.green,
              Icons.person_add,
              true,
            ),
            GestureDetector(
              onTap: () {
                if (userId != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LengkapiDataScreen(userId: userId!),
                    ),
                  ).then((_) => _getLoggedInUserAndStatuses());
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("User ID belum tersedia!")),
                  );
                }
              },
              child: _buildStep(
                "2",
                "Lengkapi Data",
                "Lengkapi data anda untuk menambah data usulan magang",
                _isDataDiriCompleted ? Colors.green : Colors.blue.shade900,
                Icons.edit,
                _isDataDiriCompleted,
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DaftarMagangPage()),
                ).then((_) => _getLoggedInUserAndStatuses());
              },
              child: _buildStep(
                "3",
                "Daftar Kegiatan",
                "Daftar magang untuk menambah usulan magang",
                _hasDaftarMagangApplication
                    ? Colors.green
                    : Colors.blue.shade900,
                Icons.assignment,
                _hasDaftarMagangApplication,
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => BerkasMagangPage()),
                ).then((_) => _getLoggedInUserAndStatuses());
              },
              child: _buildStep(
                "4",
                "Lengkapi Berkas",
                "Lengkapi berkas-berkas untuk memenuhi persyaratan magang",
                _isBerkasMagangCompleted ? Colors.green : Colors.blue.shade900,
                Icons.file_present,
                _isBerkasMagangCompleted,
              ),
            ),
            _buildStep(
              "5",
              step5Title,
              step5Description,
              step5Color,
              Icons.check_circle,
              step5IsCompleted,
            ),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(
    String number,
    String title,
    String description,
    Color stepColor,
    IconData icon,
    bool isCompleted,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: stepColor,
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          SizedBox(width: 15),
          Expanded(
            child: Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 5,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: stepColor,
                    ),
                  ),
                  Text(description, style: GoogleFonts.poppins(fontSize: 14)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
