import 'dart:convert';
import 'dart:io';
import 'package:sitemon/screens/admin/atur_bimbingan.dart';
import 'package:sitemon/screens/admin/profile_admin.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sitemon/screens/admin/home_screen_admin.dart';
import 'package:sitemon/screens/admin/manajemen_sertifikat.dart';
import 'package:sitemon/screens/admin/manajemen_konten.dart';

// Model untuk ActivityLog
class ActivityLog {
  final int id;
  final int? userId;
  final String? username;
  final String activityType;
  final String description;
  final String? ipAddress;
  final DateTime timestamp;

  ActivityLog({
    required this.id,
    this.userId,
    this.username,
    required this.activityType,
    required this.description,
    this.ipAddress,
    required this.timestamp,
  });

  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    return ActivityLog(
      id: int.parse(json['id'].toString()),
      userId: json['user_id'] != null && json['user_id'].toString().isNotEmpty
          ? int.parse(json['user_id'].toString())
          : null,
      username: json['username'],
      activityType: json['activity_type'],
      description: json['description'],
      ipAddress: json['ip_address'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

// Model untuk BackupFile
class BackupFile {
  final String fileName;
  final String filePath; // Full URL to the backup file
  final DateTime createdAt;

  BackupFile({
    required this.fileName,
    required this.filePath,
    required this.createdAt,
  });

  factory BackupFile.fromJson(Map<String, dynamic> json) {
    return BackupFile(
      fileName: json['file_name'],
      filePath: json['file_path'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

// Model untuk User (untuk filter user)
class User {
  final int id;
  final String nama;

  User({required this.id, required this.nama});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: int.parse(json['id'].toString()),
      nama: json['nama'],
    );
  }
}

class BackupKeamananPage extends StatefulWidget {
  const BackupKeamananPage({Key? key}) : super(key: key);

  @override
  State<BackupKeamananPage> createState() => _BackupKeamananPageState();
}

class _BackupKeamananPageState extends State<BackupKeamananPage> {
  List<ActivityLog> _activityLogs = [];
  List<BackupFile> _backupFiles = [];
  List<User> _users = []; // List untuk menyimpan data user
  bool _isLoading = true;
  String? _errorMessage;
  String? _lastBackupFilePath;

  int? _selectedMonth;
  int? _selectedYear;
  int? _selectedUserId; // New: Filter by user ID
  String _selectedBackupType = 'database_sql';

  final String _baseUrl =
      'http://192.168.50.189/sitemon_api/admin/backup_keamanan';
  final Dio _dio = Dio(); // Inisialisasi Dio

  @override
  void initState() {
    super.initState();
    _fetchActivityLogs();
    _fetchBackupFiles();
    _fetchUsers(); // Fetch users for filtering
  }

  Future<void> _fetchActivityLogs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/get_activity_logs.php'))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> responseBody = json.decode(response.body);
          if (responseBody['status'] == 'success') {
            final List<dynamic> data = responseBody['data'];
            setState(() {
              _activityLogs =
                  data.map((json) => ActivityLog.fromJson(json)).toList();
            });
          } else {
            throw Exception('API error: ${responseBody['message']}');
          }
        } on FormatException catch (e) {
          _errorMessage =
              'Kesalahan format data dari server: ${e.message}. Respon mentah: ${response.body}';
          print('FormatException (Activity Logs): ${e.message}');
          print('Raw response body (Activity Logs): ${response.body}');
        }
      } else {
        throw Exception(
          'Gagal mengambil log aktivitas: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Terjadi kesalahan saat mengambil log aktivitas: $e';
      });
      print('Error fetching activity logs: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchBackupFiles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/get_backup_files.php'))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> responseBody = json.decode(response.body);
          if (responseBody['status'] == 'success') {
            final List<dynamic> data = responseBody['data'];
            setState(() {
              _backupFiles =
                  data.map((json) => BackupFile.fromJson(json)).toList();
            });
          } else {
            throw Exception('API error: ${responseBody['message']}');
          }
        } on FormatException catch (e) {
          _errorMessage =
              'Kesalahan format data file backup: ${e.message}. Respon mentah: ${response.body}';
          print('FormatException (Backup Files): ${e.message}');
          print('Raw response body (Backup Files): ${response.body}');
        }
      } else {
        throw Exception(
          'Gagal mengambil daftar file backup: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage =
            'Terjadi kesalahan saat mengambil daftar file backup: $e';
      });
      print('Error fetching backup files: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // New: Fetch users for filtering (only accepted internship users)
  Future<void> _fetchUsers() async {
    try {
      final response = await http
          .get(
            Uri.parse(
                'http://192.168.50.189/sitemon_api/admin/backup_keamanan/get_users.php'),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = json.decode(response.body);
        if (responseBody['status'] == 'success') {
          final List<dynamic> data = responseBody['data'];
          setState(() {
            _users = data.map((json) => User.fromJson(json)).toList();
          });
        } else {
          print('API Error fetching users: ${responseBody['message']}');
        }
      } else {
        print('HTTP Error fetching users: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching users: $e');
    }
  }

  Future<void> _performBackup() async {
    setState(() {
      _isLoading = true;
      _lastBackupFilePath = null;
    });

    Map<String, String> queryParams = {'type': _selectedBackupType};
    if (_selectedBackupType != 'database_sql') {
      if (_selectedMonth != null) {
        queryParams['month'] = _selectedMonth.toString();
      }
      if (_selectedYear != null) {
        queryParams['year'] = _selectedYear.toString();
      }
      // Add user ID to query params if selected and not full database backup
      if (_selectedUserId != null) {
        queryParams['user_id'] = _selectedUserId.toString();
      }
    }

    Uri uri = Uri.parse(
      '$_baseUrl/backup_data.php',
    ).replace(queryParameters: queryParams);

    try {
      final response =
          await http.post(uri).timeout(const Duration(seconds: 120));

      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> responseBody = json.decode(response.body);
          _showSnackBar(responseBody['message']);

          if (responseBody['status'] == 'success') {
            setState(() {
              _lastBackupFilePath = responseBody['file_path'];
            });
            _fetchActivityLogs();
            _fetchBackupFiles();
          }
        } on FormatException catch (e) {
          _showSnackBar(
            'Error: Respon server tidak valid (bukan JSON). Mungkin ada output tambahan dari server PHP. Detail: ${e.message}',
          );
          print('FormatException (Perform Backup): ${e.message}');
          print('Raw response body (Perform Backup): ${response.body}');
        }
      } else {
        _showSnackBar(
          'Gagal melakukan backup: Status ${response.statusCode} - ${response.body}',
        );
        print(
          'HTTP Error during backup: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      _showSnackBar('Error saat melakukan backup: $e');
      print('Error performing backup: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 4)),
    );
  }

  Future<void> _downloadBackupFile(String url, String fileName) async {
    _showSnackBar('Mencoba mengunduh $fileName...');
    try {
      final directory = await getTemporaryDirectory();
      final String savePath = '${directory.path}/$fileName';

      if (!await Directory(directory.path).exists()) {
        await Directory(directory.path).create(recursive: true);
      }

      await _dio.download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            // Anda bisa menampilkan progress di UI jika mau
            // print((received / total * 100).toStringAsFixed(0) + "%");
          }
        },
      );

      _showSnackBar('File $fileName berhasil diunduh ke: $savePath');

      final result = await OpenFilex.open(savePath);

      if (result.type == ResultType.done) {
        _showSnackBar('Membuka file $fileName...');
      } else {
        _showSnackBar('Gagal membuka file $fileName: ${result.message}');
        print('OpenFilex error: ${result.message}');
      }
    } on DioException catch (e) {
      String errorMessage = 'Error unduh file: ';
      if (e.response != null) {
        errorMessage +=
            'Status ${e.response?.statusCode}. Pesan: ${e.response?.statusMessage}';
      } else {
        errorMessage += e.message ?? 'Unknown error';
      }
      _showSnackBar(errorMessage);
      print('DioError: $e');
    } catch (e) {
      _showSnackBar('Error saat mengunduh atau membuka file: $e');
      print('General download/open error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'BACKUP & KEAMANAN',
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
                      _errorMessage!,
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
                      _buildSectionTitle('Buat Backup Baru'),
                      Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pilih jenis backup yang ingin Anda buat dan filter opsionalnya.',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.blueGrey.shade700,
                                ),
                              ),
                              const SizedBox(height: 15),
                              DropdownButtonFormField<String>(
                                decoration: InputDecoration(
                                  labelText: 'Tipe Backup',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                ),
                                value: _selectedBackupType,
                                items: [
                                  DropdownMenuItem(
                                    value: 'database_sql',
                                    child: Text(
                                      'Full Database (.sql)',
                                      style: GoogleFonts.poppins(),
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'absen_csv',
                                    child: Text(
                                      'Data Absensi (.csv)',
                                      style: GoogleFonts.poppins(),
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'tugas_csv',
                                    child: Text(
                                      'Data Penugasan (.csv)',
                                      style: GoogleFonts.poppins(),
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'tugas_akhir_csv', // New backup type
                                    child: Text(
                                      'Data Tugas Akhir (.csv)', // Display text
                                      style: GoogleFonts.poppins(),
                                    ),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedBackupType = value!;
                                    if (_selectedBackupType == 'database_sql') {
                                      _selectedMonth = null;
                                      _selectedYear = null;
                                      _selectedUserId =
                                          null; // Reset user filter
                                    }
                                  });
                                },
                              ),
                              const SizedBox(height: 10),
                              if (_selectedBackupType != 'database_sql')
                                Column(
                                  children: [
                                    DropdownButtonFormField<int>(
                                      decoration: InputDecoration(
                                        labelText: 'Filter Bulan',
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        filled: true,
                                        fillColor: Colors.grey[100],
                                      ),
                                      value: _selectedMonth,
                                      hint: Text(
                                        'Pilih Bulan',
                                        style: GoogleFonts.poppins(),
                                      ),
                                      items: [
                                        const DropdownMenuItem(
                                          value: null,
                                          child: Text(
                                            'Semua Bulan',
                                            style: TextStyle(
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ),
                                        for (int i = 1; i <= 12; i++)
                                          DropdownMenuItem(
                                            value: i,
                                            child: Text(
                                              DateFormat.MMMM(
                                                'id', // Use 'id' for Indonesian month names
                                              ).format(DateTime(2023, i)),
                                              style: GoogleFonts.poppins(),
                                            ),
                                          ),
                                      ],
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedMonth = value;
                                        });
                                      },
                                    ),
                                    const SizedBox(height: 10),
                                  ],
                                ),
                              if (_selectedBackupType != 'database_sql')
                                DropdownButtonFormField<int>(
                                  decoration: InputDecoration(
                                    labelText: 'Filter Tahun',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[100],
                                  ),
                                  value: _selectedYear,
                                  hint: Text(
                                    'Pilih Tahun',
                                    style: GoogleFonts.poppins(),
                                  ),
                                  items: [
                                    const DropdownMenuItem(
                                      value: null,
                                      child: Text(
                                        'Semua Tahun',
                                        style: TextStyle(
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                    for (int i = DateTime.now().year - 5;
                                        i <= DateTime.now().year + 1;
                                        i++)
                                      DropdownMenuItem(
                                        value: i,
                                        child: Text(
                                          i.toString(),
                                          style: GoogleFonts.poppins(),
                                        ),
                                      ),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedYear = value;
                                    });
                                  },
                                ),
                              const SizedBox(height: 10),
                              if (_selectedBackupType !=
                                  'database_sql') // Only show user filter for CSV
                                DropdownButtonFormField<int>(
                                  decoration: InputDecoration(
                                    // **Potential fix: Shorten label or ensure wrapping**
                                    labelText:
                                        'Filter Pengguna (Magang Diterima)', // Shorter label
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[100],
                                  ),
                                  value: _selectedUserId,
                                  hint: Text(
                                    'Pilih Pengguna', // Shorter hint
                                    style: GoogleFonts.poppins(),
                                  ),
                                  items: [
                                    const DropdownMenuItem(
                                      value: null,
                                      child: Text(
                                        'Semua Pengguna',
                                        style: TextStyle(
                                            fontStyle: FontStyle.italic),
                                      ),
                                    ),
                                    ..._users.map((user) => DropdownMenuItem(
                                          value: user.id,
                                          child: Text(
                                            user.nama,
                                            // Optional: Add overflow handling if user names are very long
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        )),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedUserId = value;
                                    });
                                  },
                                ),
                              const SizedBox(height: 20),
                              Center(
                                child: ElevatedButton.icon(
                                  onPressed: _performBackup,
                                  icon: const Icon(
                                    Icons.cloud_download,
                                    color: Colors.white,
                                  ),
                                  label: Text(
                                    'Lakukan Backup Sekarang',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.purple.shade600,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ),
                              if (_lastBackupFilePath != null &&
                                  _lastBackupFilePath!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 10,
                                    left: 8,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Backup terakhir berhasil dibuat:',
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () => _downloadBackupFile(
                                          _lastBackupFilePath!,
                                          _lastBackupFilePath!.split('/').last,
                                        ),
                                        child: Text(
                                          _lastBackupFilePath!.split('/').last,
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: Colors.blue.shade700,
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const Divider(height: 30, thickness: 1),
                      _buildSectionTitle('Daftar File Backup Tersedia'),
                      _backupFiles.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Text(
                                  "Tidak ada file backup yang tersedia.",
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _backupFiles.length,
                              itemBuilder: (context, index) {
                                final backupFile = _backupFiles[index];
                                return Card(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 6.0),
                                  elevation: 1,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ListTile(
                                    leading: Icon(
                                      backupFile.fileName.endsWith('.csv')
                                          ? Icons.grid_on
                                          : Icons.storage,
                                      color:
                                          backupFile.fileName.endsWith('.csv')
                                              ? Colors.orange.shade700
                                              : Colors.blue.shade700,
                                    ),
                                    title: Text(
                                      backupFile.fileName,
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'Tanggal: ${DateFormat('dd MMMM HH:mm', 'id').format(backupFile.createdAt)}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(
                                        Icons.download,
                                        color: Colors.green,
                                      ),
                                      onPressed: () => _downloadBackupFile(
                                        backupFile.filePath,
                                        backupFile.fileName,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                      const Divider(height: 30, thickness: 1),
                      _buildSectionTitle('Log Aktivitas Pengguna'),
                      _activityLogs.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Text(
                                  "Tidak ada log aktivitas yang tersedia.",
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _activityLogs.length,
                              itemBuilder: (context, index) {
                                final log = _activityLogs[index];
                                return Card(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 8.0),
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          log.activityType,
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Colors.blue.shade700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          log.description,
                                          style:
                                              GoogleFonts.poppins(fontSize: 14),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Oleh: ${log.username ?? 'N/A'} (${log.userId != null ? log.userId.toString() : 'Sistem'}) dari IP: ${log.ipAddress ?? 'N/A'}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        Text(
                                          'Waktu: ${DateFormat('dd MMMM HH:mm:ss', 'id').format(log.timestamp.toLocal())}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                            fontStyle: FontStyle.italic,
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
        currentIndex: 4,
        onTap: (index) {
          if (index != 4) {
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 15.0, bottom: 10.0),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: Colors.blue.shade800,
        ),
      ),
    );
  }
}
