import 'package:emonic/helpers/database_helper.dart';
import 'package:emonic/models/usage_model.dart';
import 'package:emonic/services/auth_service.dart';

class DailyUsageService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<Map<String, dynamic>?> getActiveTarget() async {
    final userId = AuthService.getCurrentUserId();
    if (userId == null) return null;

    final activeTarget = await _dbHelper.getActiveTarget();

    if (activeTarget != null &&
        AuthService.verifyDataOwnership(activeTarget, userId)) {
      return activeTarget;
    }

    return null;
  }

  Future<void> saveDailyUsage(UsageModel usage) async {
    final userId = AuthService.getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    if (!AuthService.verifyDataOwnership(usage.toMap(), userId)) {
      throw Exception('Data ownership verification failed');
    }

    await _dbHelper.insertDailyUsage(usage.toMap());
  }
}
