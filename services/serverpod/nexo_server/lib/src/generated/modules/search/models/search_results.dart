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
import '../../../modules/content/models/post_view.dart' as _ido7bd9b;
import '../../../modules/identity/models/profile_view.dart' as _iucarp80;
import '../../../modules/live/models/live_show_view.dart' as _idtyojf8;

/// Lo que encontró `search.query`: cuentas, publicaciones, vivos y
/// etiquetas que coinciden con el texto. [query] es el texto ya normalizado:
/// la app lo usa para descartar una respuesta que llegó tarde.
abstract class SearchResults
    implements _is.SerializableModel, _is.ProtocolSerialization {
  SearchResults._({
    required this.query,
    required this.accounts,
    required this.posts,
    required this.lives,
    required this.tags,
  });

  factory SearchResults({
    required String query,
    required List<_iucarp80.ProfileView> accounts,
    required List<_ido7bd9b.PostView> posts,
    required List<_idtyojf8.LiveShowView> lives,
    required List<String> tags,
  }) = _SearchResultsImpl;

  factory SearchResults.fromJson(Map<String, dynamic> jsonSerialization) {
    return SearchResults(
      query: jsonSerialization['query'] as String,
      accounts: _i8p6m2v0.Protocol().deserialize<List<_iucarp80.ProfileView>>(
        jsonSerialization['accounts'],
      ),
      posts: _i8p6m2v0.Protocol().deserialize<List<_ido7bd9b.PostView>>(
        jsonSerialization['posts'],
      ),
      lives: _i8p6m2v0.Protocol().deserialize<List<_idtyojf8.LiveShowView>>(
        jsonSerialization['lives'],
      ),
      tags: _i8p6m2v0.Protocol().deserialize<List<String>>(
        jsonSerialization['tags'],
      ),
    );
  }

  String query;

  List<_iucarp80.ProfileView> accounts;

  List<_ido7bd9b.PostView> posts;

  List<_idtyojf8.LiveShowView> lives;

  List<String> tags;

  /// Returns a shallow copy of this [SearchResults]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  SearchResults copyWith({
    String? query,
    List<_iucarp80.ProfileView>? accounts,
    List<_ido7bd9b.PostView>? posts,
    List<_idtyojf8.LiveShowView>? lives,
    List<String>? tags,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SearchResults',
      'query': query,
      'accounts': accounts.toJson(valueToJson: (v) => v.toJson()),
      'posts': posts.toJson(valueToJson: (v) => v.toJson()),
      'lives': lives.toJson(valueToJson: (v) => v.toJson()),
      'tags': tags.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'SearchResults',
      'query': query,
      'accounts': accounts.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      'posts': posts.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      'lives': lives.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      'tags': tags.toJson(),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _SearchResultsImpl extends SearchResults {
  _SearchResultsImpl({
    required String query,
    required List<_iucarp80.ProfileView> accounts,
    required List<_ido7bd9b.PostView> posts,
    required List<_idtyojf8.LiveShowView> lives,
    required List<String> tags,
  }) : super._(
         query: query,
         accounts: accounts,
         posts: posts,
         lives: lives,
         tags: tags,
       );

  /// Returns a shallow copy of this [SearchResults]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  SearchResults copyWith({
    String? query,
    List<_iucarp80.ProfileView>? accounts,
    List<_ido7bd9b.PostView>? posts,
    List<_idtyojf8.LiveShowView>? lives,
    List<String>? tags,
  }) {
    return SearchResults(
      query: query ?? this.query,
      accounts: accounts ?? this.accounts.map((e0) => e0.copyWith()).toList(),
      posts: posts ?? this.posts.map((e0) => e0.copyWith()).toList(),
      lives: lives ?? this.lives.map((e0) => e0.copyWith()).toList(),
      tags: tags ?? this.tags.map((e0) => e0).toList(),
    );
  }
}
