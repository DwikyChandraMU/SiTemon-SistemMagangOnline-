import 'package:sitemon/screens/pembimbing/home_screen_pembimbing.dart';
import 'package:sitemon/screens/pembimbing/manajemen_tugas.dart';
import 'package:sitemon/screens/pembimbing/penilaian_feedback.dart';
import 'package:sitemon/screens/pembimbing/riwayat_absensi.dart';
import 'package:sitemon/screens/pembimbing/penilaian_akhir_siswa.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:sitemon/screens/login_screen.dart'; // Import halaman login

class ProfilePagePembimbing extends StatefulWidget {
  // Tambahkan Key untuk praktik terbaik Flutter
  const ProfilePagePembimbing({super.key});

  @override
  _ProfilePagePembimbingState createState() => _ProfilePagePembimbingState();
}

class _ProfilePagePembimbingState extends State<ProfilePagePembimbing> {
  // Variabel untuk menyimpan data profil yang diambil dari API
  Map<String, dynamic> profileData = {};
  // Status loading untuk menampilkan indikator loading
  bool isLoading = true;
  // Menyimpan ID pengguna yang diambil dari SharedPreferences
  int? userId;
  // Variabel untuk mengelola indeks Bottom Navigation Bar yang aktif
  int _selectedIndex = 5; // Indeks 5 untuk tab "Profil" (sesuai jumlah item 6)

  @override
  void initState() {
    super.initState();
    // Memuat ID pengguna dan kemudian mengambil data profil saat widget diinisialisasi
    _loadUserIdAndFetchProfile();
  }

  // Fungsi untuk memuat ID pengguna dari SharedPreferences
  // dan kemudian memanggil fungsi untuk mengambil data profil
  Future<void> _loadUserIdAndFetchProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? id = prefs.getInt('user_id'); // Mengambil user_id
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
    // URL API untuk mengambil data profil pembimbing
    // Pastikan IP address ini sesuai dengan server Anda
    final url =
        'http://192.168.50.189/sitemon_api/pembimbing/profile.php?user_id=$id';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {"Accept": "application/json"}, // Mengharapkan respons JSON
      );

      // Memeriksa apakah widget masih ada di tree sebelum memanggil setState
      if (!mounted) return;

      if (response.statusCode == 200) {
        // Mendekode body respons JSON
        final jsonData = json.decode(response.body);
        print('Data Profil Diterima: $jsonData'); // Log debugging data

        if (jsonData != null && jsonData is Map<String, dynamic>) {
          setState(() {
            profileData = jsonData; // Perbarui state dengan data yang diambil
            isLoading = false; // Hentikan loading
          });
        } else {
          // Menangani respons JSON yang tidak valid (misal: bukan map)
          setState(() {
            isLoading = false;
          });
          _showSnackBar('Data profil tidak valid atau kosong.');
        }
      } else {
        // Menangani error server (kode status bukan 200 OK)
        print('Error Server: ${response.statusCode}'); // Log error server
        setState(() {
          isLoading = false;
        });
        _showSnackBar(
          'Gagal mengambil data profil dari server: ${response.statusCode}',
        );
      }
    } catch (e) {
      // Menangani error jaringan atau parsing
      print('Error Jaringan/Parsing: $e'); // Log error yang tertangkap
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
          backgroundColor:
              Colors.blue.shade700, // Warna SnackBar yang konsisten
          behavior: SnackBarBehavior.floating, // Efek floating
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(10),
        ),
      );
    }
  }

  // Fungsi untuk menangani logout pengguna
  // Menghapus user_id dari SharedPreferences dan menavigasi ke LoginScreen
  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id'); // Hapus user_id
    await prefs.remove('user_role'); // Hapus juga role jika disimpan

    // Navigasi ke LoginScreen dan hapus semua rute sebelumnya dari stack
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (route) => false, // Hapus semua rute sampai rute baru ini
    );
  }

  // --- Membangun UI ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Colors.grey[50], // Latar belakang yang lebih terang dan bersih
      appBar: AppBar(
        title: Text(
          "PROFIL SAYA", // Judul AppBar
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700, // Font lebih tebal
            color: Colors.white,
          ),
        ),
        centerTitle: true, // Pusatkan judul
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blue.shade800, // Warna gradien biru gelap
                Colors.blue.shade500, // Warna gradien biru terang
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0, // Hilangkan bayangan di bawah AppBar
        toolbarHeight: 40, // Tinggi AppBar yang lebih besar
      ),
      body: isLoading
          ? Center(
              // Tampilan loading saat data sedang diambil
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.blue.shade700),
                  const SizedBox(height: 15),
                  Text(
                    "Memuat data profil...",
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
                    backgroundColor:
                        Colors.blue.shade600, // Warna latar belakang avatar
                    child: const Icon(
                      Icons.person_rounded,
                      size: 70,
                      color: Colors.white,
                    ), // Ikon orang yang modern
                  ),
                  const SizedBox(height: 20),
                  // Nama Lengkap Pembimbing
                  Text(
                    profileData['nama_lengkap'] ?? 'Nama Pembimbing',
                    style: GoogleFonts.poppins(
                      fontSize: 26, // Ukuran font lebih besar
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey.shade900, // Warna teks gelap
                    ),
                    textAlign: TextAlign.center, // Pusatkan teks
                  ),
                  const SizedBox(height: 8),
                  // Bidang Keahlian/Jabatan Pembimbing
                  // Menggunakan 'jabatan' dari PHP, atau default 'Bidang Keahlian'
                  Text(
                    profileData['jabatan'] ?? 'Bidang Keahlian',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: Colors.blueGrey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  // Detail Informasi dalam bentuk Card
                  Card(
                    elevation: 8, // Bayangan lebih menonjol
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        20,
                      ), // Sudut membulat
                    ),
                    margin: EdgeInsets.zero, // Hapus margin default Card
                    child: Padding(
                      padding: const EdgeInsets.all(
                        25.0,
                      ), // Padding di dalam Card
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Baris Informasi: Nama Lengkap
                          _buildInfoRowWithIcon(
                            Icons.perm_identity,
                            'Nama Lengkap',
                            profileData['nama_lengkap'] ?? '-',
                          ),
                          _buildDivider(), // Divider antara baris informasi
                          // Baris Informasi: Instansi
                          _buildInfoRowWithIcon(
                            Icons
                                .work_outline, // Ikon lebih sesuai untuk instansi
                            'Instansi',
                            profileData['instansi'] ?? '-',
                          ),
                          _buildDivider(),
                          // BARU: Baris Informasi: Ruangan (sebelumnya Periode Bimbingan)
                          _buildInfoRowWithIcon(
                            Icons
                                .meeting_room_outlined, // Ikon yang relevan untuk ruangan
                            'Ruangan',
                            // Menggunakan kunci 'ruangan' dari respons PHP
                            profileData['ruangan'] ?? '-',
                          ),
                          // Anda bisa menambahkan baris informasi lain di sini, contoh:
                          // _buildDivider(),
                          // _buildInfoRowWithIcon(Icons.phone, 'No. Telepon', profileData['no_hp'] ?? '-'),
                          // _buildDivider(),
                          // _buildInfoRowWithIcon(Icons.email, 'Email', profileData['email'] ?? '-'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Tombol Logout
                  SizedBox(
                    width: double.infinity, // Membuat tombol lebar penuh
                    child: ElevatedButton.icon(
                      onPressed: _logout, // Memanggil fungsi logout
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
                        backgroundColor:
                            Colors.redAccent.shade700, // Warna merah yang kuat
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            15,
                          ), // Sudut membulat
                        ),
                        elevation: 6, // Bayangan tombol
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
        currentIndex: 5,
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

  // Helper widget untuk membangun baris informasi yang konsisten dengan ikon
  Widget _buildInfoRowWithIcon(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.center, // Pusatkan secara vertikal
        children: [
          Icon(
            icon,
            color: Colors.blue.shade700, // Warna ikon
            size: 24, // Ukuran ikon
          ),
          const SizedBox(width: 18), // Jarak antara ikon dan teks
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 14, // Ukuran font label
                    fontWeight: FontWeight.w500,
                    color: Colors.blueGrey.shade600, // Warna label lebih lembut
                  ),
                ),
                const SizedBox(height: 4), // Jarak antara label dan nilai
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 17, // Ukuran font nilai
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
      height: 25, // Tinggi divider
      thickness: 0.8, // Ketebalan divider
      color: Colors.grey.shade300, // Warna divider lembut
      indent: 40, // Indentasi agar sejajar dengan teks informasi
      endIndent: 10,
    );
  }
}
