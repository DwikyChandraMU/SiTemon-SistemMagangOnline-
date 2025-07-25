import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

class DaftarMagangPage extends StatefulWidget {
  @override
  _DaftarMagangPageState createState() => _DaftarMagangPageState();
}

class _DaftarMagangPageState extends State<DaftarMagangPage> {
  String? selectedKategori;
  String? selectedBidang;

  final TextEditingController lamaMagangController = TextEditingController();
  final TextEditingController tanggalMulaiController = TextEditingController();
  final TextEditingController tanggalSelesaiController =
      TextEditingController();

  int? userId; // Tetap nullable, tapi akan divalidasi dengan baik

  @override
  void initState() {
    super.initState();
    getUserId();
  }

  Future<void> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getInt('user_id');
    });
  }

  Future<void> pilihTanggal(TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      controller.text =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
    }
  }

  Future<void> simpanData() async {
    // Validasi bahwa userId tidak null sebelum melanjutkan
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("User belum login. Mohon login terlebih dahulu.")),
      );
      return;
    }

    // Validasi semua kolom, termasuk dropdown
    if (selectedKategori == null ||
        selectedKategori!.trim().isEmpty ||
        lamaMagangController.text.trim().isEmpty ||
        tanggalMulaiController.text.trim().isEmpty ||
        tanggalSelesaiController.text.trim().isEmpty ||
        selectedBidang == null ||
        selectedBidang!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Semua kolom harus diisi!")),
      );
      return;
    }

    final url = Uri.parse(
      'http://192.168.50.189/sitemon_api/users/daftar_magang.php',
    );

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "user_id": userId, // userId dijamin tidak null di sini
          "kategori_kegiatan": selectedKategori,
          "lama_magang": lamaMagangController.text,
          "tanggal_mulai": tanggalMulaiController.text,
          "tanggal_selesai": tanggalSelesaiController.text,
          "bidang": selectedBidang,
        }),
      );

      final data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? "Berhasil disimpan!")),
        );
        // Opsional: Kosongkan formulir setelah berhasil disimpan
        _clearForm();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? "Gagal menyimpan data.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Terjadi kesalahan koneksi atau server: $e")),
      );
    }
  }

  // Fungsi untuk mengosongkan formulir
  void _clearForm() {
    setState(() {
      selectedKategori = null;
      selectedBidang = null;
      lamaMagangController.clear();
      tanggalMulaiController.clear();
      tanggalSelesaiController.clear();
    });
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
          "DAFTAR KEGIATAN",
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 10,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            buildDropdownField(
              "Pilih Kategori Kegiatan",
              ["Magang", "Kerja Praktik", "Penelitian", "Skripsi"],
              (value) => setState(() => selectedKategori = value),
              selectedKategori,
            ),
            buildTextField("Lama Magang", lamaMagangController),
            GestureDetector(
              onTap: () => pilihTanggal(tanggalMulaiController),
              child: AbsorbPointer(
                child: buildTextField(
                  "Tanggal Mulai Magang",
                  tanggalMulaiController,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => pilihTanggal(tanggalSelesaiController),
              child: AbsorbPointer(
                child: buildTextField(
                  "Tanggal Selesai Magang",
                  tanggalSelesaiController,
                ),
              ),
            ),
            buildDropdownField(
              "Bidang",
              [
                "LTPS",
                "TU",
                "Otomasi",
                "Deposit",
                "Pengolahan",
                "Layanan Dewasa",
                "Referensi",
                "RBM",
                "Pelestarian",
                "ruangan berkala",
                "ruangan difabel",
                "pendaftaran kta"
              ],
              (value) => setState(() => selectedBidang = value),
              selectedBidang,
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: simpanData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 3,
                ),
                child: const Text(
                  "SIMPAN",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
        ),
      ),
    );
  }

  Widget buildDropdownField(
    String label,
    List<String> items,
    ValueChanged<String?> onChanged,
    String? currentValue,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
        ),
        // Pastikan `value` hanya diatur jika `currentValue` ada dalam `items`
        value: items.contains(currentValue) ? currentValue : null,
        items: items
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
        onChanged: onChanged,
        // Tambahkan validator untuk memastikan dropdown tidak kosong
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Pilih $label';
          }
          return null;
        },
      ),
    );
  }
}
