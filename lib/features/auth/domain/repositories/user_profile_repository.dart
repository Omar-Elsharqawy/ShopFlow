import '../entities/user_entity.dart';

abstract class UserProfileRepository {
  Future<UserEntity?> getUserProfile(String uid);
}