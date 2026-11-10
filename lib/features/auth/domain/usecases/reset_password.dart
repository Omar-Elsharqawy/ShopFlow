import 'package:e_app/features/auth/domain/repositories/auth_repository.dart';

class ResetPassword {
  final AuthRepository repository;

  ResetPassword(this.repository);

  Future<void> call({
    required String email,
}) {
    return repository.resetPassword(
        email: email
    );
  }
}