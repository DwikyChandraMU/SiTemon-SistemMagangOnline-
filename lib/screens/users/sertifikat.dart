import 'dart:io';
import 'dart:convert';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:sitemon/screens/users/home_screen_users.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sitemon/screens/users/absen_screen.dart';
import 'package:sitemon/screens/users/penugasan.dart';
import 'package:sitemon/screens/users/profile.dart';
import 'package:permission_handler/permission_handler.dart';

class SertifikatPage extends StatefulWidget {
  const SertifikatPage({Key? key}) : super(key: key);

  @override
  SertifikatPageState createState() => SertifikatPageState();
}

class SertifikatPageState extends State<SertifikatPage> {
  List<Map<String, dynamic>> certificates = [];
  bool isLoading = true;
  String errorMessage = '';
  int? _currentUserId;

  final String _baseUrl = 'http://192.168.50.189/sitemon_api/users/sertifikat/';

  @override
  void initState() {
    super.initState();
    _loadUserIdAndFetchCertificates();
  }

  Future<void> _loadUserIdAndFetchCertificates() async {
    final prefs = await SharedPreferences.getInstance();
    final int? userIdFromPrefs = prefs.getInt('user_id');

    if (userIdFromPrefs == null) {
      setState(() {
        isLoading = false;
        errorMessage =
            'Anda belum login atau User ID tidak ditemukan. Silakan login terlebih dahulu.';
      });
      return;
    }

    setState(() {
      _currentUserId = userIdFromPrefs;
    });

    await _fetchCertificates();
  }

  Future<void> _fetchCertificates() async {
    if (_currentUserId == null) {
      setState(() {
        isLoading = false;
        errorMessage = 'User ID tidak tersedia. Harap login kembali.';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await http.get(
          Uri.parse('$_baseUrl/get_sertifikat.php?user_id=$_currentUserId'));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == true) {
          setState(() {
            certificates =
                List<Map<String, dynamic>>.from(responseData['data']);
          });
        } else {
          setState(() {
            certificates = [];
            errorMessage =
                responseData['message'] ?? 'Gagal memuat sertifikat.';
          });
        }
      } else if (response.statusCode >= 500) {
        setState(() {
          errorMessage =
              'Server sedang bermasalah. Silakan coba lagi nanti atau hubungi administrator. (Kode: ${response.statusCode})';
        });
      } else if (response.statusCode == 404) {
        setState(() {
          errorMessage =
              'Data tidak ditemukan atau alamat server salah. (Kode: ${response.statusCode})';
        });
      } else {
        setState(() {
          errorMessage =
              'Gagal memuat data. Terjadi masalah pada permintaan Anda. (Kode: ${response.statusCode})';
        });
      }
    } on SocketException {
      setState(() {
        errorMessage =
            'Tidak ada koneksi internet atau server sedang offline. Mohon periksa koneksi Anda.';
      });
    } on FormatException {
      setState(() {
        errorMessage =
            'Terjadi masalah dalam memproses data dari server. Silakan coba lagi.';
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Terjadi kesalahan tidak terduga: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _downloadAndOpenFile(
      String? fileUrl, String filename, String fileType) async {
    if (fileUrl == null || fileUrl.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('URL $fileType kosong.')));
      return;
    }

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mengunduh $fileType...')),
      );

      // Dapatkan informasi perangkat untuk memeriksa versi Android
      final plugin = DeviceInfoPlugin();
      final androidInfo = await plugin.androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      Directory downloadDirectory;

      if (sdkInt >= 33) {
        // Android 13 (API 33) dan di atasnya
        // Untuk tujuan demonstrasi dan kompatibilitas, kita akan mencoba langsung ke path Download
        // yang mungkin memerlukan MANAGE_EXTERNAL_STORAGE untuk akses tulis penuh di A13+.
        // Namun, kita akan menggunakan path_provider yang lebih aman jika direct access fails.

        // Coba pendekatan yang lebih langsung ke Download di Android 13+
        try {
          // Akses langsung ke folder Download mungkin memerlukan izin khusus
          // di Android 13+, atau aplikasi harus menjadi default file handler.
          // Cara paling aman tanpa izin MANAGE_EXTERNAL_STORAGE adalah
          // mengandalkan sistem untuk menanganinya, atau save ke App specific dir
          // dan biarkan user "share" ke download.

          // Untuk mencoba menulis langsung ke Downloads di Android 13+,
          // Anda mungkin perlu menambahkan permission MANAGE_EXTERNAL_STORAGE
          // dan meminta pengguna untuk memberikan izin khusus ini.
          // Ini sangat tidak disarankan untuk aplikasi biasa karena pembatasan Google Play.
          // Sebagai alternatif, kita bisa menyimpan ke direktori aplikasi lalu membiarkan
          // user membagikannya ke Download, atau menggunakan FilePicker.saveFile.

          // Mari kita coba solusi yang lebih aman: Unduh ke direktori dokumen aplikasi,
          // lalu tampilkan pesan bahwa file sudah diunduh. OpenFilex akan tetap bisa membukanya.
          downloadDirectory = await getApplicationDocumentsDirectory();
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Mengunduh file ke folder aplikasi...')));
        } catch (e) {
          // Fallback jika ada masalah dengan path publik
          downloadDirectory = await getApplicationDocumentsDirectory();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  'Gagal mengakses folder Download, menyimpan ke folder aplikasi...')));
        }
      } else {
        // Android 12 (API 32) dan di bawahnya
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
          if (!status.isGranted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Izin penyimpanan ditolak.')),
            );
            return;
          }
        }
        // Ini adalah cara lama untuk mendapatkan direktori Download.
        // Di beberapa Android, ini mungkin tetap berfungsi, tapi tidak dijamin di API 33+.
        downloadDirectory = Directory('/storage/emulated/0/Download');
        if (!await downloadDirectory.exists()) {
          await downloadDirectory.create(recursive: true);
        }
      }

      final filePath = '${downloadDirectory.path}/$filename';
      final response = await http.get(Uri.parse(fileUrl));

      if (response.statusCode == 200) {
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$fileType berhasil disimpan di: $filePath')),
        );

        // Membuka file menggunakan OpenFilex
        // OpenFilex dapat membuka file dari lokasi mana pun yang bisa diakses aplikasi,
        // termasuk folder Download atau direktori aplikasi.
        final result = await OpenFilex.open(filePath);
        if (result.type != ResultType.done) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal membuka file: ${result.message}')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal mengunduh file: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
          "SERTIFIKAT KEGIATAN",
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        elevation: 4,
        toolbarHeight: 40,
      ),
      body: Container(
        color: Colors.grey.shade50,
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.blue))
            : errorMessage.isNotEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline,
                              color: Colors.red, size: 60),
                          const SizedBox(height: 15),
                          Text(
                            errorMessage,
                            style: GoogleFonts.poppins(
                                color: Colors.red.shade700, fontSize: 17),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 25),
                          ElevatedButton.icon(
                            onPressed: _fetchCertificates,
                            icon:
                                const Icon(Icons.refresh, color: Colors.white),
                            label: Text('Coba Lagi',
                                style:
                                    GoogleFonts.poppins(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 25, vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              elevation: 5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : certificates.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.info_outline,
                                  color: Colors.blue, size: 60),
                              const SizedBox(height: 15),
                              Text(
                                "Belum ada sertifikat yang diterbitkan untuk Anda saat ini.",
                                style: GoogleFonts.poppins(
                                    color: Colors.black54, fontSize: 18),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 25),
                              ElevatedButton.icon(
                                onPressed: _fetchCertificates,
                                icon: const Icon(Icons.refresh,
                                    color: Colors.white),
                                label: Text('Perbarui Data',
                                    style: GoogleFonts.poppins(
                                        color: Colors.white)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade700,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 25, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                  elevation: 5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchCertificates,
                        color: Colors.blue.shade700,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: certificates.length,
                          itemBuilder: (context, index) {
                            final certificate = certificates[index];
                            final String sertifikatFileName =
                                certificate['sertifikat_filename'] ??
                                    'sertifikat.pdf';
                            String nilaiFileName = 'nilai_mahasiswa.pdf';
                            if (certificate['nilai_file_path'] != null &&
                                certificate['nilai_file_path'].isNotEmpty) {
                              nilaiFileName = certificate['nilai_file_path']
                                  .split('/')
                                  .last;
                            }

                            final String formattedDate = certificate[
                                    'tanggal_terbit_sertifikat_formatted'] ??
                                '-';

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 5),
                              elevation: 6,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15)),
                              shadowColor: Colors.blue.shade100,
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      certificate['nama_siswa'] ??
                                          'Nama Siswa Tidak Tersedia',
                                      style: GoogleFonts.poppins(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue.shade900),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Kegiatan: ${certificate['kategori_kegiatan'] ?? '-'} (${certificate['lama_magang'] ?? '-'})',
                                      style: GoogleFonts.poppins(
                                          fontSize: 16, color: Colors.black87),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      'Bidang: ${certificate['bidang'] ?? '-'}',
                                      style: GoogleFonts.poppins(
                                          fontSize: 16, color: Colors.black87),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Diterbitkan pada: $formattedDate',
                                      style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontStyle: FontStyle.italic,
                                          color: Colors.grey.shade700),
                                    ),
                                    if (certificate['komentar_akhir'] != null &&
                                        certificate['komentar_akhir']
                                            .isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 10),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Komentar Pembimbing:',
                                              style: GoogleFonts.poppins(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.blue.shade700),
                                            ),
                                            const SizedBox(height: 5),
                                            Text(
                                              '${certificate['komentar_akhir']}',
                                              style: GoogleFonts.poppins(
                                                  fontSize: 14,
                                                  color: Colors.grey.shade800),
                                            ),
                                          ],
                                        ),
                                      ),
                                    const SizedBox(height: 20),
                                    Center(
                                      child: ElevatedButton.icon(
                                        onPressed: () => _downloadAndOpenFile(
                                            certificate['sertifikat_url'],
                                            sertifikatFileName,
                                            "Sertifikat"),
                                        icon: const Icon(Icons.file_download,
                                            color: Colors.white),
                                        label: Text(
                                          'Unduh & Buka Sertifikat',
                                          style: GoogleFonts.poppins(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              Colors.indigo.shade700,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 24, vertical: 12),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10)),
                                          elevation: 4,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    if (certificate['nilai_file_url'] != null &&
                                        certificate['nilai_file_url']
                                            .isNotEmpty)
                                      Center(
                                        child: ElevatedButton.icon(
                                          onPressed: () => _downloadAndOpenFile(
                                              certificate['nilai_file_url'],
                                              nilaiFileName,
                                              "File Nilai"),
                                          icon: const Icon(Icons.assignment,
                                              color: Colors.white),
                                          label: Text(
                                            'Unduh & Buka File Nilai',
                                            style: GoogleFonts.poppins(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                Colors.green.shade700,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 24, vertical: 12),
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10)),
                                            elevation: 4,
                                          ),
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
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const HomeScreenUsers()));
              break;
            case 1:
              Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (_) => AbsenPage()));
              break;
            case 2:
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const TugasPage()));
              break;
            case 3:
              break;
            case 4:
              Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (_) => ProfilePage()));
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home, size: 30), label: "Home"),
          BottomNavigationBarItem(
              icon: Icon(Icons.camera, size: 30), label: "Camera"),
          BottomNavigationBarItem(
              icon: Icon(Icons.assignment_turned_in, size: 30),
              label: "Checklist"),
          BottomNavigationBarItem(
              icon: Icon(Icons.school, size: 30), label: "Certificate"),
          BottomNavigationBarItem(
              icon: Icon(Icons.person, size: 30), label: "Profile"),
        ],
      ),
    );
  }
}
