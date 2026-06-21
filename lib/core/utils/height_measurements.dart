class FeetInches {
  const FeetInches({required this.feet, required this.inches});

  final int feet;
  final int inches;

  int get totalInches => feet * 12 + inches;

  double get totalInchesDouble => totalInches.toDouble();

  String get displayLabel => '$feet ft $inches in';

  String get inputLabel => '$feet.$inches';
}

FeetInches? tryParseFeetInchesInput(String? input) {
  final normalized = input?.trim();
  if (normalized == null || normalized.isEmpty) return null;

  final compact = normalized
      .toLowerCase()
      .replaceAll('feet', 'ft')
      .replaceAll('foot', 'ft')
      .replaceAll('inches', 'in')
      .replaceAll('inch', 'in')
      .replaceAll('"', ' in')
      .replaceAll("'", ' ft ');

  final feetInchesMatch = RegExp(
    r'^(\d+)\s*(?:ft|\s)\s*(\d{1,2})(?:\s*in)?$',
  ).firstMatch(compact);
  if (feetInchesMatch != null) {
    return _feetInchesOrNull(
      int.parse(feetInchesMatch.group(1)!),
      int.parse(feetInchesMatch.group(2)!),
    );
  }

  final decimalParts = normalized.split('.');
  if (decimalParts.length == 2 && decimalParts[1].isNotEmpty) {
    final feet = int.tryParse(decimalParts[0]);
    final inches = int.tryParse(decimalParts[1]);
    if (feet != null && inches != null) {
      return _feetInchesOrNull(feet, inches);
    }
  }

  final feetOnly = int.tryParse(normalized);
  if (feetOnly != null) {
    return _feetInchesOrNull(feetOnly, 0);
  }

  return null;
}

double? parseHeightForStorage(String input, String unit) {
  if (unit != 'ft') return double.tryParse(input.trim());

  final feetInches = tryParseFeetInchesInput(input);
  return feetInches?.totalInchesDouble;
}

String formatHeightMeasurement(
  double value,
  String unit, {
  String? rawHeightInput,
}) {
  if (unit == 'ft') {
    return feetInchesFromHeightValue(
      value,
      rawHeightInput: rawHeightInput,
    ).displayLabel;
  }

  final displayValue = value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
  return '$displayValue$unit';
}

double heightInCentimeters(
  double height,
  String unit, {
  String? rawHeightInput,
}) {
  if (unit != 'ft') return height;

  return feetInchesFromHeightValue(
        height,
        rawHeightInput: rawHeightInput,
      ).totalInches *
      2.54;
}

FeetInches feetInchesFromHeightValue(double height, {String? rawHeightInput}) {
  final fromRawInput = tryParseFeetInchesInput(rawHeightInput);
  if (fromRawInput != null) return fromRawInput;

  if (height >= 12) {
    return _fromTotalInches(height.round());
  }

  final fromLegacyDecimalInput = tryParseFeetInchesInput(height.toString());
  if (fromLegacyDecimalInput != null) return fromLegacyDecimalInput;

  return _fromTotalInches((height * 12).round());
}

String heightInputLabelFromStoredValue(double height, String unit) {
  if (unit != 'ft') {
    return height == height.roundToDouble()
        ? height.toStringAsFixed(0)
        : height.toString();
  }

  return feetInchesFromHeightValue(height).inputLabel;
}

String? convertHeightInputForUnit({
  required String input,
  required String fromUnit,
  required String toUnit,
}) {
  final trimmedInput = input.trim();
  if (trimmedInput.isEmpty) return null;
  if (fromUnit == toUnit) return trimmedInput;

  final parsedHeight = parseHeightForStorage(trimmedInput, fromUnit);
  if (parsedHeight == null || parsedHeight <= 0) return null;

  if (fromUnit == 'ft' && toUnit != 'ft') {
    final feetInches = feetInchesFromHeightValue(
      parsedHeight,
      rawHeightInput: trimmedInput,
    );
    return _formatMeasurementInput(feetInches.totalInches * 2.54);
  }

  if (fromUnit != 'ft' && toUnit == 'ft') {
    return _fromTotalInches((parsedHeight / 2.54).round()).inputLabel;
  }

  return _formatMeasurementInput(parsedHeight);
}

FeetInches? _feetInchesOrNull(int feet, int inches) {
  if (feet <= 0 || inches < 0 || inches > 11) return null;
  return FeetInches(feet: feet, inches: inches);
}

FeetInches _fromTotalInches(int totalInches) {
  final safeTotal = totalInches < 0 ? 0 : totalInches;
  return FeetInches(feet: safeTotal ~/ 12, inches: safeTotal % 12);
}

String _formatMeasurementInput(double value) {
  final rounded = double.parse(value.toStringAsFixed(1));
  return rounded == rounded.roundToDouble()
      ? rounded.toStringAsFixed(0)
      : rounded.toStringAsFixed(1);
}
