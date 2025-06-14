import 'package:user_repository/src/models/models.dart';

abstract class UserRepository {
  Stream<MyUser?> get user;

  Future<MyUser> signUp(MyUser myUser, String password);

  Future<void> setUserData(MyUser user);

  Future<void> signIn(String email, String password);

  Future<void> logOut();

  Future<String> updateEmail(String newEmail, String password);

  Future<void> updatePassword(String currentPassword, String newPassword);

  Future<void> resetPassword(String email);
}
