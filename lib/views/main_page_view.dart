import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:flutter_flame_playground/little%20guy.dart';
import 'package:flutter_flame_playground/widgets/button.dart';
import 'package:flutter_flame_playground/widgets/progress_bar.dart';
import 'feed_view.dart';
import 'clean_view.dart';
import 'play_view.dart';
import '../models/pet_maintainment_database.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PetStatsDatabase _petStatsDB = PetStatsDatabase();
  
  // Dummy values will be replaced with actual values from the database
  double _hunger = 0;
  double _enjoyment = 0;
  double _hygiene = 0;

  @override
  void initState() {
    super.initState();
    _loadPetStats();
  }

  Future<void> _loadPetStats() async {
    // load pet stats, assuming petId is 1 for now, will be dynamic later

    double hunger = await _petStatsDB.getPetStat(1, 'hunger_level');
    double enjoyment = await _petStatsDB.getPetStat(1, 'enjoyment_level');
    double hygiene = await _petStatsDB.getPetStat(1, 'hygiene_level');
    String? lastOnlineIso = await _petStatsDB.getLastOnlineByUserId(1);
    lastOnlineIso ??= DateTime.now().toUtc().toIso8601String();

    // convert lastOnlineIso to DateTime
    DateTime lastOnline = DateTime.parse(lastOnlineIso);
    DateTime now = DateTime.now().toUtc();

    // Calculate hours since last online
    int hoursSinceLastOnline = now.difference(lastOnline).inHours;

    // Decrease stats by 10% per 2 hours since last online
    double decayBy = 0.1 * (hoursSinceLastOnline / 2);

    hunger = hunger - decayBy > 0 ? hunger - decayBy : 0;
    enjoyment = enjoyment - decayBy > 0 ? enjoyment - decayBy : 0;
    hygiene = hygiene - decayBy > 0 ? hygiene - decayBy : 0;

    // Update the database with decayed stats and new last online time
    await _petStatsDB.updatePetStat(1, 'hunger_level', hunger);
    await _petStatsDB.updatePetStat(1, 'enjoyment_level', enjoyment);
    await _petStatsDB.updatePetStat(1, 'hygiene_level', hygiene);
    await _petStatsDB.updateLastOnlineByUserId(1, now.toIso8601String());

    setState(() {
      _hunger = hunger;
      _enjoyment = enjoyment;
      _hygiene = hygiene;
    });

    print('Pet stats loaded and decayed based on last online time. Hunger: $_hunger, Enjoyment: $_enjoyment, Hygiene: $_hygiene');
  }

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
                              ProgressBar(
                                iconPath: 'assets/images/hunger.png',
                                progress: _hunger
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
                                  ProgressBar(
                                    iconPath: 'assets/images/enjoyment.png',
                                    progress: _enjoyment
                                  ),
                                ],
                              ),
                              Gap(MediaQuery.of(context).size.width * 0.1),
                              // Hygiene Progress Bar
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  ProgressBar(
                                    iconPath: 'assets/images/hygiene.png',
                                    progress: _hygiene
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
