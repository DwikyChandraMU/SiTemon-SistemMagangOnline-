// verifikasi_pengajuan_magang.dart
import 'dart:async';
import 'dart:convert'; // Untuk encoding/decoding JSON
import 'dart:io'; // Untuk manipulasi File
import 'package:flutter/material.dart'; // Core Flutter widgets
import 'package:google_fonts/google_fonts.dart'; // Untuk font kustom
import 'package:http/http.dart' as http; // Untuk HTTP requests
import 'package:open_filex/open_filex.dart'; // Untuk membuka file
import 'package:path_provider/path_provider.dart'; // Untuk mendapatkan direktori perangkat
import 'package:file_picker/file_picker.dart'; // Untuk memilih file

// --- Model Data ---
/// Merepresentasikan data pengajuan magang.
/// Properti opsional (nullable) ditandai dengan `?`.
class PengajuanMagang {
  final int id;
  final String namaMahasiswa;
  final String kategoriKegiatan;
  final String lamaMagang;
  final String tanggalMulai;
  final String tanggalSelesai;
  final String bidang;
  final String status;
  final String catatanMahasiswa;
  final String? noKtm;
  final String? tempatLahir;
  final String? tanggalLahir;
  final String? alamat;
  final String? noHp;
  final String? jenisKelamin;
  final String? instansi;
  final String? jurusan;
  final String? proposalMagangUrl;
  final String? cvUrl;
  final String? transkripNilaiUrl;
  final String? ktmUrl;
  final String? pasFotoUrl;
  final String? suratBalasanUrl; // URL untuk surat balasan yang diunggah admin

  PengajuanMagang({
    required this.id,
    required this.namaMahasiswa,
    required this.kategoriKegiatan,
    required this.lamaMagang,
    required this.tanggalMulai,
    required this.tanggalSelesai,
    required this.bidang,
    required this.status,
    required this.catatanMahasiswa,
    this.noKtm,
    this.tempatLahir,
    this.tanggalLahir,
    this.alamat,
    this.noHp,
    this.jenisKelamin,
    this.instansi,
    this.jurusan,
    this.proposalMagangUrl,
    this.cvUrl,
    this.transkripNilaiUrl,
    this.ktmUrl,
    this.pasFotoUrl,
    this.suratBalasanUrl,
  });

  /// Membuat instance [PengajuanMagang] dari objek JSON.
  factory PengajuanMagang.fromJson(Map<String, dynamic> json) {
    return PengajuanMagang(
      id: int.tryParse(json['pengajuan_id'].toString()) ??
          0, // Fallback ke 0 jika parse gagal
      namaMahasiswa: json['nama_mahasiswa'] ?? 'Tidak Diketahui',
      kategoriKegiatan: json['kategori_kegiatan'] ?? '-',
      lamaMagang: json['lama_magang'] ?? '-',
      tanggalMulai: json['tanggal_mulai'] ?? '-',
      tanggalSelesai: json['tanggal_selesai'] ?? '-',
      bidang: json['bidang'] ?? '-',
      status: json['status'] ?? 'Menunggu',
      catatanMahasiswa: json['catatan'] ?? 'Tidak ada catatan',
      noKtm: json['no_ktm'],
      tempatLahir: json['tempat_lahir'],
      tanggalLahir: json['tanggal_lahir'],
      alamat: json['alamat'],
      noHp: json['no_hp'],
      jenisKelamin: json['jenis_kelamin'],
      instansi: json['instansi'],
      jurusan: json['jurusan'],
      proposalMagangUrl: json['proposal_magang'],
      cvUrl: json['cv'],
      transkripNilaiUrl: json['transkrip_nilai'],
      ktmUrl: json['ktm'],
      pasFotoUrl: json['pas_foto'],
      suratBalasanUrl: json['surat_balasan_url'],
    );
  }
}

// --- Halaman Verifikasi Pengajuan ---
class VerifikasiPengajuanPage extends StatefulWidget {
  const VerifikasiPengajuanPage({super.key}); // Tambahkan Key

  @override
  _VerifikasiPengajuanPageState createState() =>
      _VerifikasiPengajuanPageState();
}

class _VerifikasiPengajuanPageState extends State<VerifikasiPengajuanPage> {
  List<PengajuanMagang> _listPengajuan = [];
  bool _isLoading = true;
  String? _errorMessage;
  File? _pickedFile; // Untuk menyimpan file yang dipilih admin

  // Base URL untuk API Anda
  static const String _baseUrl =
      'http://192.168.50.189/sitemon_api/admin/verifikasi_pengajuan';
  // Base URL untuk berkas yang diunggah. Sesuaikan dengan struktur folder di server Anda.
  static const String _filesBaseUrl =
      'http://192.168.50.189/sitemon_api/uploads/';

  @override
  void initState() {
    super.initState();
    _fetchPengajuan();
  }

  /// Mengambil daftar pengajuan magang dari API.
  Future<void> _fetchPengajuan() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/get_pengajuan.php'))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        // Cek jika respons kosong atau tidak valid JSON
        if (response.body.isEmpty) {
          throw Exception('Respons API kosong.');
        }

        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _listPengajuan =
              data.map((json) => PengajuanMagang.fromJson(json)).toList();
        });
      } else {
        throw Exception(
            'Gagal mengambil pengajuan: ${response.statusCode} - ${response.body}');
      }
    } on http.ClientException catch (e) {
      setState(() {
        _errorMessage = 'Gagal terhubung ke server: $e';
      });
      print('HTTP Client Exception: $e');
    } on SocketException catch (e) {
      setState(() {
        _errorMessage =
            'Tidak ada koneksi internet atau server tidak dapat dijangkau: $e';
      });
      print('Socket Exception: $e');
    } on FormatException catch (e) {
      setState(() {
        _errorMessage = 'Format respons tidak valid: $e';
      });
      print('Format Exception: $e');
    } catch (e) {
      setState(() {
        _errorMessage = 'Terjadi kesalahan tidak terduga: $e';
      });
      print('Unexpected Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Memperbarui status pengajuan (Diterima/Ditolak) melalui API.
  Future<void> _updateStatusPengajuan(
    int id,
    String status,
    String? catatan,
    File? suratBalasan,
  ) async {
    setState(() {
      _isLoading = true;
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/update_status_pengajuan.php'),
      );
      request.fields['pengajuan_id'] = id.toString();
      request.fields['status'] = status;
      if (catatan != null && catatan.isNotEmpty) {
        request.fields['catatan_admin'] = catatan;
      }

      // Hanya tambahkan file jika ada
      if (suratBalasan != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'surat_balasan', // Nama field di PHP
            suratBalasan.path,
            filename: suratBalasan.path.split('/').last,
          ),
        );
      }

      var response = await request.send().timeout(const Duration(seconds: 30));
      var responseBody = await response.stream.bytesToString();

      // Debugging: print raw server response
      print('Raw Server Response on Update: $responseBody');

      // Cek jika respons bukan JSON yang valid (misal, ada warning PHP)
      if (responseBody.trim().isEmpty ||
          (responseBody.startsWith('<') && responseBody.contains('<br />'))) {
        throw FormatException(
            'Respons tidak valid atau mengandung pesan error server. Respons: $responseBody');
      }

      final decodedResponse = json.decode(responseBody);

      if (decodedResponse['status'] == 'success') {
        _showSnackBar(decodedResponse['message']);
        _fetchPengajuan(); // Muat ulang data setelah pembaruan
      } else {
        _showSnackBar(
            'Gagal memperbarui: ${decodedResponse['message'] ?? 'Pesan tidak diketahui'}',
            isError: true);
      }
    } on FormatException catch (e) {
      _showSnackBar(
          'Error format data dari server: ${e.message}. Cek log server.',
          isError: true);
      print('FormatException caught: $e');
    } on TimeoutException {
      _showSnackBar(
          'Permintaan ke server memakan waktu terlalu lama. Silakan coba lagi.',
          isError: true);
    } catch (e) {
      _showSnackBar('Error saat memperbarui status: $e', isError: true);
      print('Error updating status: $e');
    } finally {
      setState(() {
        _isLoading = false;
        _pickedFile = null; // Reset file setelah upload
      });
    }
  }

  /// Mengunduh dan membuka file dari URL.
  Future<void> _downloadAndOpenFile(
    String? fileUrl,
    String fileName,
    String subfolder,
  ) async {
    if (fileUrl == null || fileUrl.isEmpty) {
      _showSnackBar('File tidak tersedia.', isError: true);
      return;
    }

    _showSnackBar('Mengunduh $fileName...');
    try {
      final fullUrl = '$_filesBaseUrl$subfolder/$fileUrl'; // Buat URL lengkap
      print('Attempting to download: $fullUrl');
      final response = await http.get(Uri.parse(fullUrl));

      if (response.statusCode == 200) {
        final directory = await getTemporaryDirectory();
        final filePath = '${directory.path}/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        final result = await OpenFilex.open(filePath);
        if (result.type != ResultType.done) {
          _showSnackBar('Gagal membuka file: ${result.message}', isError: true);
        }
      } else {
        _showSnackBar(
          'Gagal mengunduh $fileName: ${response.statusCode} - ${response.body}',
          isError: true,
        );
      }
    } on SocketException {
      _showSnackBar('Tidak ada koneksi internet saat mengunduh file.',
          isError: true);
    } catch (e) {
      _showSnackBar('Error saat mengunduh $fileName: $e', isError: true);
      print('Error downloading file: $e');
    }
  }

  /// Menampilkan SnackBar dengan pesan.
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating, // Lebih modern
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  /// Fungsi untuk memilih file PDF.
  Future<void> _pickPdfFile(Function(File?) onFilePicked) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'], // Hanya izinkan PDF
    );

    if (result != null && result.files.single.path != null) {
      onFilePicked(File(result.files.single.path!));
      _showSnackBar('File dipilih: ${result.files.single.name}');
    } else {
      // User canceled the picker
      onFilePicked(null); // Pastikan state file direset jika dibatalkan
      _showSnackBar('Pemilihan file dibatalkan.', isError: true);
    }
  }

  /// Menampilkan dialog detail pengajuan dan opsi verifikasi.
  void _showDetailDialog(PengajuanMagang pengajuan) {
    final TextEditingController catatanController = TextEditingController(
      text: pengajuan.catatanMahasiswa != 'Tidak ada catatan'
          ? pengajuan.catatanMahasiswa
          : '',
    );

    // Reset _pickedFile setiap kali dialog dibuka
    // Ini penting agar state file upload tidak tercampur antar dialog
    setState(() {
      _pickedFile = null;
    });

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        // Gunakan StatefulBuilder untuk mengupdate UI dalam dialog
        return StatefulBuilder(
          builder: (context, setStateSB) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                'Detail Pengajuan & Verifikasi',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: Colors.blue.shade800,
                ),
                textAlign: TextAlign.center,
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildSectionTitle('Detail Pengajuan Magang'),
                    _buildInfoRow(
                      'Nama Mahasiswa:',
                      pengajuan.namaMahasiswa,
                      Icons.person_outline,
                    ),
                    _buildInfoRow(
                      'Kategori Kegiatan:',
                      pengajuan.kategoriKegiatan,
                      Icons.category_outlined,
                    ),
                    _buildInfoRow(
                      'Lama Magang:',
                      pengajuan.lamaMagang,
                      Icons.timer_outlined,
                    ),
                    _buildInfoRow(
                      'Tanggal Mulai:',
                      pengajuan.tanggalMulai,
                      Icons.calendar_today_outlined,
                    ),
                    _buildInfoRow(
                      'Tanggal Selesai:',
                      pengajuan.tanggalSelesai,
                      Icons.calendar_today_outlined,
                    ),
                    _buildInfoRow(
                      'Bidang:',
                      pengajuan.bidang,
                      Icons.work_outline,
                    ),
                    const SizedBox(height: 20),
                    _buildSectionTitle('Data Diri Mahasiswa'),
                    _buildInfoRow(
                      'No. KTM:',
                      pengajuan.noKtm ?? '-',
                      Icons.credit_card,
                    ),
                    _buildInfoRow(
                      'Tempat, Tanggal Lahir:',
                      '${pengajuan.tempatLahir ?? '-'}, ${pengajuan.tanggalLahir ?? '-'}',
                      Icons.cake_outlined,
                    ),
                    _buildInfoRow(
                      'Alamat:',
                      pengajuan.alamat ?? '-',
                      Icons.location_on_outlined,
                    ),
                    _buildInfoRow(
                      'No. HP:',
                      pengajuan.noHp ?? '-',
                      Icons.phone_outlined,
                    ),
                    _buildInfoRow(
                      'Jenis Kelamin:',
                      pengajuan.jenisKelamin ?? '-',
                      Icons.people_outline,
                    ),
                    _buildInfoRow(
                      'Instansi:',
                      pengajuan.instansi ?? '-',
                      Icons.school_outlined,
                    ),
                    _buildInfoRow(
                      'Jurusan:',
                      pengajuan.jurusan ?? '-',
                      Icons.book_outlined,
                    ),
                    const SizedBox(height: 20),
                    _buildSectionTitle('Berkas Magang'),
                    _buildFileDownloadRow(
                      'Proposal Magang:',
                      pengajuan.proposalMagangUrl,
                      'proposal_magang.pdf',
                      'berkas_magang', // Subfolder
                      Icons.description_outlined,
                    ),
                    _buildFileDownloadRow(
                      'CV:',
                      pengajuan.cvUrl,
                      'cv.pdf',
                      'berkas_magang', // Subfolder
                      Icons.insert_drive_file_outlined,
                    ),
                    _buildFileDownloadRow(
                      'Transkrip Nilai:',
                      pengajuan.transkripNilaiUrl,
                      'transkrip_nilai.pdf',
                      'berkas_magang', // Subfolder
                      Icons.assignment_outlined,
                    ),
                    _buildFileDownloadRow(
                      'KTM:',
                      pengajuan.ktmUrl,
                      'ktm.pdf',
                      'berkas_magang', // Subfolder
                      Icons.perm_identity_outlined,
                    ),
                    _buildFileDownloadRow(
                      'Pas Foto:',
                      pengajuan.pasFotoUrl,
                      'pas_foto.jpg',
                      'berkas_magang', // Subfolder
                      Icons.image_outlined,
                    ),
                    _buildFileDownloadRow(
                      'Surat Balasan (Admin):',
                      pengajuan.suratBalasanUrl,
                      'surat_balasan.pdf',
                      'surat_balasan', // Subfolder baru
                      Icons.mail_outline,
                    ),
                    const SizedBox(height: 20),
                    _buildSectionTitle('Catatan (Mahasiswa/Admin)'),
                    TextField(
                      controller: catatanController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Tambahkan catatan atau komentar...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.all(12),
                      ),
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    // Widget untuk memilih file surat balasan
                    if (pengajuan.status ==
                        'Menunggu') // Hanya tampilkan jika status menunggu
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle(
                            'Unggah Surat Balasan (Opsional untuk Status "Diterima")',
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _pickedFile != null
                                      ? _pickedFile!.path.split('/').last
                                      : 'Belum ada file dipilih',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.blueGrey.shade700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton.icon(
                                onPressed: () => _pickPdfFile((file) {
                                  setStateSB(() {
                                    // Gunakan setStateSB di sini
                                    _pickedFile = file;
                                  });
                                }),
                                icon: const Icon(Icons.upload_file, size: 20),
                                label: Text(
                                  'Pilih File PDF',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade100,
                                  foregroundColor: Colors.blue.shade700,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Pilih file PDF surat balasan jika ada (opsional).',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              actionsPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 15,
              ),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 3,
                        ),
                        onPressed: () {
                          Navigator.of(dialogContext)
                              .pop(); // Tutup dialog dulu
                          _updateStatusPengajuan(
                            pengajuan.id,
                            'Ditolak',
                            catatanController.text.trim().isEmpty
                                ? null
                                : catatanController.text.trim(),
                            null, // Tidak ada file surat balasan jika ditolak
                          );
                        },
                        icon: const Icon(Icons.cancel_outlined, size: 20),
                        label: Text(
                          'Tolak',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 3,
                        ),
                        onPressed: () {
                          Navigator.of(dialogContext)
                              .pop(); // Tutup dialog dulu
                          _updateStatusPengajuan(
                            pengajuan.id,
                            'Diterima',
                            catatanController.text.trim().isEmpty
                                ? null
                                : catatanController.text.trim(),
                            _pickedFile, // Kirim file yang dipilih (bisa null)
                          );
                        },
                        icon: const Icon(Icons.check_circle_outline, size: 20),
                        label: Text(
                          'Terima',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: Text(
                      'Tutup',
                      style: GoogleFonts.poppins(
                        color: Colors.blueGrey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- Widget Pembantu ---

  /// Widget untuk menampilkan judul bagian dalam dialog.
  Widget _buildSectionTitle(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.blue.shade700,
          ),
        ),
        const Divider(height: 10, thickness: 1.5, color: Colors.blueGrey),
        const SizedBox(height: 10),
      ],
    );
  }

  /// Widget untuk menampilkan baris informasi (label dan nilai) dengan ikon opsional.
  Widget _buildInfoRow(String label, String value, [IconData? icon]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: Colors.blueGrey.shade600),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: label,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Colors.blueGrey.shade700,
                    ),
                  ),
                  TextSpan(
                    text: ' $value',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      color: Colors.blueGrey.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Widget untuk menampilkan baris unduh file.
  Widget _buildFileDownloadRow(
    String label,
    String? fileUrl,
    String defaultFileName,
    String subfolder,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, size: 20, color: Colors.blueGrey.shade600),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: Colors.blueGrey.shade700,
              ),
            ),
          ),
          if (fileUrl != null && fileUrl.isNotEmpty)
            OutlinedButton.icon(
              onPressed: () =>
                  _downloadAndOpenFile(fileUrl, defaultFileName, subfolder),
              icon: const Icon(
                Icons.cloud_download_outlined,
                size: 18,
                color: Colors.blue,
              ),
              label: Text(
                'Lihat/Unduh',
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.blue),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.blue.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            )
          else
            Text(
              'Tidak ada berkas',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  /// Widget untuk menampilkan chip status dengan warna berbeda.
  Widget _buildStatusChip(String status) {
    Color chipColor;
    Color textColor;
    switch (status.toLowerCase()) {
      case 'diterima':
        chipColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        break;
      case 'ditolak':
        chipColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        break;
      case 'menunggu':
      default:
        chipColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        break;
    }

    return Chip(
      backgroundColor: chipColor,
      label: Text(
        status,
        style: GoogleFonts.poppins(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  // --- UI Utama (build method) ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Verifikasi Pengajuan Magang',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
        toolbarHeight: 70,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade700, Colors.blue.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    'Memuat data pengajuan...',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 80,
                          color: Colors.red.shade400,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            color: Colors.red.shade700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: _fetchPengajuan,
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          label: Text(
                            'Coba Lagi',
                            style: GoogleFonts.poppins(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade600,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
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
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            "Tidak ada pengajuan magang yang perlu diverifikasi.",
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
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _listPengajuan.length,
                      itemBuilder: (context, index) {
                        final pengajuan = _listPengajuan[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          elevation: 6,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          clipBehavior: Clip
                              .antiAlias, // Penting untuk border radius pada InkWell
                          child: InkWell(
                            onTap: () => _showDetailDialog(pengajuan),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
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
                                            fontSize: 20,
                                            color: Colors.blue.shade800,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      _buildStatusChip(pengajuan.status),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  _buildInfoRow(
                                    'Kategori:',
                                    pengajuan.kategoriKegiatan,
                                    Icons.category,
                                  ),
                                  _buildInfoRow(
                                    'Bidang:',
                                    pengajuan.bidang,
                                    Icons.work,
                                  ),
                                  _buildInfoRow(
                                    'Periode:',
                                    '${pengajuan.tanggalMulai} s/d ${pengajuan.tanggalSelesai}',
                                    Icons.date_range,
                                  ),
                                  if (pengajuan.catatanMahasiswa.isNotEmpty &&
                                      pengajuan.catatanMahasiswa !=
                                          'Tidak ada catatan')
                                    _buildInfoRow(
                                      'Catatan Mahasiswa:',
                                      pengajuan.catatanMahasiswa,
                                      Icons.notes,
                                    ),
                                  const SizedBox(height: 15),
                                  Align(
                                    alignment: Alignment.bottomRight,
                                    child: ElevatedButton.icon(
                                      onPressed: () =>
                                          _showDetailDialog(pengajuan),
                                      icon: const Icon(
                                        Icons.info_outline,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      label: Text(
                                        'Lihat Detail',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 14,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue.shade600,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 18,
                                          vertical: 10,
                                        ),
                                        elevation: 3,
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
    );
  }
}
