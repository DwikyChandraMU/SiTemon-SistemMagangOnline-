import 'dart:async';
import 'dart:io';
import 'package:sitemon/screens/users/home_screen_users.dart';
import 'package:sitemon/screens/users/penugasan.dart';
import 'package:sitemon/screens/users/profile.dart';
import 'package:sitemon/screens/users/sertifikat.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// Definisi LatLng dipindahkan ke luar kelas untuk reusable
class LatLng {
  final double latitude;
  final double longitude;
  const LatLng(this.latitude, this.longitude);
}

class AbsenPage extends StatefulWidget {
  @override
  _AbsenPageState createState() => _AbsenPageState();
}

class _AbsenPageState extends State<AbsenPage> {
  Position? _currentPosition;
  File? _image;
  List<Map<String, dynamic>> _absenHistory = [];
  final _apiUrl = "http://192.168.50.189/sitemon_api/users/absen/absen.php";
  final _officeLocation = const LatLng(-7.002832, 110.424714);
  final double _allowedRadius = 30.0; // in meters

  int? userId;
  bool _isLoading = false;
  final TextEditingController _noteController =
      TextEditingController(); // Controller for TextField

  @override
  void initState() {
    super.initState();
    getUserId();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getInt('user_id');
    });
    if (userId != null) {
      await getRiwayatAbsen();
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showError('Layanan lokasi tidak aktif. Mohon aktifkan GPS Anda.');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showError(
          'Izin lokasi ditolak. Aplikasi memerlukan izin lokasi untuk berfungsi.',
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showError(
        'Izin lokasi ditolak permanen. Harap aktifkan secara manual di pengaturan aplikasi.',
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
      _showSuccess('Lokasi berhasil didapatkan!');
      setState(() {
        _isLoading = false;
      });
    } on TimeoutException catch (_) {
      _showError(
          'Gagal mendapatkan lokasi: Waktu habis. Pastikan sinyal GPS Anda baik.');
      setState(() {
        _isLoading = false;
      });
    } on SocketException catch (_) {
      _showError('Anda sedang offline. Periksa koneksi internet Anda.');
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      _showError('Gagal mendapatkan lokasi: ${e.toString()}.');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 75,
      maxWidth: 1024,
      maxHeight: 768,
    );
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _absen(String type) async {
    if (userId == null) {
      _showError('Autentikasi gagal. Mohon login ulang.');
      return;
    }

    if (_currentPosition == null) {
      _showError('Mohon dapatkan lokasi Anda terlebih dahulu.');
      return;
    }

    if (_image == null) {
      _showError('Mohon ambil foto absensi Anda.');
      return;
    }

    final distance = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      _officeLocation.latitude,
      _officeLocation.longitude,
    );

    if (distance > _allowedRadius) {
      _showError(
        'Anda berada di luar area kantor. Jarak Anda: ${distance.toStringAsFixed(2)} meter. Harap absen di dalam radius ${_allowedRadius.toStringAsFixed(0)} meter dari kantor.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final request = http.MultipartRequest('POST', Uri.parse(_apiUrl))
        ..fields['user_id'] = userId.toString()
        ..fields['latitude'] = _currentPosition!.latitude.toString()
        ..fields['longitude'] = _currentPosition!.longitude.toString()
        ..fields['catatan'] = _noteController.text.trim()
        ..fields['type'] = type;

      request.files.add(
        await http.MultipartFile.fromPath(
          'foto',
          _image!.path,
          filename: 'absen_photo.jpg',
        ),
      );

      final response = await request.send();
      final respStr = await response.stream.bytesToString();
      final jsonResp = json.decode(respStr);

      if (response.statusCode == 200 && jsonResp['status'] == 'success') {
        _showSuccess(jsonResp['message']);
        setState(() {
          _image = null;
          _noteController.clear();
          _currentPosition = null;
          _isLoading = false;
        });
        getRiwayatAbsen();
      } else {
        String errorMessage =
            jsonResp['message'] ?? 'Gagal menyimpan absen. Silakan coba lagi.';
        if (response.statusCode >= 400 && response.statusCode < 500) {
          errorMessage =
              'Terjadi kesalahan pada permintaan Anda: $errorMessage';
        } else if (response.statusCode >= 500) {
          errorMessage =
              'Terjadi masalah pada server: $errorMessage. Mohon coba lagi nanti.';
        }
        _showError(errorMessage);
        setState(() {
          _isLoading = false;
        });
      }
    } on SocketException catch (_) {
      _showError(
          'Tidak dapat terhubung ke server. Pastikan Anda memiliki koneksi internet.');
      setState(() {
        _isLoading = false;
      });
    } on FormatException catch (_) {
      _showError(
          'Terjadi masalah dalam memproses data dari server. Silakan coba lagi.');
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      _showError(
        'Terjadi kesalahan tidak terduga: ${e.toString()}.',
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> getRiwayatAbsen() async {
    if (userId == null) return;

    try {
      final response = await http.get(Uri.parse("$_apiUrl?user_id=$userId"));
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        setState(() {
          _absenHistory = data.map((e) {
            String tanggalFormatted = DateFormat(
              'EEEE, dd MMMM yyyy',
            ).format(DateTime.parse(e['tanggal']));

            double? lat =
                e['latitude'] is num ? (e['latitude'] as num).toDouble() : null;
            double? lon = e['longitude'] is num
                ? (e['longitude'] as num).toDouble()
                : null;

            String lokasiText;
            if (lat != null && lon != null) {
              lokasiText =
                  '${lat.toStringAsFixed(5)}, ${lon.toStringAsFixed(5)}';
            } else {
              lokasiText = 'Lokasi tidak tersedia';
            }

            String jamMasuk =
                e['jam_masuk'] != null ? 'Masuk: ${e['jam_masuk']}' : '';
            String jamPulang =
                e['jam_pulang'] != null ? 'Pulang: ${e['jam_pulang']}' : '';
            String status =
                e['status'] == 'masuk' ? 'Absen Masuk' : 'Absen Pulang';

            return {
              'tanggal': tanggalFormatted,
              'jam_masuk': jamMasuk,
              'jam_pulang': jamPulang,
              'lokasi': lokasiText,
              'catatan': e['catatan'] ?? '-',
              'status': status,
            };
          }).toList();

          _absenHistory.sort((a, b) {
            DateTime dateA = DateFormat(
              'EEEE, dd MMMM yyyy',
            ).parse(a['tanggal']);
            DateTime dateB = DateFormat(
              'EEEE, dd MMMM yyyy',
            ).parse(b['tanggal']);
            int dateComparison = dateB.compareTo(dateA);

            if (dateComparison != 0) {
              return dateComparison;
            } else {
              if (a['status'] == 'Absen Masuk' &&
                  b['status'] == 'Absen Pulang') {
                return -1;
              } else if (a['status'] == 'Absen Pulang' &&
                  b['status'] == 'Absen Masuk') {
                return 1;
              }
              return 0;
            }
          });
        });
      } else if (response.statusCode == 404) {
        _showError("Riwayat absensi tidak ditemukan untuk pengguna ini.");
      } else {
        _showError(
            "Gagal memuat riwayat absensi. Kode status: ${response.statusCode}");
      }
    } on SocketException catch (_) {
      _showError(
          "Tidak dapat terhubung ke server untuk memuat riwayat. Periksa koneksi internet Anda.");
    } on FormatException catch (_) {
      _showError(
          "Terjadi masalah dalam memproses data riwayat dari server. Silakan coba lagi.");
    } catch (e) {
      _showError(
          "Terjadi kesalahan tidak terduga saat mengambil riwayat: ${e.toString()}");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          "ABSENSI SISWA",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 4,
        toolbarHeight: 40,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.blueAccent),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- Bagian Pengambilan Foto ---
                  Card(
                    child: InkWell(
                      onTap: _pickImage,
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        height: 220,
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.blueAccent,
                            width: 2,
                          ),
                        ),
                        child: _image != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: Image.file(
                                  _image!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.camera_alt,
                                    size: 60,
                                    color: Colors.blueAccent.shade400,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    "Ketuk untuk Ambil Foto Absen",
                                    style: GoogleFonts.poppins(
                                      color: Colors.blueAccent.shade700,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    "(Wajib)",
                                    style: GoogleFonts.poppins(
                                      color: Colors.redAccent,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- Bagian Lokasi ---
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Status Lokasi",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey.shade800,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(
                                Icons.my_location,
                                color: Colors.blueAccent,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _currentPosition != null
                                      ? 'Koordinat: ${_currentPosition!.latitude.toStringAsFixed(5)}, ${_currentPosition!.longitude.toStringAsFixed(5)}'
                                      : 'Lokasi belum didapatkan.',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          ElevatedButton.icon(
                            onPressed: _getCurrentLocation,
                            icon: const Icon(
                              Icons.location_on,
                              color: Colors.white,
                            ),
                            label: Text(
                              _currentPosition != null
                                  ? 'Perbarui Lokasi'
                                  : 'Dapatkan Lokasi',
                              style: GoogleFonts.poppins(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  // --- Input Catatan ---
                  TextField(
                    controller: _noteController,
                    maxLines: 2,
                    keyboardType: TextInputType.text,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: "Catatan (Opsional)",
                      hintText: "Contoh: Sedang rapat di luar...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.blueAccent,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.blueAccent,
                          width: 2,
                        ),
                      ),
                      prefixIcon: Icon(
                        Icons.edit_note,
                        color: Colors.blueAccent.shade400,
                      ),
                      labelStyle: GoogleFonts.poppins(
                        color: Colors.blueGrey.shade700,
                      ),
                      hintStyle: GoogleFonts.poppins(
                        color: Colors.blueGrey.shade400,
                        fontSize: 14,
                      ),
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                    ),
                  ),
                  const SizedBox(height: 25),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _absen('masuk'),
                          icon: const Icon(Icons.login, color: Colors.white),
                          label: Text(
                            "ABSEN MASUK",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo.shade700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _absen('pulang'),
                          icon: const Icon(Icons.logout, color: Colors.white),
                          label: Text(
                            "ABSEN PULANG",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrange.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(
                    height: 50,
                    thickness: 1.5,
                    color: Colors.blueGrey,
                  ),

                  // --- Riwayat Absensi ---
                  Text(
                    "Riwayat Absensi Anda",
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey.shade800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 15),
                  _absenHistory.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  "Belum ada riwayat absensi. Mulai dengan absen masuk!",
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    color: Colors.grey,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: _absenHistory.length,
                          itemBuilder: (context, index) {
                            final entry = _absenHistory[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 5,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          entry['tanggal'],
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                entry['status'] == 'Absen Masuk'
                                                    ? Colors.blue.shade100
                                                    : Colors.orange.shade100,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            entry['status'],
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: entry['status'] ==
                                                      'Absen Masuk'
                                                  ? Colors.blue.shade700
                                                  : Colors.orange.shade700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 10, thickness: 0.5),
                                    if (entry['jam_masuk'] != '')
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 4.0,
                                        ),
                                        child: Text(
                                          entry['jam_masuk'],
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: Colors.green.shade700,
                                          ),
                                        ),
                                      ),
                                    if (entry['jam_pulang'] != '')
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 4.0,
                                        ),
                                        child: Text(
                                          entry['jam_pulang'],
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: Colors.red.shade700,
                                          ),
                                        ),
                                      ),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          Icons.location_on,
                                          size: 16,
                                          color: Colors.grey.shade600,
                                        ),
                                        const SizedBox(width: 5),
                                        Expanded(
                                          child: Text(
                                            'Lokasi: ${entry['lokasi']}',
                                            style: GoogleFonts.poppins(
                                              fontSize: 13,
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (entry['catatan'] != '-' &&
                                        entry['catatan'] != '')
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 4.0,
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Icon(
                                              Icons.notes,
                                              size: 16,
                                              color: Colors.grey.shade600,
                                            ),
                                            const SizedBox(width: 5),
                                            Expanded(
                                              child: Text(
                                                'Catatan: ${entry['catatan']}',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 13,
                                                  fontStyle: FontStyle.italic,
                                                  color: Colors.grey.shade700,
                                                ),
                                              ),
                                            ),
                                          ],
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
        currentIndex: 1,
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
