import 'dart:convert';
import 'package:sitemon/screens/admin/backup_keamanan.dart';
import 'package:sitemon/screens/admin/manajemen_konten.dart';
import 'package:sitemon/screens/admin/manajemen_sertifikat.dart';
import 'package:sitemon/screens/admin/profile_admin.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:sitemon/screens/admin/home_screen_admin.dart';
import 'package:sitemon/screens/admin/manajemen_pengguna.dart';

/// Model untuk data pengajuan bimbingan/magang
class AturBimbingan {
  final int pengajuanId;
  final String namaMahasiswa;
  final String emailMahasiswa;
  final String? instansi;
  final String? jurusan;
  final String kategoriKegiatan;
  final String lamaMagang;
  final String tanggalMulai;
  final String tanggalSelesai;
  final String bidang;
  final String status;
  final String? catatan;
  final int? pembimbingId;
  final String? namaPembimbing;

  AturBimbingan({
    required this.pengajuanId,
    required this.namaMahasiswa,
    required this.emailMahasiswa,
    this.instansi,
    this.jurusan,
    required this.kategoriKegiatan,
    required this.lamaMagang,
    required this.tanggalMulai,
    required this.tanggalSelesai,
    required this.bidang,
    required this.status,
    this.catatan,
    this.pembimbingId,
    this.namaPembimbing,
  });

  /// Factory constructor untuk membuat objek AturBimbingan dari JSON
  factory AturBimbingan.fromJson(Map<String, dynamic> json) {
    return AturBimbingan(
      pengajuanId: int.parse(json['pengajuan_id'].toString()),
      namaMahasiswa: json['nama_mahasiswa'] ?? 'Tidak Diketahui',
      emailMahasiswa: json['email_mahasiswa'] ?? 'Tidak Diketahui',
      instansi: json['instansi'],
      jurusan: json['jurusan'],
      kategoriKegiatan: json['kategori_kegiatan'] ?? '-',
      lamaMagang: json['lama_magang'] ?? '-',
      tanggalMulai: json['tanggal_mulai'] ?? '-',
      tanggalSelesai: json['tanggal_selesai'] ?? '-',
      bidang: json['bidang'] ?? '-',
      status: json['status'] ?? 'Menunggu',
      catatan: json['catatan'],
      pembimbingId: json['pembimbing_id'] != null
          ? int.parse(json['pembimbing_id'].toString())
          : null,
      namaPembimbing: json['nama_pembimbing'],
    );
  }
}

/// Model untuk Pembimbing (Mentor)
class Pembimbing {
  final int id;
  final String nama;

  Pembimbing({required this.id, required this.nama});

  /// Factory constructor untuk membuat objek Pembimbing dari JSON
  factory Pembimbing.fromJson(Map<String, dynamic> json) {
    return Pembimbing(id: int.parse(json['id'].toString()), nama: json['nama']);
  }
}

/// Halaman utama untuk mengatur bimbingan
class AturBimbinganPage extends StatefulWidget {
  const AturBimbinganPage({super.key});

  @override
  State<AturBimbinganPage> createState() => _AturBimbinganPageState();
}

class _AturBimbinganPageState extends State<AturBimbinganPage> {
  List<AturBimbingan> _listPengajuan = [];
  List<Pembimbing> _listPembimbing = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _selectedIndex = 1; // Index untuk "Atur Bimbingan" di BottomNavigationBar

  // Base URL untuk API Anda
  final String _baseUrl =
      'http://192.168.50.189/sitemon_api/admin/atur_bimbingan/';

  @override
  void initState() {
    super.initState();
    _fetchData(); // Ambil data saat halaman dimuat
  }

  /// Fungsi untuk mengambil data pengajuan dan daftar pembimbing secara bersamaan
  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null; // Bersihkan pesan error sebelumnya
    });

    try {
      await Future.wait([_fetchPengajuan(), _fetchPembimbingList()]);
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memuat data. Mohon periksa koneksi Anda.';
      });
      print('Error fetching data: $e'); // Log error untuk debugging
    } finally {
      setState(() {
        _isLoading = false; // Sembunyikan indikator loading
      });
    }
  }

  /// Fungsi untuk mengambil data pengajuan magang
  Future<void> _fetchPengajuan() async {
    final response = await http
        .get(Uri.parse('$_baseUrl/get_all_pengajuan.php'))
        .timeout(const Duration(seconds: 15)); // Batas waktu request

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      setState(() {
        _listPengajuan =
            data.map((json) => AturBimbingan.fromJson(json)).toList();
      });
    } else {
      throw Exception('Gagal mengambil pengajuan: ${response.statusCode}');
    }
  }

  /// Fungsi untuk mengambil daftar pembimbing yang tersedia
  Future<void> _fetchPembimbingList() async {
    final response = await http
        .get(Uri.parse('$_baseUrl/get_pembimbing_list.php'))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      setState(() {
        _listPembimbing =
            data.map((json) => Pembimbing.fromJson(json)).toList();
      });
    } else {
      throw Exception(
          'Gagal mengambil daftar pembimbing: ${response.statusCode}');
    }
  }

  /// Fungsi untuk memperbarui pembimbing yang ditugaskan untuk suatu pengajuan
  Future<void> _updatePembimbing(int pengajuanId, int? pembimbingId) async {
    setState(() {
      _isLoading = true; // Tampilkan loading saat memperbarui
    });

    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/update_pembimbing.php'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'pengajuan_id': pengajuanId,
              'pembimbing_id': pembimbingId,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final responseBody = json.decode(response.body);
      if (responseBody['status'] == 'success') {
        _showSnackBar(responseBody['message'], success: true);
        await _fetchPengajuan(); // Muat ulang daftar pengajuan setelah berhasil diperbarui
      } else {
        _showSnackBar(
          'Gagal memperbarui pembimbing: ${responseBody['message']}',
          success: false,
        );
      }
    } catch (e) {
      _showSnackBar(
        'Error memperbarui pembimbing: $e',
        success: false,
      );
      print('Error updating pembimbing: $e');
    } finally {
      setState(() {
        _isLoading = false; // Sembunyikan loading setelah update
      });
    }
  }

  /// Fungsi bantuan untuk menampilkan pesan SnackBar
  void _showSnackBar(String message, {bool success = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: success ? Colors.green.shade600 : Colors.red.shade600,
        behavior: SnackBarBehavior.floating, // SnackBar mengambang
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10), // Margin dari tepi
      ),
    );
  }

  /// Fungsi untuk menampilkan dialog penetapan pembimbing
  void _showEditPembimbingDialog(AturBimbingan pengajuan) {
    int? selectedPembimbingId = pengajuan.pembimbingId;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20), // Dialog lebih membulat
          ),
          title: Text(
            'Tetapkan Pembimbing untuk ${pengajuan.namaMahasiswa}',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 20, // Ukuran font judul lebih besar
              color: Colors.blue.shade800,
            ),
          ),
          content: StatefulBuilder(
            // Gunakan StatefulBuilder untuk memperbarui dropdown dalam dialog
            builder: (BuildContext context, StateSetter setState) {
              return DropdownButtonFormField<int?>(
                value: selectedPembimbingId,
                decoration: InputDecoration(
                  labelText: 'Pilih Pembimbing',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      12,
                    ), // Border input lebih membulat
                    borderSide: BorderSide(color: Colors.blue.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.blue.shade600,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                hint: Text(
                  'Pilih seorang Pembimbing',
                  style: GoogleFonts.poppins(color: Colors.grey[600]),
                ),
                items: [
                  DropdownMenuItem<int?>(
                    value: null, // Opsi untuk "Tidak ada pembimbing"
                    child: Text(
                      'Belum Ditugaskan',
                      style: GoogleFonts.poppins(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
                  ..._listPembimbing.map((pembimbing) {
                    return DropdownMenuItem<int>(
                      value: pembimbing.id,
                      child: Text(
                        pembimbing.nama,
                        style: GoogleFonts.poppins(
                          color: Colors.blueGrey.shade800,
                        ),
                      ),
                    );
                  }).toList(),
                ],
                onChanged: (int? newValue) {
                  setState(() {
                    selectedPembimbingId = newValue;
                  });
                },
              );
            },
          ),
          actionsPadding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 10,
          ), // Padding untuk actions
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Batal',
                style: GoogleFonts.poppins(
                  color: Colors.blueGrey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700, // Biru lebih kuat
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    12,
                  ), // Tombol lebih membulat
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20, // Padding disesuaikan
                  vertical: 10,
                ),
                elevation: 3, // Tambahkan sedikit elevasi
              ),
              onPressed: () {
                _updatePembimbing(pengajuan.pengajuanId, selectedPembimbingId);
                Navigator.of(context).pop();
              },
              child: Text(
                'Simpan',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Widget untuk membangun baris tampilan informasi
  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 3.0,
      ), // Padding vertikal disesuaikan
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start, // Sejajarkan ke atas jika teks membungkus
        children: [
          Text(
            '$label ',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 14, // Font sedikit lebih besar
              color: Colors.blueGrey.shade700,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14, // Font sedikit lebih besar
                color: valueColor ?? Colors.blueGrey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Widget untuk membangun chip status yang stylish
  Widget _buildStatusChip(String status) {
    Color chipColor;
    Color textColor;
    switch (status) {
      case 'Diterima':
        chipColor = Colors.green.shade100;
        textColor = Colors.green.shade700;
        break;
      case 'Ditolak':
        chipColor = Colors.red.shade100;
        textColor = Colors.red.shade700;
        break;
      case 'Menunggu':
      default:
        chipColor = Colors.orange.shade100;
        textColor = Colors.orange.shade700;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ), // Padding sedikit lebih banyak
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(25), // Chip lebih membulat
        border: Border.all(
          color: textColor.withOpacity(0.3),
          width: 0.5,
        ), // Border tipis
      ),
      child: Text(
        status,
        style: GoogleFonts.poppins(
          fontSize: 13, // Font sedikit lebih besar
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  /// Handler ketukan item Bottom Navigation Bar
  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });

      Widget nextPage;
      switch (index) {
        case 0:
          nextPage = HomeScreenAdmin();
          break;
        case 1:
          nextPage = AturBimbinganPage(); // Halaman saat ini
          break;
        case 2:
          nextPage = ManajemenPenggunaPage();
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Latar belakang terang
      appBar: AppBar(
        title: Text(
          'KELOLA BIMBINGAN', // Disesuaikan ke Bahasa Indonesia dan huruf kapital
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        elevation: 0, // Hapus bayangan default
        toolbarHeight: 60, // Tingkatkan tinggi app bar
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blue.shade700,
                Colors.blue.shade400,
              ], // Gradien konsisten
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              // Tambahkan bayangan halus ke app bar
              BoxShadow(
                color: Colors.blue.shade900.withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(height: 20), // Spasi ditingkatkan
                  Text(
                    "Memuat data...",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey[700],
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
                        Icon(
                          Icons
                              .cloud_off_outlined, // Ikon konsisten untuk error
                          color: Colors.redAccent.shade700, // Merah lebih gelap
                          size: 70, // Ikon lebih besar
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 25),
                        ElevatedButton.icon(
                          onPressed: _fetchData,
                          icon: const Icon(Icons.refresh, size: 24),
                          label: Text(
                            "Coba Lagi",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 25,
                              vertical: 14,
                            ),
                            elevation: 5,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : _listPengajuan.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 80,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            "Tidak ada pengajuan magang yang tersedia.",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: _fetchData,
                            icon: const Icon(Icons.refresh, size: 24),
                            label: Text(
                              "Segarkan Data", // Disesuaikan ke Bahasa Indonesia
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 25,
                                vertical: 14,
                              ),
                              elevation: 5,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _listPengajuan.length,
                      itemBuilder: (context, index) {
                        final pengajuan = _listPengajuan[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            vertical: 10.0,
                          ), // Margin vertikal ditingkatkan
                          elevation:
                              0, // Gunakan BoxShadow alih-alih elevasi default
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              20,
                            ), // Sudut kartu lebih membulat
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  spreadRadius: 2,
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(
                                  20.0), // Padding yang murah hati
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          pengajuan.namaMahasiswa,
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.bold,
                                            fontSize:
                                                20, // Ukuran font nama sedikit lebih besar
                                            color: Colors.blue.shade800,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      _buildStatusChip(
                                          pengajuan.status), // Badge status
                                    ],
                                  ),
                                  const SizedBox(
                                      height: 10), // Spasi ditingkatkan
                                  _buildInfoRow(
                                      'Email:', pengajuan.emailMahasiswa),
                                  if (pengajuan.instansi != null &&
                                      pengajuan.instansi!.isNotEmpty)
                                    _buildInfoRow(
                                      'Institusi:',
                                      pengajuan.instansi!,
                                    ),
                                  if (pengajuan.jurusan != null &&
                                      pengajuan.jurusan!.isNotEmpty)
                                    _buildInfoRow(
                                      'Jurusan:',
                                      pengajuan.jurusan!,
                                    ),
                                  const Divider(
                                    height:
                                        30, // Tinggi lebih banyak untuk pembatas
                                    thickness:
                                        1, // Pembatas sedikit lebih tebal
                                    color: Colors.grey,
                                  ),
                                  _buildInfoRow(
                                      'Kategori:', pengajuan.kategoriKegiatan),
                                  _buildInfoRow('Bidang:', pengajuan.bidang),
                                  _buildInfoRow(
                                    'Periode:',
                                    '${pengajuan.tanggalMulai} sampai ${pengajuan.tanggalSelesai}',
                                  ),
                                  _buildInfoRow(
                                    'Pembimbing:',
                                    pengajuan.namaPembimbing ??
                                        'Belum Ditugaskan',
                                    valueColor: pengajuan.namaPembimbing == null
                                        ? Colors.red.shade500
                                        : Colors.green.shade600,
                                  ),
                                  if (pengajuan.catatan != null &&
                                      pengajuan.catatan!.isNotEmpty)
                                    _buildInfoRow(
                                      'Catatan Mahasiswa:',
                                      pengajuan.catatan!,
                                    ),
                                  const SizedBox(
                                      height: 20), // Spasi ditingkatkan
                                  Align(
                                    alignment: Alignment.bottomRight,
                                    child: ElevatedButton.icon(
                                      onPressed: () =>
                                          _showEditPembimbingDialog(pengajuan),
                                      icon: const Icon(
                                        Icons.person_add_alt_1,
                                        color: Colors.white,
                                        size: 22, // Ukuran ikon disesuaikan
                                      ),
                                      label: Text(
                                        'Tetapkan Pembimbing',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors
                                            .blue.shade700, // Biru lebih kuat
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ), // Tombol lebih membulat
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20, // Padding disesuaikan
                                          vertical: 12,
                                        ),
                                        elevation:
                                            5, // Tambahkan lebih banyak elevasi pada tombol
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
        currentIndex: 1, // Set current index
        onTap: (index) {
          // Hanya navigasi jika index yang dipilih berbeda dari halaman saat ini
          if (index != 1) {
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
}
