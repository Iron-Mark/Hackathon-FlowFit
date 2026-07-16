import 'package:flowfit/services/storage/database_service.dart';

Future<void> clearLocalDatabaseAccountData() async {
  await DatabaseService.instance.clearAllData();
}
