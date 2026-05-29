import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../auth/auth_service.dart';
import '../providers/auth_provider.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(ref);
});

class UserRepository {
  final Ref _ref;

  UserRepository(this._ref);

  Future<UserModel?> getCurrentUserData() async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return null;

    final authService = _ref.read(authServiceProvider);
    return authService.getUserData(user.uid);
  }
}
