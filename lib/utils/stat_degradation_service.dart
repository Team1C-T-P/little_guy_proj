import 'package:flutter_flame_playground/models/pet_maintainment_database.dart';

class StatDegradation {
  PetStatsDatabase petStatsDB;
  int userID;
  int petID;
  StatDegradation({required this.petStatsDB, required this.userID, required this.petID});

  Future<void> degradeStats() async {
    double hunger = await petStatsDB.getPetStat(petID, 'hunger_level');
    double enjoyment = await petStatsDB.getPetStat(petID, 'enjoyment_level');
    double hygiene = await petStatsDB.getPetStat(petID, 'hygiene_level');
    String? lastOnlineIso = await petStatsDB.getLastOnlineByUserId(userID);
    lastOnlineIso ??= DateTime.now().toUtc().toIso8601String();

    DateTime lastOnline = DateTime.parse(lastOnlineIso);
    DateTime now = DateTime.now().toUtc();

    int hoursSinceLastOnline = now.difference(lastOnline).inHours;
    double decayBy = 0.1 * (hoursSinceLastOnline / 2);
    
    hunger = hunger - decayBy;
    enjoyment = enjoyment - decayBy;
    hygiene = hygiene - decayBy;  

    await petStatsDB.updatePetStat(petID, 'hunger_level', hunger);
    await petStatsDB.updatePetStat(petID, 'enjoyment_level', enjoyment);
    await petStatsDB.updatePetStat(petID, 'hygiene_level', hygiene);
    await petStatsDB.updateLastOnlineByUserId(userID, now.toIso8601String());
  }
}