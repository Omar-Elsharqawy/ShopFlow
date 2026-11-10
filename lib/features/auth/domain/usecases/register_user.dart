

import 'package:e_app/features/auth/domain/entities/user_entity.dart';
import 'package:e_app/features/auth/domain/repositories/auth_repository.dart';

class RegisterUser {
  final AuthRepository repository;


  RegisterUser(this.repository);

  Future<UserEntity> call({
    required String email,
    required String password,
    required String name,
}){
    return repository.register(
        email: email,
        password: password,
        name: name
    );
  }
}