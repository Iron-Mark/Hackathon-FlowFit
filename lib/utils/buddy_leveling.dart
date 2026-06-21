/// Buddy Leveling System
class BuddyLeveling {
  static int xpForLevel(int level) => level * 100;

  static String getStageName(int level) {
    if (level <= 5) return 'Baby';
    if (level <= 10) return 'Kid';
    if (level <= 20) return 'Teen';
    if (level <= 30) return 'Super';
    return 'Mega';
  }

  static double getStageSize(int level) {
    if (level <= 5) return 0.7;
    if (level <= 10) return 1.0;
    if (level <= 20) return 1.3;
    if (level <= 30) return 1.5;
    return 1.7;
  }
}
