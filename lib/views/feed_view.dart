import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:flutter_flame_playground/widgets/progress_bar.dart';
import 'package:flutter_flame_playground/little%20guy.dart';
import '../models/pet_maintainment_database.dart';


class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final PetStatsDatabase _petStatsDB = PetStatsDatabase();
  final InventoryDatabase _foodDB = InventoryDatabase();

  // Dummy values will be replaced with actual values from the database
  double _hunger = 0;
  List<Map<String, dynamic>> _food = [];
  
  @override 
  void initState() {
    super.initState();
    _loadPetHunger();
  }

  Future<void> _loadPetHunger() async {
     // Assuming userId is 1 for now, will be dynamic later
    final hunger = await _petStatsDB.getPetStat(1, 'hunger_level');
    final food = await _foodDB.getFoodByUserId(1);

    setState(() {
      _hunger = hunger;
      _food = food;
    });
  }

  Future<void> _useFood(int foodId, int petId, int userId) async {
    if (_food.firstWhere((item) => item['item_id'] == foodId)['quantity'] <= 0 || _hunger >= 1.0) {
      return;
    }
    await _foodDB.useFood(foodId, userId);
    await _petStatsDB.updatePetStat(petId, 'hunger_level', _hunger+0.2); // Update pet's hunger level
    _loadPetHunger(); // Refresh data after using food
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feed'),
        backgroundColor: const Color.fromARGB(219, 150, 242, 176),
      ),
      body: Column(
        children: <Widget>[
          // Decoration for the background
          Expanded(
            flex: 1,
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.only(left: 24),
              color: Color.fromARGB(255, 213, 248, 255),
              child: Image.asset('assets/images/cloud.png')
            )
          ),
          Expanded(
            flex: 1,
            child: 
            Container(
              color: Color.fromARGB(255, 221, 249, 255),
              alignment: Alignment.centerLeft,
              child: Image.asset('assets/images/cloud.png')
            ),
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
            flex: 6,
            child: Container(
              alignment: Alignment.bottomCenter,
              color: Color.fromARGB(255, 221, 249, 255),
              child: Center(child: LittleGuy()),
            ),
          ),
          // Main content of the page
          Expanded(
            flex: 5,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              color: const Color.fromARGB(219, 150, 242, 176),
              width: MediaQuery.of(context).size.width,
              alignment: Alignment.center,
              child: 
              Column(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(219, 246, 255, 226),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ProgressBar(
                      iconPath: 'assets/images/hunger.png',
                      progress: _hunger,
                    ),
                  ),
                  const Gap(16),
                  Expanded(
                    flex: 3,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(219, 246, 255, 226),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: GridView.builder(
                        padding: const EdgeInsets.all(8),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ), 
                        itemCount: _food.length,
                        itemBuilder: (context, index) {
                          final foodItem = _food[index];
                          final foodId = foodItem['item_id'];
                          final quantity = foodItem['quantity'];
                          final foodImagePath = foodItem['image_path'];
                          return Column(
                            children: [
                              Expanded(
                                child: Stack(
                                  children: [
                                    IconButton(
                                      padding: EdgeInsets.all(8),
                                      onPressed: () => _useFood(foodId, 1, 1), // Assuming petId & userId are 1 for now, will be dynamic later
                                      icon:Image.asset(foodImagePath),
                                      iconSize: 48,
                                    ),
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Color.fromARGB(219, 150, 242, 176),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'x$quantity',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    )
                                  ]
                                )  
                              )
                            ]
                          );
                        },
                      )
                    )
                  ),
                  const Gap(16)
                ]
              ),
            ),
          ),
        ],
      )
    );
  }
}