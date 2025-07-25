import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:sitemon/models/auth_services.dart';

// Import halaman-halaman navigasi lainnya
import 'package:sitemon/screens/pembimbing/home_screen_pembimbing.dart';
import 'package:sitemon/screens/pembimbing/penilaian_feedback.dart';
import 'package:sitemon/screens/pembimbing/profile_pembimbing.dart';
import 'package:sitemon/screens/pembimbing/riwayat_absensi.dart';
import 'package:sitemon/screens/pembimbing/penilaian_akhir_siswa.dart'; // Ini akan menjadi ManajemenTugasHarianAkhirPage

// --- Model untuk merepresentasikan data Tugas Harian ---
class TugasHarian {
  final int id;
  final String namaTugas;
  final String deadline;

  TugasHarian({
    required this.id,
    required this.namaTugas,
    required this.deadline,
  });

  factory TugasHarian.fromJson(Map<String, dynamic> json) {
    return TugasHarian(
      id: int.parse(json['id'].toString()),
      namaTugas: json['nama_tugas'],
      deadline: json['deadline'],
    );
  }
}

// --- Model untuk merepresentasikan data Tugas Akhir ---
class TugasAkhir {
  final int id;
  final String namaTugas;
  final String deadline;

  TugasAkhir({
    required this.id,
    required this.namaTugas,
    required this.deadline,
  });

  factory TugasAkhir.fromJson(Map<String, dynamic> json) {
    return TugasAkhir(
      id: int.parse(json['id'].toString()),
      namaTugas: json['nama_tugas'],
      deadline: json['deadline'],
    );
  }
}

// --- Halaman Manajemen Tugas Terintegrasi ---
class ManajemenTugasPage extends StatefulWidget {
  const ManajemenTugasPage({super.key});

  @override
  _ManajemenTugasPageState createState() => _ManajemenTugasPageState();
}

class _ManajemenTugasPageState extends State<ManajemenTugasPage> {
  // Daftar untuk kedua jenis tugas
  List<TugasHarian> daftarTugasHarian = [];
  List<TugasAkhir> daftarTugasAkhir = [];
  List<Map<String, dynamic>> daftarSiswa = [];
  List<int> selectedUserIds = [];

  final TextEditingController namaTugasController = TextEditingController();
  final TextEditingController deadlineController = TextEditingController();

  bool isLoading = true;
  String? errorMessage;
  int? _currentPembimbingId;

  // Index untuk Tab Bar
  int _selectedIndex = 0; // 0 untuk Tugas Harian, 1 untuk Tugas Akhir

  @override
  void initState() {
    super.initState();
    _loadPembimbingIdAndFetchData();
  }

  @override
  void dispose() {
    namaTugasController.dispose();
    deadlineController.dispose();
    super.dispose();
  }

  Future<void> _loadPembimbingIdAndFetchData() async {
    int? id = await AuthService.getUserId();
    if (!mounted) return;

    setState(() {
      _currentPembimbingId = id;
    });

    if (_currentPembimbingId != null) {
      await fetchTugasHarian();
      await fetchTugasAkhir();
      await fetchSiswa();
    } else {
      setState(() {
        isLoading = false;
        errorMessage = "ID Pembimbing tidak ditemukan. Harap login ulang.";
      });
    }
  }

  // --- Fetch Data Tugas Harian ---
  Future<void> fetchTugasHarian() async {
    if (!mounted)
      return; // Tambahkan ini untuk mencegah setState setelah dispose
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    if (_currentPembimbingId == null) {
      setState(() {
        isLoading = false;
        errorMessage =
            "Pembimbing ID tidak tersedia untuk memuat tugas harian.";
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(
          'http://192.168.50.189/sitemon_api/pembimbing/tugas_harian/get_tugas_harian.php?pembimbing_id=$_currentPembimbingId',
        ),
      );
      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null && data['status'] == 'success') {
          setState(() {
            daftarTugasHarian = List<TugasHarian>.from(
              data['data'].map((json) => TugasHarian.fromJson(json)),
            );
          });
        } else {
          setState(() {
            daftarTugasHarian = [];
            errorMessage = data['message'] ??
                "Tidak ada tugas harian ditemukan untuk pembimbing ini.";
          });
        }
      } else {
        _showSnackBar(
          "Gagal mengambil data tugas harian: ${response.statusCode}",
        );
        print("Gagal mengambil data tugas harian: ${response.body}");
        setState(() {
          errorMessage =
              "Server error saat mengambil tugas harian: ${response.statusCode}";
        });
      }
    } catch (e) {
      _showSnackBar("Terjadi kesalahan jaringan saat memuat tugas harian: $e");
      print("Error fetching daily tasks: $e");
      setState(() {
        errorMessage = "Koneksi gagal saat memuat tugas harian: $e";
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // --- Fetch Data Tugas Akhir ---
  Future<void> fetchTugasAkhir() async {
    if (!mounted)
      return; // Tambahkan ini untuk mencegah setState setelah dispose
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    if (_currentPembimbingId == null) {
      setState(() {
        isLoading = false;
        errorMessage = "Pembimbing ID tidak tersedia untuk memuat tugas akhir.";
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(
          'http://192.168.50.189/sitemon_api/pembimbing/tugas_akhir/get_tugas_akhir.php?pembimbing_id=$_currentPembimbingId',
        ),
      );
      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null && data['status'] == 'success') {
          setState(() {
            daftarTugasAkhir = List<TugasAkhir>.from(
              data['data'].map((json) => TugasAkhir.fromJson(json)),
            );
          });
        } else {
          setState(() {
            daftarTugasAkhir = [];
            errorMessage = data['message'] ??
                "Tidak ada tugas akhir ditemukan untuk pembimbing ini.";
          });
        }
      } else {
        _showSnackBar(
          "Gagal mengambil data tugas akhir: ${response.statusCode}",
        );
        print("Gagal mengambil data tugas akhir: ${response.body}");
        setState(() {
          errorMessage =
              "Server error saat mengambil tugas akhir: ${response.statusCode}";
        });
      }
    } catch (e) {
      _showSnackBar("Terjadi kesalahan jaringan saat memuat tugas akhir: $e");
      print("Error fetching final tasks: $e");
      setState(() {
        errorMessage = "Koneksi gagal saat memuat tugas akhir: $e";
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // --- Fetch Data Siswa ---
  Future<void> fetchSiswa() async {
    if (_currentPembimbingId == null) {
      return;
    }
    try {
      final response = await http.get(
        Uri.parse(
          'http://192.168.50.189/sitemon_api/pembimbing/tugas_harian/get_siswa.php?pembimbing_id=$_currentPembimbingId', // Asumsi endpoint ini mengembalikan semua siswa bimbingan
        ),
      );
      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null && data['status'] == 'success') {
          setState(() {
            daftarSiswa = List<Map<String, dynamic>>.from(data['data']);
          });
        } else {
          setState(() {
            daftarSiswa = [];
            _showSnackBar(
              data['message'] ?? "Tidak ada siswa bimbingan ditemukan.",
            );
          });
        }
      } else {
        _showSnackBar("Gagal mengambil data siswa: ${response.statusCode}");
        print("Gagal mengambil data siswa: ${response.body}");
      }
    } catch (e) {
      _showSnackBar("Terjadi kesalahan jaringan saat mengambil data siswa: $e");
      print("Error fetching students: $e");
    }
  }

  // --- Fetch Assigned Users untuk Tugas Harian ---
  Future<void> _fetchAssignedUsersHarian(int taskId) async {
    try {
      final response = await http.get(
        Uri.parse(
          'http://192.168.50.189/sitemon_api/pembimbing/tugas_harian/get_assigned_users_harian.php?task_id=$taskId',
        ),
      );
      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            selectedUserIds = List<int>.from(
              data['data'].map((user) => int.parse(user['user_id'].toString())),
            );
          });
        } else {
          _showSnackBar("Gagal mengambil siswa yang ditugaskan (Harian).");
          print(
            "Gagal mengambil siswa yang ditugaskan (Harian): ${data['message']}",
          );
        }
      } else {
        _showSnackBar(
          "Gagal koneksi ke API siswa yang ditugaskan (Harian): ${response.statusCode}",
        );
      }
    } catch (e) {
      _showSnackBar(
        "Terjadi kesalahan jaringan saat mengambil siswa yang ditugaskan (Harian): $e",
      );
      print("Error fetching assigned users Harian: $e");
    }
  }

  // --- Fetch Assigned Users untuk Tugas Akhir ---
  Future<void> _fetchAssignedUsersAkhir(int taskId) async {
    try {
      final response = await http.get(
        Uri.parse(
          'http://192.168.50.189/sitemon_api/pembimbing/tugas_akhir/get_assigned_users_tugas_akhir.php?task_id=$taskId',
        ),
      );
      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            selectedUserIds = List<int>.from(
              data['data'].map((user) => int.parse(user['user_id'].toString())),
            );
          });
        } else {
          _showSnackBar("Gagal mengambil siswa yang ditugaskan (Akhir).");
          print(
            "Gagal mengambil siswa yang ditugaskan (Akhir): ${data['message']}",
          );
        }
      } else {
        _showSnackBar(
          "Gagal koneksi ke API siswa yang ditugaskan (Akhir): ${response.statusCode}",
        );
      }
    } catch (e) {
      _showSnackBar(
        "Terjadi kesalahan jaringan saat mengambil siswa yang ditugaskan (Akhir): $e",
      );
      print("Error fetching assigned users Akhir: $e");
    }
  }

  // --- Fungsi untuk Menampilkan Dialog Tambah/Edit Tugas (Fleksibel) ---
  void _showTugasDialog({
    required String title,
    required VoidCallback onSave,
    bool isEdit = false,
    required String taskType, // 'harian' or 'akhir'
  }) {
    final ScrollController _localScrollController = ScrollController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            title,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: Colors.blue.shade800,
            ),
          ),
          content: SingleChildScrollView(
            controller: _localScrollController,
            child: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: namaTugasController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText:
                          "Nama Tugas ${taskType == 'harian' ? 'Harian' : 'Akhir'} / Deskripsi",
                      labelStyle: TextStyle(color: Colors.blueGrey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 18),
                  TextField(
                    controller: deadlineController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: "Deadline (YYYY-MM-DD)",
                      labelStyle: TextStyle(color: Colors.blueGrey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.blue.shade700,
                        ),
                      ),
                      suffixIcon: Icon(
                        Icons.calendar_today,
                        color: Colors.blue,
                      ),
                    ),
                    onTap: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        builder: (context, child) {
                          return Theme(
                            data: ThemeData.light().copyWith(
                              colorScheme: ColorScheme.light(
                                primary: Colors.blue.shade700,
                                onPrimary: Colors.white,
                                onSurface: Colors.black,
                              ),
                              textButtonTheme: TextButtonThemeData(
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.blue.shade700,
                                ),
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (pickedDate != null) {
                        String formattedDate =
                            pickedDate.toIso8601String().split('T')[0];
                        setStateDialog(() {
                          deadlineController.text = formattedDate;
                        });
                      }
                    },
                  ),
                  SizedBox(height: 20),
                  Text(
                    "Pilih siswa yang dibimbing:",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.blueGrey.shade700,
                    ),
                  ),
                  SizedBox(height: 10),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue.shade100),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Scrollbar(
                      thumbVisibility: true,
                      child: daftarSiswa.isEmpty
                          ? Center(
                              child: Text(
                                "Tidak ada siswa bimbingan tersedia.",
                                style: GoogleFonts.poppins(
                                  color: Colors.blueGrey,
                                ),
                              ),
                            )
                          : ListView(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              children: daftarSiswa.map((siswa) {
                                final id = (siswa['id'] is int)
                                    ? siswa['id']
                                    : int.parse(
                                        siswa['id'].toString(),
                                      );
                                final nama = siswa['nama'];
                                return CheckboxListTile(
                                  activeColor: Colors.blue.shade700,
                                  title: Text(
                                    nama,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.blueGrey.shade800,
                                    ),
                                  ),
                                  value: selectedUserIds.contains(
                                    id,
                                  ),
                                  onChanged: (bool? selected) {
                                    setStateDialog(() {
                                      if (selected == true) {
                                        if (!selectedUserIds.contains(id)) {
                                          selectedUserIds.add(id);
                                        }
                                      } else {
                                        selectedUserIds.remove(
                                          id,
                                        );
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actionsPadding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          actions: [
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(color: Colors.blue.shade700),
                padding: EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                "Batal",
                style: GoogleFonts.poppins(
                  color: Colors.blue.shade700,
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              onPressed: () {
                onSave();
                Navigator.pop(context);
              },
              child: Text(
                isEdit ? "Update" : "Simpan",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    ).whenComplete(() {
      _localScrollController.dispose();
    });
  }

  // --- Tambah Tugas Harian ---
  Future<void> tambahTugasHarian() async {
    if (namaTugasController.text.isEmpty || deadlineController.text.isEmpty) {
      _showSnackBar("Nama tugas dan deadline wajib diisi!");
      return;
    }
    if (selectedUserIds.isEmpty) {
      _showSnackBar("Pilih minimal satu siswa!");
      return;
    }
    if (_currentPembimbingId == null) {
      _showSnackBar("ID Pembimbing tidak tersedia. Tidak bisa menambah tugas.");
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(
          'http://192.168.50.189/sitemon_api/pembimbing/tugas_harian/add_tugas_harian.php',
        ),
        body: {
          'nama_tugas': namaTugasController.text,
          'deadline': deadlineController.text,
          'user_ids': json.encode(selectedUserIds),
          'pembimbing_id': _currentPembimbingId
              .toString(), // Pastikan pembimbing_id juga dikirim
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          _showSnackBar("Tugas harian berhasil ditambahkan!");
          fetchTugasHarian(); // Refresh daftar tugas harian
        } else {
          _showSnackBar("Gagal menambahkan tugas harian: ${data['message']}");
        }
      } else {
        _showSnackBar("Terjadi kesalahan server: ${response.statusCode}");
      }
    } catch (e) {
      _showSnackBar("Terjadi kesalahan jaringan: $e");
      print("Error adding daily task: $e");
    }
  }

  // --- Edit Tugas Harian ---
  void showEditTugasHarianDialog(TugasHarian tugas) async {
    namaTugasController.text = tugas.namaTugas;
    deadlineController.text = tugas.deadline;
    selectedUserIds.clear();

    await _fetchAssignedUsersHarian(tugas.id);

    _showTugasDialog(
      title: "Edit Tugas Harian",
      onSave: () => editTugasHarian(tugas.id),
      isEdit: true,
      taskType: 'harian',
    );
  }

  Future<void> editTugasHarian(int taskId) async {
    if (namaTugasController.text.isEmpty || deadlineController.text.isEmpty) {
      _showSnackBar("Nama tugas dan deadline wajib diisi!");
      return;
    }
    if (selectedUserIds.isEmpty) {
      _showSnackBar("Pilih minimal satu siswa!");
      return;
    }
    if (_currentPembimbingId == null) {
      _showSnackBar(
        "ID Pembimbing tidak tersedia. Tidak bisa memperbarui tugas.",
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(
          'http://192.168.50.189/sitemon_api/pembimbing/tugas_harian/update_tugas_harian.php',
        ),
        body: {
          'id': taskId.toString(),
          'nama_tugas': namaTugasController.text,
          'deadline': deadlineController.text,
          'user_ids': json.encode(selectedUserIds),
          'pembimbing_id': _currentPembimbingId
              .toString(), // Pastikan pembimbing_id juga dikirim
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          _showSnackBar("Tugas harian berhasil diperbarui!");
          fetchTugasHarian(); // Refresh daftar tugas harian
        } else {
          _showSnackBar("Gagal memperbarui tugas harian: ${data['message']}");
        }
      } else {
        _showSnackBar("Terjadi kesalahan server: ${response.statusCode}");
      }
    } catch (e) {
      _showSnackBar("Terjadi kesalahan jaringan: $e");
      print("Error updating daily task: $e");
    }
  }

  // --- Hapus Tugas Harian ---
  Future<void> hapusTugasHarian(int id) async {
    try {
      final response = await http.post(
        Uri.parse(
          'http://192.168.50.189/sitemon_api/pembimbing/tugas_harian/delete_tugas_harian.php',
        ),
        body: {'id': id.toString()},
      );
      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          _showSnackBar("Tugas harian berhasil dihapus!");
          fetchTugasHarian(); // Refresh daftar tugas harian
        } else {
          _showSnackBar("Gagal menghapus tugas harian: ${data['message']}");
        }
      } else {
        _showSnackBar("Terjadi kesalahan server: ${response.statusCode}");
      }
    } catch (e) {
      _showSnackBar("Terjadi kesalahan jaringan: $e");
      print("Error deleting daily task: $e");
    }
  }

  // --- Tambah Tugas Akhir ---
  Future<void> tambahTugasAkhir() async {
    if (namaTugasController.text.isEmpty || deadlineController.text.isEmpty) {
      _showSnackBar("Nama tugas dan deadline wajib diisi!");
      return;
    }
    if (selectedUserIds.isEmpty) {
      _showSnackBar("Pilih minimal satu siswa!");
      return;
    }
    if (_currentPembimbingId == null) {
      _showSnackBar("ID Pembimbing tidak tersedia. Tidak bisa menambah tugas.");
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(
          'http://192.168.50.189/sitemon_api/pembimbing/tugas_akhir/add_tugas_akhir.php',
        ),
        body: {
          'nama_tugas': namaTugasController.text,
          'deadline': deadlineController.text,
          'user_ids': json.encode(selectedUserIds),
          'pembimbing_id': _currentPembimbingId
              .toString(), // Pastikan pembimbing_id juga dikirim
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          _showSnackBar("Tugas akhir berhasil ditambahkan!");
          fetchTugasAkhir(); // Refresh daftar tugas akhir
        } else {
          _showSnackBar("Gagal menambahkan tugas akhir: ${data['message']}");
        }
      } else {
        _showSnackBar("Terjadi kesalahan server: ${response.statusCode}");
      }
    } catch (e) {
      _showSnackBar("Terjadi kesalahan jaringan: $e");
      print("Error adding final task: $e");
    }
  }

  // --- Edit Tugas Akhir ---
  void showEditTugasAkhirDialog(TugasAkhir tugas) async {
    namaTugasController.text = tugas.namaTugas;
    deadlineController.text = tugas.deadline;
    selectedUserIds.clear();

    await _fetchAssignedUsersAkhir(tugas.id);

    _showTugasDialog(
      title: "Edit Tugas Akhir",
      onSave: () => editTugasAkhir(tugas.id),
      isEdit: true,
      taskType: 'akhir',
    );
  }

  Future<void> editTugasAkhir(int taskId) async {
    if (namaTugasController.text.isEmpty || deadlineController.text.isEmpty) {
      _showSnackBar("Nama tugas dan deadline wajib diisi!");
      return;
    }
    if (selectedUserIds.isEmpty) {
      _showSnackBar("Pilih minimal satu siswa!");
      return;
    }
    if (_currentPembimbingId == null) {
      _showSnackBar(
        "ID Pembimbing tidak tersedia. Tidak bisa memperbarui tugas.",
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(
          'http://192.168.50.189/sitemon_api/pembimbing/tugas_akhir/update_tugas_akhir.php',
        ),
        body: {
          'id': taskId.toString(),
          'nama_tugas': namaTugasController.text,
          'deadline': deadlineController.text,
          'user_ids': json.encode(selectedUserIds),
          'pembimbing_id': _currentPembimbingId
              .toString(), // Pastikan pembimbing_id juga dikirim
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          _showSnackBar("Tugas akhir berhasil diperbarui!");
          fetchTugasAkhir(); // Refresh daftar tugas akhir
        } else {
          _showSnackBar("Gagal memperbarui tugas akhir: ${data['message']}");
        }
      } else {
        _showSnackBar("Terjadi kesalahan server: ${response.statusCode}");
      }
    } catch (e) {
      _showSnackBar("Terjadi kesalahan jaringan: $e");
      print("Error updating final task: $e");
    }
  }

  // --- Hapus Tugas Akhir ---
  Future<void> hapusTugasAkhir(int id) async {
    try {
      final response = await http.post(
        Uri.parse(
          'http://192.168.50.189/sitemon_api/pembimbing/tugas_akhir/delete_tugas_akhir.php',
        ),
        body: {'id': id.toString()},
      );
      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          _showSnackBar("Tugas akhir berhasil dihapus!");
          fetchTugasAkhir(); // Refresh daftar tugas akhir
        } else {
          _showSnackBar("Gagal menghapus tugas akhir: ${data['message']}");
        }
      } else {
        _showSnackBar("Terjadi kesalahan server: ${response.statusCode}");
      }
    } catch (e) {
      _showSnackBar("Terjadi kesalahan jaringan: $e");
      print("Error deleting final task: $e");
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
    }
  }

  // --- Widget Card untuk Tugas Harian ---
  Widget buildTugasHarianCard(TugasHarian tugas) {
    return Card(
      elevation: 6,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      shadowColor: Colors.blue.shade200,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tugas.namaTugas,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey.shade900,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Colors.blue.shade400,
                ),
                const SizedBox(width: 8),
                Text(
                  "Deadline: ${tugas.deadline}",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.blueGrey.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Align(
              alignment: Alignment.bottomRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => showEditTugasHarianDialog(tugas),
                    icon: const Icon(Icons.edit, size: 18, color: Colors.white),
                    label: Text(
                      "Edit",
                      style: GoogleFonts.poppins(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 10,
                      ),
                      elevation: 3,
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          title: Text(
                            'Konfirmasi Hapus',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          content: Text(
                            'Apakah Anda yakin ingin menghapus tugas harian ini?',
                            style: GoogleFonts.poppins(),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: Text(
                                'Batal',
                                style: GoogleFonts.poppins(
                                  color: Colors.blueGrey,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                hapusTugasHarian(tugas.id);
                              },
                              child: Text(
                                'Hapus',
                                style: GoogleFonts.poppins(
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.delete_forever,
                      size: 18,
                      color: Colors.white,
                    ),
                    label: Text(
                      "Hapus",
                      style: GoogleFonts.poppins(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 10,
                      ),
                      elevation: 3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Widget Card untuk Tugas Akhir ---
  Widget buildTugasAkhirCard(TugasAkhir tugas) {
    return Card(
      elevation: 6,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      shadowColor: Colors.blue.shade200,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tugas.namaTugas,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey.shade900,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Colors.blue.shade400,
                ),
                const SizedBox(width: 8),
                Text(
                  "Deadline: ${tugas.deadline}",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.blueGrey.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Align(
              alignment: Alignment.bottomRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => showEditTugasAkhirDialog(tugas),
                    icon: const Icon(Icons.edit, size: 18, color: Colors.white),
                    label: Text(
                      "Edit",
                      style: GoogleFonts.poppins(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 10,
                      ),
                      elevation: 3,
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          title: Text(
                            'Konfirmasi Hapus',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          content: Text(
                            'Apakah Anda yakin ingin menghapus tugas akhir ini?',
                            style: GoogleFonts.poppins(),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: Text(
                                'Batal',
                                style: GoogleFonts.poppins(
                                  color: Colors.blueGrey,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                hapusTugasAkhir(tugas.id);
                              },
                              child: Text(
                                'Hapus',
                                style: GoogleFonts.poppins(
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.delete_forever,
                      size: 18,
                      color: Colors.white,
                    ),
                    label: Text(
                      "Hapus",
                      style: GoogleFonts.poppins(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 10,
                      ),
                      elevation: 3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Dua tab: Tugas Harian dan Tugas Akhir
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
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
            "MANAJEMEN TUGAS",
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
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
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            // Tampilkan bottom sheet dengan pilihan tambah tugas
            showModalBottomSheet(
              context: context,
              builder: (BuildContext bc) {
                return SafeArea(
                  child: Wrap(
                    children: <Widget>[
                      ListTile(
                        leading: Icon(
                          Icons.assignment_outlined,
                          color: Colors.blue.shade700,
                        ),
                        title: Text(
                          'Tambah Tugas Harian',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(bc); // Tutup bottom sheet
                          namaTugasController.clear();
                          deadlineController.clear();
                          selectedUserIds.clear();
                          _showTugasDialog(
                            title: "Tambah Tugas Harian Baru",
                            onSave: tambahTugasHarian,
                            taskType: 'harian',
                          );
                        },
                      ),
                      ListTile(
                        leading: Icon(
                          Icons.assignment_add,
                          color: Colors.blue.shade700,
                        ),
                        title: Text(
                          'Tambah Tugas Akhir',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(bc); // Tutup bottom sheet
                          namaTugasController.clear();
                          deadlineController.clear();
                          selectedUserIds.clear();
                          _showTugasDialog(
                            title: "Tambah Tugas Akhir Baru",
                            onSave: tambahTugasAkhir,
                            taskType: 'akhir',
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
          tooltip: "Tambah Tugas",
          icon: const Icon(Icons.add, size: 28),
          label: Text(
            "Tambah Tugas",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue.shade50, Colors.blue.shade100],
            ),
          ),
          child: TabBarView(
            children: [
              // --- Tampilan untuk Tugas Harian ---
              isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: Colors.blue.shade700,
                      ),
                    )
                  : errorMessage != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: Colors.red,
                                  size: 60,
                                ),
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
                                  errorMessage!,
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    color: Colors.grey.shade700,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 30),
                                ElevatedButton.icon(
                                  onPressed: _loadPembimbingIdAndFetchData,
                                  icon: const Icon(Icons.refresh),
                                  label: Text(
                                    "Coba Lagi",
                                    style: GoogleFonts.poppins(),
                                  ),
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
                        )
                      : daftarTugasHarian.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.assignment_turned_in_outlined,
                                    size: 80,
                                    color: Colors.blueGrey.shade300,
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    "Belum ada tugas harian yang diberikan.",
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      color: Colors.blueGrey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  Text(
                                    "Tekan tombol '+' untuk menambah tugas harian baru.",
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.blueGrey.shade400,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              itemCount: daftarTugasHarian.length,
                              itemBuilder: (context, index) {
                                return buildTugasHarianCard(
                                    daftarTugasHarian[index]);
                              },
                            ),
              // --- Tampilan untuk Tugas Akhir ---
              isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: Colors.blue.shade700,
                      ),
                    )
                  : errorMessage != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: Colors.red,
                                  size: 60,
                                ),
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
                                  errorMessage!,
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    color: Colors.grey.shade700,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 30),
                                ElevatedButton.icon(
                                  onPressed: _loadPembimbingIdAndFetchData,
                                  icon: const Icon(Icons.refresh),
                                  label: Text(
                                    "Coba Lagi",
                                    style: GoogleFonts.poppins(),
                                  ),
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
                        )
                      : daftarTugasAkhir.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.assignment_turned_in_outlined,
                                    size: 80,
                                    color: Colors.blueGrey.shade300,
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    "Belum ada tugas akhir yang diberikan.",
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      color: Colors.blueGrey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  Text(
                                    "Tekan tombol '+' untuk menambah tugas akhir baru.",
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.blueGrey.shade400,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              itemCount: daftarTugasAkhir.length,
                              itemBuilder: (context, index) {
                                return buildTugasAkhirCard(
                                    daftarTugasAkhir[index]);
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
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PenilaianFeedbackPage(),
                  ),
                );
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
                    builder: (context) => const PenilaianAkhirPage(),
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
              // This is the new item for Final Assessment
              icon: Icon(Icons.star_half, size: 30),
              label: "Final Grade",
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
}
