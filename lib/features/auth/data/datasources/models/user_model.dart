import '../../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({required super.id, required super.email, super.name});

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      email: map['email'] as String,
      name: map['name'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'email': email, 'name': name};
  }

  factory UserModel.fromFirebaseUser({
    required String id,
    required String email,
    String? name,
  }) {
    return UserModel(id: id, email: email, name: name);
  }
}
