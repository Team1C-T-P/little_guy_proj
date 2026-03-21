import 'package:flutter/material.dart';
import 'models/database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'views/main_page_view.dart';
import 'views/settings_view.dart';
import 'views/shop_view.dart';
import 'views/dress_view.dart';
import 'views/map_view.dart';
import 'views/test_view.dart';
import 'views/community_view.dart';
import 'views/profile_view.dart';
import 'package:pedometer/pedometer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Ensure the database is initialized before running the app
  await AppDatabase.instance.database;
  // Initialize default data if necessary
  await AppDatabase.instance.initializeDefaultData();

  await _debugPrintDatabase();

  runApp(const MyApp());
}

Future<void> _debugPrintDatabase() async {
  final db = await AppDatabase.instance.database;

  // Print users
  final users = await db.query('user');
  print('=== USERS ===');
  print(users);

  // Print little guys
  final littleGuys = await db.query('little_guy');
  print('=== LITTLE GUYS ===');
  print(littleGuys);

  // Print items
  final items = await db.query('item');
  print('=== ITEMS ===');
  print(items);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flittle Guy',
      theme: ThemeData(
        scaffoldBackgroundColor: Color.fromARGB(255, 213, 248, 255),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        textTheme: GoogleFonts.juaTextTheme(),
      ),
      home: const MyHomePage(title: 'FLittle Guy'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    HomeScreen(),
    MapScreen(),
    DressUp(),
    Shop(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        backgroundColor: const Color.fromARGB(255, 213, 248, 255),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report), // Icon for the button
            tooltip: 'Test Screen',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TestScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.diversity_1), // Icon for the button
            tooltip: 'Community',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CommunityScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person), // Icon for the button
            tooltip: 'Profile',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: const Color.fromARGB(219, 150, 242, 176),
        selectedItemColor: const Color.fromARGB(255, 77, 151, 86),
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.spa),
            label: 'Little Guy',
            backgroundColor: const Color.fromARGB(219, 150, 242, 176),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
            backgroundColor: const Color.fromARGB(219, 150, 242, 176),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.checkroom),
            label: 'Dress',
            backgroundColor: const Color.fromARGB(219, 150, 242, 176),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.tag),
            label: 'Shop',
            backgroundColor: const Color.fromARGB(219, 150, 242, 176),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
            backgroundColor: const Color.fromARGB(219, 150, 242, 176),
          ),
        ],
      ),
    );
  }
}
