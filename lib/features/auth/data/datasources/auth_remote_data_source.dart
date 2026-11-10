
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'models/user_model.dart';
abstract class AuthRemoteDataSource {
  Future<UserModel> register({
    required String email,
    required String password,
    required String name,
  });

  Future<UserModel> login({
    required String email,
    required String password,
  });

  Future<void> logout();

  Future<void> resetPassword({
    required String email,
  });

  Future<UserModel?> getCurrentUser();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth firebaseAuth;
  final FirebaseFirestore firestore;

  AuthRemoteDataSourceImpl({
    required this.firebaseAuth,
    required this.firestore,
  });

  @override
  Future<UserModel> register({
    required String email,
    required String password,
    required String name,
  }) async {
    final credential =
    await firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user;

    if (user == null) {
      throw Exception('User registration failed');
    }

    await user.updateDisplayName(name);

    final userModel = UserModel.fromFirebaseUser(
      id: user.uid,
      email: user.email ?? email,
      name: name,
    );

    await firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'name': name,
      'email': user.email ?? email,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return userModel;
  }

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final credential =
    await firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user;

    if (user == null) {
      throw Exception('User login failed');
    }

    return UserModel.fromFirebaseUser(
      id: user.uid,
      email: user.email ?? email,
      name: user.displayName,
    );
  }

  @override
  Future<void> logout() async {
    await firebaseAuth.signOut();
  }

  @override
  Future<void> resetPassword({
    required String email,
  }) async {
    await firebaseAuth.sendPasswordResetEmail(
      email: email,
    );
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final user = firebaseAuth.currentUser;

    if (user == null) {
      return null;
    }

    return UserModel.fromFirebaseUser(
      id: user.uid,
      email: user.email ?? '',
      name: user.displayName,
    );
  }
}
