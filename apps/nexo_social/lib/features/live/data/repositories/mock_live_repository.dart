import '../../domain/entities/live_session.dart';
import '../../domain/repositories/live_repository.dart';

class MockLiveRepository implements LiveRepository {
  final _items = <LiveSession>[
    const LiveSession(
      id: 'live-1',
      title: 'Masterclass de Diseño Mobile',
      hostName: 'Elena Vega',
      status: LiveStatus.live,
      viewers: 2845,
    ),
    const LiveSession(
      id: 'live-2',
      title: 'Café entre creadores',
      hostName: 'Carlos Méndez',
      status: LiveStatus.scheduled,
      viewers: 120,
    ),
    const LiveSession(
      id: 'live-3',
      title: 'Construyendo en público',
      hostName: 'Lucía Torres',
      status: LiveStatus.recorded,
      viewers: 940,
    ),
  ];
  @override
  Future<List<LiveSession>> list() async => List.of(_items);
  @override
  Future<LiveSession> transition(String id, LiveStatus status) async {
    final index = _items.indexWhere((item) => item.id == id);
    final updated = _items[index].copyWith(status: status);
    _items[index] = updated;
    return updated;
  }
}
