import 'package:sitemon/screens/users/penugasan.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:sitemon/screens/users/absen_screen.dart';
import 'package:sitemon/screens/users/profile.dart';
import 'package:sitemon/screens/users/sertifikat.dart';
import 'dart:io'; // Import for SocketException

class HomeScreenUsers extends StatefulWidget {
  const HomeScreenUsers({super.key});

  @override
  State<HomeScreenUsers> createState() => _HomeScreenUsersState();
}

class _HomeScreenUsersState extends State<HomeScreenUsers> {
  int? userId;
  bool _isLoading = true;
  String _absenStatus = 'Memuat...';
  String _jamMasuk = '-';
  String _jamPulang = '-';
  int _unfinishedTasksCount = 0;
  List<dynamic> _urgentTasks = [];
  String _magangProgress = 'Memuat...';
  String _magangDetail = 'Memuat informasi progress magang Anda.';
  double _progressPercentage = 0.0;
  List<dynamic> _announcements = [];

  final _apiUrl =
      "http://192.168.50.189/sitemon_api/users/home_screen/home_screen_users.php";

  @override
  void initState() {
    super.initState();
    _loadUserDataAndFetchDashboard();
  }

  Future<void> _loadUserDataAndFetchDashboard() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getInt('user_id');
    });
    if (userId != null) {
      await _fetchDashboardData();
    } else {
      setState(() {
        _isLoading = false;
        _absenStatus = 'Error: User ID tidak ditemukan.';
        _magangDetail = 'Error: User ID tidak ditemukan.';
      });
      _showError('Autentikasi gagal. Mohon login ulang.');
    }
  }

  Future<void> _fetchDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse("$_apiUrl?user_id=$userId"));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['status'] == 'success') {
          final data = jsonResponse['data'];
          setState(() {
            _absenStatus = data['absen_status'];
            _jamMasuk = data['jam_masuk'] ?? '-';
            _jamPulang = data['jam_pulang'] ?? '-';
            _unfinishedTasksCount = data['unfinished_tasks_count'] ?? 0;
            _urgentTasks = data['urgent_tasks'] ?? [];
            _magangProgress = data['magang_progress'];
            _magangDetail = data['magang_detail'];
            _progressPercentage =
                (data['progress_percentage'] as num).toDouble();
            _announcements = data['announcements'] ?? [];
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
            _absenStatus = 'Gagal memuat status absen.';
            _magangDetail = 'Gagal memuat progress magang.';
          });
          _showError(jsonResponse['message'] ?? 'Gagal memuat data dashboard.');
          print("Error API response: ${jsonResponse['message']}");
        }
      } else {
        setState(() {
          _isLoading = false;
          _absenStatus = 'Error: ${response.statusCode}';
          _magangDetail = 'Error: ${response.statusCode}';
        });
        _showError(
            'Tidak dapat terhubung ke server (Kode: ${response.statusCode}). Silakan coba lagi.');
        print(
            "Error fetching dashboard data: HTTP Status ${response.statusCode}");
      }
    } on SocketException catch (_) {
      setState(() {
        _isLoading = false;
        _absenStatus = 'Anda sedang offline.';
        _magangDetail = 'Anda sedang offline.';
      });
      _showError('Anda sedang offline. Periksa koneksi internet Anda.');
      print("SocketException: No internet connection.");
    } on FormatException catch (_) {
      setState(() {
        _isLoading = false;
        _absenStatus = 'Error data server.';
        _magangDetail = 'Error data server.';
      });
      _showError(
          'Terjadi masalah dalam memproses data dari server. Format tidak valid.');
      print("FormatException: Invalid JSON response from server.");
    } catch (e) {
      setState(() {
        _isLoading = false;
        _absenStatus = 'Terjadi kesalahan.';
        _magangDetail = 'Terjadi kesalahan.';
      });
      _showError('Terjadi kesalahan tidak terduga: ${e.toString()}');
      print("General error fetching dashboard data: $e");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4), // Lebih lama untuk pesan error
      ),
    );
  }

  Widget _buildDashboardCard({
    required String title,
    required List<Widget> children,
    EdgeInsetsGeometry? margin,
  }) {
    return Card(
      margin: margin ?? const EdgeInsets.only(bottom: 20),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey.shade800,
              ),
            ),
            const Divider(height: 20, thickness: 1, color: Colors.grey),
            ...children,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
          "Beranda",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        toolbarHeight: 40,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.blueAccent),
            )
          : RefreshIndicator(
              onRefresh: _fetchDashboardData,
              color: Colors.blueAccent,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- Pengumuman Terbaru ---
                    if (_announcements.isNotEmpty)
                      _buildDashboardCard(
                        title: "Pengumuman Terbaru",
                        children: [
                          ..._announcements.map((announcement) {
                            String formattedDate = DateFormat(
                              'dd MMMM yyyy HH:mm',
                            ).format(
                              DateTime.parse(announcement['created_at']),
                            );
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    announcement['title'],
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    announcement['content'],
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Diumumkan pada: $formattedDate',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  if (announcement['expires_at'] != null)
                                    Text(
                                      'Berlaku hingga: ${DateFormat('dd MMMM yyyy').format(DateTime.parse(announcement['expires_at']))}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                        color: Colors.red.shade600,
                                      ),
                                    ),
                                  if (_announcements.last != announcement)
                                    const Divider(height: 10, thickness: 0.5),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ),

                    // --- Progress Magang ---
                    _buildDashboardCard(
                      title: "Progress Magang",
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.school,
                              color: Colors.blueAccent,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _magangProgress,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: _magangProgress == 'Selesai'
                                      ? Colors.green.shade700
                                      : (_magangProgress == 'Belum Dimulai'
                                          ? Colors.amber.shade700
                                          : Colors.blue.shade700),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _magangDetail,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 15),
                        LinearProgressIndicator(
                          value: _progressPercentage / 100,
                          backgroundColor: Colors.grey.shade300,
                          color: Colors.blue.shade700,
                          minHeight: 12,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '${_progressPercentage.toStringAsFixed(1)}%',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // --- Status Absensi Hari Ini ---
                    _buildDashboardCard(
                      title: "Status Absensi Hari Ini",
                      children: [
                        Row(
                          children: [
                            Icon(
                              _absenStatus == 'Belum Absen'
                                  ? Icons.event_note
                                  : Icons.check_circle_outline,
                              color: _absenStatus == 'Belum Absen'
                                  ? Colors.amber.shade700
                                  : Colors.green.shade700,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _absenStatus,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: _absenStatus == 'Belum Absen'
                                      ? Colors.amber.shade700
                                      : Colors.green.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_absenStatus != 'Belum Absen') ...[
                          const SizedBox(height: 10),
                          Text(
                            'Jam Masuk: $_jamMasuk',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          if (_jamPulang != '-')
                            Text(
                              'Jam Pulang: $_jamPulang',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                            ),
                        ],
                        const SizedBox(height: 15),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AbsenPage(),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                            ),
                            label: Text(
                              _absenStatus == 'Sudah Absen Pulang'
                                  ? "Lihat Riwayat Absen"
                                  : "Lakukan Absen",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo.shade700,
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // --- Notifikasi Penugasan Baru/Mendesak ---
                    _buildDashboardCard(
                      title: "Notifikasi Penugasan",
                      children: [
                        if (_unfinishedTasksCount > 0) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.notification_important,
                                color: Colors.orange.shade700,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Anda memiliki $_unfinishedTasksCount tugas yang Belum Dinilai atau Revisi!',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    color: Colors.orange.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                        ] else if (_urgentTasks.isEmpty &&
                            _unfinishedTasksCount == 0) ...[
                          Row(
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                color: Colors.green.shade700,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Tidak ada tugas baru atau mendesak saat ini.',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                        ],
                        if (_urgentTasks.isNotEmpty) ...[
                          Text(
                            "Tugas Mendesak/Lewat Batas Waktu:",
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ..._urgentTasks.map((task) {
                            String deadline = DateFormat(
                              'dd MMM yyyy',
                            ).format(DateTime.parse(task['deadline']));
                            Color textColor = task['is_overdue']
                                ? Colors.red.shade900
                                : Colors.orange.shade800;
                            String statusText = task['is_overdue']
                                ? '(Lewat Batas)'
                                : '(Deadline: $deadline)';
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4.0,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.assignment,
                                    size: 18,
                                    color: textColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${task['nama_tugas']} - ${task['status']} $statusText',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: textColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          const SizedBox(height: 15),
                        ],
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TugasPage(),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.assignment_turned_in,
                              color: Colors.white,
                            ),
                            label: Text(
                              "Lihat Semua Penugasan",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal.shade700,
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
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
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => TugasPage()),
              );
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
    );
  }
}
