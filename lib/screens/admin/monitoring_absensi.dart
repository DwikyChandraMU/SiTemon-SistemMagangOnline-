import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

// --- Data Model ---
class AbsensiData {
  final int absenId;
  final int userId;
  final String namaMahasiswa;
  final String emailMahasiswa;
  final String? instansi;
  final String? jurusan;
  final String tanggal; // Tanggal absen (misal: 'YYYY-MM-DD')
  final String? jamMasuk; // Jam masuk (misal: 'HH:MM:SS')
  final String? jamPulang; // Jam pulang (misal: 'HH:MM:SS')
  final String status; // 'masuk' atau 'pulang'
  final double? latitude;
  final double? longitude;
  final String? catatan;
  final String? foto; // Nama file foto

  AbsensiData({
    required this.absenId,
    required this.userId,
    required this.namaMahasiswa,
    required this.emailMahasiswa,
    this.instansi,
    this.jurusan,
    required this.tanggal,
    this.jamMasuk,
    this.jamPulang,
    required this.status,
    this.latitude,
    this.longitude,
    this.catatan,
    this.foto,
  });

  factory AbsensiData.fromJson(Map<String, dynamic> json) {
    return AbsensiData(
      absenId: int.parse(json['absen_id'].toString()),
      userId: int.parse(json['user_id'].toString()),
      namaMahasiswa: json['nama_mahasiswa'] ?? 'Tidak Diketahui',
      emailMahasiswa: json['email_mahasiswa'] ?? 'Tidak Diketahui',
      instansi: json['instansi'],
      jurusan: json['jurusan'],
      tanggal: json['tanggal'] ?? '-',
      jamMasuk:
          json['jam_masuk'], // Pastikan ini sesuai dengan nama kolom di DB
      jamPulang:
          json['jam_pulang'], // Pastikan ini sesuai dengan nama kolom di DB
      status: json['status'] ??
          'Tidak Diketahui', // Pastikan ini sesuai dengan nama kolom di DB
      latitude: json['latitude'] != null
          ? double.parse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.parse(json['longitude'].toString())
          : null,
      catatan: json['catatan'],
      foto: json['foto'],
    );
  }
}

// --- Main Page Widget ---
class MonitoringAbsensiPage extends StatefulWidget {
  const MonitoringAbsensiPage({super.key});

  @override
  State<MonitoringAbsensiPage> createState() => _MonitoringAbsensiPageState();
}

class _MonitoringAbsensiPageState extends State<MonitoringAbsensiPage> {
  // Mengelompokkan absensi berdasarkan tanggal, lalu per mahasiswa
  Map<String, Map<String, Map<String, AbsensiData>>> _groupedAbsensi = {};
  bool _isLoading = true;
  String? _errorMessage;

  int? _selectedMonth;
  int? _selectedYear;

  // URL dasar untuk backend PHP dan gambar
  final String _apiBaseDomain = '192.168.50.189';
  final String _apiPath = 'sitemon_api/admin/monitoring_absensi/';
  final String _imageServerPath = 'sitemon_api/uploads/absen/';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = now.month;
    _selectedYear = now.year;
    _fetchAbsensi();
  }

  Future<void> _fetchAbsensi() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _groupedAbsensi.clear(); // Bersihkan data sebelumnya
    });

    try {
      final uri = Uri.http(_apiBaseDomain, '${_apiPath}get_absensi.php', {
        'month': _selectedMonth?.toString(),
        'year': _selectedYear?.toString(),
      });

      final response = await http.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> rawData = json.decode(response.body);

        // Proses data untuk dikelompokkan
        Map<String, Map<String, Map<String, AbsensiData>>> tempGrouped = {};
        for (var item in rawData) {
          final absensi = AbsensiData.fromJson(item);
          final String dateKey = DateFormat('yyyy-MM-dd').format(DateTime.parse(
              absensi
                  .tanggal)); // Gunakan format tanggal standar untuk kunci map
          final String namaMahasiswa = absensi.namaMahasiswa;
          final String status = absensi.status;

          if (!tempGrouped.containsKey(dateKey)) {
            tempGrouped[dateKey] = {};
          }
          if (!tempGrouped[dateKey]!.containsKey(namaMahasiswa)) {
            tempGrouped[dateKey]![namaMahasiswa] = {};
          }
          tempGrouped[dateKey]![namaMahasiswa]![status] = absensi;
        }

        setState(() {
          _groupedAbsensi = tempGrouped;
        });
      } else {
        throw Exception(
            'Gagal mengambil data absensi: ${response.statusCode}. Body: ${response.body}');
      }
    } catch (e) {
      setState(() {
        _errorMessage =
            'Terjadi kesalahan: ${e.toString()}. Pastikan server berjalan dan koneksi stabil.';
      });
      print('Error fetching absensi: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Fungsi ini tidak lagi relevan karena permintaan dari user
  // Future<void> _exportAbsensi(String format) async {
  //   String filename;
  //   if (format == 'excel') {
  //     filename = 'export_absensi_csv.php';
  //   } else {
  //     _showSnackBar('Format ekspor $format belum didukung.');
  //     return;
  //   }

  //   final uri = Uri.http(_apiBaseDomain, '${_apiPath}$filename', {
  //     'month': _selectedMonth?.toString(),
  //     'year': _selectedYear?.toString(),
  //   });

  //   if (await canLaunchUrl(uri)) {
  //     await launchUrl(uri, mode: LaunchMode.externalApplication);
  //     _showSnackBar('Mulai mengunduh laporan $format...');
  //   } else {
  //     _showSnackBar('Tidak dapat meluncurkan URL: $uri');
  //     print('Could not launch $uri');
  //   }
  // }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  // Helper widget untuk baris informasi
  Widget _buildInfoRow(
    String label,
    String value, {
    Color? valueColor,
    FontWeight? fontWeight,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120, // Lebar tetap untuk label agar rapi
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Colors.blueGrey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: valueColor ?? Colors.blueGrey.shade800,
                fontWeight: fontWeight ?? FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Fungsi untuk menampilkan dialog detail absen
  void _showDetailAbsenDialog(AbsensiData absensi) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final imageUrl = Uri.http(
          _apiBaseDomain,
          '${_imageServerPath}${absensi.foto}',
        ).toString();

        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Detail Absensi',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.blue.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: absensi.foto != null && absensi.foto!.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            width: 280, // Ukuran sesuai preferensi
                            height: 280 * 9 / 16, // Untuk rasio 16:9
                            fit: BoxFit.cover,
                            loadingBuilder: (
                              context,
                              child,
                              loadingProgress,
                            ) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                  color: Colors.blue.shade300,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 280,
                                height: 280 * 9 / 16,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  Icons.image_not_supported,
                                  color: Colors.grey.shade500,
                                  size: 60,
                                ),
                              );
                            },
                          )
                        : Container(
                            width: 280,
                            height: 280 * 9 / 16,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.no_photography,
                              color: Colors.grey.shade500,
                              size: 60,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildInfoRow(
                  'Nama Mahasiswa:',
                  absensi.namaMahasiswa,
                  fontWeight: FontWeight.bold,
                ),
                _buildInfoRow('Email:', absensi.emailMahasiswa),
                if (absensi.instansi != null && absensi.instansi!.isNotEmpty)
                  _buildInfoRow('Instansi:', absensi.instansi!),
                if (absensi.jurusan != null && absensi.jurusan!.isNotEmpty)
                  _buildInfoRow('Jurusan:', absensi.jurusan!),
                _buildInfoRow(
                  'Tanggal Absen:',
                  DateFormat(
                    'dd MMMM yyyy',
                  ).format(DateTime.parse(absensi.tanggal)),
                ),
                _buildInfoRow(
                  'Status:',
                  absensi.status == 'masuk' ? 'Absen Masuk' : 'Absen Pulang',
                  valueColor: absensi.status == 'masuk'
                      ? Colors.green.shade700
                      : Colors.orange.shade700,
                  fontWeight: FontWeight.bold,
                ),
                if (absensi.jamMasuk != null && absensi.jamMasuk!.isNotEmpty)
                  _buildInfoRow('Jam Masuk:', absensi.jamMasuk!),
                if (absensi.jamPulang != null && absensi.jamPulang!.isNotEmpty)
                  _buildInfoRow('Jam Pulang:', absensi.jamPulang!),
                if (absensi.latitude != null && absensi.longitude != null)
                  _buildInfoRow(
                    'Lokasi:',
                    '${absensi.latitude}, ${absensi.longitude}',
                    valueColor: Colors.blue.shade600,
                  ),
                if (absensi.catatan != null && absensi.catatan!.isNotEmpty)
                  _buildInfoRow('Catatan:', absensi.catatan!),
              ],
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 25,
                  vertical: 12,
                ),
              ),
              child: Text('Tutup', style: GoogleFonts.poppins(fontSize: 15)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Urutkan tanggal dari terbaru ke terlama
    List<String> sortedDates = _groupedAbsensi.keys.toList()
      ..sort((a, b) => DateTime.parse(b).compareTo(DateTime.parse(a)));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Monitoring Absensi',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 22,
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade700, Colors.blue.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        centerTitle: true,
        elevation: 0,
        toolbarHeight: 80,
        // Tombol ekspor CSV dihapus sesuai permintaan
        // actions: [
        //   PopupMenuButton<String>(
        //     onSelected: (value) {
        //       if (value == 'excel') {
        //         _exportAbsensi('excel');
        //       } else if (value == 'pdf') {
        //         _showSnackBar('Ekspor ke PDF sedang dalam pengembangan.');
        //       }
        //     },
        //     itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        //       PopupMenuItem<String>(
        //         value: 'excel',
        //         child: Row(
        //           children: [
        //             Icon(Icons.description, color: Colors.green.shade600),
        //             const SizedBox(width: 10),
        //             Text(
        //               'Ekspor ke Excel (CSV)',
        //               style: GoogleFonts.poppins(),
        //             ),
        //           ],
        //         ),
        //       ),
        //       PopupMenuItem<String>(
        //         value: 'pdf',
        //         child: Row(
        //           children: [
        //             Icon(Icons.picture_as_pdf, color: Colors.red.shade600),
        //             const SizedBox(width: 10),
        //             Text(
        //               'Ekspor ke PDF (Segera Hadir)',
        //               style: GoogleFonts.poppins(),
        //             ),
        //           ],
        //         ),
        //       ),
        //     ],
        //     icon: const Icon(Icons.download, color: Colors.white, size: 28),
        //     offset: const Offset(0, 50),
        //     shape: RoundedRectangleBorder(
        //       borderRadius: BorderRadius.circular(10),
        //     ),
        //   ),
        //   const SizedBox(width: 15),
        // ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _selectedMonth,
                    decoration: InputDecoration(
                      labelText: 'Bulan',
                      labelStyle: GoogleFonts.poppins(
                        color: Colors.blueGrey.shade600,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.blue.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.blue.shade700,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Semua Bulan')),
                      DropdownMenuItem(value: 1, child: Text('Januari')),
                      DropdownMenuItem(value: 2, child: Text('Februari')),
                      DropdownMenuItem(value: 3, child: Text('Maret')),
                      DropdownMenuItem(value: 4, child: Text('April')),
                      DropdownMenuItem(value: 5, child: Text('Mei')),
                      DropdownMenuItem(value: 6, child: Text('Juni')),
                      DropdownMenuItem(value: 7, child: Text('Juli')),
                      DropdownMenuItem(value: 8, child: Text('Agustus')),
                      DropdownMenuItem(value: 9, child: Text('September')),
                      DropdownMenuItem(value: 10, child: Text('Oktober')),
                      DropdownMenuItem(value: 11, child: Text('November')),
                      DropdownMenuItem(value: 12, child: Text('Desember')),
                    ],
                    onChanged: (newValue) {
                      setState(() {
                        _selectedMonth = newValue;
                      });
                      _fetchAbsensi();
                    },
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.blueGrey.shade900,
                    ),
                    icon: Icon(
                      Icons.arrow_drop_down_rounded,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _selectedYear,
                    decoration: InputDecoration(
                      labelText: 'Tahun',
                      labelStyle: GoogleFonts.poppins(
                        color: Colors.blueGrey.shade600,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.blue.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.blue.shade700,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Semua Tahun'),
                      ),
                      ...List.generate(
                        5, // Menampilkan tahun saat ini dan 4 tahun sebelumnya
                        (index) => DateTime.now().year - index,
                      ).map((year) {
                        return DropdownMenuItem(
                          value: year,
                          child: Text(year.toString()),
                        );
                      }).toList(),
                    ],
                    onChanged: (newValue) {
                      setState(() {
                        _selectedYear = newValue;
                      });
                      _fetchAbsensi();
                    },
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.blueGrey.shade900,
                    ),
                    icon: Icon(
                      Icons.arrow_drop_down_rounded,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: Colors.blue.shade700,
                        ),
                        const SizedBox(height: 15),
                        Text(
                          'Memuat data absensi...',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.blueGrey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 80,
                                color: Colors.red.shade400,
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Gagal memuat data:',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade700,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _errorMessage!,
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  color: Colors.red.shade500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                onPressed: _fetchAbsensi,
                                icon: const Icon(Icons.refresh),
                                label: Text(
                                  'Coba Lagi',
                                  style: GoogleFonts.poppins(),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade600,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _groupedAbsensi.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.calendar_today_outlined,
                                  size: 100,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  "Tidak ada data absensi untuk periode ini.",
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    color: Colors.grey.shade500,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  "Coba filter bulan atau tahun yang berbeda.",
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16.0),
                            itemCount: sortedDates.length,
                            itemBuilder: (context, index) {
                              final date = sortedDates[index];
                              final absensiPerMahasiswa =
                                  _groupedAbsensi[date]!;

                              return Card(
                                margin:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                elevation: 8,
                                shadowColor: Colors.blue.shade100,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: ExpansionTile(
                                  title: Text(
                                    DateFormat('EEEE, dd MMMM yyyy', 'id_ID')
                                        .format(DateTime.parse(date)),
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Colors.blue.shade800,
                                    ),
                                  ),
                                  children: absensiPerMahasiswa.keys
                                      .map((namaMahasiswa) {
                                    final dataAbsenMahasiswa =
                                        absensiPerMahasiswa[namaMahasiswa]!;
                                    final absenMasuk =
                                        dataAbsenMahasiswa['masuk'];
                                    final absenPulang =
                                        dataAbsenMahasiswa['pulang'];

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16.0, vertical: 8.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Divider(
                                              color: Colors.grey[300],
                                              thickness: 1),
                                          const SizedBox(height: 8),
                                          Text(
                                            namaMahasiswa,
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          if (absenMasuk != null)
                                            _buildAbsenEntry(absenMasuk,
                                                'Masuk', Colors.green.shade700),
                                          if (absenPulang != null)
                                            _buildAbsenEntry(
                                                absenPulang,
                                                'Pulang',
                                                Colors.orange.shade700),
                                          if (absenMasuk == null &&
                                              absenPulang == null)
                                            Text(
                                              'Tidak ada data absensi untuk mahasiswa ini pada tanggal ini.',
                                              style: GoogleFonts.poppins(
                                                  fontSize: 13,
                                                  fontStyle: FontStyle.italic,
                                                  color: Colors.grey[600]),
                                            ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  // Widget baru untuk menampilkan entri absen (masuk/pulang)
  Widget _buildAbsenEntry(AbsensiData absensi, String type, Color color) {
    String waktuAbsen = 'Tidak Diketahui';
    if (type == 'Masuk' &&
        absensi.jamMasuk != null &&
        absensi.jamMasuk!.isNotEmpty) {
      waktuAbsen = absensi.jamMasuk!.substring(0, 8); // Format HH:MM:SS
    } else if (type == 'Pulang' &&
        absensi.jamPulang != null &&
        absensi.jamPulang!.isNotEmpty) {
      waktuAbsen = absensi.jamPulang!.substring(0, 8); // Format HH:MM:SS
    }

    return Card(
      color: color.withOpacity(0.08), // Latar belakang lebih lembut
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: color.withOpacity(0.3), width: 1),
      ),
      margin: const EdgeInsets.only(bottom: 8.0),
      child: InkWell(
        onTap: () => _showDetailAbsenDialog(absensi),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Absen $type: $waktuAbsen',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: color,
                ),
              ),
              if (absensi.catatan != null && absensi.catatan!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    'Catatan: ${absensi.catatan}',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.blueGrey.shade600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              if (absensi.foto != null && absensi.foto!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    'Lihat Foto',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.blue.shade600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
