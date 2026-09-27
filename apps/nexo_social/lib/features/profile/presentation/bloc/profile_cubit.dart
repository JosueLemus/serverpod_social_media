import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/storage/mock_social_store.dart';

class ProfileCubit extends Cubit<bool> {
  ProfileCubit(this._store, this.username)
    : super(_store.isFollowing(username));
  final MockSocialStore _store;
  final String username;
  Future<void> toggle() async {
    await _store.toggleFollowing(username);
    emit(_store.isFollowing(username));
  }
}
