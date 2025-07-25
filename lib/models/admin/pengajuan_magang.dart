class PengajuanMagang {
  final String id;
  final String userId;
  final String nama;
  final String kategori;
  final String tanggalMulai;
  final String tanggalSelesai;
  final String lama;
  final String bidang;
  final String status;
  final String catatan;

  PengajuanMagang({
    required this.id,
    required this.userId,
    required this.nama,
    required this.kategori,
    required this.tanggalMulai,
    required this.tanggalSelesai,
    required this.lama,
    required this.bidang,
    required this.status,
    required this.catatan,
  });

  factory PengajuanMagang.fromJson(Map<String, dynamic> json) {
    return PengajuanMagang(
      id: json['id'].toString(),
      userId: json['user_id'].toString(),
      nama: json['nama'],
      kategori: json['kategori_kegiatan'],
      tanggalMulai: json['tanggal_mulai'],
      tanggalSelesai: json['tanggal_selesai'],
      lama: json['lama_magang'],
      bidang: json['bidang'],
      status: json['status'],
      catatan: json['catatan'] ?? '',
    );
  }
}
