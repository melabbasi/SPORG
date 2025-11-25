import 'dart:convert'; // لحل مشكلة json
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http; // لحل مشكلة http
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

// ==========================================
// 1. MODELS
// ==========================================

class Member {
  final String id;
  final String name;
  final String team;
  final String imageLink;
  final String additionalInfo;

  // حقول الحضور
  bool isPresent;
  String? roleInSession; // Organizer, Trainer, etc.

  Member({
    required this.id,
    required this.name,
    required this.team,
    required this.imageLink,
    required this.additionalInfo,
    this.isPresent = false,
    this.roleInSession,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'].toString(),
      name: json['name'] ?? 'Unknown',
      team: json['team'] ?? 'General',
      imageLink: json['image_link'] ?? '',
      additionalInfo: json['additional_info'] ?? '',
    );
  }

  String get firstName => name.split(' ')[0].toLowerCase();
}

// ==========================================
// 2. PROVIDER (THE BRAIN)
// ==========================================

class AppProvider extends ChangeNotifier {
  List<Member> _allMembers = [];
  List<Member> _filteredMembers = [];

  List<Member> get members => _filteredMembers;

  // بيانات الإيفنت
  String eventName = "";
  String sessionName = "";
  String sessionDate = "";
  String sessionPlace = "";

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // الأدمن
  final Map<String, String> _admins = {
    'elabbasi': 'Elabbasi100@SPORG',
    'shrouk_hr': 'SPORG@admin',
    'bakr_hr': 'SPORG@admin',
    'spot_sg': 'SPORG@sg@admin',
    'owner': 'SPORG@owner',
  };

  // --- دالة جلب البيانات من GitHub ---
  Future<void> fetchMembers() async {
    _isLoading = true;
    notifyListeners();

    // ⚠️ استبدل الرابط ده بالرابط بتاعك من GitHub (Raw URL)
    const String url = "https://raw.githubusercontent.com/melabbasi/SPORG.data/refs/heads/main/members.json";

    try {
      // محاولة الجلب من النت
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        _allMembers = data.map((e) => Member.fromJson(e)).toList();
      } else {
        print("Failed to load data, status: ${response.statusCode}");
        // لو فشل، حمل داتا وهمية عشان البرنامج ما يوقفش
        _loadMockData();
      }
    } catch (e) {
      print("Error or No Internet: $e");
      // لو مفيش نت، حمل داتا وهمية
      _loadMockData();
    } finally {
      _filteredMembers = List.from(_allMembers);
      _isLoading = false;
      notifyListeners();
    }
  }

  void _loadMockData() {
    // داتا احتياطية لو مفيش نت
    _allMembers = [
      Member(id: "001", name: "Mohamed El-Abbasi", team: "Computer", imageLink: "", additionalInfo: "Vice Moderator"),
      Member(id: "002", name: "Test Member", team: "HR", imageLink: "", additionalInfo: "Member"),
    ];
  }

  // --- دالة تسجيل الدخول (حل مشكلة login undefined) ---
  bool login(String username, String password) {
    // 1. هل هو أدمن؟
    if (_admins.containsKey(username) && _admins[username] == password) {
      return true;
    }
    // 2. هل هو يوزر عادي؟
    try {
      final member = _allMembers.firstWhere(
            (m) => m.firstName == username.toLowerCase() && m.id == password,
      );
      return true; // Login success for user too
    } catch (e) {
      return false;
    }
  }

  // --- دالة البحث ---
  void search(String query) {
    if (query.isEmpty) {
      _filteredMembers = List.from(_allMembers);
    } else {
      _filteredMembers = _allMembers.where((m) {
        return m.name.toLowerCase().contains(query.toLowerCase()) ||
            m.id.contains(query) ||
            m.team.toLowerCase().contains(query.toLowerCase());
      }).toList();
    }
    notifyListeners();
  }

  // --- دالة تسجيل الحضور ---
  void markAttendance(String id, String role) {
    int index = _allMembers.indexWhere((m) => m.id == id);
    if (index != -1) {
      _allMembers[index].isPresent = true;
      _allMembers[index].roleInSession = role;

      // تحديث القائمة المفلترة
      int filteredIndex = _filteredMembers.indexWhere((m) => m.id == id);
      if (filteredIndex != -1) {
        _filteredMembers[filteredIndex].isPresent = true;
        _filteredMembers[filteredIndex].roleInSession = role;
      }
      notifyListeners();
    }
  }

  // --- دالة التصدير للإكسيل ---
  Future<void> exportToExcel(BuildContext context) async {
    List<List<dynamic>> rows = [];
    rows.add(["ID", "Name", "Role", "Session", "Event", "Date", "Place"]); // Header

    List<Member> attendees = _allMembers.where((m) => m.isPresent).toList();

    for (var m in attendees) {
      rows.add([
        m.id,
        m.name,
        m.roleInSession,
        sessionName,
        eventName,
        sessionDate,
        sessionPlace
      ]);
    }

    String csvData = const ListToCsvConverter().convert(rows);
    final directory = await getTemporaryDirectory();
    final path = "${directory.path}/SPORG_Attendance_${DateTime.now().millisecondsSinceEpoch}.csv";
    final file = File(path);
    await file.writeAsString(csvData);
    await Share.shareXFiles([XFile(path)], text: 'SPORG Attendance: $sessionName');
  }
}

// ==========================================
// 3. UI IMPLEMENTATION
// ==========================================

void main() {
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AppProvider())],
      child: const SporgApp(),
    ),
  );
}

class SporgApp extends StatelessWidget {
  const SporgApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SPORG',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        primaryColor: const Color(0xFFFF9800),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF9800),
          secondary: Color(0xFFFFEB3B),
          surface: Color(0xFF1E1E1E),
        ),
        textTheme: GoogleFonts.cairoTextTheme(ThemeData.dark().textTheme),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

// --- Splash Screen ---
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Provider.of<AppProvider>(context, listen: false).fetchMembers().then((_) {
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.qr_code_2, size: 80, color: Color(0xFFFF9800)),
            SizedBox(height: 20),
            Text("SPORG", style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            CircularProgressIndicator(color: Color(0xFFFFEB3B)),
          ],
        ),
      ),
    );
  }
}

// --- Login Screen ---
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  void _login() {
    bool success = Provider.of<AppProvider>(context, listen: false)
        .login(_userCtrl.text.trim(), _passCtrl.text.trim());

    if (success) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const EventSetupScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("بيانات خاطئة"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.security, size: 60, color: Color(0xFFFF9800)),
            const SizedBox(height: 20),
            TextField(controller: _userCtrl, decoration: const InputDecoration(labelText: "User Name", border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: _passCtrl, obscureText: true, decoration: const InputDecoration(labelText: "Password", border: OutlineInputBorder())),
            const SizedBox(height: 20),
            SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF9800), foregroundColor: Colors.black),
                    onPressed: _login, child: const Text("LOGIN")
                )
            )
          ],
        ),
      ),
    );
  }
}

// --- Event Setup Screen ---
class EventSetupScreen extends StatefulWidget {
  const EventSetupScreen({super.key});
  @override
  State<EventSetupScreen> createState() => _EventSetupScreenState();
}

class _EventSetupScreenState extends State<EventSetupScreen> {
  final _eventCtrl = TextEditingController();
  final _sessionCtrl = TextEditingController();
  final _placeCtrl = TextEditingController();
  final _dateCtrl = TextEditingController(text: DateFormat('yyyy-MM-dd').format(DateTime.now()));

  void _start() {
    if (_eventCtrl.text.isEmpty || _sessionCtrl.text.isEmpty || _placeCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("املأ كل البيانات يا دكتور")));
      return;
    }
    final prov = Provider.of<AppProvider>(context, listen: false);
    prov.eventName = _eventCtrl.text;
    prov.sessionName = _sessionCtrl.text;
    prov.sessionPlace = _placeCtrl.text;
    prov.sessionDate = _dateCtrl.text;

    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AttendanceScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("بيانات الإيفنت"), backgroundColor: Colors.black),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildField("Event Name", _eventCtrl, Icons.event),
            _buildField("Session Name", _sessionCtrl, Icons.class_),
            _buildField("Place", _placeCtrl, Icons.location_on),
            InkWell(
              onTap: () async {
                DateTime? picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
                if (picked != null) {
                  _dateCtrl.text = DateFormat('yyyy-MM-dd').format(picked);
                }
              },
              child: IgnorePointer(child: _buildField("Date", _dateCtrl, Icons.calendar_today)),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFEB3B), foregroundColor: Colors.black),
                onPressed: _start,
                child: const Text("ابدأ الحضور", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextField(
        controller: ctrl,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFFFF9800)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: const Color(0xFF1E1E1E),
        ),
      ),
    );
  }
}

// --- Attendance Screen ---
class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});
  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final _searchCtrl = TextEditingController();

  void _showRoleDialog(BuildContext context, Member member) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: Text("تسجيل: ${member.name}", style: const TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("اختر الدور (Role) في السيشن:", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 15),
              _roleBtn(ctx, member.id, "Organizer"),
              _roleBtn(ctx, member.id, "Trainer"),
              _roleBtn(ctx, member.id, "Co-trainer"),
              _roleBtn(ctx, member.id, "Facilitator"),
              _roleBtn(ctx, member.id, "Participant"),
            ],
          ),
        );
      },
    );
  }

  Widget _roleBtn(BuildContext ctx, String id, String role) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFFFEB3B)),
        onPressed: () {
          Provider.of<AppProvider>(context, listen: false).markAttendance(id, role);
          Navigator.pop(ctx);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$role: تم تسجيل الحضور"), backgroundColor: Colors.green));
        },
        child: Text(role),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: TextField(
          controller: _searchCtrl,
          onChanged: (val) => provider.search(val),
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "بحث بالاسم أو ID...",
            hintStyle: TextStyle(color: Colors.grey),
            border: InputBorder.none,
            icon: Icon(Icons.search, color: Color(0xFFFF9800)),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file, color: Colors.green),
            onPressed: () => provider.exportToExcel(context),
            tooltip: "تصدير Excel",
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: const Color(0xFF1E1E1E),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Session: ${provider.sessionName}", style: const TextStyle(color: Color(0xFFFFEB3B))),
                Text("Count: ${provider.members.where((m)=>m.isPresent).length}", style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
              itemCount: provider.members.length,
              itemBuilder: (ctx, i) {
                final member = provider.members[i];
                return Card(
                  color: member.isPresent ? const Color(0xFF2E7D32) : const Color(0xFF1E1E1E),
                  child: ListTile(
                    leading: CircleAvatar(child: Text(member.id)),
                    title: Text(member.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(member.isPresent ? "Role: ${member.roleInSession}" : member.team),
                    trailing: member.isPresent
                        ? const Icon(Icons.check, color: Colors.white)
                        : IconButton(
                      icon: const Icon(Icons.add_circle, color: Color(0xFFFF9800)),
                      onPressed: () => _showRoleDialog(context, member),
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
        // استبدل الـ floatingActionButton القديم بده:
        floatingActionButton: FloatingActionButton(
          backgroundColor: const Color(0xFFFF9800),
          child: const Icon(Icons.qr_code_scanner, color: Colors.black),
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => QRScannerScreen(onDetect: (code) {
              try {
                // 1. تنظيف الكود من أي مسافات زيادة في الأول والآخر
                String rawCode = code.trim();
                String id = "";

                // 2. محاولة استخراج الـ ID بذكاء (سواء فيه مسافات أو لا)
                if (rawCode.contains('-')) {
                  // لو الشكل: 21028 - Mohamed أو 21028-Mohamed
                  id = rawCode.split('-')[0].trim();
                } else {
                  // لو الشكل: 21028 Mohamed (مسافة بس)
                  id = rawCode.split(' ')[0].trim();
                }

                // 3. البحث عن العضو
                // بنستخدم try/catch هنا عشان لو ملقاش العضو نعرف السبب
                var mem = provider.members.firstWhere(
                        (m) => m.id.toString().trim() == id,
                    orElse: () => Member(id: "", name: "", team: "", imageLink: "", additionalInfo: "")
                );

                if(mem.id.isNotEmpty) {
                  Navigator.pop(context); // اقفل الكاميرا
                  _showRoleDialog(context, mem); // اظهر الحضور
                } else {
                  // 4. رسالة خطأ توضيحية (Debugging)
                  // عشان تعرف هو قرأ الـ ID كام بالظبط وهل هو موجود في الليستة ولا لأ
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("ID: $id غير موجود في القائمة! (عدد الأعضاء المحملين: ${provider.members.length})"),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 3),
                      )
                  );
                }
              } catch(e) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("خطأ في قراءة الـ QR")));
              }
            })));
          },
        ),
    );
  }
}

// --- QR Scanner Screen ---
class QRScannerScreen extends StatefulWidget {
  final Function(String) onDetect;
  const QRScannerScreen({super.key, required this.onDetect});
  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  bool processed = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan QR")),
      body: MobileScanner(
        onDetect: (capture) {
          if (!processed && capture.barcodes.isNotEmpty && capture.barcodes.first.rawValue != null) {
            processed = true;
            widget.onDetect(capture.barcodes.first.rawValue!);
          }
        },
      ),
    );
  }
}
