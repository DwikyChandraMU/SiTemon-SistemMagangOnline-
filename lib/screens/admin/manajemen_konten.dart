// manajemen_konten.dart
import 'dart:convert';
import 'package:sitemon/screens/admin/backup_keamanan.dart';
import 'package:sitemon/screens/admin/atur_bimbingan.dart';
import 'package:sitemon/screens/admin/profile_admin.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart'; // Import ini
import 'package:sitemon/screens/admin/home_screen_admin.dart';
import 'package:sitemon/screens/admin/manajemen_sertifikat.dart';

// Model untuk AppContent
class AppContent {
  final String pageName;
  String content;

  AppContent({required this.pageName, required this.content});

  factory AppContent.fromJson(Map<String, dynamic> json) {
    return AppContent(pageName: json['page_name'], content: json['content']);
  }
}

// Model untuk Announcement
class Announcement {
  final int id;
  String title;
  String content;
  final DateTime createdAt;
  bool isActive;
  DateTime? expiresAt;

  Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.isActive,
    this.expiresAt,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: int.parse(json['id'].toString()),
      title: json['title'],
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
      isActive: json['is_active'] == 1, // Konversi int (0/1) ke bool
      expiresAt: json['expires_at'] != null && json['expires_at'].isNotEmpty
          ? DateTime.tryParse(
              json['expires_at']) // Gunakan tryParse untuk keamanan
          : null,
    );
  }
}

class ManajemenKontenPage extends StatefulWidget {
  const ManajemenKontenPage({Key? key}) : super(key: key);

  @override
  State<ManajemenKontenPage> createState() => _ManajemenKontenPageState();
}

class _ManajemenKontenPageState extends State<ManajemenKontenPage> {
  // Konten Statis
  final TextEditingController _homePageController = TextEditingController();
  final TextEditingController _panduanMagangController =
      TextEditingController();
  final TextEditingController _faqController = TextEditingController();

  // Pengumuman Global
  List<Announcement> _announcements = [];
  final TextEditingController _announcementTitleController =
      TextEditingController();
  final TextEditingController _announcementContentController =
      TextEditingController();
  bool _newAnnouncementIsActive = true;
  DateTime? _newAnnouncementExpiresAt;

  bool _isLoading = true;
  String? _errorMessage;

  final String _baseUrl =
      'http://192.168.50.189/sitemon_api/admin/manajemen_konten/';

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null).then((_) {
      // Inisialisasi format tanggal lokal
      _fetchData();
    });
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Fetch static page content
      await _fetchContent('home_page', _homePageController);
      await _fetchContent('panduan_magang', _panduanMagangController);
      await _fetchContent('faq', _faqController);

      // Ambil pengumuman
      final anncUri = Uri.parse('$_baseUrl/get_announcements.php');
      final anncResponse =
          await http.get(anncUri).timeout(const Duration(seconds: 10));

      debugPrint(
          'Announcements GET Response Status: ${anncResponse.statusCode}');
      debugPrint('Announcements GET Response Body: ${anncResponse.body}');

      if (anncResponse.statusCode == 200) {
        final Map<String, dynamic> responseBody =
            json.decode(anncResponse.body);
        if (responseBody['status'] == 'success') {
          final List<dynamic> data = responseBody['data'];
          setState(() {
            _announcements =
                data.map((json) => Announcement.fromJson(json)).toList();
          });
        } else {
          throw Exception(
              'API error fetching announcements: ${responseBody['message']}');
        }
      } else {
        throw Exception(
            'Gagal mengambil pengumuman: Server mengembalikan status ${anncResponse.statusCode}');
      }
    } on http.ClientException catch (e) {
      _errorMessage =
          'Koneksi gagal: ${e.message}. Pastikan IP dan koneksi Anda benar.';
    } on FormatException catch (e) {
      _errorMessage =
          'Gagal memproses data: Format JSON tidak valid. Error: ${e.message}';
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan tidak terduga saat mengambil data: $e';
    } finally {
      setState(() {
        _isLoading = false;
      });
      if (_errorMessage != null) {
        print('Error in _fetchData: $_errorMessage');
        _showSnackBar(_errorMessage!, isError: true);
      }
    }
  }

  Future<void> _fetchContent(
      String pageName, TextEditingController controller) async {
    try {
      final uri = Uri.parse('$_baseUrl/get_content.php?page_name=$pageName');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      debugPrint(
          'Content ($pageName) GET Response Status: ${response.statusCode}');
      debugPrint('Content ($pageName) GET Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = json.decode(response.body);
        if (responseBody['status'] == 'success' &&
            responseBody['data'] != null) {
          controller.text = responseBody['data']['content'] ?? '';
        } else if (responseBody['status'] == 'error') {
          print(
              'Warning: No content found for $pageName. Message: ${responseBody['message']}');
        }
      } else {
        throw Exception(
            'Server returned status ${response.statusCode} for $pageName.');
      }
    } catch (e) {
      print('Error fetching content for $pageName: $e');
      // Tidak menampilkan snackbar di sini agar tidak spam jika banyak konten kosong
    }
  }

  Future<void> _updateContent(String pageName, String content) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/update_content.php'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'page_name': pageName, 'content': content}),
          )
          .timeout(const Duration(seconds: 10));

      debugPrint('Update Content POST Response Status: ${response.statusCode}');
      debugPrint('Update Content POST Response Body: ${response.body}');

      final responseBody = json.decode(response.body);
      if (responseBody['status'] == 'success') {
        _showSnackBar(responseBody['message']);
      } else {
        _showSnackBar(responseBody['message'] ?? 'Gagal memperbarui konten.',
            isError: true);
      }
    } on http.ClientException catch (e) {
      _showSnackBar('Koneksi gagal saat update konten: ${e.message}.',
          isError: true);
    } on FormatException catch (e) {
      _showSnackBar(
          'Format respons tidak valid saat update konten: ${e.message}.',
          isError: true);
    } catch (e) {
      _showSnackBar('Error updating content: $e', isError: true);
      print('Error updating content for $pageName: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addAnnouncement() async {
    if (_announcementTitleController.text.trim().isEmpty ||
        _announcementContentController.text.trim().isEmpty) {
      _showSnackBar('Judul dan Konten pengumuman tidak boleh kosong.',
          isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/add_announcement.php'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'title': _announcementTitleController.text,
              'content': _announcementContentController.text,
              'is_active': _newAnnouncementIsActive ? 1 : 0,
              'expires_at':
                  _newAnnouncementExpiresAt?.toIso8601String().substring(0, 10),
            }),
          )
          .timeout(const Duration(seconds: 10));

      debugPrint(
          'Add Announcement POST Response Status: ${response.statusCode}');
      debugPrint('Add Announcement POST Response Body: ${response.body}');

      final responseBody = json.decode(response.body);
      if (responseBody['status'] == 'success') {
        _showSnackBar(responseBody['message']);
        _announcementTitleController.clear();
        _announcementContentController.clear();
        setState(() {
          _newAnnouncementIsActive = true;
          _newAnnouncementExpiresAt = null;
        });
        _fetchData(); // Refresh list pengumuman
      } else {
        _showSnackBar(
            responseBody['message'] ?? 'Gagal menambahkan pengumuman.',
            isError: true);
      }
    } on http.ClientException catch (e) {
      _showSnackBar('Koneksi gagal saat menambah pengumuman: ${e.message}.',
          isError: true);
    } on FormatException catch (e) {
      _showSnackBar(
          'Format respons tidak valid saat menambah pengumuman: ${e.message}.',
          isError: true);
    } catch (e) {
      _showSnackBar('Error adding announcement: $e', isError: true);
      print('Error adding announcement: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateAnnouncement(Announcement announcement) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/update_announcement.php'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'id': announcement.id,
              'title': announcement.title,
              'content': announcement.content,
              'is_active': announcement.isActive ? 1 : 0,
              'expires_at':
                  announcement.expiresAt?.toIso8601String().substring(0, 10),
            }),
          )
          .timeout(const Duration(seconds: 10)); // Tambahkan timeout

      debugPrint(
          'Update Announcement POST Response Status: ${response.statusCode}');
      debugPrint('Update Announcement POST Response Body: ${response.body}');

      final responseBody = json.decode(response.body);
      if (responseBody['status'] == 'success') {
        _showSnackBar(responseBody['message']);
        _fetchData(); // Refresh list pengumuman
      } else if (responseBody['status'] == 'info') {
        _showSnackBar(responseBody['message']); // Pesan "tidak ada perubahan"
      } else {
        _showSnackBar(
            responseBody['message'] ?? 'Gagal memperbarui pengumuman.',
            isError: true);
      }
    } on http.ClientException catch (e) {
      _showSnackBar('Koneksi gagal saat update pengumuman: ${e.message}.',
          isError: true);
    } on FormatException catch (e) {
      // Ini adalah bagian yang menangani error dari gambar yang Anda berikan.
      // Pastikan file PHP Anda tidak memiliki karakter di luar JSON.
      _showSnackBar(
          'Format respons tidak valid saat update pengumuman: ${e.message}.',
          isError: true);
    } catch (e) {
      _showSnackBar('Error updating announcement: $e', isError: true);
      print('Error updating announcement: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteAnnouncement(int id) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/delete_announcement.php'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'id': id}),
          )
          .timeout(const Duration(seconds: 10)); // Tambahkan timeout

      debugPrint(
          'Delete Announcement POST Response Status: ${response.statusCode}');
      debugPrint('Delete Announcement POST Response Body: ${response.body}');

      final responseBody = json.decode(response.body);
      if (responseBody['status'] == 'success') {
        _showSnackBar(responseBody['message']);
        _fetchData(); // Refresh list pengumuman
      } else {
        _showSnackBar(responseBody['message'] ?? 'Gagal menghapus pengumuman.',
            isError: true);
      }
    } on http.ClientException catch (e) {
      _showSnackBar('Koneksi gagal saat menghapus pengumuman: ${e.message}.',
          isError: true);
    } on FormatException catch (e) {
      _showSnackBar(
          'Format respons tidak valid saat menghapus pengumuman: ${e.message}.',
          isError: true);
    } catch (e) {
      _showSnackBar('Error deleting announcement: $e', isError: true);
      print('Error deleting announcement: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins(color: Colors.white)),
        duration: const Duration(seconds: 3), // Durasi sedikit lebih lama
        backgroundColor: isError ? Colors.red.shade700 : Colors.blue.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  Future<void> _selectDate(
    BuildContext context,
    DateTime? initialDate,
    Function(DateTime?) onSelected,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime.now()
          .subtract(const Duration(days: 365 * 5)), // 5 tahun ke belakang
      lastDate: DateTime.now()
          .add(const Duration(days: 365 * 10)), // 10 tahun ke depan
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue.shade700,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue.shade700,
                textStyle: GoogleFonts.poppins(),
              ),
            ),
            textTheme: TextTheme(
              titleMedium: GoogleFonts.poppins(fontSize: 18),
              bodyLarge: GoogleFonts.poppins(fontSize: 16),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != initialDate) {
      onSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        title: Text(
          'MANAJEMEN KONTEN',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
        toolbarHeight: 40,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blue.shade800,
                Colors.blue.shade500,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red.shade400,
                          size: 50,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _errorMessage!,
                          style: GoogleFonts.poppins(
                            color: Colors.red.shade700,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        _buildPrimaryButton(
                          onPressed: _fetchData,
                          label: 'Coba Lagi',
                          icon: Icons.refresh,
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 25),

                      // Bagian untuk Menambahkan Pengumuman Baru
                      _buildSectionTitle(
                          'Buat Pengumuman Baru', Icons.campaign_outlined),
                      Card(
                        margin: const EdgeInsets.only(bottom: 16.0),
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        shadowColor: Colors.blue.shade100.withOpacity(0.6),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTextField(
                                controller: _announcementTitleController,
                                label: 'Judul Pengumuman',
                                hintText: 'Misal: Libur Idul Fitri',
                              ),
                              const SizedBox(height: 15),
                              _buildTextField(
                                controller: _announcementContentController,
                                label: 'Isi Pengumuman',
                                hintText: 'Informasi detail pengumuman...',
                                maxLines: 5,
                              ),
                              const SizedBox(height: 15),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  'Aktifkan Pengumuman',
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                value: _newAnnouncementIsActive,
                                onChanged: (bool value) {
                                  setState(() {
                                    _newAnnouncementIsActive = value;
                                  });
                                },
                                activeColor: Colors.green.shade600,
                                inactiveThumbColor: Colors.grey,
                                secondary: Icon(
                                  _newAnnouncementIsActive
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: _newAnnouncementIsActive
                                      ? Colors.green.shade600
                                      : Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 10),
                              GestureDetector(
                                onTap: () => _selectDate(
                                  context,
                                  _newAnnouncementExpiresAt,
                                  (pickedDate) {
                                    setState(() {
                                      _newAnnouncementExpiresAt = pickedDate;
                                    });
                                  },
                                ),
                                child: InputDecorator(
                                  decoration: _buildInputDecoration(
                                    'Tanggal Kadaluarsa (Opsional)',
                                  ).copyWith(
                                    hintText:
                                        'Pilih tanggal pengumuman berakhir',
                                    suffixIcon:
                                        _newAnnouncementExpiresAt != null
                                            ? IconButton(
                                                icon: const Icon(
                                                  Icons.clear_rounded,
                                                  color: Colors.red,
                                                ),
                                                onPressed: () {
                                                  setState(() {
                                                    _newAnnouncementExpiresAt =
                                                        null;
                                                  });
                                                },
                                              )
                                            : const Icon(
                                                Icons.calendar_month_outlined,
                                                color: Colors.grey,
                                              ),
                                  ),
                                  child: Text(
                                    _newAnnouncementExpiresAt == null
                                        ? 'Pilih tanggal'
                                        : DateFormat('dd MMMM yyyy', 'id_ID')
                                            .format(_newAnnouncementExpiresAt!),
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 25),
                              Center(
                                child: _buildPrimaryButton(
                                  onPressed: _addAnnouncement,
                                  label: 'Kirim Pengumuman',
                                  icon: Icons.send_rounded,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),
                      Center(
                        child: Divider(
                          height: 1,
                          thickness: 1,
                          color: Colors.blue.shade200,
                        ),
                      ),
                      const SizedBox(height: 25),

                      // Bagian Daftar Pengumuman
                      _buildSectionTitle(
                          'Daftar Pengumuman', Icons.announcement_outlined),
                      _announcements.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Text(
                                  "Belum ada pengumuman yang tersedia.",
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    color: Colors.grey.shade600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _announcements.length,
                              itemBuilder: (context, index) {
                                final announcement = _announcements[index];
                                return _buildAnnouncementCard(announcement);
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
        currentIndex: 3,
        onTap: (index) {
          if (index != 3) {
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

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0, bottom: 15.0),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.blue.shade700,
            size: 28,
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 22,
              color: Colors.blue.shade800,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration(String labelText, {String? hintText}) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: GoogleFonts.poppins(
        color: Colors.grey.shade600,
        fontSize: 14,
      ),
      hintText: hintText,
      hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Colors.blue.shade200,
          width: 1.5,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.blue.shade200, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Colors.blue.shade600,
          width: 2.5,
        ),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        vertical: 16,
        horizontal: 16,
      ),
      isDense: false,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hintText,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      decoration: _buildInputDecoration(label, hintText: hintText),
      maxLines: maxLines,
      style: GoogleFonts.poppins(fontSize: 15, color: Colors.black87),
      cursorColor: Colors.blue.shade700,
    );
  }

  Widget _buildPrimaryButton({
    required VoidCallback onPressed,
    required String label,
    required IconData icon,
    Color? backgroundColor,
    Color? foregroundColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (backgroundColor ?? Colors.blue.shade700).withOpacity(0.4),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
        gradient: LinearGradient(
          colors: [
            backgroundColor ?? Colors.blue.shade700,
            (backgroundColor ?? Colors.blue.shade700).withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: foregroundColor ?? Colors.white, size: 22),
        label: Text(
          label,
          style: GoogleFonts.poppins(
            color: foregroundColor ?? Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 14),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildContentCard({
    required String title,
    required TextEditingController controller,
    required VoidCallback onSave,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20.0),
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      shadowColor: Colors.blue.shade100.withOpacity(0.6),
      child: Padding(
        padding: const EdgeInsets.all(22.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: Colors.blue.shade800,
              ),
            ),
            const SizedBox(height: 18),
            _buildTextField(
              controller: controller,
              label: 'Konten Halaman',
              hintText: 'Isi konten halaman ini...',
              maxLines: 7,
            ),
            const SizedBox(height: 25),
            Center(
              child: _buildPrimaryButton(
                onPressed: onSave,
                label: 'Simpan Perubahan',
                icon: Icons.save_rounded,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnouncementCard(Announcement announcement) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15.0),
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: announcement.isActive
            ? BorderSide(
                color: Colors.green.shade400,
                width: 2,
              )
            : BorderSide(color: Colors.orange.shade400, width: 1.5),
      ),
      shadowColor: Colors.grey.shade200.withOpacity(0.7),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              announcement.title,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: Colors.blue.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              announcement.content,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.black87,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dibuat: ${DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(announcement.createdAt.toLocal())}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    if (announcement.expiresAt != null)
                      Text(
                        'Kadaluarsa: ${DateFormat('dd MMM yyyy', 'id_ID').format(announcement.expiresAt!)}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
                Transform.scale(
                  scale: 0.9,
                  child: Switch(
                    value: announcement.isActive,
                    onChanged: (bool value) {
                      setState(() {
                        announcement.isActive = value;
                      });
                      _updateAnnouncement(announcement);
                    },
                    activeColor: Colors.green.shade600,
                    inactiveThumbColor: Colors.grey,
                    inactiveTrackColor: Colors.grey.shade300,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.bottomRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.edit_rounded,
                      color: Colors.amber.shade700,
                      size: 22,
                    ),
                    tooltip: 'Edit Pengumuman',
                    onPressed: () => _showEditAnnouncementDialog(announcement),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_rounded,
                      color: Colors.red.shade700,
                      size: 22,
                    ),
                    tooltip: 'Hapus Pengumuman',
                    onPressed: () =>
                        _confirmDeleteAnnouncement(announcement.id),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditAnnouncementDialog(Announcement announcement) {
    final TextEditingController editTitleController = TextEditingController(
      text: announcement.title,
    );
    final TextEditingController editContentController = TextEditingController(
      text: announcement.content,
    );
    bool editIsActive = announcement.isActive;
    DateTime? editExpiresAt = announcement.expiresAt;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateDialog) {
            return AlertDialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 25,
                vertical: 24,
              ),
              contentPadding: const EdgeInsets.fromLTRB(
                20,
                20,
                20,
                15,
              ),
              actionsPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 10,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: Text(
                'Edit Pengumuman',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 19,
                  color: Colors.blue.shade800,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTextField(
                      controller: editTitleController,
                      label: 'Judul',
                      hintText: 'Misal: Perubahan Jadwal',
                    ),
                    const SizedBox(height: 15),
                    _buildTextField(
                      controller: editContentController,
                      label: 'Konten',
                      hintText: 'Detail pengumuman...',
                      maxLines: 5,
                    ),
                    const SizedBox(height: 15),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Aktifkan',
                        style: GoogleFonts.poppins(fontSize: 15),
                      ),
                      value: editIsActive,
                      onChanged: (bool value) {
                        setStateDialog(() {
                          editIsActive = value;
                        });
                      },
                      activeColor: Colors.green.shade600,
                      inactiveThumbColor: Colors.grey,
                      secondary: Icon(
                        editIsActive
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color:
                            editIsActive ? Colors.green.shade600 : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () =>
                          _selectDate(context, editExpiresAt, (pickedDate) {
                        setStateDialog(() {
                          editExpiresAt = pickedDate;
                        });
                      }),
                      child: InputDecorator(
                        decoration: _buildInputDecoration(
                          'Tanggal Kadaluarsa (Opsional)',
                        ).copyWith(
                          hintText: 'Pilih tanggal berakhir',
                          suffixIcon: editExpiresAt != null
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.clear_rounded,
                                    color: Colors.red,
                                  ),
                                  onPressed: () {
                                    setStateDialog(() {
                                      editExpiresAt = null;
                                    });
                                  },
                                )
                              : const Icon(
                                  Icons.calendar_month_outlined,
                                  color: Colors.grey,
                                ),
                        ),
                        child: Text(
                          editExpiresAt == null
                              ? 'Pilih tanggal'
                              : DateFormat('dd MMMM yyyy', 'id_ID')
                                  .format(editExpiresAt!),
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 10,
                    ),
                  ),
                  child: Text(
                    'Batal',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
                _buildPrimaryButton(
                  onPressed: () {
                    if (editTitleController.text.isNotEmpty &&
                        editContentController.text.isNotEmpty) {
                      Announcement updatedAnnouncement = Announcement(
                        id: announcement.id,
                        title: editTitleController.text,
                        content: editContentController.text,
                        createdAt: announcement.createdAt,
                        isActive: editIsActive,
                        expiresAt: editExpiresAt,
                      );
                      _updateAnnouncement(updatedAnnouncement);
                      Navigator.of(context).pop();
                    } else {
                      _showSnackBar('Judul dan konten tidak boleh kosong.',
                          isError: true);
                    }
                  },
                  label: 'Simpan',
                  icon: Icons.save_alt_rounded,
                  backgroundColor: Colors.blue.shade700,
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteAnnouncement(int id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 30,
            vertical: 24,
          ),
          contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 15),
          actionsPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 10,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            'Hapus Pengumuman?',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: Colors.red.shade700,
              fontSize: 19,
            ),
          ),
          content: Text(
            'Apakah Anda yakin ingin menghapus pengumuman ini? Tindakan ini tidak bisa dibatalkan.',
            style: GoogleFonts.poppins(fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade700,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 10,
                ),
              ),
              child: Text(
                'Batal',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            _buildPrimaryButton(
              onPressed: () {
                _deleteAnnouncement(id);
                Navigator.of(context).pop();
              },
              label: 'Hapus',
              icon: Icons.delete_forever_rounded,
              backgroundColor: Colors.red.shade700,
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _homePageController.dispose();
    _panduanMagangController.dispose();
    _faqController.dispose();
    _announcementTitleController.dispose();
    _announcementContentController.dispose();
    super.dispose();
  }
}
