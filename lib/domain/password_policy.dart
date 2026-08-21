/// Shared password rule for signup and password changes.
///
/// Matches local Auth checks and Supabase `password_requirements =
/// "letters_digits"` plus `minimum_password_length = 8`.
class PasswordPolicy {
  PasswordPolicy._();

  static const int minLength = 8;

  static const String helperText =
      'Must be at least 8 characters with a letter and a digit';

  static const String errorText =
      'Password must be at least 8 characters with a letter and a digit';

  static final RegExp _letter = RegExp(r'[A-Za-z]');
  static final RegExp _digit = RegExp(r'\d');

  static bool isSatisfied(String password) {
    return password.length >= minLength &&
        _letter.hasMatch(password) &&
        _digit.hasMatch(password);
  }
}
