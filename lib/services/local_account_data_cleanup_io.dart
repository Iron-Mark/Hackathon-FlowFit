import 'database_service.dart';

Future<void> clearLocalDatabaseAccountData() async {
  await DatabaseService.instance.clearAllData();
}
