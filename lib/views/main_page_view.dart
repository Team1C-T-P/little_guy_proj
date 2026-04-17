import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:flutter_flame_playground/little%20guy.dart';
import 'package:flutter_flame_playground/widgets/button.dart';
import 'feed_view.dart';
import 'clean_view.dart';
import 'play_view.dart';

// Dummy values for the progress bars - will need to be replaced with actual values later on
int hunger = 50;
int enjoyment = 50;
int hygiene = 50;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 24),
            color: Color.fromARGB(255, 213, 248, 255),
            child: Image.asset('assets/images/cloud.png')
          ),
          Expanded(
            flex: 1,
            child: Container(
              color: Color.fromARGB(255, 221, 249, 255),
              alignment: Alignment.centerRight,
              child: Image.asset('assets/images/cloud.png')
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              color: Color.fromARGB(255, 221, 249, 255),
              alignment: Alignment.center,
              child: Image.asset('assets/images/cloud.png')
            ),
          ),
          Expanded(
            flex: 10,
            child: Container(
              alignment: Alignment.bottomCenter,
              color: Color.fromARGB(255, 221, 249, 255),
              child: Center(child: LittleGuy()),
            ),
          ),
          Container(
            color: Color.fromARGB(219, 150, 242, 176),
            width: MediaQuery.of(context).size.width,

            child: Column(
              children: <Widget>[
                Row(
                  children: [
                    Image.asset('assets/images/clover.png'),
                    Spacer(),

                    SizedBox(
                      width: 150,
                      height: 50,
                      child: FittedBox(
                        child: GreenButton(
                          buttonText: "Feed",
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const FeedScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    Spacer(),
                    Container(
                      alignment: Alignment.bottomRight,
                      padding: const EdgeInsets.only(right: 18),
                      child: Image.asset('assets/images/flowerplant.png'),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Row(
                    children: <Widget>[
                      Spacer(),
                      SizedBox(
                        width: 150,
                        height: 50,
                        child: FittedBox(
                          child: GreenButton(
                            buttonText: "Play",
                            onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const PlayScreen(),
                              ),
                            );
                          },
                          ),
                        ),
                      ),
                      Spacer(),
                      SizedBox(
                        width: 150,
                        height: 50,
                        child: FittedBox(
                          child: GreenButton(
                            buttonText: "Clean",
                            onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const CleanScreen(),
                              ),
                            );
                          },
                          ),
                        ),
                      ),
                      Spacer(),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color.fromARGB(219, 246, 255, 226),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    width: MediaQuery.of(context).size.width,
                    height: 120,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(top: 0),
                          // Hunger Progress Bar
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              SizedBox(
                                width: 40,
                                height: 40,
                                child: Image.asset('assets/images/hunger.png'),
                              ),
                              SizedBox(
                                width: 100,
                                child: LinearProgressIndicator(
                                  minHeight: 10,
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(10),
                                  ),
                                  value: hunger.toDouble() / 100,
                                  backgroundColor: Color.fromARGB(
                                    255,
                                    246,
                                    255,
                                    226,
                                  ),
                                  color: Color.fromARGB(255, 159, 239, 167),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              // Enjoyment Progress Bar
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  SizedBox(
                                    width: 40,
                                    height: 40,
                                    child: Image.asset(
                                      'assets/images/enjoyment.png',
                                    ),
                                  ),
                                  SizedBox(
                                    width: 100,
                                    child: LinearProgressIndicator(
                                      minHeight: 10,
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(10),
                                      ),
                                      value: enjoyment.toDouble() / 100,
                                      backgroundColor: Color.fromARGB(
                                        255,
                                        248,
                                        255,
                                        233,
                                      ),
                                      color: Color.fromARGB(255, 159, 239, 167),
                                    ),
                                  ),
                                ],
                              ),
                              Gap(MediaQuery.of(context).size.width * 0.1),
                              // Hygiene Progress Bar
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  SizedBox(
                                    width: 40,
                                    height: 40,
                                    child: Image.asset(
                                      'assets/images/hygiene.png',
                                    ),
                                  ),
                                  SizedBox(
                                    width: 100,
                                    child: LinearProgressIndicator(
                                      minHeight: 10,
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(10),
                                      ),
                                      value: hygiene.toDouble() / 100,
                                      backgroundColor: Color.fromARGB(
                                        255,
                                        246,
                                        255,
                                        226,
                                      ),
                                      color: Color.fromARGB(255, 159, 239, 167),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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

// Dummy function to increment progress bars on button press, will be removed with backend integration
int incrementBar(int value) {
  if (value >= 100) {
    return 0;
  }
  return value + 10;
}
