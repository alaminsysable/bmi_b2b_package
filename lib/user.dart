import 'package:bmi_global/bmi_global.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract class B2bAuthUser extends AuthUser {
  final RawMap _b2b;

  static B2bAuthUser? _inUse;
  static B2bAuthUser? get inUse => _inUse;

  B2bAuthUser(User user, Map<String, Object?> claims)
      : _b2b = RawObj(claims["b2b"]).toMap(),
        super(user, claims) {
    _inUse = this;
  }

  bool get hasExpiredPermission {
    if (isDev) return false;
    final compneyID = compneyIdInUse;
    if (compneyID == null) return false;
    return isExpired(compneyID);
  }

  bool get hasOwnerPermission {
    if (isDev) return true;
    final compneyID = compneyIdInUse;
    if (compneyID == null) return false;
    return isOwner(compneyID);
  }

  bool get hasWorkerPermission {
    if (isDev) return true;
    final compneyID = compneyIdInUse;
    if (compneyID == null) return false;
    return isOwner(compneyID) || isWorker(compneyID);
  }

  bool isOwner([String? compneyID]) {
    return _b2b[compneyID ?? compneyIdInUse].data == 0;
  }

  bool isWorker([String? compneyID]) {
    return _b2b[compneyID ?? compneyIdInUse].data == 1;
  }

  bool isExpired([String? compneyID]) {
    return (_b2b[compneyID ?? compneyIdInUse].data ?? -1) == -1;
  }

  Iterable<String> get compneyIDs => _b2b.keys;

  bool hasCompney(String compneyID) =>
      isOwner(compneyID) || isWorker(compneyID) || isDev;

  String hasRoleOf([String? compneyID]) {
    if (isDev) return "Devloper";
    final id = compneyID ?? compneyIdInUse;
    if (id == null) return "Normal User";
    if (isOwner(id)) return "Owner";
    if (isWorker(id)) return "Worker";
    if (isExpired(id)) return "Expired";
    return "Normal User";
  }

  String? get compneyIdInUse;
}
