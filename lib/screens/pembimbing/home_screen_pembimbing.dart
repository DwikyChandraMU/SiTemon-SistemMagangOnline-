import 'dart:convert'; // Untuk mengelola JSON (encode/decode)
import 'package:sitemon/screens/pembimbing/penilaian_akhir_siswa.dart';
import 'package:flutter/material.dart'; // Core UI Flutter
import 'package:http/http.dart' as http; // Untuk permintaan HTTP
import 'package:google_fonts/google_fonts.dart'; // Untuk gaya teks kustom
import 'package:sitemon/models/auth_services.dart'; // Import AuthService

// Import halaman-halaman navigasi lainnya
import 'package:sitemon/screens/pembimbing/manajemen_tugas.dart';
import 'package:sitemon/screens/pembimbing/penilaian_feedback.dart';
import 'package:sitemon/screens/pembimbing/profile_pembimbing.dart';
import 'package:sitemon/screens/pembimbing/riwayat_absensi.dart';

// --- Model Data Mahasiswa Bimbingan ---
class Mahasiswa {
  final int userId; // ID pengguna siswa
  final String nama;
  final String statusMagang;

  Mahasiswa({
    required this.userId,
    required this.nama,
    required this.statusMagang,
  });

  factory Mahasiswa.fromJson(Map<String, dynamic> json) {
    return Mahasiswa(
      userId: int.parse(json['user_id'].toString()),
      nama: json['nama'],
      statusMagang: json['status_magang'] ??
          'Belum Diketahui', // Sesuaikan nama kolom di PHP
    );
  }
}

// --- Model Data Bio Siswa ---
// Model ini digunakan oleh SiswaDetailPage, perlu didefinisikan di sini atau di file terpisah.
class SiswaBio {
  final String namaLengkap;
  final String noKTM;
  final String tempatLahir;
  final String tanggalLahir;
  final String alamat;
  final String noHp;
  final String jenisKelamin;
  final String instansi;
  final String jurusan;

  SiswaBio({
    required this.namaLengkap,
    required this.noKTM,
    required this.tempatLahir,
    required this.tanggalLahir,
    required this.alamat,
    required this.noHp,
    required this.jenisKelamin,
    required this.instansi,
    required this.jurusan,
  });

  factory SiswaBio.fromJson(Map<String, dynamic> json) {
    return SiswaBio(
      namaLengkap: json['nama_lengkap'] ?? 'N/A',
      noKTM: json['no_ktm'] ?? 'N/A',
      tempatLahir: json['tempat_lahir'] ?? 'N/A',
      tanggalLahir: json['tanggal_lahir'] ?? 'N/A',
      alamat: json['alamat'] ?? 'N/A',
      noHp: json['no_hp'] ?? 'N/A',
      jenisKelamin: json['jenis_kelamin'] ?? 'N/A',
      instansi: json['instansi'] ?? 'N/A',
      jurusan: json['jurusan'] ?? 'N/A',
    );
  }
}

class HomeScreenPembimbing extends StatefulWidget {
  const HomeScreenPembimbing({super.key});

  @override
  _HomeScreenPembimbingState createState() => _HomeScreenPembimbingState();
}

class _HomeScreenPembimbingState extends State<HomeScreenPembimbing> {
  List<Mahasiswa> daftarMahasiswa = [];
  bool isLoading = true;
  String? errorMessage;
  int? _currentPembimbingId; // Akan diisi otomatis dari AuthService
  int _selectedIndex = 0; // Untuk mengelola BottomNavigationBar

  @override
  void initState() {
    super.initState();
    _loadPembimbingIdAndFetchData();
  }

  /// Memuat ID Pembimbing dari AuthService dan kemudian memanggil fetchMahasiswa.
  Future<void> _loadPembimbingIdAndFetchData() async {
    int? id = await AuthService
        .getUserId(); // Asumsi getUserId() mengembalikan ID pembimbing

    if (!mounted) return;

    setState(() {
      _currentPembimbingId = id;
    });

    if (_currentPembimbingId != null) {
      await fetchMahasiswa();
    } else {
      setState(() {
        isLoading = false;
        errorMessage = "ID Pembimbing tidak ditemukan. Harap login ulang.";
      });
    }
  }

  /// Mengambil daftar mahasiswa yang dibimbing dari API berdasarkan ID pembimbing.
  Future<void> fetchMahasiswa() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    if (_currentPembimbingId == null) {
      setState(() {
        isLoading = false;
        errorMessage = "ID Pembimbing belum tersedia.";
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(
          "http://192.168.50.189/sitemon_api/pembimbing/home_screen/get_bimbingan_by_pembimbing.php?pembimbing_id=$_currentPembimbingId",
        ),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == true) {
          final List<Mahasiswa> loaded = (data['data'] as List)
              .map((item) => Mahasiswa.fromJson(item))
              .toList();

          setState(() {
            daftarMahasiswa = loaded;
          });
        } else {
          setState(() {
            errorMessage =
                data['message'] ?? 'Gagal memuat data mahasiswa bimbingan.';
          });
        }
      } else {
        setState(() {
          errorMessage =
              'Server error: ${response.statusCode}. Coba lagi nanti.';
        });
      }
    } catch (e) {
      print("Error fetching mahasiswa: $e");
      setState(() {
        errorMessage =
            'Koneksi gagal: Tidak dapat terhubung ke server. Pastikan IP dan koneksi Anda benar. ($e)';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  /// Membuka halaman detail bio siswa.
  void _showSiswaBio(Mahasiswa mahasiswa) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SiswaDetailPage(mahasiswa: mahasiswa),
      ),
    );
  }

  /// Menentukan warna berdasarkan status magang.
  Color _statusColor(String status) {
    switch (status) {
      case "Sedang Magang":
        return Colors.orange.shade700;
      case "Belum Mulai":
        return Colors.red.shade700;
      case "Selesai":
        return Colors.green.shade700;
      case "Diterima": // Status pengajuan
        return Colors.green.shade700;
      case "Ditolak": // Status pengajuan
        return Colors.red.shade700;
      case "Menunggu": // Status pengajuan
        return Colors.orange.shade700;
      default:
        return Colors.grey.shade600;
    }
  }

  /// Menentukan ikon berdasarkan status magang.
  IconData _statusIcon(String status) {
    switch (status) {
      case "Sedang Magang":
        return Icons.work;
      case "Belum Mulai":
        return Icons.timelapse;
      case "Selesai":
        return Icons.check_circle;
      case "Diterima":
        return Icons.check_circle_outline;
      case "Ditolak":
        return Icons.cancel_outlined;
      case "Menunggu":
        return Icons.hourglass_empty;
      default:
        return Icons.info_outline;
    }
  }

  // List of pages for BottomNavigationBar
  static final List<Widget> _widgetOptions = <Widget>[
    const HomeScreenPembimbingContent(), // Konten utama Home
    ManajemenTugasPage(),
    PenilaianFeedbackPage(),
    RiwayatAbsensiMahasiswaPage(),
    ProfilePagePembimbing(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Navigasi ke halaman yang sesuai, menghindari rebuild HomeScreenPembimbing jika index 0
    if (index != 0) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => _widgetOptions[index]),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50, // Latar belakang lebih terang
      appBar: _buildAppBar(),
      body: _buildBody(), // Menggunakan _buildBody untuk menampilkan konten
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.blue,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.black,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        currentIndex: 0,
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

  /// Membangun AppBar dengan gradien.
  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent, // Transparan agar gradien terlihat
      elevation: 0, // Tanpa elevasi untuk tampilan flat
      flexibleSpace: Container(
        // Tambahkan gradien di AppBar
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade800, Colors.blue.shade500],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      title: Text(
        "BERANDA PEMBIMBING",
        style: GoogleFonts.poppins(
          fontSize: 22, // Font size sedikit lebih kecil agar pas
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      centerTitle: true,
      toolbarHeight: 40,
    );
  }

  /// Membangun bagian body utama berdasarkan state (loading, error, empty, data).
  Widget _buildBody() {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
            ),
            const SizedBox(height: 16),
            Text(
              "Memuat daftar bimbingan...",
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.blue.shade700,
              ),
            ),
          ],
        ),
      );
    } else if (errorMessage != null) {
      return Center(
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
                errorMessage!,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed:
                    _loadPembimbingIdAndFetchData, // Memuat ulang data dan ID pembimbing
                icon: const Icon(Icons.refresh),
                label: Text(
                  "Coba Lagi",
                  style: GoogleFonts.poppins(fontSize: 16),
                ),
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
      );
    } else if (daftarMahasiswa.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.people_alt_outlined,
                size: 100, // Ukuran ikon lebih besar
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 20),
              Text(
                "Belum ada mahasiswa yang dibimbing pada saat ini.",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadPembimbingIdAndFetchData, // Tombol refresh
                icon: const Icon(Icons.refresh),
                label: Text("Refresh Data", style: GoogleFonts.poppins()),
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
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Daftar Bimbingan Anda",
              style: GoogleFonts.poppins(
                fontSize: 26, // Lebih besar
                fontWeight: FontWeight.w700, // Lebih tebal
                color: Colors.blue.shade900,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Pantau dan kelola mahasiswa bimbingan Anda di sini.",
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: Colors.grey.shade700,
              ),
            ),
            const Divider(
              height: 30,
              thickness: 1.5,
              color: Colors.blueGrey,
            ), // Garis pemisah modern
            Expanded(
              child: ListView.builder(
                itemCount: daftarMahasiswa.length,
                itemBuilder: (context, index) {
                  final mhs = daftarMahasiswa[index];
                  return _buildMahasiswaCard(mhs);
                },
              ),
            ),
          ],
        ),
      );
    }
  }

  /// Membangun widget Card untuk setiap mahasiswa.
  Widget _buildMahasiswaCard(Mahasiswa mhs) {
    return Card(
      elevation: 8, // Elevasi lebih tinggi
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ), // Sudut lebih bulat
      margin: const EdgeInsets.symmetric(
        vertical: 10,
        horizontal: 5,
      ), // Margin sedikit diubah
      child: InkWell(
        // Gunakan InkWell untuk efek ripple saat diklik
        borderRadius: BorderRadius.circular(20),
        onTap: () => _showSiswaBio(mhs), // Panggil fungsi untuk menampilkan bio
        child: Padding(
          padding: const EdgeInsets.all(18.0), // Padding lebih besar
          child: Row(
            children: [
              CircleAvatar(
                radius: 32, // Ukuran avatar lebih besar
                backgroundColor: _statusColor(
                  mhs.statusMagang,
                ).withOpacity(0.15), // Opacity lebih rendah
                child: Icon(
                  _statusIcon(mhs.statusMagang),
                  color: _statusColor(mhs.statusMagang),
                  size: 36, // Ukuran ikon lebih besar
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mhs.nama,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 20, // Ukuran font lebih besar
                        color: Colors.blue.shade900, // Warna teks lebih gelap
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor(mhs.statusMagang).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(
                          25,
                        ), // Sudut lebih bulat
                      ),
                      child: Text(
                        mhs.statusMagang,
                        style: GoogleFonts.poppins(
                          color: _statusColor(mhs.statusMagang),
                          fontWeight: FontWeight.w600,
                          fontSize: 14, // Ukuran font sedikit lebih besar
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey.shade500, // Warna abu-abu yang lebih kontras
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Temporary class to represent the content of HomeScreenPembimbing
// This is done to make the BottomNavigationBar work without rebuilding the whole HomeScreenPembimbing
// In a real app, you would have separate stateless widgets for each tab's content.
class HomeScreenPembimbingContent extends StatelessWidget {
  const HomeScreenPembimbingContent({super.key});

  @override
  Widget build(BuildContext context) {
    // This is just a placeholder. The actual content will be managed by _HomeScreenPembimbingState
    // through its _buildBody method.
    return Container();
  }
}

// --- Halaman Detail Siswa: SiswaDetailPage ---
// Kelas ini Ditempatkan di file yang sama untuk memenuhi permintaan "jadi satu saja".
// DISARANKAN untuk memisahkannya ke 'lib/screens/pembimbing/siswa_detail_page.dart'
// untuk modularitas yang lebih baik pada proyek yang lebih besar.

class SiswaDetailPage extends StatefulWidget {
  final Mahasiswa
      mahasiswa; // Objek Mahasiswa yang diteruskan dari halaman sebelumnya

  const SiswaDetailPage({super.key, required this.mahasiswa});

  @override
  State<SiswaDetailPage> createState() => _SiswaDetailPageState();
}

class _SiswaDetailPageState extends State<SiswaDetailPage> {
  SiswaBio? _siswaBio;
  bool _isLoadingBio = true;
  String? _errorBioMessage;

  @override
  void initState() {
    super.initState();
    _fetchSiswaBio();
  }

  /// Mengambil data bio siswa dari API.
  Future<void> _fetchSiswaBio() async {
    setState(() {
      _isLoadingBio = true;
      _errorBioMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse(
          "http://192.168.50.189/sitemon_api/pembimbing/home_screen/get_siswa_bio.php?user_id=${widget.mahasiswa.userId}",
        ),
      );

      if (!mounted) return; // Pastikan widget masih terpasang setelah await

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true && data['data'] != null) {
          setState(() {
            _siswaBio = SiswaBio.fromJson(data['data']);
          });
        } else {
          setState(() {
            _errorBioMessage =
                data['message'] ?? 'Data bio siswa tidak ditemukan.';
          });
        }
      } else {
        setState(() {
          _errorBioMessage =
              'Server error: ${response.statusCode} saat memuat bio.';
        });
      }
    } catch (e) {
      print("Error fetching siswa bio: $e");
      setState(() {
        _errorBioMessage = 'Koneksi gagal saat memuat bio: $e';
      });
    } finally {
      setState(() {
        _isLoadingBio = false;
      });
    }
  }

  /// Menentukan warna berdasarkan status magang (fungsi ini khusus untuk halaman detail ini).
  Color _getStatusColor(String status) {
    switch (status) {
      case "Sedang Magang":
        return Colors.orange.shade700;
      case "Belum Mulai":
        return Colors.red.shade700;
      case "Selesai":
        return Colors.green.shade700;
      case "Diterima": // Status pengajuan
        return Colors.green.shade700;
      case "Ditolak": // Status pengajuan
        return Colors.red.shade700;
      case "Menunggu": // Status pengajuan
        return Colors.orange.shade700;
      default:
        return Colors.grey.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
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
          "PROFIL SISWA",
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoadingBio
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.blue.shade700),
                  const SizedBox(height: 16),
                  Text(
                    "Memuat profil siswa...",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
            )
          : _errorBioMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline,
                            color: Colors.orange, size: 60),
                        const SizedBox(height: 15),
                        Text(
                          "Informasi Tidak Tersedia:",
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _errorBioMessage!,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.grey.shade700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 30),
                        ElevatedButton.icon(
                          onPressed: _fetchSiswaBio,
                          icon: const Icon(Icons.refresh),
                          label: Text(
                            "Coba Lagi",
                            style: GoogleFonts.poppins(fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade700,
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
              : _siswaBio == null
                  ? Center(
                      child: Text(
                        "Profil siswa tidak ditemukan.",
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProfileHeader(),
                          const SizedBox(height: 25),
                          _buildInfoCard(
                            title: "Informasi Pribadi",
                            children: [
                              _buildInfoRow(
                                Icons.person_outline,
                                "Nama Lengkap",
                                _siswaBio!.namaLengkap,
                              ),
                              _buildInfoRow(
                                Icons.credit_card,
                                "No. KTM",
                                _siswaBio!.noKTM,
                              ),
                              _buildInfoRow(
                                Icons.cake_outlined,
                                "TTL",
                                "${_siswaBio!.tempatLahir}, ${_siswaBio!.tanggalLahir}",
                              ),
                              _buildInfoRow(
                                Icons.wc_outlined,
                                "Jenis Kelamin",
                                _siswaBio!.jenisKelamin,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildInfoCard(
                            title: "Informasi Kontak & Alamat",
                            children: [
                              _buildInfoRow(
                                Icons.phone_outlined,
                                "No. HP",
                                _siswaBio!.noHp,
                              ),
                              _buildInfoRow(
                                Icons.location_on_outlined,
                                "Alamat",
                                _siswaBio!.alamat,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildInfoCard(
                            title: "Informasi Pendidikan",
                            children: [
                              _buildInfoRow(
                                Icons.school_outlined,
                                "Instansi",
                                _siswaBio!.instansi,
                              ),
                              _buildInfoRow(
                                Icons.science_outlined,
                                "Jurusan",
                                _siswaBio!.jurusan,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
    );
  }

  /// Membangun header profil siswa di halaman detail.
  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade100.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.blue.shade100,
            child: Icon(
              Icons.account_circle,
              size: 70,
              color: Colors.blue.shade600,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _siswaBio!.namaLengkap,
                  style: GoogleFonts.poppins(
                    fontSize: 22, // Sedikit lebih kecil agar lebih proporsional
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
                const SizedBox(height: 4), // Spasi kecil
                Text(
                  "Status Magang: ${widget.mahasiswa.statusMagang}",
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    color: _getStatusColor(
                      widget.mahasiswa.statusMagang,
                    ), // Menggunakan _getStatusColor dari kelas ini
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Membangun Card untuk kelompok informasi.
  Widget _buildInfoCard({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade800,
              ),
            ),
            const Divider(height: 20, thickness: 1, color: Colors.grey),
            ...children,
          ],
        ),
      ),
    );
  }

  /// Membangun baris informasi tunggal.
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blue.shade600, size: 22),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
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
}
