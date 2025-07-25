import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

// Model Data Pengguna
class UserData {
  final int id;
  String username;
  String email;
  String role;
  String? namaLengkap;
  String? noHp;
  String? instansi;
  String? jurusan;

  UserData({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    this.namaLengkap,
    this.noHp,
    this.instansi,
    this.jurusan,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: int.parse(json['user_id'].toString()),
      username: json['username'] ?? 'N/A',
      email: json['email'] ?? 'N/A',
      role: json['role'] ?? 'user',
      namaLengkap: json['nama_lengkap'],
      noHp: json['no_hp'],
      instansi: json['instansi'],
      jurusan: json['jurusan'],
    );
  }
}

// Halaman Manajemen Pengguna
class ManajemenPenggunaPage extends StatefulWidget {
  @override
  _ManajemenPenggunaPageState createState() => _ManajemenPenggunaPageState();
}

class _ManajemenPenggunaPageState extends State<ManajemenPenggunaPage> {
  List<UserData> _users = [];
  bool _isLoading = true;
  String? _errorMessage;

  final String _baseUrl =
      'http://192.168.50.189/sitemon_api/admin/manajemen_pengguna';

  // Controllers for dialogs
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _namaLengkapController = TextEditingController();
  String _selectedRole = 'user'; // Default role

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _namaLengkapController.dispose();
    super.dispose();
  }

  // --- Fungsi API Calls ---
  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.get(Uri.parse('$_baseUrl/get_users.php'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _users = data.map((json) => UserData.fromJson(json)).toList();
        });
      } else {
        throw Exception(
          'Gagal memuat pengguna: ${response.statusCode}. ${response.body.isNotEmpty ? 'Detail: ${response.body}' : ''}',
        );
      }
    } on FormatException catch (e) {
      setState(() {
        _errorMessage =
            'Kesalahan format data: ${e.message}. Pastikan server mengembalikan JSON valid.';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Terjadi kesalahan: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addUser() async {
    if (_usernameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _namaLengkapController.text.isEmpty) {
      _showSnackBar('Harap isi semua kolom!', Colors.orange);
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/add_users.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': _usernameController.text,
          'email': _emailController.text,
          'password': _passwordController.text,
          'role': _selectedRole,
          'nama_lengkap': _namaLengkapController.text,
        }),
      );

      final responseBody = json.decode(response.body);

      if (responseBody['status'] == 'success') {
        _showSnackBar(responseBody['message'], Colors.green);
        Navigator.of(context).pop();
        _fetchUsers();
      } else {
        _showSnackBar(
          'Gagal menambah pengguna: ${responseBody['message']}',
          Colors.red,
        );
      }
    } on FormatException catch (e) {
      _showSnackBar('Error format data dari server. Debug: $e', Colors.red);
    } catch (e) {
      _showSnackBar('Error menambah pengguna: $e', Colors.red);
    }
  }

  Future<void> _editUser(int userId) async {
    if (_usernameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _namaLengkapController.text.isEmpty) {
      _showSnackBar('Harap isi semua kolom!', Colors.orange);
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/edit_users.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'username': _usernameController.text,
          'email': _emailController.text,
          'role': _selectedRole,
          'nama_lengkap': _namaLengkapController.text,
        }),
      );

      final responseBody = json.decode(response.body);

      if (responseBody['status'] == 'success') {
        _showSnackBar(responseBody['message'], Colors.green);
        Navigator.of(context).pop();
        _fetchUsers();
      } else {
        _showSnackBar(
          'Gagal mengedit pengguna: ${responseBody['message']}',
          Colors.red,
        );
      }
    } on FormatException catch (e) {
      _showSnackBar('Error format data dari server. Debug: $e', Colors.red);
    } catch (e) {
      _showSnackBar('Error mengedit pengguna: $e', Colors.red);
    }
  }

  Future<void> _deleteUser(int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/delete_users.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'user_id': userId}),
      );

      final responseBody = json.decode(response.body);

      if (responseBody['status'] == 'success') {
        _showSnackBar(responseBody['message'], Colors.green);
        _fetchUsers();
      } else {
        _showSnackBar(
          'Gagal menghapus pengguna: ${responseBody['message']}',
          Colors.red,
        );
      }
    } on FormatException catch (e) {
      _showSnackBar('Error format data dari server. Debug: $e', Colors.red);
    } catch (e) {
      _showSnackBar('Error menghapus pengguna: $e', Colors.red);
    }
  }

  Future<void> _resetPassword(int userId, String newPassword) async {
    if (newPassword.isEmpty) {
      _showSnackBar('Password baru tidak boleh kosong!', Colors.orange);
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/reset_password.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'user_id': userId, 'new_password': newPassword}),
      );

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        if (responseBody['status'] == 'success') {
          _showSnackBar(responseBody['message'], Colors.green);
        } else {
          _showSnackBar(
            'Gagal reset password: ${responseBody['message'] ?? 'Respon tidak sesuai.'}',
            Colors.red,
          );
        }
      } else {
        String errorMessage =
            'Error server: ${response.statusCode} ${response.reasonPhrase ?? 'Unknown Error'}';
        if (response.body.isNotEmpty) {
          errorMessage += '\nDetail: ${response.body}';
        }
        _showSnackBar(errorMessage, Colors.red);
      }
    } on FormatException catch (e) {
      _showSnackBar(
        'Error: Respon server bukan JSON valid. Debug: $e',
        Colors.red,
      );
    } catch (e) {
      _showSnackBar('Error reset password: ${e.toString()}', Colors.red);
    }
  }

  // --- Utility Functions ---
  void _showSnackBar(String message, [Color? color]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: color ?? Colors.blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  // --- Dialogs for Add/Edit/Reset ---
  void _showAddEditUserDialog({UserData? user}) {
    _usernameController.clear();
    _emailController.clear();
    _passwordController.clear();
    _namaLengkapController.clear();
    _selectedRole = 'user'; // Reset to default

    bool isEditing = user != null;
    if (isEditing) {
      _usernameController.text = user.username;
      _emailController.text = user.email;
      _namaLengkapController.text = user.namaLengkap ?? '';
      _selectedRole = user.role;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                isEditing ? 'Edit Pengguna' : 'Tambah Pengguna Baru',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTextField(
                      _namaLengkapController,
                      'Nama Lengkap',
                      Icons.person,
                    ),
                    const SizedBox(height: 10),
                    _buildTextField(
                      _usernameController,
                      'Username',
                      Icons.alternate_email,
                    ),
                    const SizedBox(height: 10),
                    _buildTextField(
                      _emailController,
                      'Email',
                      Icons.email,
                      TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 10),
                    if (!isEditing)
                      _buildTextField(
                        _passwordController,
                        'Password',
                        Icons.lock,
                        null,
                        true,
                      ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: _selectedRole,
                      decoration: _inputDecoration(
                        'Role',
                        Icons.supervised_user_circle,
                      ),
                      items: <String>[
                        'user',
                        'pembimbing',
                        'admin',
                      ].map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value.toUpperCase(),
                            style: GoogleFonts.poppins(),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setStateDialog(() {
                          _selectedRole = newValue!;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actionsPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                    textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (isEditing) {
                      _editUser(user!.id);
                    } else {
                      _addUser();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  child: Text(isEditing ? 'Update' : 'Tambah'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showResetPasswordDialog(int userId) {
    _passwordController.clear();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Atur Ulang Password',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade800,
            ),
          ),
          content: _buildTextField(
            _passwordController,
            'Password Baru',
            Icons.lock,
            null,
            true,
          ),
          actionsPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 10,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade700,
                textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_passwordController.text.isNotEmpty) {
                  _resetPassword(userId, _passwordController.text);
                  Navigator.of(context).pop();
                } else {
                  _showSnackBar(
                    'Password baru tidak boleh kosong.',
                    Colors.orange,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              child: const Text('Set Password'),
            ),
          ],
        );
      },
    );
  }

  // Helper untuk TextField dengan gaya konsisten
  InputDecoration _inputDecoration(String labelText, IconData iconData) {
    return InputDecoration(
      labelText: labelText,
      prefixIcon: Icon(iconData, color: Colors.blue.shade600),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.blue.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.blue.shade300, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
      ),
      labelStyle: GoogleFonts.poppins(color: Colors.grey.shade700),
      floatingLabelStyle: GoogleFonts.poppins(color: Colors.blue.shade700),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, [
    TextInputType? keyboardType,
    bool obscureText = false,
  ]) {
    return TextField(
      controller: controller,
      decoration: _inputDecoration(label, icon),
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: GoogleFonts.poppins(color: Colors.black87),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Manajemen Pengguna',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue.shade700,
        elevation: 4,
        toolbarHeight: 80,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditUserDialog(),
        label: Text(
          'Tambah Pengguna',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        icon: const Icon(Icons.person_add_alt_1),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 6,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(30.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cloud_off,
                          color: Colors.red.shade400,
                          size: 80,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Oops, ada masalah koneksi!',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            color: Colors.red.shade700,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '$_errorMessage\n\nPastikan Anda terhubung ke internet dan server aktif.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 30),
                        ElevatedButton.icon(
                          onPressed: _fetchUsers,
                          icon: const Icon(Icons.refresh),
                          label: Text(
                            'Coba Lagi',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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
                        ),
                      ],
                    ),
                  ),
                )
              : _users.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons
                                .group_off_outlined, // Icon yang lebih informatif untuk 'no users'
                            size: 90,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 25),
                          Text(
                            "Belum ada pengguna terdaftar.",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Ketuk tombol '+' di bawah untuk menambahkan pengguna baru.",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _users.length,
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 10.0),
                          elevation: 6,
                          shadowColor: Colors.blue.shade100,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: InkWell(
                            onTap: () => _showAddEditUserDialog(
                                user: user), // Edit on tap
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 25,
                                        backgroundColor: Colors.blue.shade100,
                                        child: Icon(
                                          Icons.person,
                                          color: Colors.blue.shade800,
                                          size: 30,
                                        ),
                                      ),
                                      const SizedBox(width: 15),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              user.namaLengkap ?? user.username,
                                              style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 20,
                                                color: Colors.blue.shade900,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              user.email,
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                color: Colors.grey.shade700,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: user.role == 'admin'
                                              ? Colors.purple.shade100
                                              : user.role == 'pembimbing'
                                                  ? Colors.green.shade100
                                                  : Colors.blue.shade100,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          user.role.toUpperCase(),
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: user.role == 'admin'
                                                ? Colors.purple.shade800
                                                : user.role == 'pembimbing'
                                                    ? Colors.green.shade800
                                                    : Colors.blue.shade800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 15),
                                  // Detail tambahan (optional)
                                  if (user.noHp != null &&
                                      user.noHp!.isNotEmpty)
                                    _buildDetailRow(Icons.phone, user.noHp!),
                                  if (user.instansi != null &&
                                      user.instansi!.isNotEmpty)
                                    _buildDetailRow(
                                        Icons.business, user.instansi!),
                                  if (user.jurusan != null &&
                                      user.jurusan!.isNotEmpty)
                                    _buildDetailRow(
                                        Icons.school, user.jurusan!),
                                  const Divider(
                                    height: 25,
                                    thickness: 1,
                                    color: Colors.grey,
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Tooltip(
                                        message: 'Reset Password',
                                        child: IconButton(
                                          icon: Icon(
                                            Icons.key_outlined,
                                            color: Colors.orange.shade600,
                                            size: 26,
                                          ),
                                          onPressed: () =>
                                              _showResetPasswordDialog(user.id),
                                        ),
                                      ),
                                      Tooltip(
                                        message: 'Hapus Pengguna',
                                        child: IconButton(
                                          icon: Icon(
                                            Icons.delete_forever,
                                            color: Colors.red.shade600,
                                            size: 26,
                                          ),
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (ctx) => AlertDialog(
                                                title: Text(
                                                  'Konfirmasi Hapus',
                                                  style: GoogleFonts.poppins(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                content: Text(
                                                  'Anda yakin ingin menghapus ${user.namaLengkap ?? user.username}?',
                                                  style: GoogleFonts.poppins(),
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(ctx),
                                                    child: Text(
                                                      'Batal',
                                                      style:
                                                          GoogleFonts.poppins(),
                                                    ),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () {
                                                      _deleteUser(user.id);
                                                      Navigator.pop(ctx);
                                                    },
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          Colors.red.shade600,
                                                      foregroundColor:
                                                          Colors.white,
                                                    ),
                                                    child: Text(
                                                      'Hapus',
                                                      style:
                                                          GoogleFonts.poppins(),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }

  // Helper widget untuk baris detail
  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade500),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey.shade800,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
