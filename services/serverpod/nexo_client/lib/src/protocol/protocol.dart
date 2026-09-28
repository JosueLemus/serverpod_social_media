/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: dead_code, unnecessary_type_check

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as _iacc;
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart'
    as _iaic;
import 'package:serverpod_client/serverpod_client.dart' as _isc;
import 'shared/errors/nexo_error_code.dart' as _idt8nicn;
import 'shared/errors/nexo_exception.dart' as _invvqh96;
import 'shared/pagination/page_cursor.dart' as _ihkyxh72;
export 'shared/errors/nexo_error_code.dart';
export 'shared/errors/nexo_exception.dart';
export 'shared/pagination/page_cursor.dart';
export 'client.dart';

class Protocol extends _isc.SerializationManager {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._().._registerHostProtocols();

  static String? getClassNameFromObjectJson(dynamic data) {
    if (data is! Map) return null;
    final className = data['__className__'] as String?;
    return className;
  }

  @override
  T deserialize<T>(
    dynamic data, [
    Type? t,
  ]) {
    t ??= T;

    final dataClassName = getClassNameFromObjectJson(data);
    if (dataClassName != null && dataClassName != getClassNameForType(t)) {
      try {
        return deserializeByClassName({
          'className': dataClassName,
          'data': data,
        });
      } on _isc.DeserializationClassNameNotFoundException catch (_) {
        // If the className is not recognized (e.g., older client receiving
        // data with a new subtype), fall back to deserializing without the
        // className, using the expected type T.
      }
    }

    if (t == _idt8nicn.NexoErrorCode) {
      return _idt8nicn.NexoErrorCode.fromJson(data) as T;
    }
    if (t == _invvqh96.NexoException) {
      return _invvqh96.NexoException.fromJson(data) as T;
    }
    if (t == _ihkyxh72.PageCursor) {
      return _ihkyxh72.PageCursor.fromJson(data) as T;
    }
    if (t == _isc.getType<_idt8nicn.NexoErrorCode?>()) {
      return (data != null ? _idt8nicn.NexoErrorCode.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_invvqh96.NexoException?>()) {
      return (data != null ? _invvqh96.NexoException.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ihkyxh72.PageCursor?>()) {
      return (data != null ? _ihkyxh72.PageCursor.fromJson(data) : null) as T;
    }
    try {
      return _iaic.Protocol().deserialize<T>(data, t);
    } on _isc.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _iacc.Protocol().deserialize<T>(data, t);
    } on _isc.DeserializationTypeNotFoundException catch (_) {}
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _idt8nicn.NexoErrorCode => 'NexoErrorCode',
      _invvqh96.NexoException => 'NexoException',
      _ihkyxh72.PageCursor => 'PageCursor',
      _ => null,
    };
  }

  @override
  String? getClassNameForObject(Object? data) {
    String? className = super.getClassNameForObject(data);
    if (className != null) return className;

    if (data is Map<String, dynamic> && data['__className__'] is String) {
      return (data['__className__'] as String).replaceFirst('nexo.', '');
    }

    switch (data) {
      case _idt8nicn.NexoErrorCode():
        return 'NexoErrorCode';
      case _invvqh96.NexoException():
        return 'NexoException';
      case _ihkyxh72.PageCursor():
        return 'PageCursor';
    }
    className = _iaic.Protocol().getClassNameForObject(data);
    if (className != null) {
      return className.contains('.')
          ? className
          : 'serverpod_auth_idp.$className';
    }
    className = _iacc.Protocol().getClassNameForObject(data);
    if (className != null) {
      return className.contains('.')
          ? className
          : 'serverpod_auth_core.$className';
    }
    return null;
  }

  @override
  dynamic deserializeByClassName(Map<String, dynamic> data) {
    var dataClassName = data['className'];
    if (dataClassName is! String) {
      return super.deserializeByClassName(data);
    }
    if (dataClassName == 'NexoErrorCode') {
      return deserialize<_idt8nicn.NexoErrorCode>(data['data']);
    }
    if (dataClassName == 'NexoException') {
      return deserialize<_invvqh96.NexoException>(data['data']);
    }
    if (dataClassName == 'PageCursor') {
      return deserialize<_ihkyxh72.PageCursor>(data['data']);
    }
    if (dataClassName.startsWith('serverpod_auth_idp.')) {
      data['className'] = dataClassName.substring(19);
      return _iaic.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth_core.')) {
      data['className'] = dataClassName.substring(20);
      return _iacc.Protocol().deserializeByClassName(data);
    }
    return super.deserializeByClassName(data);
  }

  void _registerHostProtocols() {
    _iaic.Protocol().registerHostProtocol('nexo', this);
    _iacc.Protocol().registerHostProtocol('nexo', this);
  }

  @override
  String getModuleName() => 'nexo';

  /// Maps any `Record`s known to this [Protocol] to their JSON representation
  ///
  /// Throws in case the record type is not known.
  ///
  /// This method will return `null` (only) for `null` inputs.
  Map<String, dynamic>? mapRecordToJson(Record? record) {
    if (record == null) {
      return null;
    }
    try {
      return _iaic.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _iacc.Protocol().mapRecordToJson(record);
    } catch (_) {}
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
