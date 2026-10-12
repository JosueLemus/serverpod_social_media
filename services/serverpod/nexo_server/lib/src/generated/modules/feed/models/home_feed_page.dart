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
import 'package:nexo_server/src/generated/protocol.dart' as _i8p6m2v0;
import 'package:serverpod/serverpod.dart' as _is;
import '../../../modules/feed/models/feed_section.dart' as _i2shzcw4;
import '../../../modules/feed/models/home_feed_cursor.dart' as _imq8u6jj;

/// Una página del feed de inicio. La primera trae todas las secciones que
/// tengan algo; las siguientes, sólo `following` o `discover`.
abstract class HomeFeedPage
    implements _is.SerializableModel, _is.ProtocolSerialization {
  HomeFeedPage._({
    required this.sections,
    this.nextCursor,
  });

  factory HomeFeedPage({
    required List<_i2shzcw4.FeedSection> sections,
    _imq8u6jj.HomeFeedCursor? nextCursor,
  }) = _HomeFeedPageImpl;

  factory HomeFeedPage.fromJson(Map<String, dynamic> jsonSerialization) {
    return HomeFeedPage(
      sections: _i8p6m2v0.Protocol().deserialize<List<_i2shzcw4.FeedSection>>(
        jsonSerialization['sections'],
      ),
      nextCursor: jsonSerialization['nextCursor'] == null
          ? null
          : _i8p6m2v0.Protocol().deserialize<_imq8u6jj.HomeFeedCursor>(
              jsonSerialization['nextCursor'],
            ),
    );
  }

  List<_i2shzcw4.FeedSection> sections;

  _imq8u6jj.HomeFeedCursor? nextCursor;

  /// Returns a shallow copy of this [HomeFeedPage]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  HomeFeedPage copyWith({
    List<_i2shzcw4.FeedSection>? sections,
    _imq8u6jj.HomeFeedCursor? nextCursor,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'HomeFeedPage',
      'sections': sections.toJson(valueToJson: (v) => v.toJson()),
      if (nextCursor != null) 'nextCursor': nextCursor?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'HomeFeedPage',
      'sections': sections.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      if (nextCursor != null) 'nextCursor': nextCursor?.toJsonForProtocol(),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _HomeFeedPageImpl extends HomeFeedPage {
  _HomeFeedPageImpl({
    required List<_i2shzcw4.FeedSection> sections,
    _imq8u6jj.HomeFeedCursor? nextCursor,
  }) : super._(
         sections: sections,
         nextCursor: nextCursor,
       );

  /// Returns a shallow copy of this [HomeFeedPage]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  HomeFeedPage copyWith({
    List<_i2shzcw4.FeedSection>? sections,
    Object? nextCursor = _Undefined,
  }) {
    return HomeFeedPage(
      sections: sections ?? this.sections.map((e0) => e0.copyWith()).toList(),
      nextCursor: nextCursor is _imq8u6jj.HomeFeedCursor?
          ? nextCursor
          : this.nextCursor?.copyWith(),
    );
  }
}
