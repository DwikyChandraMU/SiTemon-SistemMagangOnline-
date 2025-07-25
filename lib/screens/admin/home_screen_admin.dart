import 'package:sitemon/screens/admin/backup_keamanan.dart';
import 'package:sitemon/screens/admin/manajemen_konten.dart';
import 'package:sitemon/screens/admin/manajemen_pembimbing.dart';
import 'package:sitemon/screens/admin/atur_bimbingan.dart';
import 'package:sitemon/screens/admin/manajemen_pengguna.dart';
import 'package:sitemon/screens/admin/manajemen_sertifikat.dart';
import 'package:sitemon/screens/admin/monitoring_absensi.dart';
import 'package:sitemon/screens/admin/profile_admin.dart';
import 'package:sitemon/screens/admin/verifikasi_pengajuan_magang.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Main screen for the Admin Dashboard
class HomeScreenAdmin extends StatefulWidget {
  @override
  _HomeScreenAdminState createState() => _HomeScreenAdminState();
}

class _HomeScreenAdminState extends State<HomeScreenAdmin> {
  // State variables for statistics and error messages
  int totalUser = 0;
  int totalPembimbing = 0;
  int totalPengajuan = 0;
  int absenHarian = 0;
  String? errorMessage;
  int _selectedIndex = 0; // To manage the selected tab in BottomNavigationBar

  // Initialize state and fetch statistics when the widget is created
  @override
  void initState() {
    super.initState();
    fetchStatistik();
  }

  // Asynchronous function to fetch statistics from the API
  Future<void> fetchStatistik() async {
    setState(() {
      errorMessage = null; // Clear previous error messages on retry
    });
    try {
      final response = await http.get(
        Uri.parse(
          'http://192.168.50.189/sitemon_api/admin/home_screen/statistik.php',
        ),
      );

      if (response.statusCode == 200) {
        print("Response body: ${response.body}"); // Log response for debugging
        final data = json.decode(response.body);

        // Check for 'error' key in the response JSON
        if (data['error'] != null) {
          setState(() {
            errorMessage = data['error']; // Set error message if present
          });
        } else {
          // Update state with fetched data
          setState(() {
            totalUser = data['totalUser'];
            totalPembimbing = data['totalPembimbing'];
            totalPengajuan = data['totalPengajuan'];
            absenHarian = data['absenHarian'];
            errorMessage = null; // Clear error if data is successfully loaded
          });
        }
      } else {
        // Handle non-200 status codes
        throw Exception('Failed to load statistics: ${response.statusCode}');
      }
    } catch (e) {
      // Catch any errors during the HTTP request or JSON decoding
      print('Error fetching statistics: $e');
      setState(() {
        errorMessage =
            'Gagal memuat data. Mohon periksa koneksi Anda.'; // User-friendly error message
      });
    }
  }

  // Widget to build individual statistic cards
  Widget _buildStatCard(
    String label,
    int value,
    IconData icon,
    VoidCallback onTap,
    Color iconColor,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
      elevation: 0, // Use BoxShadow instead of default elevation
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ), // More rounded corners
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          // Adding a subtle shadow for a modern look
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 2,
                blurRadius: 10,
                offset: const Offset(0, 5), // Changes position of shadow
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(
                    14,
                  ), // Slightly larger padding for icon
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(
                      0.18,
                    ), // Slightly darker opacity
                    borderRadius: BorderRadius.circular(
                      12,
                    ), // More rounded icon background
                  ),
                  child: Icon(
                    icon,
                    size: 38,
                    color: iconColor,
                  ), // Slightly larger icon
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors
                              .grey[600], // Slightly lighter grey for label
                        ),
                      ),
                      const SizedBox(height: 8), // Increased spacing
                      Text(
                        value.toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 32, // Larger font size for value
                          fontWeight: FontWeight.bold,
                          color: Colors
                              .blue.shade800, // Stronger blue for emphasis
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 22,
                  color: Colors.grey,
                ), // Slightly larger arrow
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Function to handle BottomNavigationBar item taps
  void _onItemTapped(int index) {
    // Only navigate if the tapped index is different from the current one
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });

      Widget nextPage;
      switch (index) {
        case 0:
          nextPage = HomeScreenAdmin();
          break;
        case 1:
          nextPage =
              AturBimbinganPage(); // Renamed from ManajemenPembimbing as per icon below
          break;
        case 2:
          nextPage =
              ManajemenPenggunaPage(); // This maps to "Manage User" as per new labels
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Colors.grey[100], // Even lighter background for a more modern feel
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blue.shade700,
                Colors.blue.shade400,
              ], // Slightly adjusted blue shades
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              // Add a subtle shadow to the app bar
              BoxShadow(
                color: Colors.blue.shade900.withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
        title: Text(
          "ADMIN DASHBOARD",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing:
                1.5, // Increased letter spacing for better readability
          ),
        ),
        centerTitle: true,
        elevation: 0,
        toolbarHeight: 40.0,
      ),
      body: errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons
                          .cloud_off_outlined, // More descriptive icon for connection error
                      color: Colors.redAccent,
                      size: 70, // Larger icon
                    ),
                    const SizedBox(height: 20), // Increased spacing
                    Text(
                      errorMessage!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        color:
                            Colors.red.shade700, // Darker red for error message
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 25), // Increased spacing
                    ElevatedButton.icon(
                      onPressed: fetchStatistik,
                      icon: const Icon(
                        Icons.refresh,
                        size: 24,
                      ), // Larger icon for button
                      label: Text(
                        "Coba Lagi", // Changed to Indonesian
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Colors.blue.shade700, // Darker blue for button
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            12,
                          ), // More rounded button
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 25, // Increased horizontal padding
                          vertical: 14, // Increased vertical padding
                        ),
                        elevation: 5, // Add subtle elevation
                      ),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildStatCard(
                    'Total Pengguna', // Changed to Indonesian
                    totalUser,
                    Icons.group_outlined, // More fitting icon for total users
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ManajemenPenggunaPage(),
                        ),
                      );
                    },
                    Colors.deepPurple.shade600, // Darker shade of purple
                  ),
                  _buildStatCard(
                    'Total Pembimbing', // Changed to Indonesian
                    totalPembimbing,
                    Icons
                        .supervisor_account_outlined, // More specific icon for mentors
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ManajemenPembimbingPage(),
                        ),
                      );
                    },
                    Colors.teal.shade600, // Darker shade of teal
                  ),
                  _buildStatCard(
                    'Pengajuan Magang', // Changed to Indonesian
                    totalPengajuan,
                    Icons
                        .description_outlined, // More fitting icon for applications
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VerifikasiPengajuanPage(),
                        ),
                      );
                    },
                    Colors.orange.shade700, // Darker shade of orange
                  ),
                  _buildStatCard(
                    'Absensi Hari Ini', // Changed to Indonesian
                    absenHarian,
                    Icons
                        .checklist_rtl_outlined, // More specific icon for attendance
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MonitoringAbsensiPage(),
                        ),
                      );
                    },
                    Colors.redAccent.shade700, // Darker shade of red
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.blue,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.black,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        currentIndex: 0, // Set current index
        onTap: (index) {
          // Hanya navigasi jika index yang dipilih berbeda dari halaman saat ini
          if (index != 0) {
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
}
