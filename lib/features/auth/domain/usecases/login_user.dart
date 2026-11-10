import 'package:e_app/features/auth/domain/entities/user_entity.dart';
import 'package:e_app/features/auth/domain/repositories/auth_repository.dart';

class
    LoginUser {
  final AuthRepository repository;

  LoginUser(this.repository);
  Future<UserEntity>call ({
    required String email,
    required String password,
}){
    return repository.login(
        email: email,
        password: password
    );
  }
}