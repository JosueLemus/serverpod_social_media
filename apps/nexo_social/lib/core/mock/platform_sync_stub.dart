import 'platform_sync.dart';

class PlatformSyncImpl implements PlatformSync {
  PlatformSyncImpl(String storageKey);

  @override
  Stream<void> get externalChanges => const Stream.empty();
}
