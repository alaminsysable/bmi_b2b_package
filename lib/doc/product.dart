import 'dart:convert';

import 'package:bmi_b2b_package/user.dart';
import 'package:bmi_global/bmi_global.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductDoc {
  final RawMap _rawData;
  ProductDoc.fromJson(this._rawData) {
    _inUse = this;
  }

  static ProductDoc? _inUse;
  static ProductDoc? get inUse => _inUse;
  final _products = <String, Product>{};

  int get _nextUsableID => _rawData["nextUsableID"].toInt();

  Iterable<Product> get items {
    return _rawData["avalable"]
        .toMap()
        .entries
        .map(
          (e) => _products[e.key] ??= Product._(
            toInt(e.key),
            e.value.toMap(),
          ),
        )
        .toList()
      ..sort((p1, p2) => p1.rankOrderValue - p2.rankOrderValue);
  }

  Iterable<Product> get deletedItems {
    final data = _rawData["deleted"].toMap().entries;
    return Iterable.generate(data.length, (index) {
      final entry = data.elementAt(index);
      return _products[entry.key] ??= Product._(
        toInt(entry.key),
        entry.value.toMap(),
      );
    });
  }

  Product? getItem(String? id) {
    if (id == null || toInt(id) >= _nextUsableID) return null;
    return _products[id] ??= Product._(
      toInt(id),
      (_rawData["avalable"].toMap()[id].nullOr ??
              _rawData["deleted"].toMap()[id])
          .toMap(),
    );
  }
}

class Product {
  final int id;
  final int rankOrderValue;
  final String name;
  final IntMoney rate;
  final IntMoney defaultDiscount;
  final Map<String, IntMoney> customerDiscount;
  final Map<int, IntMoney> sellerRate;
  final IntMoney defaultBoughtRate;
  final IntQuntity? pckInBox;
  final bool isNew;

  Product({
    required Map<String, int> customerDiscount,
    required Map<int, int> sellerRate,
    required int defaultDiscount,
    required this.name,
    required int rate,
    required int defaultBoughtRate,
    required int? pckInBox,
    required this.rankOrderValue,
  })  : customerDiscount = customerDiscount
            .map((key, value) => MapEntry(key, IntMoney(value))),
        sellerRate =
            sellerRate.map((key, value) => MapEntry(key, IntMoney(value))),
        defaultDiscount = IntMoney(defaultDiscount),
        defaultBoughtRate = IntMoney(defaultBoughtRate),
        rate = IntMoney(rate),
        pckInBox = pckInBox == null ? null : IntQuntity(pckInBox),
        isNew = true,
        id = ProductDoc.inUse?._nextUsableID ?? -1;

  Product._(this.id, RawMap data)
      : pckInBox = data["pIB"].nullOr?.toIntQuntity(),
        customerDiscount = data["cD"].toMap().map(
              (key, value) => MapEntry(key, value.toIntMoney()),
            ),
        sellerRate = data["sR"].toMap().map(
              (key, value) => MapEntry(toInt(key), value.toIntMoney()),
            ),
        defaultDiscount = data["dD"].toIntMoney(),
        name = data["n"].toString(),
        rate = data["r"].toIntMoney(),
        defaultBoughtRate = data["dBR"].toIntMoney(),
        rankOrderValue = data["rOV"].toInt(),
        isNew = false;
  Future<FirestoreErrors?> makeChanges({
    String? newName,
    int? newRate,
    int? newDefaultDiscount,
    Map<String, int>? newCustomerDiscount,
    Map<int, int>? newSellerRate,
    int? newDefaultBoughtRate,
    int? newRankOrderValue,
  }) async {
    if (id == -1) return null;
    final compneyID = B2bAuthUser.inUse?.compneyIdInUse;
    if (compneyID == null) return null;
    if (B2bAuthUser.inUse?.hasOwnerPermission != true) return null;
    return await firestore.updateDoc(
      docPath: "B2B/$compneyID/DATA/PRODUCTS",
      data: {
        if (isNew) "avalable.$id.pIB": pckInBox?.quntity,
        "avalable.$id.n": newName ?? name,
        "avalable.$id.r": newRate ?? rate.money,
        "avalable.$id.dD": newDefaultDiscount ?? defaultDiscount.money,
        "avalable.$id.cD": newCustomerDiscount ??
            customerDiscount.map((key, value) => MapEntry(key, value.money)),
        "avalable.$id.rOV": newRankOrderValue ?? rankOrderValue,
        "avalable.$id.sR": newSellerRate
                ?.map((key, value) => MapEntry(key.toString(), value)) ??
            sellerRate.map((key, value) => MapEntry(key, value.money)),
        "avalable.$id.dBR": newDefaultBoughtRate ?? defaultBoughtRate.money,
        if (isNew == true) "nextUsableID": FieldValue.increment(1),
      },
    );
  }

  Future<FirestoreErrors?> remove() async {
    if (id == -1) return null;
    final compneyID = B2bAuthUser.inUse?.compneyIdInUse;
    if (compneyID == null) return null;
    if (B2bAuthUser.inUse?.hasOwnerPermission != true) return null;
    return await firestore.updateDoc(
      docPath: "B2B/$compneyID/DATA/PRODUCTS",
      data: {
        "deleted.$id": jsonEncode({"n": name})
      },
      deletePaths: {"avalable.$id"},
    );
  }
}
