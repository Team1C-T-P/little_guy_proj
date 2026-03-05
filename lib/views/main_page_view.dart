import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

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
          children: <Widget> [
            Container(
              color: Color.fromARGB(255, 221, 249, 255),
              width: MediaQuery.of(context).size.width,
              child: Column(
                children: <Widget>[
                  Text('main page'),
                ],
              ),
            ),
            Spacer(),
            Container(
              color: Color.fromARGB(219, 173, 230, 189),
              width: MediaQuery.of(context).size.width,
              child: Column(
                children: <Widget>[
                  Row(
                    children: [
                        Image.asset('images/clover.png'),
                        Spacer(),
                        SizedBox(
                          width: 150,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 159, 239, 167),
                          ),
                          onPressed: () {
                            // temp to increment until backend integration
                            setState(() {
                              hunger = incrementBar(hunger);
                            });
                          },
                          child: Text(
                                "Feed",
                                style: DefaultTextStyle.of(
                                  context,
                                ).style.apply(fontSizeFactor: 1),
                          )
                        )
                      ),
                      Spacer(),
                      Image.asset('images/daisy.png')
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Row(
                      children: <Widget> [
                        Spacer(),
                        SizedBox(
                            width: 150,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(255, 159, 239, 167),
                              ),
                              onPressed: () {
                                // temp to increment until backend integration
                                setState(() {
                                  enjoyment = incrementBar(enjoyment);
                                });
                              },
                              child: Text(
                                    "Play",
                                    style: DefaultTextStyle.of(
                                      context,
                                    ).style.apply(fontSizeFactor: 1),
                              )
                            )
                        ),
                        Spacer(),
                        SizedBox(
                            width: 150,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(255, 159, 239, 167),
                              ),
                              onPressed: () {
                                // temp to increment until backend integration
                                setState(() {
                                  hygiene = incrementBar(hygiene);
                                });
                              },
                              child: Text(
                                    "Clean",
                                    style: DefaultTextStyle.of(
                                      context,
                                    ).style.apply(fontSizeFactor: 1),
                              )
                            )
                        ),
                        Spacer(),
                      ]
                    )
                  ),
                  Padding(
                    padding:  const EdgeInsets.all(20),
                    child: Container(
                      color: Color.fromARGB(219, 246, 255, 226),
                      width: MediaQuery.of(context).size.width,
                      height: 150,
                      child: Column(
                        children: <Widget> [
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            // Hunger Progress Bar
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget> [
                                Image.asset('images/hunger.png'),
                                SizedBox(
                                  width: 100,
                                  child: LinearProgressIndicator(
                                    value: hunger.toDouble() / 100,
                                    backgroundColor: Color.fromARGB(255, 246, 255, 226),
                                    color: Color.fromARGB(255, 159, 239, 167),
                                  )
                                )
                              ]
                            )
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget> [
                                // Enjoyment Progress Bar
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget> [
                                    Image.asset('images/enjoyment.png'),
                                    SizedBox(
                                      width: 100,
                                      child: LinearProgressIndicator(
                                        value: enjoyment.toDouble() / 100,
                                        backgroundColor: Color.fromARGB(255, 246, 255, 226),
                                        color: Color.fromARGB(255, 159, 239, 167),
                                      )
                                    )
                                  ]
                                ),
                                Gap(MediaQuery.of(context).size.width * 0.1),
                                // Hygiene Progress Bar
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget> [
                                    Image.asset('images/hygiene.png'),
                                    SizedBox(
                                      width: 100,
                                      child: LinearProgressIndicator(
                                        value: hygiene.toDouble() / 100,
                                        backgroundColor: Color.fromARGB(255, 246, 255, 226),
                                        color: Color.fromARGB(255, 159, 239, 167),
                                      )
                                    )
                                  ]
                                )
                              ]
                            )
                          )
                        ]
                      )
                    )
                  )
                ]
              ),
            )
          ]
      )
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
