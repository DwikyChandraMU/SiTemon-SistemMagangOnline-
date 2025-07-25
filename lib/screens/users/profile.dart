import 'package:sitemon/screens/users/home_screen_users.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';

// Import other screens for the bottom navigation bar
import 'package:sitemon/screens/login_screen.dart';
import 'package:sitemon/screens/users/absen_screen.dart';
import 'package:sitemon/screens/users/penugasan.dart';
import 'package:sitemon/screens/users/sertifikat.dart';
// import 'package:sitemon/screens/users/pendaftaran_magang.dart'; // Jika tidak digunakan, bisa dihapus

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic> profileData = {}; // Stores fetched profile data
  bool isLoading = true; // Controls loading indicator display
  int? userId; // Stores the user ID retrieved from SharedPreferences

  @override
  void initState() {
    super.initState();
    // Loads user ID and then fetches profile data when the widget initializes
    _loadUserIdAndFetchProfile();
  }

  // --- Data Loading Functions ---

  // Loads the user ID from SharedPreferences
  Future<void> _loadUserIdAndFetchProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? id = prefs.getInt('user_id'); // Get the user_id
    print('User ID loaded from SharedPreferences: $id'); // Debug print

    if (id != null) {
      userId = id;
      await _fetchProfileData(id); // Fetch profile data if ID is found
    } else {
      print('User ID is not available'); // Debug print if ID is missing
      setState(() {
        isLoading = false; // Stop loading if no user ID
      });
      // Optionally, you could redirect to login here if user ID is missing
      // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
    }
  }

  // Fetches profile data from the PHP API
  Future<void> _fetchProfileData(int id) async {
    // IMPORTANT: Replace with your actual server IP address
    final url =
        'http://192.168.50.189/sitemon_api/users/profile.php?user_id=$id';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {"Accept": "application/json"}, // Expect JSON response
      );

      if (response.statusCode == 200) {
        // Decode the JSON response body
        final jsonData = json.decode(response.body);
        print('Profile Data: $jsonData'); // Debug print the received data

        if (jsonData != null && jsonData is Map<String, dynamic>) {
          setState(() {
            profileData = jsonData; // Update state with fetched data
            isLoading = false; // Stop loading
          });
        } else {
          // Handle invalid JSON response (e.g., not a map)
          setState(() {
            isLoading = false;
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Data profile tidak valid')));
        }
      } else {
        // Handle server errors (non-200 status code)
        print(
          'Server Error: ${response.statusCode}',
        ); // Debug print server error
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengambil data profile dari server')),
        );
      }
    } catch (e) {
      // Handle network or parsing errors
      print('Error: $e'); // Debug print any caught errors
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
    }
  }

  // --- User Actions ---

  // Handles user logout by clearing SharedPreferences and navigating to LoginScreen
  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id'); // Remove user_id to log out

    // Navigate to LoginScreen and clear all previous routes
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (route) => false, // Remove all routes until the new one
    );
  }

  // --- UI Building ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Background lebih soft
      appBar: AppBar(
        // AppBar dikembalikan
        title: Text(
          "PROFILE",
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF2196F3), // Biru lebih terang
                Color(0xFF0D47A1), // Biru lebih gelap
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0, // Hilangkan shadow di bawah AppBar
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 30),
                  // Bagian Foto dan Nama Utama
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.blue.shade500,
                    child: Icon(Icons.person, size: 60, color: Colors.white),
                  ),
                  SizedBox(height: 16),
                  Text(
                    profileData['nama_lengkap'] ?? 'NAMA MAHASISWA MAGANG',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    profileData['jurusan'] ?? 'JURUSAN',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: 30),
                  // Detail Informasi dalam bentuk Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoRow(
                              Icons.person_outline,
                              'Nama Lengkap',
                              profileData['nama_lengkap'] ?? '-',
                            ),
                            Divider(
                              height: 20,
                              thickness: 1,
                              color: Colors.grey[200],
                            ), // Pembatas
                            _buildInfoRow(
                              Icons.business_center_outlined,
                              'Instansi',
                              profileData['instansi'] ?? '-',
                            ),
                            Divider(
                              height: 20,
                              thickness: 1,
                              color: Colors.grey[200],
                            ), // Pembatas
                            _buildInfoRow(
                              Icons.calendar_today_outlined,
                              'Periode',
                              profileData['periode'] ?? '-',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 30),
                  // Tombol Logout
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ElevatedButton.icon(
                      onPressed: _logout,
                      icon: Icon(Icons.logout, size: 24),
                      label: Text(
                        'Keluar',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Colors.redAccent, // Warna merah yang menarik
                        foregroundColor: Colors.white,
                        minimumSize: Size(double.infinity, 50), // Lebar penuh
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 5,
                      ),
                    ),
                  ),
                  SizedBox(height: 40),
                ],
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.blue,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.black,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        currentIndex: 4,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HomeScreenUsers()),
              );
              break;
            case 1:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AbsenPage()),
              );
              break;
            case 2:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TugasPage()),
              );
              break;
            case 3:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SertifikatPage()),
              );
              break;
            case 4:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfilePage()),
              );
              break;
          }
        },
        items: [
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

  // Helper widget to build consistent info rows with icons
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5), // Padding disesuaikan
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Colors.blue.shade700,
            size: 22,
          ), // Warna icon lebih gelap, ukuran sedikit kecil
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 13, // Ukuran label lebih kecil
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 2), // Jarak antar label dan value
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
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
