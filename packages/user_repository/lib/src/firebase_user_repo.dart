import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/transformers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:user_repository/user_repository.dart';

class FirebaseUserRepo implements UserRepository {
  final FirebaseAuth _firebaseAuth;
  final usersCollection = FirebaseFirestore.instance.collection('user');

  FirebaseUserRepo({
    FirebaseAuth? firebaseAuth,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  @override
  Stream<MyUser?> get user {
    return _firebaseAuth.authStateChanges().flatMap((firebaseUser) async* {
      log('AuthStateChanges triggered: ${firebaseUser?.uid}'); // Tambahkan log ini
      if (firebaseUser == null) {
        log('No Firebase user, yielding MyUser.empty');
        yield MyUser.empty;
      } else {
        try {
          log('Fetching user document for uid: ${firebaseUser.uid}');
          final doc = await usersCollection.doc(firebaseUser.uid).get();
          if (doc.exists && doc.data() != null) {
            log('User document found, creating MyUser');
            final myUser =
                MyUser.fromEntity(MyUserEntity.fromDocument(doc.data()!));
            log('MyUser created: ${myUser.toString()}');
            yield myUser;
          } else {
            log('User document not found, yielding MyUser.empty');
            yield MyUser.empty;
          }
        } catch (e) {
          log('Error fetching user data: $e');
          yield MyUser.empty;
        }
      }
    });
  }

  @override
  Future<void> signIn(String email, String password) async {
    try {
      log('Attempting to sign in with email: $email');
      final result = await _firebaseAuth.signInWithEmailAndPassword(
          email: email, password: password);
      log('Sign in successful, uid: ${result.user?.uid}');

      final userDoc = await usersCollection.doc(result.user!.uid).get();
      if (!userDoc.exists) {
        log('Creating user document for uid: ${result.user!.uid}');
        await usersCollection.doc(result.user!.uid).set({
          'userId': result.user!.uid,
          'email': email,
          'name': result.user!.displayName ?? '',
        });
      }
    } catch (e) {
      log('Sign in failed: ${e.toString()}');
      rethrow;
    }
  }

  @override
  Future<MyUser> signUp(MyUser myUser, String password) async {
    try {
      UserCredential user = await _firebaseAuth.createUserWithEmailAndPassword(
          email: myUser.email, password: password);

      myUser.userId = user.user!.uid;
      return myUser;
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }

  @override
  Future<void> logOut() async {
    await _firebaseAuth.signOut();
  }

  @override
  Future<void> setUserData(MyUser myUser) async {
    try {
      await usersCollection
          .doc(myUser.userId)
          .set(myUser.toEntity().toDocument());
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }

  @override
  Future<String> updateEmail(String newEmail, String password) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      // Re-authenticate user first
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);

      // Store user ID for later use
      final userId = user.uid;

      // Send verification email to new address
      await user.verifyBeforeUpdateEmail(newEmail);

      // Create a subscription to monitor email changes
      late final subscription;
      subscription =
          _firebaseAuth.userChanges().listen((User? updatedUser) async {
        if (updatedUser != null && updatedUser.email == newEmail) {
          try {
            // Update Firestore
            await usersCollection.doc(userId).update({
              'email': newEmail,
            });
            log('Firestore email updated successfully');
          } catch (e) {
            log('Error updating Firestore: ${e.toString()}');
          } finally {
            // Cancel subscription after update
            subscription.cancel();
          }
        }
      });

      return 'Verification email sent. Please check your email to complete the process.';
    } catch (e) {
      log('Error updating email: ${e.toString()}');
      throw Exception('Failed to update email: ${e.toString()}');
    }
  }

  @override
  Future<void> updatePassword(
      String currentPassword, String newPassword) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      // Re-authenticate user first
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);
    } catch (e) {
      log('Error updating password: ${e.toString()}');
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'wrong-password':
            throw Exception('Current password is incorrect');
          case 'weak-password':
            throw Exception('New password is too weak');
          default:
            throw Exception('Failed to update password: ${e.message}');
        }
      }
      throw Exception('Failed to update password');
    }
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      log('Password reset email sent to $email');
    } catch (e) {
      log('Error sending password reset email: ${e.toString()}');
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'user-not-found':
            throw Exception('No user found with this email address');
          case 'invalid-email':
            throw Exception('Invalid email address');
          default:
            throw Exception('Failed to send reset email: ${e.message}');
        }
      }
      throw Exception('Failed to send password reset email');
    }
  }
}
