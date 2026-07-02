import 'package:flowfit/core/config/supabase_tables.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupportRequestDraft {
  const SupportRequestDraft({
    required this.category,
    required this.subject,
    required this.message,
    this.appSurface = 'help_support',
  });

  final String category;
  final String subject;
  final String message;
  final String appSurface;

  SupportRequestDraft normalized() {
    return SupportRequestDraft(
      category: category.trim(),
      subject: subject.trim(),
      message: message.trim(),
      appSurface: appSurface.trim().isEmpty
          ? 'help_support'
          : appSurface.trim(),
    );
  }
}

class SupportRequestException implements Exception {
  const SupportRequestException(this.message);

  final String message;

  @override
  String toString() => message;
}

class SupportRequestAuthException extends SupportRequestException {
  const SupportRequestAuthException()
    : super('Sign in before sending an in-app support request.');
}

class SupportRequestValidationException extends SupportRequestException {
  const SupportRequestValidationException(super.message);
}

class SupportRequestService {
  SupportRequestService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<String> submit(SupportRequestDraft draft) async {
    final normalized = draft.normalized();
    _validate(normalized);

    final user = _client.auth.currentUser;
    if (user == null) {
      throw const SupportRequestAuthException();
    }

    final row = await _client
        .from(SupabaseTables.supportRequests)
        .insert({
          'user_id': user.id,
          'user_email': user.email,
          'category': normalized.category,
          'subject': normalized.subject,
          'message': normalized.message,
          'app_surface': normalized.appSurface,
        })
        .select('id')
        .single();

    final id = row['id'];
    if (id is String && id.isNotEmpty) {
      return id;
    }

    throw const SupportRequestException(
      'Support request was accepted without a request id.',
    );
  }

  void _validate(SupportRequestDraft draft) {
    const categories = {'support', 'bug', 'account', 'privacy'};
    if (!categories.contains(draft.category)) {
      throw const SupportRequestValidationException(
        'Choose a valid support request type.',
      );
    }

    if (draft.subject.length < 3 || draft.subject.length > 160) {
      throw const SupportRequestValidationException(
        'Subject must be between 3 and 160 characters.',
      );
    }

    if (draft.message.length < 10 || draft.message.length > 4000) {
      throw const SupportRequestValidationException(
        'Message must be between 10 and 4000 characters.',
      );
    }
  }
}
