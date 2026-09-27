import 'package:equatable/equatable.dart';

class Entitlement extends Equatable {
  const Entitlement({required this.creator, required this.active});
  final String creator;
  final bool active;
  @override
  List<Object?> get props => [creator, active];
}
