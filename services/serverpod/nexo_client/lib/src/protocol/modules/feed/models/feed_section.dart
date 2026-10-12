/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:nexo_client/src/protocol/protocol.dart' as _il0t1g31;
import 'package:serverpod_client/serverpod_client.dart' as _isc;
import '../../../modules/feed/models/feed_item.dart' as _i6eky5rw;
import '../../../modules/feed/models/feed_section_kind.dart' as _i6mr9dus;
import '../../../modules/identity/models/profile_view.dart' as _iucarp80;

/// Una sección del feed de inicio. [accounts] sólo se llena en
/// `suggestedAccounts`; el resto lleva [items].
abstract class FeedSection
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  FeedSection._({
    required this.kind,
    required this.items,
    required this.accounts,
  });

  factory FeedSection({
    required _i6mr9dus.FeedSectionKind kind,
    required List<_i6eky5rw.FeedItem> items,
    required List<_iucarp80.ProfileView> accounts,
  }) = _FeedSectionImpl;

  factory FeedSection.fromJson(Map<String, dynamic> jsonSerialization) {
    return FeedSection(
      kind: _i6mr9dus.FeedSectionKind.fromJson(
        (jsonSerialization['kind'] as String),
      ),
      items: _il0t1g31.Protocol().deserialize<List<_i6eky5rw.FeedItem>>(
        jsonSerialization['items'],
      ),
      accounts: _il0t1g31.Protocol().deserialize<List<_iucarp80.ProfileView>>(
        jsonSerialization['accounts'],
      ),
    );
  }

  _i6mr9dus.FeedSectionKind kind;

  List<_i6eky5rw.FeedItem> items;

  List<_iucarp80.ProfileView> accounts;

  /// Returns a shallow copy of this [FeedSection]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  FeedSection copyWith({
    _i6mr9dus.FeedSectionKind? kind,
    List<_i6eky5rw.FeedItem>? items,
    List<_iucarp80.ProfileView>? accounts,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'FeedSection',
      'kind': kind.toJson(),
      'items': items.toJson(valueToJson: (v) => v.toJson()),
      'accounts': accounts.toJson(valueToJson: (v) => v.toJson()),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'FeedSection',
      'kind': kind.toJson(),
      'items': items.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      'accounts': accounts.toJson(valueToJson: (v) => v.toJsonForProtocol()),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _FeedSectionImpl extends FeedSection {
  _FeedSectionImpl({
    required _i6mr9dus.FeedSectionKind kind,
    required List<_i6eky5rw.FeedItem> items,
    required List<_iucarp80.ProfileView> accounts,
  }) : super._(
         kind: kind,
         items: items,
         accounts: accounts,
       );

  /// Returns a shallow copy of this [FeedSection]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  FeedSection copyWith({
    _i6mr9dus.FeedSectionKind? kind,
    List<_i6eky5rw.FeedItem>? items,
    List<_iucarp80.ProfileView>? accounts,
  }) {
    return FeedSection(
      kind: kind ?? this.kind,
      items: items ?? this.items.map((e0) => e0.copyWith()).toList(),
      accounts: accounts ?? this.accounts.map((e0) => e0.copyWith()).toList(),
    );
  }
}
