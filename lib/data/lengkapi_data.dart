import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // Import untuk json decode

class LengkapiDataScreen extends StatefulWidget {
  final int userId;

  const LengkapiDataScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _LengkapiDataScreenState createState() => _LengkapiDataScreenState();
}

class _LengkapiDataScreenState extends State<LengkapiDataScreen> {
  final TextEditingController namaLengkapController = TextEditingController();
  final TextEditingController noKtmController = TextEditingController();
  final TextEditingController tempatLahirController = TextEditingController();
  final TextEditingController tanggalLahirController = TextEditingController();
  final TextEditingController alamatController = TextEditingController();
  final TextEditingController noHpController = TextEditingController();
  final TextEditingController instansiController = TextEditingController();
  final TextEditingController jurusanController = TextEditingController();

  String jenisKelamin = "Laki-laki"; // Default value
  bool isLoading = false; // Status untuk menampilkan loading indicator

  @override
  void initState() {
    super.initState();
    _fetchExistingData(); // Panggil fungsi untuk memuat data saat layar diinisialisasi
  }

  // Fungsi untuk memuat data yang sudah ada dari server
  Future<void> _fetchExistingData() async {
    // Pastikan widget masih ada di tree sebelum setState
    if (!mounted) return;

    setState(() {
      isLoading = true; // Set loading true saat memulai pengambilan data
    });

    // Endpoint untuk mengambil data diri pengguna
    final String url =
        "http://192.168.50.189/sitemon_api/users/get_data_diri.php";

    // Pastikan user_id disertakan dalam URL untuk permintaan GET
    final Uri uri = Uri.parse('$url?user_id=${widget.userId}');

    try {
      final response = await http.get(uri).timeout(const Duration(
          seconds:
              10)); // Tambahkan timeout untuk mencegah loading tak terbatas

      // Pastikan widget masih ada di tree setelah async operation
      if (!mounted) return;

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseJson = jsonDecode(response.body);
        if (responseJson['status'] == 'success' &&
            responseJson['data'] != null) {
          final data = responseJson['data'];
          // Isi controller dengan data yang dimuat, gunakan operator ?? '' untuk menghindari null
          namaLengkapController.text = data['nama_lengkap'] ?? '';
          noKtmController.text = data['no_ktm'] ?? '';
          tempatLahirController.text = data['tempat_lahir'] ?? '';
          tanggalLahirController.text = data['tanggal_lahir'] ?? '';
          alamatController.text = data['alamat'] ?? '';
          noHpController.text = data['no_hp'] ?? '';

          setState(() {
            jenisKelamin =
                data['jenis_kelamin'] ?? 'Laki-laki'; // Set default jika null
          });
          instansiController.text = data['instansi'] ?? '';
          jurusanController.text = data['jurusan'] ?? '';
          tampilkanPesan("Data diri berhasil dimuat.");
        } else {
          tampilkanPesan("Belum ada data diri. Silakan lengkapi.");
        }
      } else {
        tampilkanPesan(
            "Gagal memuat data diri. Status: ${response.statusCode}");
      }
    } on http.ClientException catch (e) {
      // Penanganan khusus untuk masalah koneksi jaringan
      tampilkanPesan(
          "Tidak dapat terhubung ke server. Periksa koneksi internet Anda atau hubungi administrator.");
      print("ClientException during data fetch: $e");
    } on FormatException catch (e) {
      // Penanganan khusus jika respons bukan JSON yang valid
      tampilkanPesan("Format data tidak valid dari server.");
      print("FormatException during data fetch: $e");
    } catch (e) {
      // Penanganan error umum lainnya
      tampilkanPesan("Terjadi kesalahan saat memuat data diri: $e");
      print("Error memuat data diri: $e");
    } finally {
      // Selalu set loading false setelah operasi selesai
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // Fungsi untuk menampilkan date picker dan mengisi tanggal ke controller
  Future<void> pilihTanggal(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1,
          1), // Atur tanggal awal yang lebih relevan untuk tanggal lahir
      firstDate: DateTime(1960),
      lastDate: DateTime.now(), // Batasi hingga tanggal hari ini
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue.shade700, // Warna header date picker
              onPrimary: Colors.white, // Warna teks di header
              onSurface: Colors.black, // Warna teks di body date picker
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue.shade700, // Warna teks tombol
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      // Format tanggal ke format yyyy-mm-dd yang diharapkan database
      tanggalLahirController.text =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
    }
  }

  // Fungsi validasi nomor telepon
  bool isNomorTeleponValid(String number) {
    // Regex untuk 10-15 digit angka, bisa disesuaikan
    final RegExp phoneRegex = RegExp(r'^[0-9]{10,15}$');
    return phoneRegex.hasMatch(number);
  }

  // Fungsi untuk mengirim data ke server
  Future<void> kirimData() async {
    // Pastikan widget masih ada di tree sebelum setState
    if (!mounted) return;

    setState(() {
      isLoading = true; // Set loading true saat mulai mengirim data
    });

    final String url =
        "http://192.168.50.189/sitemon_api/users/lengkapi_data.php";

    print("Mengirim data ke URL: $url");

    // Validasi semua kolom tidak boleh kosong
    if (namaLengkapController.text.trim().isEmpty ||
        noKtmController.text.trim().isEmpty ||
        tempatLahirController.text.trim().isEmpty ||
        tanggalLahirController.text.trim().isEmpty ||
        alamatController.text.trim().isEmpty ||
        noHpController.text.trim().isEmpty ||
        instansiController.text.trim().isEmpty ||
        jurusanController.text.trim().isEmpty) {
      tampilkanPesan("Harap isi semua kolom yang wajib diisi!");
      if (mounted) {
        setState(() {
          isLoading = false; // Set loading false jika validasi gagal
        });
      }
      return;
    }

    // Validasi format nomor HP
    if (!isNomorTeleponValid(noHpController.text.trim())) {
      tampilkanPesan("Nomor HP harus terdiri dari 10-15 digit angka.");
      if (mounted) {
        setState(() {
          isLoading = false; // Set loading false jika validasi gagal
        });
      }
      return;
    }

    // Data yang akan dikirim dalam format Map<String, String>
    final Map<String, String> dataToSend = {
      "user_id": widget.userId.toString(),
      "nama_lengkap": namaLengkapController.text.trim(),
      "no_ktm": noKtmController.text.trim(),
      "tempat_lahir": tempatLahirController.text.trim(),
      "tanggal_lahir": tanggalLahirController.text.trim(),
      "alamat": alamatController.text.trim(),
      "no_hp": noHpController.text.trim(),
      "jenis_kelamin":
          jenisKelamin, // jenisKelamin tidak perlu .trim() karena dari dropdown
      "instansi": instansiController.text.trim(),
      "jurusan": jurusanController.text.trim(),
    };

    print("Data yang dikirim: $dataToSend");

    try {
      final response = await http
          .post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/x-www-form-urlencoded"
        }, // Headers sesuai body
        body: dataToSend, // Kirim data dalam format x-www-form-urlencoded
      )
          .timeout(
        const Duration(
            seconds: 15), // Tingkatkan timeout untuk operasi pengiriman
        onTimeout: () {
          throw Exception(
            "Waktu permintaan habis. Periksa koneksi internet Anda atau server.",
          );
        },
      );

      print("Status respons: ${response.statusCode}");
      print("Isi respons: ${response.body}");

      Map<String, dynamic> responseJson = {};
      try {
        String responseBody = response.body.trim();
        if (responseBody.isEmpty) {
          throw const FormatException("Respons kosong dari server.");
        }
        // Periksa apakah respons adalah JSON yang valid
        if (responseBody.startsWith("{") || responseBody.startsWith("[")) {
          responseJson = jsonDecode(responseBody);
          print("Respons JSON: $responseJson");
        } else {
          // Tangani respons non-JSON dari server
          responseJson = {
            "status": "error",
            "message":
                "Server mengembalikan respons tidak terduga. ($responseBody)",
          };
          print("Respons non-JSON: $responseBody");
        }
      } on FormatException catch (e) {
        tampilkanPesan(
            "Terjadi kesalahan format respons dari server: ${e.message}");
        print("Error parsing respons JSON: $e");
        return; // Keluar dari fungsi jika parsing gagal
      }

      // Pastikan widget masih ada di tree setelah async operation
      if (!mounted) return;

      if (response.statusCode == 200) {
        if (responseJson.containsKey('status')) {
          if (responseJson['status'] == 'success' ||
              responseJson['status'] == 'warning') {
            tampilkanPesan(
                responseJson['message'] ?? "Data berhasil disimpan!");
            if (context.mounted)
              Navigator.pop(
                  context); // Kembali ke layar sebelumnya jika berhasil
          } else {
            String pesanError = responseJson['message'] ??
                "Terjadi kesalahan saat menyimpan data.";
            tampilkanPesan("Gagal: $pesanError");
          }
        } else {
          tampilkanPesan(
              "Format respons tidak valid: 'status' tidak ditemukan.");
        }
      } else {
        String pesanError = responseJson.containsKey('message')
            ? responseJson['message']
            : "Gagal menyimpan data! Status HTTP: ${response.statusCode}";
        tampilkanPesan("Gagal: $pesanError");
      }
    } on http.ClientException catch (e) {
      tampilkanPesan(
          "Tidak dapat terhubung ke server. Periksa koneksi internet Anda atau hubungi administrator.");
      print("ClientException during data send: $e");
    } on Exception catch (e) {
      // Penanganan exception dari timeout atau custom throw
      tampilkanPesan("Terjadi kesalahan: ${e.toString()}");
      print("Exception during data send: $e");
    } catch (e) {
      // Penanganan error umum lainnya
      tampilkanPesan("Terjadi kesalahan tidak terduga: $e");
      print("Unexpected error during data send: $e");
    } finally {
      // Selalu set loading false setelah operasi selesai
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // Fungsi utilitas untuk menampilkan SnackBar
  void tampilkanPesan(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  void dispose() {
    // Pastikan untuk membuang controller saat widget dihapus untuk mencegah memory leaks
    namaLengkapController.dispose();
    noKtmController.dispose();
    tempatLahirController.dispose();
    tanggalLahirController.dispose();
    alamatController.dispose();
    noHpController.dispose();
    instansiController.dispose();
    jurusanController.dispose();
    super.dispose();
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
          "LENGKAPI DATA DIRI",
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
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                buatTextField("Nama Lengkap", namaLengkapController),
                const SizedBox(height: 12),
                buatTextField("Nomor KTM", noKtmController),
                const SizedBox(height: 12),
                buatTextField("Tempat Lahir", tempatLahirController),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => pilihTanggal(context),
                  child: AbsorbPointer(
                    child: buatTextField(
                      "Tanggal Lahir (yyyy-mm-dd)",
                      tanggalLahirController,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                buatTextField("Alamat", alamatController, maxLines: 2),
                const SizedBox(height: 12),
                buatTextField(
                  "Nomor HP",
                  noHpController,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                buatDropdownJenisKelamin(),
                const SizedBox(height: 12),
                buatTextField("Instansi", instansiController),
                const SizedBox(height: 12),
                buatTextField("Jurusan", jurusanController),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity, // Membuat tombol mengisi lebar penuh
                  child: ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : kirimData, // Nonaktifkan tombol saat loading
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      foregroundColor: Colors.white,
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(
                            color: Colors.white) // Tampilkan loading indicator
                        : const Text(
                            "Simpan",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                  ),
                ),
              ],
            ),
          ),
          // Overlay loading indicator di tengah layar
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                  child: CircularProgressIndicator(color: Colors.white)),
            ),
        ],
      ),
    );
  }

  // Widget pembantu untuk TextField yang disesuaikan
  Widget buatTextField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.grey.shade100,
      ),
    );
  }

  // Widget pembantu untuk Dropdown Jenis Kelamin
  Widget buatDropdownJenisKelamin() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: jenisKelamin,
          hint: Text("Pilih Jenis Kelamin", style: GoogleFonts.poppins()),
          onChanged: (value) {
            if (value != null) {
              // Pastikan value tidak null sebelum di-set
              setState(() {
                jenisKelamin = value;
              });
            }
          },
          items: ["Laki-laki", "Perempuan"]
              .map(
                (gender) => DropdownMenuItem(
                  value: gender,
                  child: Text(gender, style: GoogleFonts.poppins()),
                ),
              )
              .toList(),
          style: GoogleFonts.poppins(color: Colors.black87, fontSize: 16),
          dropdownColor: Colors.white,
          icon: Icon(Icons.arrow_drop_down, color: Colors.blue.shade700),
        ),
      ),
    );
  }
}
