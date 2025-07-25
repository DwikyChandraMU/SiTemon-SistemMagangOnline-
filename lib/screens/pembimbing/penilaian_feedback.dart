// penilaian_gabungan_page.dart
import 'dart:convert';
import 'dart:io';
import 'package:sitemon/screens/pembimbing/home_screen_pembimbing.dart';
import 'package:sitemon/screens/pembimbing/manajemen_tugas.dart';
import 'package:sitemon/screens/pembimbing/profile_pembimbing.dart';
import 'package:sitemon/screens/pembimbing/riwayat_absensi.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:sitemon/models/auth_services.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

enum PenilaianType { harian, akhir }

class PenilaianFeedbackPage extends StatefulWidget {
  const PenilaianFeedbackPage({super.key});

  @override
  _PenilaianFeedbackPageState createState() => _PenilaianFeedbackPageState();
}

class _PenilaianFeedbackPageState extends State<PenilaianFeedbackPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<dynamic> _tugasHarianList = [];
  List<dynamic> _tugasAkhirList = [];

  bool _isLoadingHarian = true;
  bool _isLoadingAkhir = true;
  bool _isSubmitting = false;

  String? _errorMessageHarian;
  String? _errorMessageAkhir;

  int? _currentPembimbingId;

  final Map<int, TextEditingController> _komentarControllersHarian = {};
  final Map<int, String> _statusMapHarian = {};

  final Map<int, TextEditingController> _komentarControllersAkhir = {};
  final Map<int, String> _statusMapAkhir = {};

  final String _baseUrl =
      'http://192.168.50.189/sitemon_api/pembimbing/penilaian';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPembimbingIdAndFetchAllTugas();
  }

  @override
  void dispose() {
    _komentarControllersHarian.forEach(
      (id, controller) => controller.dispose(),
    );
    _komentarControllersAkhir.forEach((id, controller) => controller.dispose());
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPembimbingIdAndFetchAllTugas() async {
    int? id = await AuthService.getUserId();
    if (!mounted) return;

    setState(() {
      _currentPembimbingId = id;
    });

    if (_currentPembimbingId != null) {
      await Future.wait([
        _fetchTugas(PenilaianType.harian),
        _fetchTugas(PenilaianType.akhir),
      ]);
    } else {
      setState(() {
        _isLoadingHarian = false;
        _isLoadingAkhir = false;
        _errorMessageHarian =
            "ID Pembimbing tidak ditemukan. Harap login ulang.";
        _errorMessageAkhir =
            "ID Pembimbing tidak ditemukan. Harap login ulang.";
      });
    }
  }

  Future<void> _fetchTugas(PenilaianType type) async {
    if (!mounted) return;

    setState(() {
      if (type == PenilaianType.harian) {
        _isLoadingHarian = true;
        _errorMessageHarian = null;
      } else {
        _isLoadingAkhir = true;
        _errorMessageAkhir = null;
      }
    });

    if (_currentPembimbingId == null) {
      setState(() {
        if (type == PenilaianType.harian) {
          _isLoadingHarian = false;
          _errorMessageHarian =
              "Pembimbing ID tidak tersedia untuk memuat tugas harian.";
        } else {
          _isLoadingAkhir = false;
          _errorMessageAkhir =
              "Pembimbing ID tidak tersedia untuk memuat tugas akhir.";
        }
      });
      return;
    }

    String endpoint = type == PenilaianType.harian
        ? 'get_tugas_siswa.php'
        : 'get_tugas_akhir_siswa.php';
    String paramName =
        type == PenilaianType.harian ? 'pembimbing_id' : 'pembimbing_id';

    final url = Uri.parse(
      '$_baseUrl/$endpoint?$paramName=$_currentPembimbingId',
    );
    print(
      'DEBUG: Memuat data ${type == PenilaianType.harian ? 'tugas harian' : 'tugas akhir'} dari URL: $url',
    );

    try {
      final response = await http.get(url);

      if (!mounted) return;

      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> responseBody = jsonDecode(response.body);

          if (responseBody['status'] == true) {
            if (responseBody['data'] != null && responseBody['data'] is List) {
              List<dynamic> data = responseBody['data'];

              if (data.isEmpty) {
                _showSnackBar(
                  "Tidak ada ${type == PenilaianType.harian ? 'tugas harian' : 'tugas akhir'} siswa yang perlu dinilai saat ini.",
                );
                print(
                  "DEBUG: Response body 'data' kosong untuk ${type == PenilaianType.harian ? 'tugas harian' : 'tugas akhir'}.",
                );
                setState(() {
                  if (type == PenilaianType.harian) {
                    _tugasHarianList = [];
                  } else {
                    _tugasAkhirList = [];
                  }
                });
                return;
              }

              setState(() {
                if (type == PenilaianType.harian) {
                  _tugasHarianList = data;
                  for (var item in data) {
                    int tugasSiswaId = int.parse(
                      item['tugas_siswa_id'].toString(),
                    );
                    if (!_komentarControllersHarian.containsKey(tugasSiswaId)) {
                      _komentarControllersHarian[tugasSiswaId] =
                          TextEditingController();
                    }
                    _komentarControllersHarian[tugasSiswaId]?.text =
                        item['komentar']?.toString() ?? '';

                    String fetchedStatus =
                        item['status_penilaian']?.toString() ?? 'Belum Dinilai';
                    if (fetchedStatus == 'Dinilai') {
                      fetchedStatus = 'Diterima';
                    }
                    if (![
                      "Diterima",
                      "Revisi",
                      "Belum Dinilai",
                    ].contains(fetchedStatus)) {
                      fetchedStatus = 'Belum Dinilai';
                    }
                    _statusMapHarian[tugasSiswaId] = fetchedStatus;
                  }
                  print(
                    'DEBUG: Data tugas harian berhasil dimuat. Jumlah: ${_tugasHarianList.length}',
                  );
                } else {
                  _tugasAkhirList = data;
                  for (var item in data) {
                    int tugasAkhirSiswaId = int.parse(
                      item['tugas_akhir_siswa_id'].toString(),
                    );
                    if (!_komentarControllersAkhir.containsKey(
                      tugasAkhirSiswaId,
                    )) {
                      _komentarControllersAkhir[tugasAkhirSiswaId] =
                          TextEditingController();
                    }
                    _komentarControllersAkhir[tugasAkhirSiswaId]?.text =
                        item['komentar']?.toString() ?? '';

                    String fetchedStatus =
                        item['status_penilaian']?.toString() ?? 'Belum Dinilai';
                    // No mapping for 'Dinilai' to 'Diterima' for final tasks if DB enum is already 'Diterima'/'Revisi'
                    if (![
                      "Diterima",
                      "Revisi",
                      "Belum Dinilai",
                    ].contains(fetchedStatus)) {
                      fetchedStatus = 'Belum Dinilai';
                    }
                    _statusMapAkhir[tugasAkhirSiswaId] = fetchedStatus;
                  }
                  print(
                    'DEBUG: Data tugas akhir berhasil dimuat. Jumlah: ${_tugasAkhirList.length}',
                  );
                }
              });
            } else {
              _showSnackBar(
                "Format data 'data' tidak valid dari server untuk ${type == PenilaianType.harian ? 'tugas harian' : 'tugas akhir'}.",
              );
              print(
                "DEBUG: Response body 'data' is null or not a List for ${type == PenilaianType.harian ? 'tugas harian' : 'tugas akhir'}: ${response.body}",
              );
              setState(() {
                if (type == PenilaianType.harian) {
                  _tugasHarianList = [];
                  _errorMessageHarian = responseBody['message'] ??
                      "Format data tidak valid dari server (key 'data' bermasalah untuk tugas harian).";
                } else {
                  _tugasAkhirList = [];
                  _errorMessageAkhir = responseBody['message'] ??
                      "Format data tidak valid dari server (key 'data' bermasalah untuk tugas akhir).";
                }
              });
            }
          } else {
            _showSnackBar(
              "Gagal memuat ${type == PenilaianType.harian ? 'tugas harian' : 'tugas akhir'}: ${responseBody['message'] ?? 'Pesan tidak diketahui'}",
            );
            print(
              "DEBUG: Status PHP false untuk ${type == PenilaianType.harian ? 'tugas harian' : 'tugas akhir'}: ${response.body}",
            );
            setState(() {
              if (type == PenilaianType.harian) {
                _tugasHarianList = [];
                _errorMessageHarian =
                    responseBody['message'] ?? "Terjadi kesalahan pada server.";
              } else {
                _tugasAkhirList = [];
                _errorMessageAkhir =
                    responseBody['message'] ?? "Terjadi kesalahan pada server.";
              }
            });
          }
        } on FormatException catch (e) {
          _showSnackBar(
            "Gagal memproses data ${type == PenilaianType.harian ? 'tugas harian' : 'tugas akhir'}: Respons server tidak valid (bukan JSON).",
          );
          print(
            "DEBUG: FormatException saat _fetchTugas for $type: $e. Respons Body: '${response.body}'",
          );
          setState(() {
            if (type == PenilaianType.harian) {
              _tugasHarianList = [];
              _errorMessageHarian =
                  "Format data tidak valid dari server (bukan JSON yang diharapkan untuk tugas harian).";
            } else {
              _tugasAkhirList = [];
              _errorMessageAkhir =
                  "Format data tidak valid dari server (bukan JSON yang diharapkan untuk tugas akhir).";
            }
          });
        }
      } else {
        _showSnackBar(
          "Gagal memuat ${type == PenilaianType.harian ? 'tugas harian' : 'tugas akhir'}: Server mengembalikan status ${response.statusCode}",
        );
        print(
          "DEBUG: Gagal memuat ${type == PenilaianType.harian ? 'tugas harian' : 'tugas akhir'}. Status: ${response.statusCode}, Body: '${response.body}'",
        );
        setState(() {
          if (type == PenilaianType.harian) {
            _errorMessageHarian = "Server error: ${response.statusCode}.";
          } else {
            _errorMessageAkhir = "Server error: ${response.statusCode}.";
          }
        });
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          "Koneksi gagal: Tidak dapat terhubung ke server untuk ${type == PenilaianType.harian ? 'tugas harian' : 'tugas akhir'}. Pastikan IP dan koneksi Anda benar.",
        );
      }
      print("DEBUG: Error saat _fetchTugas for $type: $e");
      setState(() {
        if (type == PenilaianType.harian) {
          _errorMessageHarian = "Koneksi gagal: $e";
        } else {
          _errorMessageAkhir = "Koneksi gagal: $e";
        }
      });
    } finally {
      if (mounted) {
        setState(() {
          if (type == PenilaianType.harian) {
            _isLoadingHarian = false;
          } else {
            _isLoadingAkhir = false;
          }
        });
      }
    }
  }

  Future<void> _submitPenilaian(
    int id,
    PenilaianType type,
    String? submissionType,
    String? submissionContent,
  ) async {
    if (!mounted) return;

    setState(() => _isSubmitting = true);

    TextEditingController? controller;
    Map<int, String> statusMap;
    String endpoint;
    String idParamName;

    if (type == PenilaianType.harian) {
      controller = _komentarControllersHarian[id];
      statusMap = _statusMapHarian;
      endpoint = 'penilaian_feedback.php';
      idParamName = 'tugas_siswa_id';
    } else {
      controller = _komentarControllersAkhir[id];
      statusMap = _statusMapAkhir;
      endpoint = 'penilaian_akhir_feedback.php';
      idParamName = 'tugas_akhir_siswa_id';
    }

    final komentar = controller?.text.trim() ?? '';

    String statusToSend;
    if (statusMap[id] == null || statusMap[id] == "Belum Dinilai") {
      statusToSend = "Diterima";
    } else {
      statusToSend = statusMap[id]!;
    }

    print(
      'DEBUG: Mengirim penilaian ${type == PenilaianType.harian ? 'harian' : 'akhir'} ke URL: $_baseUrl/$endpoint',
    );
    print(
      'DEBUG: Data yang dikirim: {$idParamName: $id, komentar: "$komentar", status: "$statusToSend"}',
    );

    final url = Uri.parse('$_baseUrl/$endpoint');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          idParamName: id,
          "komentar": komentar,
          "status": statusToSend,
        }),
      );

      if (!mounted) return;

      if (response.statusCode != 200) {
        _showSnackBar(
          "Gagal menyimpan penilaian ${type == PenilaianType.harian ? 'harian' : 'akhir'}: Server mengembalikan status ${response.statusCode}",
        );
        print(
          "DEBUG: Gagal menyimpan. Status: ${response.statusCode}, Body: '${response.body}'",
        );
        return;
      }

      try {
        final resBody = jsonDecode(response.body);

        if (resBody['status'] == true) {
          _showSnackBar(
            "Penilaian ${type == PenilaianType.harian ? 'harian' : 'akhir'} berhasil disimpan!",
          );
          // Refresh data setelah berhasil menyimpan
          _fetchTugas(type);
        } else {
          _showSnackBar(
            "Gagal menyimpan penilaian ${type == PenilaianType.harian ? 'harian' : 'akhir'}: ${resBody['message'] ?? 'Pesan tidak diketahui'}",
          );
          print(
            "DEBUG: Gagal menyimpan: ${resBody['message'] ?? 'Respon tidak valid'}",
          );
        }
      } on FormatException catch (e) {
        _showSnackBar(
          "Koneksi gagal saat menyimpan penilaian ${type == PenilaianType.harian ? 'harian' : 'akhir'}: Respons server tidak valid (bukan JSON).",
        );
        print("DEBUG: FormatException saat _submitPenilaian for $type: $e");
        print("DEBUG: Respons Body yang diterima: '${response.body}'");
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          "Koneksi gagal saat menyimpan penilaian ${type == PenilaianType.harian ? 'harian' : 'akhir'}: $e",
        );
      }
      print("DEBUG: Error saat _submitPenilaian for $type: $e");
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<String?> _downloadFile(String url, String filename) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/$filename';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        print('DEBUG: File downloaded to: $filePath');
        return filePath;
      } else {
        print(
          'DEBUG: Failed to download file. Status: ${response.statusCode}. Body: ${response.body}',
        );
        return null;
      }
    } catch (e) {
      print('DEBUG: Error downloading file: $e');
      return null;
    }
  }

  void _openFile(String? submissionType, String? submissionContent) async {
    if (submissionContent == null || submissionContent.isEmpty) {
      _showSnackBar("Tidak ada file/link yang tersedia untuk dibuka.");
      return;
    }

    if (submissionType == 'file') {
      final String fileUrl = submissionContent;
      final String fileName = fileUrl.split('/').last;

      _showSnackBar("Mengunduh file...");

      final downloadedFilePath = await _downloadFile(fileUrl, fileName);

      if (downloadedFilePath != null) {
        try {
          OpenFilex.open(downloadedFilePath);
        } catch (e) {
          _showSnackBar(
            "Gagal membuka file. Pastikan ada aplikasi penampil untuk jenis file ini.",
          );
          print("DEBUG: Error OpenFilex.open: $e");
        }
      } else {
        _showSnackBar("Gagal mengunduh file.");
      }
    } else if (submissionType == 'link') {
      final uri = Uri.tryParse(submissionContent);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showSnackBar("Gagal membuka link. URL mungkin tidak valid.");
        print(
          "DEBUG: canLaunchUrl returned false for link: $submissionContent",
        );
      }
    } else {
      _showSnackBar("Tipe pengiriman tidak didukung.");
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

  Widget _buildTugasItem(dynamic item, PenilaianType type) {
    int id;
    String namaSiswa;
    String namaTugas;
    String? submissionType;
    String? submissionContent;
    String submittedAt;
    String currentStatus;
    TextEditingController? komentarController;
    Map<int, String> statusMap;

    if (type == PenilaianType.harian) {
      id = int.parse(item['tugas_siswa_id'].toString());
      namaSiswa =
          item['nama_siswa']?.toString() ?? 'Nama Siswa Tidak Diketahui';
      namaTugas = item['nama_tugas']?.toString() ?? 'Tugas Tidak Diketahui';
      submissionType = item['submission_type']?.toString();
      submissionContent = item['submission_content']?.toString();
      submittedAt = item['submitted_at']?.toString() ?? 'Belum diserahkan';
      currentStatus = _statusMapHarian[id] ?? 'Belum Dinilai';
      komentarController = _komentarControllersHarian[id];
      statusMap = _statusMapHarian;
    } else {
      id = int.parse(item['tugas_akhir_siswa_id'].toString());
      namaSiswa =
          item['nama_siswa']?.toString() ?? 'Nama Siswa Tidak Diketahui';
      namaTugas =
          item['nama_tugas_akhir']?.toString() ?? 'Tugas Akhir Tidak Diketahui';
      submissionType = item['submission_type']?.toString();
      submissionContent = item['submission_content']?.toString();
      submittedAt = item['submitted_at']?.toString() ?? 'Belum diserahkan';
      currentStatus = _statusMapAkhir[id] ?? 'Belum Dinilai';
      komentarController = _komentarControllersAkhir[id];
      statusMap = _statusMapAkhir;
    }

    String? dropdownValue;
    if (["Diterima", "Revisi"].contains(currentStatus)) {
      dropdownValue = currentStatus;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    namaSiswa,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                      color: Colors.blue.shade800,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  submittedAt,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              type == PenilaianType.harian
                  ? "Tugas: $namaTugas"
                  : "Tugas Akhir: $namaTugas",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const Divider(height: 25, thickness: 1),
            (submissionContent != null && submissionContent.isNotEmpty)
                ? GestureDetector(
                    onTap: () => _openFile(submissionType, submissionContent),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Icon(
                            submissionType == 'link'
                                ? Icons.link
                                : Icons.attachment,
                            color: Colors.teal.shade600,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              submissionType == 'link'
                                  ? "Lihat Link ${type == PenilaianType.harian ? 'Tugas' : 'Tugas Akhir'}"
                                  : "Lihat File ${type == PenilaianType.harian ? 'Tugas' : 'Tugas Akhir'}",
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                color: Colors.teal.shade600,
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      "Tidak ada file atau link yang diunggah untuk ${type == PenilaianType.harian ? 'tugas ini' : 'tugas akhir ini'}.",
                      style: GoogleFonts.poppins(
                        color: Colors.red.shade400,
                        fontStyle: FontStyle.italic,
                        fontSize: 14,
                      ),
                    ),
                  ),
            const SizedBox(height: 18),
            TextField(
              controller: komentarController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: "Komentar / Review",
                labelStyle: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
                alignLabelWithHint: true,
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
            ),
            const SizedBox(height: 18),
            DropdownButtonFormField<String>(
              value: dropdownValue,
              hint: Text(
                currentStatus == "Belum Dinilai"
                    ? "Pilih Status"
                    : currentStatus,
                style: GoogleFonts.poppins(
                  color: currentStatus == "Belum Dinilai"
                      ? Colors.orange.shade800
                      : Colors.black87,
                  fontWeight: currentStatus == "Belum Dinilai"
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
              decoration: InputDecoration(
                labelText: "Status Penilaian",
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
              items: ["Diterima", "Revisi"]
                  .map(
                    (val) => DropdownMenuItem(
                      value: val,
                      child: Text(
                        val,
                        style: GoogleFonts.poppins(fontSize: 15),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (val) {
                setState(() {
                  statusMap[id] = val!;
                });
              },
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting
                    ? null
                    : () => _submitPenilaian(
                          id,
                          type,
                          submissionType,
                          submissionContent,
                        ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                ),
                icon: _isSubmitting
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
                  _isSubmitting ? "Menyimpan..." : "Simpan Penilaian",
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
  }

  Widget _buildContentForTab(PenilaianType type) {
    bool isLoading =
        type == PenilaianType.harian ? _isLoadingHarian : _isLoadingAkhir;
    String? errorMessage =
        type == PenilaianType.harian ? _errorMessageHarian : _errorMessageAkhir;
    List<dynamic> dataList =
        type == PenilaianType.harian ? _tugasHarianList : _tugasAkhirList;

    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.blue.shade700),
            const SizedBox(height: 16),
            Text(
              "Memuat data ${type == PenilaianType.harian ? 'tugas harian' : 'tugas akhir'}...",
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
                errorMessage,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () => _fetchTugas(type),
                icon: const Icon(Icons.refresh),
                label: Text("Coba Lagi", style: GoogleFonts.poppins()),
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
      );
    } else if (dataList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox_outlined, size: 80, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                "Tidak ada ${type == PenilaianType.harian ? 'tugas harian' : 'tugas akhir'} siswa yang perlu dinilai saat ini.",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => _fetchTugas(type),
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
      return ListView.builder(
        padding: const EdgeInsets.only(bottom: 80, top: 12),
        itemCount: dataList.length,
        itemBuilder: (context, index) {
          return _buildTugasItem(dataList[index], type);
        },
      );
    }
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
          "PENILAIAN TUGAS",
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
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.blue.shade200,
          indicatorColor: Colors.white,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          unselectedLabelStyle: GoogleFonts.poppins(),
          tabs: const [Tab(text: "Tugas Harian"), Tab(text: "Tugas Akhir")],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildContentForTab(PenilaianType.harian),
          _buildContentForTab(PenilaianType.akhir),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.blue,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.black,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        currentIndex: 2, // Default to Feedback tab
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
              // Stay on this page (PenilaianFeedbackPage)
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
                  builder: (context) => const PenilaianFeedbackPage(),
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
}
