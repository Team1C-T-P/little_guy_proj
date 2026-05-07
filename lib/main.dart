import 'package:flutter/material.dart';
import 'models/database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'views/header.dart';
import 'views/main_page_view.dart';
import 'views/shop_view.dart';
import 'views/dress_view.dart';
import 'views/map_view.dart';
import 'views/nav_bar.dart';
import 'views/profile_view.dart';
import 'package:pedometer/pedometer.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Ensure the database is initialized before running the app
  await AppDatabase.instance.database;
  // Initialize default data if necessary
  await AppDatabase.instance.initializeDefaultData();
  runApp(const MyApp());
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
    ProfileScreen(),
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
      appBar: const MainHeader(),
      body: _screens[_currentIndex],
      bottomNavigationBar: MainNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
