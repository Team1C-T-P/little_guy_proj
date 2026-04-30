import 'package:flutter/material.dart';
import 'package:flutter_flame_playground/little%20guy.dart';
import '../models/dress_database.dart';
import '../models/database.dart';
import '../controller/hat_state.dart';

class DressUp extends StatefulWidget {
  const DressUp({super.key});

  @override
  State<DressUp> createState() => _DressUpState();
}

class _DressUpState extends State<DressUp> {
  // allows hat to be chosen and applied to the little guy
  int? _selectedHatId;
  String? _selectedHatImage;

  @override
  void initState() {
    super.initState();
    _loadEquippedHat();
  }

  Future<void> _loadEquippedHat() async {
    final db = await AppDatabase.instance.database;
    final dressDb = DressDatabase(db);
    final equipped = await dressDb.getEquippedHat(1);
    if (equipped != null) {
      setState(() {
        _selectedHatId = equipped['item_id'] as int;
        _selectedHatImage = equipped['image_path'] as String;
      });
    }
  }

  // moved here from StatefulWidget class
  Future<List<Map<String, dynamic>>> _loadOwnedHats() async {
    final db = await AppDatabase.instance.database;
    final dressDb = DressDatabase(db);
    return await dressDb.getHatsOwnedByUser(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(219, 150, 242, 176),
      body: Column(
        children: [
          // Top blue area containing the littleguy
          Expanded(
            flex: 3,
            child: Container(
              color: Color.fromARGB(255, 221, 249, 255),
              child: Center(child: LittleGuy()),
            ),
          ),
          // Area containing the items to choose
          Expanded(
            flex: 2,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: Color.fromARGB(219, 246, 255, 226),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _loadOwnedHats(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.data!.isEmpty) {
                      return Center(child: Text('No hats owned yet!'));
                    }
                    return GridView.builder(
                      padding: EdgeInsets.all(8),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final hat = snapshot.data![index];
                        final isSelected = _selectedHatId == hat['item_id'];
                        return IconButton(
                          padding: EdgeInsets.all(8.0),
                          style: IconButton.styleFrom(
                            backgroundColor: isSelected
                                ? Colors.green.withValues(
                                    alpha: 0.3,
                                  ) // highlight selected hat
                                : Colors
                                      .transparent, // leaves unselected transparent
                          ),
                          onPressed: () async {
                            final itemId = hat['item_id'] as int;
                            final imagePath = hat['image_path'] as String;

                            if (_selectedHatId == itemId) {
                              setState(() {
                                _selectedHatId = null;
                                _selectedHatImage = null;
                              });
                              await HatState.instance.unequipHat();
                            } else {
                              setState(() {
                                _selectedHatId = itemId;
                                _selectedHatImage = imagePath;
                              });
                              await HatState.instance.equipHat(
                                itemId,
                                imagePath,
                              );
                            }
                          },
                          icon: Image.asset(
                            hat['image_path'],
                            fit: BoxFit.cover,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
          // bottom row
          Stack(
            children: <Widget>[
              Image.asset("assets/images/clover.png"),
              Container(
                alignment: Alignment.bottomRight,
                padding: const EdgeInsets.only(right: 18),
                child: Image.asset("assets/images/daisy.png"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
