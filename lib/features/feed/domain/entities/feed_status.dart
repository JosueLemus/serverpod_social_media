import 'package:equatable/equatable.dart';

class FeedStatus extends Equatable {
  const FeedStatus({required this.isReady});
  final bool isReady;
  @override
  List<Object?> get props => [isReady];
}
