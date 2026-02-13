import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';

/// Authentication service handling Google Sign-In and user profile management
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream of authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Sign in with Google
  Future<UserProfile?> signInWithGoogle() async {
    try {
      // Trigger the Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // User canceled the sign-in
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        // Create or update user profile in Firestore
        return await _createOrUpdateUserProfile(user);
      }

      return null;
    } catch (e) {
      print('Error signing in with Google: $e');
      return null;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  /// Create or update user profile in Firestore
  Future<UserProfile> _createOrUpdateUserProfile(User user) async {
    final docRef = _firestore.collection('users').doc(user.uid);
    final doc = await docRef.get();

    if (doc.exists) {
      // User exists, update last login
      final profile = UserProfile.fromMap(doc.data()!, user.uid);
      final updatedProfile = profile.copyWith(lastLogin: DateTime.now());
      await docRef.update({'lastLogin': updatedProfile.lastLogin.toIso8601String()});
      return updatedProfile;
    } else {
      // New user, create profile
      final profile = UserProfile(
        uid: user.uid,
        email: user.email!,
        displayName: user.displayName,
        photoUrl: user.photoURL,
      );
      await docRef.set(profile.toMap());
      return profile;
    }
  }

  /// Get user profile from Firestore
  Future<UserProfile?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserProfile.fromMap(doc.data()!, uid);
      }
      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  /// Update user profile (pets, costumes, etc.)
  Future<void> updateUserProfile(UserProfile profile) async {
    try {
      await _firestore.collection('users').doc(profile.uid).update(profile.toMap());
    } catch (e) {
      print('Error updating user profile: $e');
    }
  }

  /// Add pet to user profile
  Future<void> addPet(String uid, String petName) async {
    try {
      final profile = await getUserProfile(uid);
      if (profile != null) {
        final updatedPets = [...profile.pets, petName];
        await _firestore.collection('users').doc(uid).update({
          'pets': updatedPets,
        });
      }
    } catch (e) {
      print('Error adding pet: $e');
    }
  }

  /// Add costume to user profile
  Future<void> addCostume(String uid, String costumeName) async {
    try {
      final profile = await getUserProfile(uid);
      if (profile != null) {
        final updatedCostumes = [...profile.costumes, costumeName];
        await _firestore.collection('users').doc(uid).update({
          'costumes': updatedCostumes,
        });
      }
    } catch (e) {
      print('Error adding costume: $e');
    }
  }
}
