import 'package:e_app/features/auth/domain/entities/user_entity.dart';
import 'package:e_app/features/auth/domain/repositories/auth_repository.dart';

class GetCurrentUser {
  final AuthRepository repository;

  GetCurrentUser(this.repository);

  Future<UserEntity?>call() {
    return repository.getCurrentUser();
  }
}