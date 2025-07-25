import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class BerkasMagangPage extends StatefulWidget {
  @override
  _BerkasMagangPageState createState() => _BerkasMagangPageState();
}

class _BerkasMagangPageState extends State<BerkasMagangPage> {
  Map<String, PlatformFile?> pickedFiles = {
    "Proposal Magang": null,
    "CV": null,
    "Transkrip Nilai/Nilai Raport": null,
    "Kartu Tanda Mahasiswa/Kartu Pelajar": null,
    "Pas Photo": null,
  };

  final String apiUrl =
      'http://192.168.50.189/sitemon_api/users/seleksi_berkas.php';
  final String apiGetKategoriUrl =
      'http://192.168.50.189/sitemon_api/users/get_kategori_kegiatan.php';

  String? _kategoriKegiatan;
  bool _isLoading = true;
  int? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserDataAndKategori();
  }

  Future<void> _loadUserDataAndKategori() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? userId = prefs.getInt('user_id');

    if (userId != null) {
      setState(() {
        _userId = userId;
      });
      await _fetchUserBerkas();
      await _fetchKategoriKegiatan();
    } else {
      // Menggunakan Builder untuk mendapatkan BuildContext yang valid setelah initState
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context as BuildContext).showSnackBar(
          SnackBar(
            content: Text("User ID tidak ditemukan. Harap login kembali."),
          ),
        );
        Navigator.pop(context as BuildContext);
      });
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchKategoriKegiatan() async {
    try {
      final response = await http.get(
        Uri.parse('$apiGetKategoriUrl?user_id=$_userId'),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _kategoriKegiatan = data['kategori_kegiatan'];
            _isLoading = false;
          });
          print("Kategori kegiatan fetched: $_kategoriKegiatan");
        } else {
          print("Failed to get kategori kegiatan: ${data['message']}");
          setState(() {
            _kategoriKegiatan = null;
            _isLoading = false;
          });
        }
      } else {
        print("Error fetching kategori kegiatan: ${response.statusCode}");
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Exception fetching kategori kegiatan: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchUserBerkas() async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl?action=get_berkas&user_id=$_userId'),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] && data['berkas'] != null) {
          setState(() {
            pickedFiles["Proposal Magang"] =
                data['berkas']['proposal_magang'] != null &&
                        data['berkas']['proposal_magang'].isNotEmpty
                    ? PlatformFile(
                        name: data['berkas']['proposal_magang'],
                        size: 0,
                      )
                    : null;
            pickedFiles["CV"] =
                data['berkas']['cv'] != null && data['berkas']['cv'].isNotEmpty
                    ? PlatformFile(name: data['berkas']['cv'], size: 0)
                    : null;
            pickedFiles["Transkrip Nilai"] =
                data['berkas']['transkrip_nilai'] != null &&
                        data['berkas']['transkrip_nilai'].isNotEmpty
                    ? PlatformFile(
                        name: data['berkas']['transkrip_nilai'],
                        size: 0,
                      )
                    : null;
            pickedFiles["Kartu Tanda Mahasiswa"] =
                data['berkas']['ktm'] != null &&
                        data['berkas']['ktm'].isNotEmpty
                    ? PlatformFile(name: data['berkas']['ktm'], size: 0)
                    : null;
            pickedFiles["Pas Photo"] = data['berkas']['pas_foto'] != null &&
                    data['berkas']['pas_foto'].isNotEmpty
                ? PlatformFile(name: data['berkas']['pas_foto'], size: 0)
                : null;
          });
        } else {
          print(
            "No existing berkas found or failed to fetch: ${data['message'] ?? 'Unknown error'}",
          );
        }
      } else {
        print("Error fetching existing berkas: ${response.statusCode}");
      }
    } catch (e) {
      print("Exception fetching existing berkas: $e");
    }
  }

  Future<void> pickFile(String label) async {
    FilePickerResult? result;

    if (label == "Pas Photo") {
      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ["jpg", "jpeg", "png"],
      );
    } else {
      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ["pdf"],
      );
    }

    if (result != null) {
      setState(() {
        pickedFiles[label] = result?.files.first;
      });
    }
  }

  Future<void> simpanBerkas(BuildContext context) async {
    bool areFilesOptional =
        _kategoriKegiatan == "penelitian" || _kategoriKegiatan == "skripsi";

    // Validasi hanya jika berkas tidak opsional
    if (!areFilesOptional) {
      if (pickedFiles.values.any((file) => file == null)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Harap unggah semua berkas yang diminta.")),
        );
        return;
      }
    } else {
      // Jika opsional dan tidak ada file yang dipilih, bisa langsung kirim
      // Tetapi PHP akan tetap mengharapkan parameter user_id
      // Jika semua null dan tidak ada perubahan, tidak perlu kirim request
      bool anyFilePicked = pickedFiles.values.any((file) => file != null);
      // Di sini kita perlu tahu apakah ada perubahan dari berkas yang sudah ada atau ini unggahan pertama.
      // Jika ingin skip pengiriman, Anda perlu membandingkan `pickedFiles` dengan data yang fetched di `_fetchUserBerkas`.
      // Untuk tujuan ini, kita akan tetap kirim request ke PHP agar PHP bisa menangani update/insert dengan null values.
    }

    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("User belum login atau user_id tidak ditemukan."),
        ),
      );
      return;
    }

    try {
      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      request.fields['user_id'] = _userId.toString();
      request.fields['kategori_kegiatan'] =
          _kategoriKegiatan ?? 'lainnya'; // Kirim kategori kegiatan juga

      final fieldMapping = {
        "Proposal Magang": "proposal_magang",
        "CV": "cv",
        "Transkrip Nilai": "transkrip_nilai",
        "Kartu Tanda Mahasiswa": "ktm",
        "Pas Photo": "pas_foto",
      };

      for (var entry in pickedFiles.entries) {
        final file = entry.value;
        final field = fieldMapping[entry.key]!;

        if (file != null) {
          request.files.add(
            await http.MultipartFile.fromPath(
              field,
              file.path!,
              filename: basename(file.path!),
            ),
          );
        }
      }

      var response = await request.send();
      var responseBody = await http.Response.fromStream(response);
      final responseData = json.decode(responseBody.body);

      if (response.statusCode == 200 && responseData['status'] == 'success') {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Berkas berhasil diunggah.")));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Gagal mengunggah berkas: ${responseData['message'] ?? 'Unknown error'}",
            ),
          ),
        );
      }
    } catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Terjadi kesalahan: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Lengkapi Berkas Magang"),
          centerTitle: true,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue, Colors.indigo],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          elevation: 3,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    bool areFilesOptional =
        _kategoriKegiatan == "penelitian" || _kategoriKegiatan == "skripsi";

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
          "LENGKAPI BERKAS",
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            if (areFilesOptional)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Card(
                  color: Colors.yellow.shade100,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange.shade700),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Untuk kategori kegiatan '$_kategoriKegiatan', unggahan berkas bersifat opsional.",
                            style: TextStyle(
                              color: Colors.orange.shade800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ...pickedFiles.keys.map(
              (label) => buildFileUploadField(label, areFilesOptional),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () => simpanBerkas(context),
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

  Widget buildFileUploadField(String label, bool isOptional) {
    bool fileExists =
        pickedFiles[label] != null && pickedFiles[label]!.name.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label ${isOptional ? '(Opsional)' : ''}",
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade400),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    pickedFiles[label]?.name ?? "Belum ada file yang dipilih",
                    style: TextStyle(
                      fontSize: 12,
                      color: fileExists ? Colors.black87 : Colors.black54,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  label == "Pas Photo" ? Icons.image : Icons.picture_as_pdf,
                  color: fileExists
                      ? (label == "Pas Photo" ? Colors.green : Colors.red)
                      : Colors.grey,
                  size: 18,
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 28,
                  child: ElevatedButton.icon(
                    onPressed: () => pickFile(label),
                    icon: const Icon(Icons.upload_file, size: 14),
                    label: const Text("Unggah", style: TextStyle(fontSize: 10)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
