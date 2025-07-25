import 'dart:io';
import 'dart:convert';
import 'dart:math'; // Impor ini diperlukan untuk min()
import 'package:sitemon/screens/users/home_screen_users.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:sitemon/screens/users/absen_screen.dart';
import 'package:sitemon/screens/users/profile.dart';
import 'package:sitemon/screens/users/sertifikat.dart';

// Definisikan kembali enum TugasType karena digunakan di dalam kode
enum TugasType { regular, finalTask }

class TugasPage extends StatefulWidget {
  const TugasPage({Key? key}) : super(key: key);

  @override
  _TugasPageState createState() => _TugasPageState();
}

class _TugasPageState extends State<TugasPage> {
  List<Map<String, dynamic>> dailyTasks = [];
  List<Map<String, dynamic>> finalTasks = [];

  bool isLoading = true;
  String errorMessage = '';

  int? _currentUserId;

  late String _baseUrlApi;

  int _selectedIndex = 0; // 0 untuk Tugas Harian, 1 untuk Tugas Akhir

  @override
  void initState() {
    super.initState();
    _initializeBaseUrl(); // Inisialisasi base URL
    _loadUserIdAndFetchAllTasks(); // Panggil fungsi untuk mengambil semua tugas
  }

  void _initializeBaseUrl() {
    _baseUrlApi = 'http://192.168.50.189/sitemon_api/users/tugas/';
    print('DEBUG: Base API URL for Student Tasks: $_baseUrlApi');
  }

  Future<void> _loadUserIdAndFetchAllTasks() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int? userIdFromPrefs = prefs.getInt('user_id');

    print(
        'DEBUG: userId yang diambil dari SharedPreferences: $userIdFromPrefs (Tipe: ${userIdFromPrefs.runtimeType})');

    if (userIdFromPrefs == null) {
      setState(() {
        isLoading = false;
        errorMessage =
            'Anda belum login atau User ID tidak ditemukan. Silakan login terlebih dahulu.';
      });
      print('DEBUG: userId ditemukan null, menampilkan pesan error.');
      _showError('Autentikasi gagal. Mohon login ulang.'); // Tampilkan SnackBar
      return;
    }

    setState(() {
      _currentUserId = userIdFromPrefs;
    });

    // Panggil kedua fungsi fetch sekaligus
    await _fetchTasksAndSubmissions(TugasType.regular);
    await _fetchTasksAndSubmissions(TugasType.finalTask);

    setState(() {
      isLoading = false; // Setelah semua fetch selesai
    });
  }

  Future<void> _fetchTasksAndSubmissions(TugasType type) async {
    if (_currentUserId == null) {
      errorMessage = 'User ID tidak tersedia. Harap login kembali.';
      _showError(errorMessage);
      return;
    }

    String taskNameForApi; // e.g., 'tugas' or 'tugas_akhir'
    String taskIdKey; // e.g., 'tugas_id' or 'tugas_akhir_id'
    String submissionIdKey; // e.g., 'tugas_siswa_id' or 'tugas_akhir_siswa_id'

    // Inisialisasi local variable untuk list yang akan diupdate
    List<Map<String, dynamic>> tempTasksList;

    if (type == TugasType.finalTask) {
      taskNameForApi = 'tugas_akhir';
      taskIdKey = 'tugas_akhir_id';
      submissionIdKey = 'tugas_akhir_siswa_id';
      tempTasksList = []; // Inisialisasi kosong
    } else {
      taskNameForApi = 'tugas';
      taskIdKey = 'tugas_id';
      submissionIdKey = 'tugas_siswa_id';
      tempTasksList = []; // Inisialisasi kosong
    }

    try {
      // Fetch tasks (e.g., get_tugas.php atau get_tugas_akhir.php)
      final tasksResponse = await http.get(
        Uri.parse('${_baseUrlApi}get_$taskNameForApi.php'),
      );

      if (tasksResponse.statusCode == 200) {
        List<dynamic> fetchedTasks = [];
        try {
          fetchedTasks = json.decode(tasksResponse.body);
          print(
              'DEBUG: Fetched ${taskNameForApi.toUpperCase()}: $fetchedTasks');
        } on FormatException catch (e) {
          final String typeStr =
              type == TugasType.finalTask ? 'Tugas Akhir' : 'Tugas Harian';
          errorMessage =
              'Error parsing tasks data for $typeStr: Format JSON tidak valid. (Detail: ${e.message})';
          _showError(errorMessage);
          print('JSON Parse Error (Tasks $typeStr): $e');
          print('Raw Tasks Response: ${tasksResponse.body}');
          setState(() {
            isLoading = false;
          }); // Update loading state on error
          return; // Hentikan eksekusi lebih lanjut jika ada error JSON
        }

        // Fetch submissions (e.g., user_submission_tugas.php atau user_submission_tugas_akhir.php)
        final submissionsResponse = await http.get(
          Uri.parse(
              '${_baseUrlApi}user_submission_$taskNameForApi.php?userId=$_currentUserId'),
        );

        List<dynamic> fetchedSubmissions = [];
        if (submissionsResponse.statusCode == 200) {
          try {
            fetchedSubmissions = json.decode(submissionsResponse.body);
            print(
                'DEBUG: Fetched Submissions for ${taskNameForApi.toUpperCase()}: $fetchedSubmissions');
          } on FormatException catch (e) {
            final String typeStr =
                type == TugasType.finalTask ? 'Tugas Akhir' : 'Tugas Harian';
            errorMessage =
                'Error parsing user submissions data for $typeStr: Format JSON tidak valid. (Detail: ${e.message})';
            _showError(errorMessage);
            print('JSON Parse Error (Submissions $typeStr): $e');
            print('Raw Submissions Response: ${submissionsResponse.body}');
            setState(() {
              isLoading = false;
            }); // Update loading state on error
            return;
          }
        } else {
          final String typeStr =
              type == TugasType.finalTask ? 'Tugas Akhir' : 'Tugas Harian';
          errorMessage =
              'Gagal memuat kiriman pengguna untuk $typeStr: Status ${submissionsResponse.statusCode}. (Pesan: ${submissionsResponse.body})';
          _showError(errorMessage);
          print(
              'Submissions Response Body for $typeStr: ${submissionsResponse.body}');
          setState(() {
            isLoading = false;
          }); // Update loading state on error
          return;
        }

        // Fetch feedback (e.g., get_penilaian_tugas.php atau get_penilaian_tugas_akhir.php)
        final feedbackResponse = await http.get(
          Uri.parse(
              '${_baseUrlApi}get_penilaian_$taskNameForApi.php?userId=$_currentUserId'),
        );

        Map<int, Map<String, dynamic>> feedbackMap = {};
        if (feedbackResponse.statusCode == 200) {
          try {
            final List<dynamic> fetchedFeedback =
                json.decode(feedbackResponse.body);
            print(
                'DEBUG: Fetched Feedback for ${taskNameForApi.toUpperCase()}: $fetchedFeedback');
            for (var feedback in fetchedFeedback) {
              feedbackMap[
                  int.tryParse(feedback[submissionIdKey].toString()) ?? 0] = {
                'komentar': feedback['komentar'],
                'status_penilaian':
                    (feedback['status'] as String? ?? '').trim(),
              };
            }
            print(
                'DEBUG: Feedback Map for ${taskNameForApi.toUpperCase()}: $feedbackMap');
          } on FormatException catch (e) {
            print(
                'JSON Parse Error (Feedback ${taskNameForApi.toUpperCase()}): $e');
            print('Raw Feedback Response: ${feedbackResponse.body}');
            // Ini mungkin bukan error fatal jika feedback tidak kritis,
            // jadi kita tidak return, hanya log dan mungkin set pesan.
          }
        } else {
          print(
              'Failed to load feedback for ${taskNameForApi.toUpperCase()}: ${feedbackResponse.statusCode}. Response: ${feedbackResponse.body}');
        }

        tempTasksList = fetchedTasks.map((task) {
          final int taskId = int.tryParse(task['id'].toString()) ?? 0;

          final submission = fetchedSubmissions.firstWhere(
            (sub) => int.tryParse(sub[taskIdKey].toString()) == taskId,
            orElse: () => null,
          );

          String submissionStatus = (submission != null
                      ? (submission['status'] as String? ?? '')
                      : 'Belum Selesai')
                  .trim() // Trim whitespace
              ;

          String submissionType = submission != null
              ? (submission['submission_type'] ?? 'none')
              : 'none';
          String submissionContent = submission != null
              ? (submission['submission_content'] ?? '')
              : '';

          final int submissionId =
              int.tryParse(submission?['id'].toString() ?? '0') ?? 0;
          final feedback = feedbackMap[submissionId];

          if (feedback != null) {
            String feedbackStatusFromDb =
                (feedback['status_penilaian'] as String);
            if (feedbackStatusFromDb == 'Diterima') {
              submissionStatus = 'Diterima';
            } else if (feedbackStatusFromDb == 'Revisi') {
              submissionStatus = 'Revisi';
            }
          }

          String supervisorComment = _getKomentarPembimbing(
            submissionStatus,
            feedback,
            taskNameForApi.replaceAll(
                '_', ' '), // Untuk komentar dinamis seperti "tugas akhir"
          );

          Widget? taskProofWidget;
          if (submissionType == 'file' && submissionContent.isNotEmpty) {
            final String fileUrl = submissionContent;
            final String fileExtension = fileUrl.split('.').last.toLowerCase();
            final String fileName = fileUrl.split('/').last;

            if (_isImageFile(fileExtension)) {
              taskProofWidget = Image.network(
                fileUrl,
                fit: BoxFit.cover,
                width: 100,
                height: 100,
                errorBuilder: (context, error, stackTrace) {
                  print('Image.network error: $error, URL: $fileUrl');
                  return const Icon(
                    Icons.broken_image,
                    size: 100,
                    color: Colors.red,
                  );
                },
              );
            } else {
              taskProofWidget = GestureDetector(
                onTap: () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Mengunduh $fileExtension: $fileName...',
                      ),
                    ),
                  );
                  final downloadedFilePath = await _downloadFile(
                    fileUrl,
                    fileName,
                  );

                  if (downloadedFilePath != null) {
                    OpenFilex.open(downloadedFilePath);
                  } else {
                    _showError('Gagal mengunduh file.');
                  }
                },
                child: Column(
                  children: [
                    Icon(
                      Icons.description,
                      size: 50,
                      color: Colors.blueAccent,
                    ),
                    Text(
                      'Lihat Dokumen ($fileExtension)',
                      style: GoogleFonts.poppins(
                        color: Colors.blue.shade700,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              );
            }
          } else if (submissionType == 'link' && submissionContent.isNotEmpty) {
            taskProofWidget = GestureDetector(
              onTap: () async {
                final uri = Uri.tryParse(submissionContent);
                if (uri != null && await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                } else {
                  _showError('Tidak bisa membuka link: $submissionContent');
                }
              },
              child: Text(
                'Lihat Link',
                style: GoogleFonts.poppins(
                  color: Colors.blue.shade700,
                  decoration: TextDecoration.underline,
                ),
              ),
            );
          }

          return {
            'id': taskId,
            'nama_tugas': task['nama_tugas'],
            'deadline': task['deadline'],
            'deskripsi_tugas': task['deskripsi_tugas'],
            'selesai': submission != null,
            'submission_type': submissionType,
            'submission_content': submissionContent,
            'proof_widget': taskProofWidget,
            'komentarPembimbing': supervisorComment,
            'status': submissionStatus,
          };
        }).toList();

        setState(() {
          if (type == TugasType.finalTask) {
            finalTasks = tempTasksList;
          } else {
            dailyTasks = tempTasksList;
          }
          errorMessage = ''; // Clear error message on successful fetch
          print(
              'DEBUG: ${taskNameForApi.toUpperCase()} state updated. Count: ${tempTasksList.length}');
        });
      } else {
        final String typeStr =
            type == TugasType.finalTask ? 'Tugas Akhir' : 'Tugas Harian';
        errorMessage =
            'Gagal memuat tugas untuk $typeStr: Status ${tasksResponse.statusCode}. (Pesan: ${tasksResponse.body})';
        _showError(errorMessage);
        print('Tasks Response Body for $typeStr: ${tasksResponse.body}');
        setState(() {
          isLoading = false;
        }); // Update loading state on error
      }
    } on SocketException catch (e) {
      final String typeStr =
          type == TugasType.finalTask ? 'Tugas Akhir' : 'Tugas Harian';
      errorMessage = 'Anda sedang offline. Periksa koneksi internet Anda.';
      _showError(errorMessage);
      print('SocketException fetching $typeStr data: $e');
      setState(() {
        isLoading = false;
      }); // Update loading state on error
    } catch (e) {
      final String typeStr =
          type == TugasType.finalTask ? 'Tugas Akhir' : 'Tugas Harian';
      errorMessage =
          'Terjadi kesalahan tidak terduga saat mengambil data $typeStr: ${e.toString()}';
      _showError(errorMessage);
      print('Error fetching tasks and submissions for $typeStr: $e');
      setState(() {
        isLoading = false;
      }); // Update loading state on error
    }
  }

  bool _isImageFile(String fileExtension) {
    return [
      'jpg',
      'jpeg',
      'png',
      'gif',
      'bmp',
      'webp',
    ].contains(fileExtension.toLowerCase());
  }

  Future<String?> _downloadFile(String url, String filename) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/$filename';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        return filePath;
      } else {
        print('Failed to download file. Status: ${response.statusCode}');
        return null;
      }
    } on SocketException catch (e) {
      _showError('Gagal mengunduh file: Tidak ada koneksi internet.');
      print('SocketException downloading file: $e');
      return null;
    } catch (e) {
      _showError('Gagal mengunduh file: Terjadi kesalahan. ${e.toString()}');
      print('Error downloading file: $e');
      return null;
    }
  }

  String _getKomentarPembimbing(String currentTaskStatus,
      Map<String, dynamic>? feedback, String taskTypeName) {
    if (feedback != null &&
        feedback['komentar'] != null &&
        feedback['komentar'].isNotEmpty) {
      return feedback['komentar'];
    }

    switch (currentTaskStatus) {
      case 'Diterima':
        return '${taskTypeName.toUpperCase()} telah diperiksa dan Diterima, bagus sekali!';
      case 'Revisi':
        return '${taskTypeName.toUpperCase()} perlu direvisi. Silakan periksa kembali.';
      case 'Belum Dinilai':
        return '${taskTypeName.toUpperCase()} sedang menunggu penilaian.';
      case 'Menunggu Pengiriman':
        return 'Sedang mengunggah bukti ${taskTypeName.toLowerCase()}...';
      case 'Gagal Dikirim':
        return 'Pengiriman ${taskTypeName.toLowerCase()} gagal. Coba lagi.';
      default:
        return 'Belum dikirim';
    }
  }

  Future<void> _showSubmissionDialog(int index, TugasType type) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Unggah Bukti ${_getTaskNameForDisplay(type)}',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                    _submitTask(index, 'file_image', type);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.image, color: Colors.blue.shade700),
                        const SizedBox(width: 10),
                        Text('Unggah Foto', style: GoogleFonts.poppins()),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                    _submitTask(index, 'file_document', type);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.insert_drive_file,
                          color: Colors.purple.shade700,
                        ),
                        const SizedBox(width: 10),
                        Text('Unggah Dokumen', style: GoogleFonts.poppins()),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                    _submitTask(index, 'link', type);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.link, color: Colors.green.shade700),
                        const SizedBox(width: 10),
                        Text('Unggah Link', style: GoogleFonts.poppins()),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _submitTask(
      int index, String submissionType, TugasType type) async {
    if (_currentUserId == null) {
      _showError(
          'Anda harus login untuk mengunggah ${_getTaskNameForDisplay(type).toLowerCase()}.');
      return;
    }

    List<Map<String, dynamic>> targetTasksList;
    String taskIdKey;
    String taskNameForApi;

    if (type == TugasType.finalTask) {
      targetTasksList = finalTasks;
      taskIdKey = 'tugas_akhir_id';
      taskNameForApi = 'tugas_akhir';
    } else {
      targetTasksList = dailyTasks;
      taskIdKey = 'tugas_id';
      taskNameForApi = 'tugas';
    }

    final int dynamicTaskId = targetTasksList[index]['id'];
    String? content;

    if (submissionType.startsWith('file_')) {
      String? pickedFilePath;
      if (submissionType == 'file_image') {
        final picker = ImagePicker();
        final pickedFile = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 70,
          maxWidth: 1024,
          maxHeight:
              (1024 / (16 / 9)).roundToDouble(), // Ensures 16:9 aspect ratio
        );
        pickedFilePath = pickedFile?.path;
      } else if (submissionType == 'file_document') {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: [
            'pdf',
            'doc',
            'docx',
            'ppt',
            'pptx',
            'xls',
            'xlsx',
            'txt',
          ],
        );
        pickedFilePath = result?.files.single.path;
      }

      if (pickedFilePath == null) {
        print('File selection cancelled by user.');
        _showError('Unggahan dibatalkan.');
        return;
      }
      content = pickedFilePath;
    } else if (submissionType == 'link') {
      TextEditingController linkController = TextEditingController();
      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
              'Masukkan Link ${_getTaskNameForDisplay(type)}',
              style: GoogleFonts.poppins(),
            ),
            content: TextField(
              controller: linkController,
              decoration: InputDecoration(
                hintText: 'Misal: https://docs.google.com/document/d/...',
                border: OutlineInputBorder(),
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text('Batal', style: GoogleFonts.poppins()),
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
              ),
              ElevatedButton(
                child: Text('Kirim', style: GoogleFonts.poppins()),
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
              ),
            ],
          );
        },
      );

      if (confirm == null || !confirm || linkController.text.isEmpty) {
        _showError('Pengiriman link dibatalkan atau kosong.');
        return;
      }
      content = linkController.text;
    }

    // Perbarui UI secara optimistik atau untuk menampilkan status "Menunggu Pengiriman"
    setState(() {
      targetTasksList[index]['komentarPembimbing'] =
          'Mengunggah ${_getTaskNameForDisplay(type).toLowerCase()}...';
      targetTasksList[index]['status'] = 'Menunggu Pengiriman';
      targetTasksList[index]['selesai'] = true;
      targetTasksList[index]['submission_type'] =
          submissionType.startsWith('file_') ? 'file' : submissionType;
      targetTasksList[index]['submission_content'] = content;

      if (submissionType.startsWith('file_') && content != null) {
        final String fileExtension = content.split('.').last.toLowerCase();
        if (_isImageFile(fileExtension)) {
          targetTasksList[index]['proof_widget'] = Image.file(
            File(content),
            fit: BoxFit.cover,
            width: 100,
            height: 100,
          );
        } else {
          targetTasksList[index]['proof_widget'] = Column(
            children: [
              Icon(Icons.insert_drive_file, size: 50, color: Colors.blueAccent),
              Text(
                'Dokumen (Mengunggah...)',
                style: GoogleFonts.poppins(
                  color: Colors.blue.shade700,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          );
        }
      } else if (submissionType == 'link' && content != null) {
        targetTasksList[index]['proof_widget'] = GestureDetector(
          onTap: () async {
            final uri = Uri.tryParse(content!);
            if (uri != null && await canLaunchUrl(uri)) {
              await launchUrl(uri);
            } else {
              _showError('Tidak bisa membuka link: $content');
            }
          },
          child: Text(
            'Lihat Link (Mengunggah...)',
            style: GoogleFonts.poppins(
              color: Colors.blue.shade700,
              decoration: TextDecoration.underline,
            ),
          ),
        );
      }
    });

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${_baseUrlApi}submit_$taskNameForApi.php'),
      );
      request.fields[taskIdKey] = dynamicTaskId.toString();
      request.fields['user_id'] = _currentUserId!.toString();
      request.fields['submission_type'] =
          submissionType.startsWith('file_') ? 'file' : submissionType;

      if (submissionType.startsWith('file_') && content != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            content,
            filename: content.split('/').last,
          ),
        );
      } else if (submissionType == 'link' && content != null) {
        request.fields['submission_content'] = content;
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      print(
          'DEBUG UPLOAD ${taskNameForApi.toUpperCase()} Response Status Code: ${response.statusCode}');
      print(
          'DEBUG UPLOAD ${taskNameForApi.toUpperCase()} Response Body: $responseBody');

      if (response.statusCode == 200) {
        try {
          final decodedResponse = json.decode(responseBody);
          _showSuccess(decodedResponse['message'] ??
              '${_getTaskNameForDisplay(type)} berhasil diunggah!');
          // Refresh daftar tugas spesifik setelah sukses
          _fetchTasksAndSubmissions(type);
        } on FormatException catch (e) {
          // Jika respons bukan JSON yang valid, meskipun status 200
          setState(() {
            targetTasksList[index]['selesai'] = false;
            targetTasksList[index]['komentarPembimbing'] =
                'Gagal mengunggah ${_getTaskNameForDisplay(type).toLowerCase()}: Respons server tidak valid. Silakan coba lagi.';
            targetTasksList[index]['status'] = 'Gagal Dikirim';
            targetTasksList[index]['proof_widget'] =
                null; // Clear proof widget on error
          });
          _showError('Gagal mengunggah: Respons server tidak valid.');
          print(
              'JSON Parse Error (Submit ${taskNameForApi.toUpperCase()}): $e');
          print(
              'Raw Submit ${taskNameForApi.toUpperCase()} Response: $responseBody');
        }
      } else {
        // Tangani status code non-200 dari server
        String userMessage =
            'Gagal mengunggah ${_getTaskNameForDisplay(type).toLowerCase()}. Terjadi kesalahan pada server.';
        try {
          final decodedResponse = json.decode(responseBody);
          if (decodedResponse['message'] != null) {
            userMessage = 'Gagal mengunggah: ${decodedResponse['message']}';
          }
        } on FormatException {
          userMessage =
              'Gagal mengunggah ${_getTaskNameForDisplay(type).toLowerCase()}: Respons server tidak terduga. Silakan coba lagi.';
        }
        setState(() {
          targetTasksList[index]['selesai'] = false;
          targetTasksList[index]['komentarPembimbing'] = userMessage;
          targetTasksList[index]['status'] = 'Gagal Dikirim';
          targetTasksList[index]['proof_widget'] =
              null; // Clear proof widget on error
        });
        _showError(userMessage);
        print(
            'Failed to submit ${taskNameForApi.toLowerCase()}: HTTP Status ${response.statusCode}');
        print('Error Response Body: $responseBody');
      }
    } on SocketException catch (e) {
      // Tangani masalah koneksi jaringan saat upload
      setState(() {
        targetTasksList[index]['selesai'] = false;
        targetTasksList[index]['komentarPembimbing'] =
            'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
        targetTasksList[index]['status'] = 'Gagal Dikirim';
        targetTasksList[index]['proof_widget'] =
            null; // Clear proof widget on error
      });
      _showError(
          'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.');
      print('SocketException submitting ${taskNameForApi.toLowerCase()}: $e');
    } catch (e) {
      // Tangani kesalahan umum lainnya
      setState(() {
        targetTasksList[index]['selesai'] = false;
        targetTasksList[index]['komentarPembimbing'] =
            'Terjadi kesalahan tidak terduga saat mengunggah: ${e.toString()}';
        targetTasksList[index]['status'] = 'Gagal Dikirim';
        targetTasksList[index]['proof_widget'] =
            null; // Clear proof widget on error
      });
      _showError('Terjadi kesalahan saat mengunggah: ${e.toString()}');
      print('General error submitting ${taskNameForApi.toLowerCase()}: $e');
    }
  }

  String _getTaskNameForDisplay(TugasType type) {
    return type == TugasType.regular ? 'TUGAS' : 'TUGAS AKHIR';
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4), // Durasi lebih lama untuk error
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
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
            "TUGAS SAYA",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          elevation: 4,
          toolbarHeight: 60,
          bottom: TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            unselectedLabelStyle: GoogleFonts.poppins(fontSize: 14),
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            tabs: const [
              Tab(text: "Tugas Harian", icon: Icon(Icons.assignment_outlined)),
              Tab(text: "Tugas Akhir", icon: Icon(Icons.assignment_add)),
            ],
          ),
        ),
        body: Container(
          color: Colors.white,
          child: TabBarView(
            children: [
              // Konten untuk "Tugas Harian"
              isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.blue),
                    )
                  : errorMessage.isNotEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              errorMessage,
                              style: GoogleFonts.poppins(
                                color: Colors.red,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : dailyTasks.isEmpty
                          ? Center(
                              child: Text(
                                "Belum ada tugas harian yang diberikan.",
                                style: GoogleFonts.poppins(
                                  color: Colors.black54,
                                  fontSize: 18,
                                ),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: () =>
                                  _fetchTasksAndSubmissions(TugasType.regular),
                              child: ListView.builder(
                                padding: const EdgeInsets.all(12),
                                itemCount: dailyTasks.length,
                                itemBuilder: (context, index) => buildTugasCard(
                                  dailyTasks[index],
                                  TugasType.regular,
                                  index,
                                ),
                              ),
                            ),
              // Konten untuk "Tugas Akhir"
              isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.blue),
                    )
                  : errorMessage.isNotEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              errorMessage,
                              style: GoogleFonts.poppins(
                                color: Colors.red,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : finalTasks.isEmpty
                          ? Center(
                              child: Text(
                                "Belum ada tugas akhir yang diberikan.",
                                style: GoogleFonts.poppins(
                                  color: Colors.black54,
                                  fontSize: 18,
                                ),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: () => _fetchTasksAndSubmissions(
                                  TugasType.finalTask),
                              child: ListView.builder(
                                padding: const EdgeInsets.all(12),
                                itemCount: finalTasks.length,
                                itemBuilder: (context, index) => buildTugasCard(
                                  finalTasks[index],
                                  TugasType.finalTask,
                                  index,
                                ),
                              ),
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
            switch (index) {
              case 0:
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => HomeScreenUsers()),
                );
                break;
              case 1:
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => AbsenPage()),
                );
                break;
              case 2:
                // Tetap di halaman ini dan refresh data sesuai tab yang aktif
                if (_selectedIndex == 0) {
                  _fetchTasksAndSubmissions(TugasType.regular);
                } else {
                  _fetchTasksAndSubmissions(TugasType.finalTask);
                }
                break;
              case 3:
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => SertifikatPage()),
                );
                break;
              case 4:
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => ProfilePage()),
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
              icon: Icon(Icons.camera, size: 30),
              label: "Camera",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_turned_in, size: 30),
              label: "Checklist",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.school, size: 30),
              label: "Certificate",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person, size: 30),
              label: "Profile",
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTugasCard(Map<String, dynamic> task, TugasType type, int index) {
    final bool isCompleted = task['selesai'];
    final String currentStatus = task['status'];
    final Widget? proofWidget = task['proof_widget'];
    final String taskTypeName = _getTaskNameForDisplay(type);

    String formattedDeadline = 'Tanpa Batas Waktu';
    if (task['deadline'] != null && task['deadline'].isNotEmpty) {
      try {
        DateTime deadlineDate = DateTime.parse(task['deadline']);
        formattedDeadline = DateFormat(
          'EEEE, dd MMMM yyyy',
        ).format(deadlineDate);
      } catch (e) {
        print('Error parsing deadline date: ${task['deadline']} - $e');
        formattedDeadline = task['deadline'];
      }
    }

    return Card(
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
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
                    'Deadline: $formattedDeadline',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade900,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(currentStatus).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getStatusColor(currentStatus),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    currentStatus,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(currentStatus),
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20, thickness: 1, color: Colors.grey),
            Text(
              task['nama_tugas'] ?? 'Nama $taskTypeName Tidak Tersedia',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 15),
            if (task['deskripsi_tugas'] != null &&
                task['deskripsi_tugas'].isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Deskripsi $taskTypeName:",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: Colors.blueGrey.shade700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    task['deskripsi_tugas'],
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 15),
                ],
              ),
            if (currentStatus != 'Diterima' &&
                currentStatus != 'Menunggu Pengiriman')
              Center(
                child: ElevatedButton.icon(
                  onPressed: () => _showSubmissionDialog(index, type),
                  icon: const Icon(
                    Icons.cloud_upload_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                  label: Text(
                    isCompleted &&
                            (currentStatus == 'Revisi' ||
                                currentStatus == 'Gagal Dikirim' ||
                                currentStatus == 'Belum Dinilai')
                        ? "Kirim Ulang Bukti $taskTypeName"
                        : "Unggah Bukti $taskTypeName",
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCompleted &&
                            (currentStatus == 'Revisi' ||
                                currentStatus == 'Gagal Dikirim' ||
                                currentStatus == 'Belum Dinilai')
                        ? Colors.orange.shade700
                        : Colors.green.shade600,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 5,
                  ),
                ),
              ),
            const SizedBox(height: 15),
            if (proofWidget != null) ...[
              Text(
                "Bukti $taskTypeName:",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey.shade800,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: task['submission_type'] == 'file' &&
                        _isImageFile(task['submission_content']
                            .toString()
                            .split('.')
                            .last)
                    ? 150
                    : null,
                height: task['submission_type'] == 'file' &&
                        _isImageFile(task['submission_content']
                            .toString()
                            .split('.')
                            .last)
                    ? 150
                    : null,
                decoration: BoxDecoration(
                  border: task['submission_type'] == 'file' &&
                          _isImageFile(task['submission_content']
                              .toString()
                              .split('.')
                              .last)
                      ? Border.all(color: Colors.grey.shade400, width: 1)
                      : null,
                  borderRadius: task['submission_type'] == 'file' &&
                          _isImageFile(task['submission_content']
                              .toString()
                              .split('.')
                              .last)
                      ? BorderRadius.circular(10)
                      : null,
                ),
                clipBehavior: task['submission_type'] == 'file' &&
                        _isImageFile(task['submission_content']
                            .toString()
                            .split('.')
                            .last)
                    ? Clip.antiAlias
                    : Clip.none,
                child: Center(child: proofWidget),
              ),
              const SizedBox(height: 15),
            ],
            if (task['komentarPembimbing'] != null &&
                task['komentarPembimbing'].isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Komentar Pembimbing:",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: Colors.blueGrey.shade700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      task['komentarPembimbing'],
                      style: GoogleFonts.poppins(
                        fontStyle: FontStyle.italic,
                        color: Colors.blue.shade800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Diterima':
        return Colors.green.shade700;
      case 'Revisi':
      case 'Gagal Dikirim':
        return Colors.red.shade700;
      case 'Belum Dinilai':
      case 'Menunggu Pengiriman':
        return Colors.orange.shade700;
      default:
        return Colors.grey.shade700;
    }
  }
}
