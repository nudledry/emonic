import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static String? getCurrentUserId() {
    final user = FirebaseAuth.instance.currentUser;
    return user?.uid;
  }

  static bool isUserAuthenticated() {
    return FirebaseAuth.instance.currentUser != null;
  }

  static bool verifyDataOwnership(
      Map<String, dynamic> data, String? currentUserId) {
    final dataUserId = data['userId'] as String?;
    return currentUserId != null &&
        dataUserId != null &&
        dataUserId == currentUserId;
  }
}
