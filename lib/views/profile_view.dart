import 'package:flutter/material.dart';
// import 'package:pedometer/pedometer.dart'; // no need?
// import 'package:permission_handler/permission_handler.dart'; // why
import 'package:flutter_flame_playground/utils/step_counter.dart';
import 'package:flutter_flame_playground/models/step_points_service.dart';
import 'package:gap/gap.dart';
import 'package:flutter_flame_playground/little_guy.dart';
import 'package:flutter_flame_playground/widgets/button.dart';
import 'package:flutter_flame_playground/models/pet_maintainment_database.dart'; // use step_points_service instead?
import '../models/database.dart'; // needed to work with pet_maintainment_database, but if we switch to step_points_service then this can be removed

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileState();
}

//instead of getting data from pet_maintainment_database can we get it from step points service? - as there is a summary.
class _ProfileState extends State<ProfileScreen> {
  String _userName = "";
  String _petName = "";
  late PetStatsDatabase _db;
  final int _userId = 1; // Assuming single user per phone with ID 1

  @override
  void initState() {
    super.initState();
    AppDatabase.instance.database.then((db) {
      _db = PetStatsDatabase(db);
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final userName = await _db.getUserName(_userId);
    final petName = await _db.getPetName(_userId);

    setState(() {
      _userName = userName ?? 'Unknown';
      _petName = petName ?? 'Unknown';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 250, 255, 251),
      // appBar: AppBar(
      //   backgroundColor: const Color.fromARGB(219, 150, 242, 176),
      //   title: const Text('Profile Page'),
      // ),
      body: Column(
        children: <Widget>[
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
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color.fromARGB(219, 246, 255, 226),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    width: MediaQuery.of(context).size.width,
                    child: Column(
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: <Widget>[
                              DefaultTextStyle.merge(
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                                child: Row(
                                  children: <Widget>[
                                    Container(
                                      child: Text("$_userName | $_petName"),
                                    ),
                                    Container(child: Text(" --- ")),
                                    Container(child: Text("[Currency]")),
                                  ],
                                ),
                              ),
                              Align(
                                alignment: Alignment.topLeft,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Total Steps: "),
                                    Text("Items Collected:  "),
                                    Text("Total Friends:  "),
                                  ],
                                ),
                              ),
                              Gap(10),
                              Container(
                                child: const Text(
                                  'Achievements',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Gap(5),
                              Row(
                                children: [
                                  const Align(
                                    alignment: Alignment.topLeft,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Column(
                                          children: [
                                            const Text(
                                              "Big Walk",
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text("Walk 5K"),
                                            Text("Not completed!"),
                                          ],
                                        ),
                                        Gap(10),
                                        Column(
                                          children: [
                                            const Text(
                                              "Trail Blazer",
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text("Set-up a route"),
                                            Text("Not completed!"),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Spacer(),
                                  const Align(
                                    alignment: Alignment.topLeft,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Column(
                                          children: [
                                            const Text(
                                              "Socialite",
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text("Get 5 friends. Aww!"),
                                            Text("Not completed!"),
                                          ],
                                        ),
                                        Gap(10),
                                        Column(
                                          children: [
                                            const Text(
                                              "Mad Hatter",
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text("Get 10 Hats"),
                                            Text("Not completed!"),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Spacer(),
                                  // const Align(
                                  //   alignment: Alignment.topLeft,
                                  //   child: Column(
                                  //     crossAxisAlignment:
                                  //         CrossAxisAlignment.center,
                                  //     children: [
                                  //       Column(
                                  //         children: [
                                  //           const Text(
                                  //             "Let's Play!",
                                  //             style: TextStyle(
                                  //               fontSize: 15,
                                  //               fontWeight: FontWeight.bold,
                                  //             ),
                                  //           ),
                                  //           Text("Play 20 times"),
                                  //           Text("Not completed!"),
                                  //         ],
                                  //       ),
                                  //       Gap(10),
                                  //       Column(
                                  //         children: [
                                  //           const Text(
                                  //             "Most Valuable Pet",
                                  //             style: TextStyle(
                                  //               fontSize: 15,
                                  //               fontWeight: FontWeight.bold,
                                  //             ),
                                  //           ),
                                  //           Text("Max lvl a pet"),
                                  //           Text("Not completed!"),
                                  //         ],
                                  //       ),
                                  //     ],
                                  //   ),
                                  // ),
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
