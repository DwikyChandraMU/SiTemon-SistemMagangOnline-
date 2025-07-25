import 'dart:convert';
import 'package:sitemon/screens/admin/backup_keamanan.dart';
import 'package:sitemon/screens/admin/atur_bimbingan.dart';
import 'package:sitemon/screens/admin/manajemen_konten.dart';
import 'package:sitemon/screens/admin/profile_admin.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:sitemon/screens/admin/home_screen_admin.dart';
import 'package:open_filex/open_filex.dart'; // **IMPORT INI**
import 'package:path_provider/path_provider.dart'; // Untuk mendapatkan direktori penyimpanan
import 'dart:io'; // Untuk File

// Model untuk mahasiswa yang layak mendapatkan sertifikat
class MahasiswaSertifikat {
  final int id; // ID dari daftar_magang
  final int pengajuanId; // Sama dengan id, untuk konsistensi
  final int userId; // Tambahkan userId
  final String namaMahasiswa;
  final String emailMahasiswa;

  final String? noKtm;
  final String? tempatLahir;
  final String? tanggalLahir;
  final String? alamat;
  final String? noHp;
  final String? jenisKelamin;
  final String? instansi;
  final String? jurusan;

  final String kategoriKegiatan;
  final String bidang;
  final String tanggalMulai;
  final String tanggalSelesai;

  // Penambahan untuk nilai-nilai dari penilaian_akhir_sertifikat
  final double? nilaiDisiplinKerja;
  final double? nilaiKerjasama;
  final double? nilaiInisiatif;
  final double? nilaiKerajinan;
  final double? nilaiTanggungJawab;
  final double? nilaiSopanSantun;
  final double? nilaiKehadiran;
  final double? nilaiKompetensi;

  final double? totalNilaiAkhir;
  final bool? layakSertifikatFinal;
  final String? komentarAkhir;
  final String? sertifikatFilename; // Nama file sertifikat yang dihasilkan
  final String? nilaiFilePath; // Path file nilai yang diunggah pembimbing

  // Tanggal sertifikat diserahkan (dari tabel daftar_magang)
  final String? sertifikatDiserahkanAt;

  bool layakMendapatSertifikat; // Ini yang akan diubah oleh Switch

  MahasiswaSertifikat({
    required this.id,
    required this.pengajuanId,
    required this.userId,
    required this.namaMahasiswa,
    required this.emailMahasiswa,
    this.noKtm,
    this.tempatLahir,
    this.tanggalLahir,
    this.alamat,
    this.noHp,
    this.jenisKelamin,
    this.instansi,
    this.jurusan,
    required this.kategoriKegiatan,
    required this.bidang,
    required this.tanggalMulai,
    required this.tanggalSelesai,
    this.nilaiDisiplinKerja,
    this.nilaiKerjasama,
    this.nilaiInisiatif,
    this.nilaiKerajinan,
    this.nilaiTanggungJawab,
    this.nilaiSopanSantun,
    this.nilaiKehadiran,
    this.nilaiKompetensi,
    this.totalNilaiAkhir,
    this.layakSertifikatFinal,
    this.komentarAkhir,
    this.sertifikatFilename, // Inisialisasi field baru
    this.nilaiFilePath, // Inisialisasi field nilaiFilePath
    this.sertifikatDiserahkanAt, // Inisialisasi field baru

    this.layakMendapatSertifikat = false,
  });

  factory MahasiswaSertifikat.fromJson(Map<String, dynamic> json) {
    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String && value.isNotEmpty) return double.tryParse(value);
      return null;
    }

    bool? parseBool(dynamic value) {
      if (value == null) return null;
      if (value is bool) return value;
      if (value is int) return value == 1;
      if (value is String) return value == '1';
      return null;
    }

    final bool? finalLayakSertifikat = parseBool(
      json['layak_sertifikat_akhir'],
    );

    return MahasiswaSertifikat(
      id: int.parse(json['id'].toString()),
      pengajuanId: int.parse(json['pengajuan_id'].toString()),
      userId: int.parse(json['user_id'].toString()),
      namaMahasiswa: json['nama_mahasiswa'] ?? 'Tidak Diketahui',
      emailMahasiswa: json['email_mahasiswa'] ?? 'Tidak Diketahui',
      noKtm: json['no_ktm'],
      tempatLahir: json['tempat_lahir'],
      tanggalLahir: json['tanggal_lahir'],
      alamat: json['alamat'],
      noHp: json['no_hp'],
      jenisKelamin: json['jenis_kelamin'],
      instansi: json['instansi'],
      jurusan: json['jurusan'],
      kategoriKegiatan: json['kategori_kegiatan'] ?? '-',
      bidang: json['bidang'] ?? '-',
      tanggalMulai: json['tanggal_mulai'] ?? '-',
      tanggalSelesai: json['tanggal_selesai'] ?? '-',
      nilaiDisiplinKerja: parseDouble(json['nilai_disiplin_kerja']),
      nilaiKerjasama: parseDouble(json['nilai_kerjasama']),
      nilaiInisiatif: parseDouble(json['nilai_inisiatif']),
      nilaiKerajinan: parseDouble(json['nilai_kerajinan']),
      nilaiTanggungJawab: parseDouble(json['nilai_tanggung_jawab']),
      nilaiSopanSantun: parseDouble(json['nilai_sopan_santun']),
      nilaiKehadiran: parseDouble(json['nilai_kehadiran']),
      nilaiKompetensi: parseDouble(json['nilai_kompetensi']),
      totalNilaiAkhir: parseDouble(json['total_nilai_akhir']),
      layakSertifikatFinal: finalLayakSertifikat,
      komentarAkhir: json['komentar_akhir'],
      sertifikatFilename: json['sertifikat_filename'], // Parse nama file
      nilaiFilePath: json['nilai_file_path'], // Parse nilai_file_path
      sertifikatDiserahkanAt:
          json['sertifikat_diserahkan_at'], // Parse waktu diserahkan

      layakMendapatSertifikat: finalLayakSertifikat ?? false,
    );
  }
}

class ManajemenSertifikatPage extends StatefulWidget {
  const ManajemenSertifikatPage({Key? key}) : super(key: key);

  @override
  State<ManajemenSertifikatPage> createState() =>
      _ManajemenSertifikatPageState();
}

class _ManajemenSertifikatPageState extends State<ManajemenSertifikatPage> {
  List<MahasiswaSertifikat> _listMahasiswa = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Ganti dengan IP server Anda dan pastikan endpoint mengarah ke direktori 'admin/sertifikat'
  final String _baseUrl = 'http://192.168.50.189/sitemon_api/admin/sertifikat';
  // Base URL untuk mengakses file yang diunggah (folder 'uploads' di root API Anda)
  final String _uploadBaseUrl = 'http://192.168.50.189/sitemon_api';

  @override
  void initState() {
    super.initState();
    _fetchMahasiswaSertifikat();
  }

  Future<void> _fetchMahasiswaSertifikat() async {
    // Selalu set loading state di awal
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/get_mahasiswa_sertifikat.php'))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = json.decode(response.body);

        if (responseBody['status'] == true && responseBody['data'] is List) {
          final List<dynamic> data = responseBody['data'];
          if (mounted) {
            setState(() {
              _listMahasiswa = data
                  .map((json) => MahasiswaSertifikat.fromJson(json))
                  .toList();
              _listMahasiswa.sort(
                (a, b) => a.namaMahasiswa.compareTo(b.namaMahasiswa),
              );
            });
          }
        } else {
          throw Exception(
            'Gagal mengambil daftar mahasiswa: ${responseBody['message'] ?? 'Data tidak valid atau status bukan true.'}',
          );
        }
      } else {
        throw Exception(
          'Gagal mengambil daftar mahasiswa. Status Code: ${response.statusCode}',
        );
      }
    } on http.ClientException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'Gagal terhubung ke server: $e. Pastikan IP server benar dan server PHP berjalan.';
        });
      }
      print('Error connecting to server: $e');
    } on FormatException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'Format respons tidak valid (bukan JSON): $e. Respon: ${e.source}';
        });
      }
      print('Error parsing JSON: $e');
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'Terjadi kesalahan tidak terduga saat mengambil data mahasiswa: $e';
        });
      }
      print('Error fetching data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateLayakSertifikatStatus(int userId, bool status) async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/update_penilaian_layak_sertifikat.php'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'user_id': userId,
              'layak_sertifikat': status ? 1 : 0,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final responseBody = json.decode(response.body);
      if (responseBody['status'] == 'success') {
        _showSnackBar(responseBody['message']);
        _fetchMahasiswaSertifikat(); // Refresh data
      } else {
        _showSnackBar(
          'Gagal memperbarui status kelayakan: ${responseBody['message']}',
        );
      }
    } catch (e) {
      _showSnackBar('Error saat memperbarui status kelayakan: $e');
      print('Error updating certificate eligibility: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Fungsi yang diperbaiki untuk mengunggah dan menyerahkan sertifikat
  Future<void> _uploadAndSubmitCertificate(
    int userId,
    String studentName,
  ) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx'],
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
              'Mengunggah & Menyerahkan Sertifikat',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            content: Row(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 20),
                Expanded(
                  child: Text(
                    'Mengunggah dan mengirim sertifikat ke $studentName...',
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
          // PASTIKAN ENDPOINT INI SESUAI DENGAN NAMA FILE PHP ANDA
          Uri.parse('$_baseUrl/upload_student_certificate.php'),
        );
        request.fields['user_id'] = userId.toString();
        request.files.add(
          await http.MultipartFile.fromPath(
            'certificate_file', // Pastikan nama field ini sesuai dengan PHP
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
          Navigator.pop(context); // Tutup dialog loading
        }

        if (decodedResponse['status'] == 'success' ||
            decodedResponse['status'] == 'warning') {
          _showSnackBar(decodedResponse['message']);
          _fetchMahasiswaSertifikat(); // Refresh data mahasiswa
        } else {
          _showSnackBar(
            'Gagal mengunggah dan menyerahkan sertifikat: ${decodedResponse['message']}',
          );
        }
      } catch (e) {
        if (dialogIsOpen && mounted) {
          Navigator.pop(context); // Tutup dialog loading jika ada error
        }
        _showSnackBar('Error saat mengunggah dan menyerahkan sertifikat: $e');
        print('Error uploading and submitting certificate: $e');
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  Color _getStatusColor(bool layak) {
    return layak ? Colors.green.shade700 : Colors.orange.shade700;
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    Color? valueColor,
    FontStyle? fontStyle,
    GestureTapCallback? onTap,
    bool isLink = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: GestureDetector(
        onTap: onTap,
        child: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: label,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.blueGrey.shade700,
                ),
              ),
              TextSpan(
                text: ' $value',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: isLink
                      ? Colors.blue
                      : (valueColor ?? Colors.blueGrey.shade800),
                  fontStyle: fontStyle,
                  decoration:
                      isLink ? TextDecoration.underline : TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // **Fungsi BARU untuk mengunduh dan membuka file**
  Future<void> _downloadAndOpenFile(String fileUrl, String filename) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Membuka File',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  'Mengunduh dan membuka $filename...',
                  style: GoogleFonts.poppins(),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );

    try {
      final response = await http.get(Uri.parse(fileUrl));
      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$filename');
        await file.writeAsBytes(response.bodyBytes);

        Navigator.pop(context); // Tutup dialog loading
        final result = await OpenFilex.open(file.path);
        if (result.type != ResultType.done) {
          _showSnackBar('Gagal membuka file: ${result.message}');
        }
      } else {
        Navigator.pop(context); // Tutup dialog loading
        _showSnackBar('Gagal mengunduh file. Status: ${response.statusCode}');
      }
    } catch (e) {
      Navigator.pop(context); // Tutup dialog loading
      _showSnackBar('Terjadi kesalahan saat mengunduh/membuka file: $e');
      print('Error downloading or opening file: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'MANAJEMEN SERTIFIKAT',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
        toolbarHeight: 40,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      '$_errorMessage\n\nSilakan coba lagi.',
                      textAlign: TextAlign.center,
                      style:
                          GoogleFonts.poppins(color: Colors.red, fontSize: 16),
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- Bagian Verifikasi Mahasiswa ---
                      Text(
                        'Verifikasi & Penyerahan Sertifikat',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      const SizedBox(height: 15),
                      _listMahasiswa.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.person_off_outlined,
                                    size: 80,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    "Tidak ada mahasiswa untuk diverifikasi sertifikat.",
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _listMahasiswa.length,
                              itemBuilder: (context, index) {
                                final mahasiswa = _listMahasiswa[index];
                                return Card(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 8.0),
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          mahasiswa.namaMahasiswa,
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            color: Colors.blue.shade800,
                                          ),
                                        ),
                                        _buildInfoRow(
                                          'Email:',
                                          mahasiswa.emailMahasiswa,
                                        ),
                                        _buildInfoRow(
                                          'Instansi:',
                                          mahasiswa.instansi ?? '-',
                                        ),
                                        _buildInfoRow(
                                          'Jurusan:',
                                          mahasiswa.jurusan ?? '-',
                                        ),
                                        _buildInfoRow(
                                          'Kategori:',
                                          mahasiswa.kategoriKegiatan,
                                        ),
                                        _buildInfoRow(
                                            'Bidang:', mahasiswa.bidang),
                                        _buildInfoRow(
                                          'Periode:',
                                          '${mahasiswa.tanggalMulai} s/d ${mahasiswa.tanggalSelesai}',
                                        ),

                                        const SizedBox(height: 10),
                                        if (mahasiswa.totalNilaiAkhir !=
                                            null) ...[
                                          _buildInfoRow(
                                            'Nilai Disiplin Kerja:',
                                            mahasiswa.nilaiDisiplinKerja
                                                    ?.toStringAsFixed(2) ??
                                                '-',
                                          ),
                                          _buildInfoRow(
                                            'Nilai Kerjasama:',
                                            mahasiswa.nilaiKerjasama
                                                    ?.toStringAsFixed(2) ??
                                                '-',
                                          ),
                                          _buildInfoRow(
                                            'Nilai Inisiatif:',
                                            mahasiswa.nilaiInisiatif
                                                    ?.toStringAsFixed(2) ??
                                                '-',
                                          ),
                                          _buildInfoRow(
                                            'Nilai Kerajinan:',
                                            mahasiswa.nilaiKerajinan
                                                    ?.toStringAsFixed(2) ??
                                                '-',
                                          ),
                                          _buildInfoRow(
                                            'Nilai Tanggung Jawab:',
                                            mahasiswa.nilaiTanggungJawab
                                                    ?.toStringAsFixed(2) ??
                                                '-',
                                          ),
                                          _buildInfoRow(
                                            'Nilai Sopan Santun:',
                                            mahasiswa.nilaiSopanSantun
                                                    ?.toStringAsFixed(2) ??
                                                '-',
                                          ),
                                          _buildInfoRow(
                                            'Nilai Kehadiran:',
                                            mahasiswa.nilaiKehadiran
                                                    ?.toStringAsFixed(2) ??
                                                '-',
                                          ),
                                          _buildInfoRow(
                                            'Nilai Kompetensi:',
                                            mahasiswa.nilaiKompetensi
                                                    ?.toStringAsFixed(2) ??
                                                '-',
                                          ),
                                          _buildInfoRow(
                                            'TOTAL Nilai Akhir:',
                                            mahasiswa.totalNilaiAkhir
                                                    ?.toStringAsFixed(2) ??
                                                '-',
                                            valueColor: Colors.blue.shade800,
                                          ),
                                        ] else ...[
                                          _buildInfoRow(
                                            'Nilai Akhir:',
                                            'Belum Dinilai',
                                            valueColor: Colors.orange.shade700,
                                          ),
                                        ],

                                        if (mahasiswa.komentarAkhir != null &&
                                            mahasiswa.komentarAkhir!.isNotEmpty)
                                          _buildInfoRow(
                                            'Komentar Pembimbing:',
                                            mahasiswa.komentarAkhir!,
                                          ),

                                        const Divider(height: 15, thickness: 1),

                                        // **NEW: Tampilkan informasi file nilai yang diunggah pembimbing**
                                        if (mahasiswa.nilaiFilePath != null &&
                                            mahasiswa.nilaiFilePath!.isNotEmpty)
                                          _buildInfoRow(
                                            'File Nilai Pembimbing:',
                                            mahasiswa.nilaiFilePath!
                                                .split('/')
                                                .last, // Display only the filename
                                            valueColor:
                                                Colors.deepPurple.shade700,
                                            fontStyle: FontStyle.italic,
                                            isLink: true,
                                            onTap: () {
                                              final fullUrl =
                                                  '$_uploadBaseUrl${mahasiswa.nilaiFilePath}';
                                              final filename = mahasiswa
                                                  .nilaiFilePath!
                                                  .split('/')
                                                  .last;
                                              _downloadAndOpenFile(
                                                fullUrl,
                                                filename,
                                              );
                                            },
                                          )
                                        else
                                          _buildInfoRow(
                                            'File Nilai Pembimbing:',
                                            'Belum diunggah',
                                            valueColor: Colors.red.shade700,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        const SizedBox(height: 10),

                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Status Kelayakan:',
                                              style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                                color: Colors.blueGrey.shade700,
                                              ),
                                            ),
                                            Switch(
                                              value: mahasiswa
                                                  .layakMendapatSertifikat,
                                              onChanged: (bool value) {
                                                // Memperbarui status di UI sementara sambil menunggu respons API
                                                setState(() {
                                                  mahasiswa
                                                          .layakMendapatSertifikat =
                                                      value;
                                                });
                                                // Panggil API untuk memperbarui status di backend
                                                _updateLayakSertifikatStatus(
                                                  mahasiswa.userId,
                                                  value,
                                                );
                                              },
                                              activeColor:
                                                  Colors.green.shade600,
                                            ),
                                          ],
                                        ),
                                        Text(
                                          mahasiswa.layakMendapatSertifikat
                                              ? 'Layak Mendapatkan Sertifikat'
                                              : 'Tidak Layak Mendapatkan Sertifikat',
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            color: _getStatusColor(
                                              mahasiswa.layakMendapatSertifikat,
                                            ),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        // Tampilkan status penyerahan
                                        if (mahasiswa.sertifikatDiserahkanAt !=
                                            null)
                                          _buildInfoRow(
                                            'Diserahkan Pada:',
                                            mahasiswa.sertifikatDiserahkanAt!,
                                            valueColor:
                                                Colors.deepPurple.shade700,
                                            fontStyle: FontStyle.italic,
                                          )
                                        else
                                          _buildInfoRow(
                                            'Status Penyerahan:',
                                            'Belum Diserahkan',
                                            valueColor: Colors.red.shade700,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        const SizedBox(height: 10),

                                        // Tombol Upload dan Serahkan Sertifikat
                                        if (mahasiswa.layakMendapatSertifikat)
                                          Center(
                                            child: ElevatedButton.icon(
                                              onPressed: () {
                                                _uploadAndSubmitCertificate(
                                                  mahasiswa.userId,
                                                  mahasiswa.namaMahasiswa,
                                                );
                                              },
                                              icon: const Icon(
                                                Icons.cloud_upload,
                                                color: Colors.white,
                                              ),
                                              label: Text(
                                                'Upload & Serahkan Sertifikat',
                                                style: GoogleFonts.poppins(
                                                  color: Colors.white,
                                                ),
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Colors.purple.shade700,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 20,
                                                  vertical: 12,
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
                    ],
                  ),
                ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.blue,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.black,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        currentIndex: 2,
        onTap: (index) {
          if (index != 2) {
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
