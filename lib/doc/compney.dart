import 'package:bmi_b2b_package/user.dart';
import 'package:bmi_global/bmi_global.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CompneyDoc {
  final RawMap _rawData;
  CompneyDoc.fromJson(this._rawData) {
    _inUse = this;
  }

  static CompneyDoc? _inUse;
  static CompneyDoc? get inUse => _inUse;

  Set<String> get reportAvalable =>
      _rawData["report"].toItrable().map((e) => e.toString()).toSet();

  String get name => _rawData["name"].toString();
  int get _nextUsableSellerID => _rawData["nextUsableSellerID"].toInt();
  OwnerInfo get owner => OwnerInfo._(_rawData["owner"].toMap());

  SellerInfo getSeller(int sellerID) {
    final id = sellerID.toString();
    return SellerInfo._(
        sellerID,
        (_rawData["seller"].toMap()[id].nullOr ??
                _rawData["ex-seller"].toMap()[id])
            .toMap());
  }

  BuyerInfo getBuyer(String buyerNumber) {
    return BuyerInfo._(
      buyerNumber,
      (_rawData["buyers"].toMap()[buyerNumber].nullOr ??
              _rawData["ex-buyers"].toMap()[buyerNumber])
          .toMap(),
    );
  }

  UserInfo getUser(String userNumber) {
    if (owner.phoneNumber == userNumber) return owner;
    return WorkerInfo._(
      userNumber,
      (_rawData["workers"].toMap()[userNumber].nullOr ??
              _rawData["ex-workers"].toMap()[userNumber].nullOr ??
              _rawData["buyers"].toMap()[userNumber].nullOr ??
              _rawData["ex-buyers"].toMap()[userNumber])
          .toMap(),
    );
  }

  Iterable<WorkerInfo> get workers {
    final users = _rawData["workers"].toMap().entries;
    return Iterable.generate(users.length, (index) {
      final info = users.elementAt(index);
      return WorkerInfo._(info.key, info.value.toMap());
    });
  }

  Iterable<SellerInfo> get seller {
    final users = _rawData["seller"].toMap().entries;
    return Iterable.generate(users.length, (index) {
      final info = users.elementAt(index);
      return SellerInfo._(toInt(info.key), info.value.toMap());
    });
  }

  Iterable<BuyerInfo> get buyers {
    final users = _rawData["buyers"].toMap().entries;
    return Iterable.generate(users.length, (index) {
      final info = users.elementAt(index);
      return BuyerInfo._(info.key, info.value.toMap());
    });
  }

  int get liveRefresh => _rawData["refreshAuth"].toInt();

  CompneyActions get action => CompneyActions(_rawData["action"].toMap());
}

class CompneyActions {
  final bool disabled;
  CompneyActions(RawMap data) : disabled = data["disabled"].toBool();

  Future<FirestoreErrors?> resetData() async {
    final compneyID = B2bAuthUser.inUse?.compneyIdInUse;
    if (compneyID == null) return null;
    if (B2bAuthUser.inUse?.isDev != true) return null;
    return await firestore.updateDoc(
      docPath: "B2B/$compneyID",
      data: {"action.reset": FieldValue.increment(1)},
    );
  }

  Future<FirestoreErrors?> disableCompeny() async {
    final compneyID = B2bAuthUser.inUse?.compneyIdInUse;
    if (compneyID == null) return null;
    if (B2bAuthUser.inUse?.isDev != true) return null;
    return await firestore.updateDoc(
      docPath: "B2B/$compneyID",
      data: {"action.disabled": true},
    );
  }

  Future<FirestoreErrors?> enableCompeny() async {
    final compneyID = B2bAuthUser.inUse?.compneyIdInUse;
    if (compneyID == null) return null;
    if (B2bAuthUser.inUse?.isDev != true) return null;
    return await firestore.updateDoc(
      docPath: "B2B/$compneyID",
      data: {"action.disabled": FieldValue.delete()},
    );
  }
}

enum UserStatus { error, pending, success }

extension Parse on UserStatus {
  bool? toNullBool() {
    switch (this) {
      case UserStatus.error:
        return false;
      case UserStatus.pending:
        return null;
      case UserStatus.success:
        return true;
    }
  }
}

UserStatus _userStatusOf(int? val) {
  if (val == null) return UserStatus.pending;
  if (val > 0) return UserStatus.success;
  if (val < 0) return UserStatus.error;
  return UserStatus.pending;
}

abstract class UserInfo {
  String get name;
  String get phoneNumber;
}

class OwnerInfo with UserInfo {
  @override
  final String name;
  @override
  final String phoneNumber;
  final UserStatus userStatus;

  OwnerInfo._(RawMap json)
      : name = json["name"].toString(),
        phoneNumber = json['phoneNumber'].toString(),
        userStatus = _userStatusOf(json['status'].toInt());

  Future<FirestoreErrors?> makeChanges({
    String? newName,
    String? newPhoneNumber,
  }) async {
    final compneyID = B2bAuthUser.inUse?.compneyIdInUse;
    if (compneyID == null) return null;
    if (B2bAuthUser.inUse?.isDev != true) return null;
    if (newName == null && newPhoneNumber == null) return null;
    return await firestore.updateDoc(
      docPath: "B2B/$compneyID",
      data: {
        "owner.name": newName,
        "owner.phoneNumber": newPhoneNumber,
        if (newPhoneNumber != null) "owner.status": FieldValue.delete(),
      },
    );
  }

  @override
  String toString() {
    return {"name": name, "phoneNumber": phoneNumber}.toString();
  }
}

abstract class CompneyUserInfo with UserInfo {
  @override
  final String name;
  @override
  final String phoneNumber;

  final bool _isNew;

  const CompneyUserInfo(
    this.name,
    this.phoneNumber,
    this._isNew,
  );

  String get fieldPath;

  Future<FirestoreErrors?> makeChanges({
    String? newName,
  }) async {
    final compneyID = B2bAuthUser.inUse?.compneyIdInUse;
    if (compneyID == null) return null;
    if (B2bAuthUser.inUse?.hasOwnerPermission != true) return null;
    final data = <String, Object?>{};
    if (_isNew) {
      data[fieldPath] = {"name": newName ?? name};
    } else {
      data["$fieldPath.name"] = newName ?? name;
    }
    return await firestore.updateDoc(
      docPath: "B2B/$compneyID",
      data: data,
    );
  }

  Future<FirestoreErrors?> remove() async {
    final compneyID = B2bAuthUser.inUse?.compneyIdInUse;
    if (compneyID == null) return null;
    if (B2bAuthUser.inUse?.hasOwnerPermission != true) return null;
    return await firestore.updateDoc(
      docPath: "B2B/$compneyID",
      deletePaths: {fieldPath},
    );
  }

  @override
  String toString() {
    return {"name": name, "phoneNumber": phoneNumber}.toString();
  }
}

class WorkerInfo extends CompneyUserInfo {
  final UserStatus userStatus;
  WorkerInfo({
    required String name,
    required String phoneNumber,
  })  : userStatus = UserStatus.pending,
        super(name, phoneNumber, true);

  WorkerInfo._(String phoneNumber, RawMap data)
      : userStatus = _userStatusOf(data["status"].toInt()),
        super(
          data["name"].nullOr?.toString() ?? phoneNumber,
          phoneNumber,
          false,
        );

  @override
  String get fieldPath => "workers.$phoneNumber";
}

class BuyerInfo extends CompneyUserInfo {
  BuyerInfo({
    required String name,
    required String phoneNumber,
  }) : super(name, phoneNumber, true);

  BuyerInfo._(String phoneNumber, RawMap data)
      : super(
          data["name"].nullOr?.toString() ?? phoneNumber,
          phoneNumber,
          false,
        );

  @override
  String get fieldPath => "buyers.$phoneNumber";
}

class SellerInfo {
  static const docParameter = "seller";
  final String name;
  final int id;
  final bool isNew;

  SellerInfo({required this.name})
      : isNew = true,
        id = CompneyDoc.inUse?._nextUsableSellerID ?? -1;

  SellerInfo._(this.id, RawMap data)
      : isNew = false,
        name = data["name"].nullOr?.toString() ?? "ID: $id";
  Future<FirestoreErrors?> makeChanges({
    String? newName,
  }) async {
    if (id == -1) return null;
    final compneyID = B2bAuthUser.inUse?.compneyIdInUse;
    if (compneyID == null) return null;

    if (B2bAuthUser.inUse?.hasOwnerPermission != true) return null;
    return await firestore.updateDoc(
      docPath: "B2B/$compneyID",
      data: {
        if (isNew) "nextUsableSellerID": FieldValue.increment(1),
        fieldPath: {"name": newName ?? name}
      },
    );
  }

  Future<FirestoreErrors?> remove() async {
    if (id == -1) return null;
    final compneyID = B2bAuthUser.inUse?.compneyIdInUse;
    if (compneyID == null) return null;
    if (B2bAuthUser.inUse?.hasOwnerPermission != true) return null;
    return await firestore.updateDoc(
      docPath: "B2B/$compneyID",
      deletePaths: {fieldPath},
    );
  }

  String get fieldPath => "$docParameter.$id";
}
