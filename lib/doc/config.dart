import 'package:bmi_b2b_package/user.dart';
import 'package:bmi_global/bmi_global.dart';

class ConfigDoc {
  final RawMap _rawData;
  ConfigDoc.fromJson(this._rawData) {
    _inUse = this;
  }
  static ConfigDoc? _inUse;
  static ConfigDoc? get inUse => _inUse;

  CompneyInfo? getCompney(String? id) {
    final data = _rawData[id];
    if (data.data == null || id == null) return null;
    return CompneyInfo._(id, data.toMap());
  }

  Maintenance? get maintenance {
    final data = _rawData["maintenance"];
    if (data.data == null) return null;
    return Maintenance._(data.toMap());
  }

  Iterable<CompneyInfo> get b2b {
    final entries = _rawData.entries;
    return Iterable.generate(entries.length, (index) {
      final entry = entries.elementAt(index);
      return CompneyInfo._(
        entry.key,
        entry.value.toMap(),
      );
    });
  }
}

class Maintenance {
  final String message;
  final bool applyToUs;
  Maintenance._(RawMap data)
      : message = data["message"].toString(),
        applyToUs = data["applyTo"].toItrable().any((e) => e.data == "b2b");
}

class CompneyInfo {
  final String id;
  final String name;
  final bool disable;

  static bool hasChanged(CompneyInfo before, CompneyInfo after) {
    return before.id != after.id ||
        before.name != after.name ||
        before.disable != after.disable;
  }

  CompneyInfo._(this.id, RawMap val)
      : name = val["name"].toString(),
        disable = val["disabled"].toBool();

  CompneyInfo(this.name)
      : id = "",
        disable = false;

  Future<FirestoreErrors?> deleteData() async {
    if (B2bAuthUser.inUse?.isDev != true) return null;
    return await firestore.removeDoc(docPath: "B2B/$id");
  }

  Future<FirestoreErrors?> makeChanges({String? newName}) async {
    if (B2bAuthUser.inUse?.isDev != true) return null;
    if (id.isEmpty) {
      return await firestore.addDoc(
        collPath: "B2B",
        data: {"name": newName ?? name},
      );
    }
    return await firestore.updateDoc(
      docPath: "B2B/$id",
      data: {"name": newName ?? name},
    );
  }

  Future<FirestoreErrors?> autoMateReport() async {
    if (B2bAuthUser.inUse?.isDev != true) return null;
    return await firestore.updateDoc(
      docPath: "B2B/$id",
      deletePaths: {"reportTill"},
    );
  }
}
