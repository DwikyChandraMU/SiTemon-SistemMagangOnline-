import 'package:sitemon/screens/admin/backup_keamanan.dart';
import 'package:sitemon/screens/admin/home_screen_admin.dart';
import 'package:sitemon/screens/admin/manajemen_konten.dart';
import 'package:sitemon/screens/admin/atur_bimbingan.dart';
import 'package:sitemon/screens/admin/manajemen_sertifikat.dart';
// Impor halaman pembimbing tidak lagi relevan untuk navigasi admin, bisa dihapus jika tidak digunakan
// import 'package:sitemon/screens/pembimbing/home_screen_pembimbing.dart';
// import 'package:sitemon/screens/pembimbing/manajemen_tugas.dart';
// import 'package:sitemon/screens/pembimbing/penilaian_feedback.dart';
// import 'package:sitemon/screens/pembimbing/riwayat_absensi.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:sitemon/screens/login_screen.dart'; // Import halaman login

class ProfileAdminPage extends StatefulWidget {
  const ProfileAdminPage({
    super.key,
  }); // Tambahkan Key untuk praktik terbaik Flutter

  @override
  _ProfileAdminPageState createState() => _ProfileAdminPageState();
}

class _ProfileAdminPageState extends State<ProfileAdminPage> {
  Map<String, dynamic> profileData =
      {}; // Variabel untuk menyimpan data profil admin
  bool isLoading = true; // Status loading
  int? userId; // Menyimpan ID pengguna
  int _selectedIndex =
      5; // Indeks Bottom Navigation Bar untuk 'Profil Admin' (sesuai list item)

  @override
  void initState() {
    super.initState();
    _loadUserIdAndFetchProfile();
  }

  // Fungsi untuk memuat user ID dari SharedPreferences dan mengambil data profil
  Future<void> _loadUserIdAndFetchProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? id = prefs.getInt('user_id'); // Ambil user_id
    print('User ID dimuat dari SharedPreferences: $id'); // Log debugging

    if (id != null) {
      userId = id;
      await _fetchProfileData(id); // Ambil data profil jika ID ditemukan
    } else {
      print('User ID tidak tersedia.'); // Log jika ID tidak ada
      if (mounted) {
        setState(() {
          isLoading = false; // Hentikan loading jika tidak ada user ID
        });
        // Opsional: Redirect ke halaman login jika user ID tidak ada
        // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
      }
    }
  }

  // Fungsi untuk mengambil data profil dari API PHP
  Future<void> _fetchProfileData(int id) async {
    // URL API untuk mengambil data profil.
    // Pastikan API ini dapat mengembalikan data untuk role 'admin' dari tabel data_diri.
    // Jika ada data spesifik admin yang tersimpan di tabel lain, Anda perlu membuat API baru
    // atau memodifikasi profile.php untuk mengambil data tersebut.
    final url =
        'http://192.168.50.189/sitemon_api/users/profile.php?user_id=$id&role=admin'; // Menambahkan parameter role

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {"Accept": "application/json"}, // Mengharapkan respons JSON
      );

      if (!mounted) return; // Memastikan widget masih ada di tree

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print('Data Profil Admin Diterima: $jsonData'); // Log debugging

        if (jsonData != null && jsonData is Map<String, dynamic>) {
          setState(() {
            profileData = jsonData; // Perbarui state dengan data yang diambil
            isLoading = false; // Hentikan loading
          });
        } else {
          setState(() {
            isLoading = false;
          });
          _showSnackBar('Data profil admin tidak valid atau kosong.');
        }
      } else {
        print('Error Server Admin: ${response.statusCode}');
        setState(() {
          isLoading = false;
        });
        _showSnackBar(
          'Gagal mengambil data profil admin dari server: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error Jaringan/Parsing Admin: $e');
      setState(() {
        isLoading = false;
      });
      _showSnackBar('Terjadi kesalahan jaringan: $e');
    }
  }

  // Helper function untuk menampilkan SnackBar
  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: Colors.blue.shade700, // Konsisten dengan tema
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(10),
        ),
      );
    }
  }

  // Fungsi untuk menangani logout pengguna
  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id'); // Hapus user_id
    await prefs.remove('user_role'); // Hapus role juga

    // Navigasi ke LoginScreen dan hapus semua rute sebelumnya
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Latar belakang terang dan bersih
      appBar: AppBar(
        title: Text(
          "PROFIL ADMIN", // Judul spesifik untuk admin
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade800, Colors.blue.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        toolbarHeight: 40,
      ),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.blue.shade700),
                  const SizedBox(height: 15),
                  Text(
                    "Memuat data profil admin...",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.blueGrey.shade600,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                vertical: 30,
                horizontal: 20,
              ),
              child: Column(
                children: [
                  // Bagian Foto Profil (Avatar)
                  CircleAvatar(
                    radius: 70, // Ukuran avatar lebih besar
                    backgroundColor: Colors.blue.shade600,
                    child: const Icon(
                      Icons.shield_outlined,
                      size: 70,
                      color: Colors.white,
                    ), // Ikon khusus admin
                  ),
                  const SizedBox(height: 20),
                  // Nama Lengkap Admin
                  Text(
                    profileData['nama_lengkap'] ?? 'Nama Administrator',
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey.shade900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  // Informasi Tambahan (Misal: Role atau Departemen)
                  Text(
                    profileData['jurusan'] ??
                        'Departemen IT', // Contoh untuk admin
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: Colors.blueGrey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  // Detail Informasi dalam bentuk Card
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(25.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Baris Informasi: Nama Lengkap
                          _buildInfoRowWithIcon(
                            Icons.person_outline,
                            'Nama Lengkap',
                            profileData['nama_lengkap'] ?? '-',
                          ),
                          _buildDivider(),
                          // Baris Informasi: Instansi/Perusahaan
                          _buildInfoRowWithIcon(
                            Icons
                                .business_outlined, // Ikon untuk bisnis/perusahaan
                            'Instansi',
                            profileData['instansi'] ?? '-',
                          ),
                          _buildDivider(),
                          // Baris Informasi: Role/Departemen
                          _buildInfoRowWithIcon(
                            Icons
                                .category_outlined, // Ikon untuk kategori/bidang
                            'Role/Departemen',
                            profileData['jurusan'] ??
                                'Administrator', // Menggunakan 'jurusan' untuk departemen admin
                          ),
                          // Jika Anda memiliki data email/telepon untuk admin
                          // _buildDivider(),
                          // _buildInfoRowWithIcon(Icons.email_outlined, 'Email', profileData['email'] ?? '-'),
                          // _buildDivider(),
                          // _buildInfoRowWithIcon(Icons.phone_outlined, 'Telepon', profileData['no_hp'] ?? '-'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Tombol Logout
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(
                        Icons.logout,
                        size: 24,
                        color: Colors.white,
                      ),
                      label: Text(
                        'Keluar',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.blue,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.black,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        currentIndex: 5, // Set current index
        onTap: (index) {
          // Hanya navigasi jika index yang dipilih berbeda dari halaman saat ini
          if (index != 5) {
            Widget nextPage;
            switch (index) {
              case 0:
                nextPage = HomeScreenAdmin();
                break;
              case 1:
                nextPage = AturBimbinganPage();
                break;
              case 2:
                nextPage = ManajemenSertifikatPage();
                break;
              case 3:
                nextPage = ManajemenKontenPage();
                break;
              case 4:
                nextPage = BackupKeamananPage();
                break;
              case 5:
                nextPage = ProfileAdminPage();
                break;
              default:
                nextPage = HomeScreenAdmin();
            }
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => nextPage),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home, size: 30),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.manage_accounts_outlined, size: 30),
            label: "Atur Pembimbing",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school_outlined, size: 30),
            label: "Manage Account",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.content_paste_go_outlined, size: 30),
            label: "Manage Content",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.backup_outlined, size: 30),
            label: "Backup Data",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person, size: 30),
            label: "Profile",
          ),
        ],
      ),
    );
  }

  // Helper widget untuk membangun baris informasi yang konsisten dengan ikon
  Widget _buildInfoRowWithIcon(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.blue.shade700, size: 24),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.blueGrey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget untuk membangun divider yang konsisten
  Widget _buildDivider() {
    return Divider(
      height: 25,
      thickness: 0.8,
      color: Colors.grey.shade300,
      indent: 40,
      endIndent: 10,
    );
  }
}
