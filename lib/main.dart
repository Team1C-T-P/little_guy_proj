import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'views/settings_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flittle Guy',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        textTheme: GoogleFonts.juaTextTheme(),
      ),
      home: const MyHomePage(title: 'FLittle Guy'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    HomeScreen(),
    ProfileScreen(),
    DressUp(),
    Shop(),
    SettingsScreen(),
  ];

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
    });

    void testWow() {
      child:
      Text('Hello World');
    }
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
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

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Home Screen'));
  }
}

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
          Text('Little Guy location here'),
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
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(
                                  255,
                                  159,
                                  239,
                                  167,
                                ),
                              ),
                              child: Text(
                                "Shop",
                                style: DefaultTextStyle.of(
                                  context,
                                ).style.apply(fontSizeFactor: 1),
                              ),
                              onPressed: () {
                                Shop();
                              },
                            ),
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

class Shop extends StatelessWidget {
  const Shop({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Shop'));
  }
}

// Since settings_screen.dart is imported, we can use the SettingsScreen widget in the _screens list in _MyHomePageState.
