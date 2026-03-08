import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'views/main_page_view.dart';
import 'views/settings_view.dart';
import 'views/main_page_view.dart';
import 'little guy.dart';
import 'views/shop_view.dart';
import 'views/dress_view.dart';
import 'views/map_view.dart';
import 'views/test_view.dart';
import 'package:pedometer/pedometer.dart';

void main() {
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
        backgroundColor: const Color.fromARGB(255, 221, 249, 255),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report), // Icon for the button
            tooltip: 'Go to Test Screen',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TestScreen()),
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
} // kill me

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Map'));
  }
}

class DressUp extends StatelessWidget {
  const DressUp({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          const LittleGuy(),
          // Gives twice the space between Middle and End than Begin and Middle.
          Spacer(flex: 2),
          Container(
            color: Color.fromARGB(219, 173, 230, 189),
            child: Column(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    color: Color.fromARGB(219, 246, 255, 226),
                    width: MediaQuery.of(context).size.width,
                    height: 250,

                    child: ListView(
                      children: [
                        Gap(20),
                        Row(
                          children: [
                            Gap(39),
                            Image.asset('images/hat.png'),
                            Gap(39),
                            Image.asset('images/hat.png'),
                            Gap(39),
                            Image.asset('images/hat.png'),
                            Gap(39),
                            Image.asset('images/hat.png'),
                            Gap(39),
                          ],
                        ),
                        Gap(20),
                        Row(
                          children: [
                            Gap(39),
                            Image.asset('images/hat.png'),
                            Gap(39),
                            Image.asset('images/hat.png'),
                            Gap(39),
                            Image.asset('images/hat.png'),
                            Gap(39),
                            Image.asset('images/hat.png'),
                            Gap(39),
                          ],
                        ),
                        Gap(20),
                        Row(
                          children: [
                            Gap(39),
                            Image.asset('images/hat.png'),
                            Gap(39),
                            Image.asset('images/hat.png'),
                            Gap(39),
                            Image.asset('images/hat.png'),
                            Gap(39),
                            Image.asset('images/hat.png'),
                            Gap(39),
                          ],
                        ),
                        Gap(20),
                        Row(
                          children: [
                            Gap(39),
                            Image.asset('images/hat.png'),
                            Gap(39),
                            Image.asset('images/hat.png'),
                            Gap(39),
                            Image.asset('images/hat.png'),
                            Gap(39),
                            Image.asset('images/hat.png'),
                            Gap(39),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Stack(
                  children: <Widget>[
                    Container(child: Image.asset("images/clover.png")),
                    SizedBox(
                      width: MediaQuery.of(context).size.width,
                      child: SizedBox(
                        width: 10,
                        height: 100,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: FittedBox(
                            child: TempButton(buttonText: "Shop"),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      alignment: Alignment.bottomRight,
                      padding: const EdgeInsets.only(right: 18),
                      child: Image.asset("images/daisy.png"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Since settings_screen.dart is imported, we can use the SettingsScreen widget in the _screens list in _MyHomePageState.
