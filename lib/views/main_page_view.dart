import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:flutter_flame_playground/little%20guy.dart';
import 'package:flutter_flame_playground/widgets/button.dart';
import 'package:flutter_flame_playground/controller/step_goal_controller.dart';

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
  final StepGoalController controller = StepGoalController();
  int stepGoal = 0;
  int totalSteps = 0;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final goal = await controller.loadGoal();
    final steps = await controller.loadTotalSteps();

    setState(() {
      stepGoal = goal;
      totalSteps = steps;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 24),
            child: Image.asset('assets/images/cloud.png'),
            color: Color.fromARGB(255, 213, 248, 255),
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
                
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Column(
                    children: <Widget>[

                      Row(
                        children: [

                          SizedBox(
                            width: 120,
                            height: 40,
                            child: FittedBox(
                              child: GreenButton(
                                buttonText: "+250",
                                onPressed: () async {
                                  final newGoal = stepGoal + 250;
                                  await controller.updateGoal(newGoal);

                                  setState(() {
                                    stepGoal = newGoal;
                                  });
                                },
                              ),
                            ),
                          ),

                          SizedBox(
                            width: 120,
                            height: 40,
                            child: FittedBox(
                              child: GreenButton(
                                buttonText: "-250",
                                onPressed: () async {
                                  final newGoal = (stepGoal - 250).clamp(0, 999999);
                                  await controller.updateGoal(newGoal);

                                  setState(() {
                                    stepGoal = newGoal;
                                  });
                                },
                              ),
                            ),
                          ),

                          Spacer(),

                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "Today's Goal",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                "$totalSteps / $stepGoal steps",
                                style: TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),

                          SizedBox(width: 18),
                        ],
                      ),
                    ],
                  ),
                ),

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
                            setState(() {
                              hunger = incrementBar(hunger);
                            });
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
                              setState(() {
                                enjoyment = incrementBar(enjoyment);
                              });
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
                              setState(() {
                                hygiene = incrementBar(hygiene);
                              });
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
