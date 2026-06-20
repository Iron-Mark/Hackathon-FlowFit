import '../models/buddy_profile.dart';

const String buddyAccessoryKey = 'current_accessory';
const String buddyBackgroundKey = 'current_background';

String? currentBuddyAccessory(Map<String, dynamic>? accessories) {
  return _readString(accessories, buddyAccessoryKey) ??
      _readString(accessories, 'accessory');
}

String? currentBuddyBackground(Map<String, dynamic>? accessories) {
  return _readString(accessories, buddyBackgroundKey) ??
      _readString(accessories, 'background');
}

String normalizeBuddyAccessorySelection(
  Map<String, dynamic>? accessories,
  Iterable<String> allowedKeys, {
  String fallback = 'none',
}) {
  final current = currentBuddyAccessory(accessories);
  if (current != null && allowedKeys.contains(current)) {
    return current;
  }
  return fallback;
}

String? normalizeBuddyBackgroundSelection(
  Map<String, dynamic>? accessories,
  Iterable<String> allowedKeys,
) {
  final current = currentBuddyBackground(accessories);
  if (current != null && allowedKeys.contains(current)) {
    return current;
  }
  return null;
}

String? validateBuddyCustomizationName(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return 'Buddy name must be 1-20 characters.';
  }
  if (trimmed.length > 20) {
    return 'Buddy name must be 20 characters or fewer.';
  }
  return null;
}

Map<String, dynamic> buildBuddyCustomizationUpdates({
  required BuddyProfile profile,
  required String nameInput,
  String? selectedColor,
  String? selectedAccessory,
  String? selectedBackground,
  required DateTime updatedAt,
}) {
  final nameError = validateBuddyCustomizationName(nameInput);
  if (nameError != null) {
    throw ArgumentError(nameError);
  }

  final accessories = Map<String, dynamic>.from(profile.accessories ?? {});
  if (selectedAccessory != null) {
    accessories[buddyAccessoryKey] = selectedAccessory;
  } else {
    accessories.remove(buddyAccessoryKey);
  }
  accessories.remove('accessory');

  if (selectedBackground != null) {
    accessories[buddyBackgroundKey] = selectedBackground;
  } else {
    accessories.remove(buddyBackgroundKey);
  }
  accessories.remove('background');

  final updates = <String, dynamic>{
    'name': nameInput.trim(),
    'color': selectedColor ?? profile.color,
    'updated_at': updatedAt.toIso8601String(),
  };

  if (accessories.isNotEmpty) {
    updates['accessories'] = accessories;
  }

  return updates;
}

String? _readString(Map<String, dynamic>? map, String key) {
  final value = map?[key];
  if (value is String && value.trim().isNotEmpty) {
    return value;
  }
  return null;
}
