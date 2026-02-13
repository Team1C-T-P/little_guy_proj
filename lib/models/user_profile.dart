/// User profile model to store user information including pets and costumes
class UserProfile {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final List<String> pets;
  final List<String> costumes;
  final DateTime createdAt;
  final DateTime lastLogin;

  UserProfile({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    List<String>? pets,
    List<String>? costumes,
    DateTime? createdAt,
    DateTime? lastLogin,
  })  : pets = pets ?? [],
        costumes = costumes ?? [],
        createdAt = createdAt ?? DateTime.now(),
        lastLogin = lastLogin ?? DateTime.now();

  /// Create UserProfile from Firestore document
  factory UserProfile.fromMap(Map<String, dynamic> map, String uid) {
    return UserProfile(
      uid: uid,
      email: map['email'] as String,
      displayName: map['displayName'] as String?,
      photoUrl: map['photoUrl'] as String?,
      pets: List<String>.from(map['pets'] ?? []),
      costumes: List<String>.from(map['costumes'] ?? []),
      createdAt: DateTime.parse(map['createdAt'] as String),
      lastLogin: DateTime.parse(map['lastLogin'] as String),
    );
  }

  /// Convert UserProfile to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'pets': pets,
      'costumes': costumes,
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  UserProfile copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    List<String>? pets,
    List<String>? costumes,
    DateTime? createdAt,
    DateTime? lastLogin,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      pets: pets ?? this.pets,
      costumes: costumes ?? this.costumes,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }
}
