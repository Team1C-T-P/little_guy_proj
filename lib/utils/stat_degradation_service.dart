import '../models/pet_maintainment_database.dart';

class StatDegradation {
  PetStatsDatabase petStatsDB;
  StatDegradation({required this.petStatsDB});

  Future<void> degradeStats() async {
    double hunger = await petStatsDB.getPetStat(1, 'hunger_level');
    double enjoyment = await petStatsDB.getPetStat(1, 'enjoyment_level');
    double hygiene = await petStatsDB.getPetStat(1, 'hygiene_level');
    String? lastOnlineIso = await petStatsDB.getLastOnlineByUserId(1);
    lastOnlineIso ??= DateTime.now().toUtc().toIso8601String();

    DateTime lastOnline = DateTime.parse(lastOnlineIso);
    DateTime now = DateTime.now().toUtc();

    int hoursSinceLastOnline = now.difference(lastOnline).inHours;
    double decayBy = 0.1 * (hoursSinceLastOnline / 2);
    
    hunger = hunger - decayBy;
    enjoyment = enjoyment - decayBy;
    hygiene = hygiene - decayBy;  

    await petStatsDB.updatePetStat(1, 'hunger_level', hunger);
    await petStatsDB.updatePetStat(1, 'enjoyment_level', enjoyment);
    await petStatsDB.updatePetStat(1, 'hygiene_level', hygiene);
    await petStatsDB.updateLastOnlineByUserId(1, now.toIso8601String());
  }
}