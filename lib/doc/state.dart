// ignore_for_file: prefer_void_to_null

import 'dart:convert';

import 'package:bmi_b2b_package/doc/product.dart';
import 'package:bmi_b2b_package/user.dart';
import 'package:bmi_global/bmi_global.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class StateDoc {
  final RawMap _rawData;
  StateDoc.fromJson(this._rawData) {
    _inUse = this;
  }

  static StateDoc? _inUse;
  static StateDoc? get inUse => _inUse;

  IntMoney getBuyInDuePayment(int sellerID) {
    return IntMoney(_rawData["buyInDue"].toMap()[sellerID.toString()].toInt());
  }

  IntMoney getSellOutDuePayment(String buyerNumber) {
    return IntMoney(
      _rawData["sellOutDue"].toMap()[buyerNumber].toMap()["m"].toInt(),
    );
  }

  IntQuntity getSellOutDueBoxes(String buyerNumber) {
    return IntQuntity(
      _rawData["sellOutDue"].toMap()[buyerNumber].toMap()["b"].toInt(),
    );
  }

  IntMoney get walletMoney => IntMoney(_rawData["walletMoney"].toInt());
  IntQuntity get boxes => IntQuntity(_rawData["boxes"].toInt());

  Iterable<Entry> getSellerEntries(int sellerID) {
    return entries.where((e) {
      if (e is BoughtEntry) return e.sellerID == sellerID;
      if (e is BuyInPaymentEntry) return e.sellerID == sellerID;
      return false;
    });
  }

  Iterable<Entry> getBuyerEntries(String buyerNumber) {
    return entries.where((e) {
      if (e is SoldEntry) return e.buyerNumber == buyerNumber;
      if (e is SellOutPaymentEntry) return e.buyerNumber == buyerNumber;
      if (e is ReturnBoxesEntry) return e.buyerNumber == buyerNumber;
      return false;
    });
  }

  Iterable<Entry> get entries {
    final list = _rawData["entries"].toItrable();
    return Iterable.generate(list.length, (index) {
      final entry = list.elementAt(list.length - index - 1);
      return _parseEntry(entry.toString(), entry);
    });
  }

  Entry? getEntry(String? id) {
    if (id == null) return null;
    return _parseEntry(id, RawObj(id));
  }

  ItemQun getQuntityOf(String id) {
    return ItemQun._(id, _rawData["inventory"].toMap()[id].toMap());
  }

  Iterable<ItemQun> get inventory {
    return _rawData["inventory"]
        .toMap()
        .entries
        .map((e) => ItemQun._(e.key, e.value.toMap()));
  }
}

Entry _parseEntry(String id, RawObj original) {
  final data = original.toMap();
  switch (asEntryType(data["-eT"].toString())) {
    case EntryType.sell:
      return SoldEntry._(id, data);
    case EntryType.buy:
      return BoughtEntry._(id, data);
    case EntryType.buyInPayment:
      return BuyInPaymentEntry._(id, data);
    case EntryType.sellOutPayment:
      return SellOutPaymentEntry._(id, data);
    case EntryType.wallet:
      return WalletChangesEntry._(id, data);
    case EntryType.returnBoxes:
      return ReturnBoxesEntry._(id, data);
    default:
      return WastageEntry._(id, data);
  }
}

class ItemQun {
  final int id;
  final IntQuntity quntity;
  final IntQuntity pack;
  final bool isInv;

  IntQuntity get pckPerBox =>
      ProductDoc.inUse?.getItem(id.toString())?.pckInBox ?? const IntQuntity(1);

  ItemQun.__(RawMap data)
      : id = data["-id"].toInt(),
        quntity = data["-q"].toIntQuntity(),
        pack = data["-p"].toIntQuntity(),
        isInv = false;

  ItemQun._(String key, RawMap data)
      : id = toInt(key),
        quntity = data["q"].toIntQuntity(),
        pack = data["p"].toIntQuntity(),
        isInv = true;

  Map<String, Object?> _toJson() {
    if (isInv) return {"q": quntity.quntity, "p": pack.quntity};
    return {"-id": id, "-q": quntity.quntity, "-p": pack.quntity};
  }

  ItemQun(this.id, int quntity, int pack)
      : quntity = IntQuntity(quntity),
        pack = IntQuntity(pack),
        isInv = false;

  ItemQun operator -() {
    return ItemQun(id, -quntity.quntity, -pack.quntity);
  }

  @override
  String toString({bool lead = true}) {
    return "Box:   $quntity\nPck:   $pack";
  }

  String quntityString() {
    return quntity.toString();
  }

  String packString() {
    return pack.toString();
  }
}

abstract class BuyInPayment {
  int get sellerID;
  IntMoney get amount;
}

abstract class SellOutPayment {
  String get buyerNumber;
  IntMoney get amount;
}

abstract class BoxesIn {
  String get buyerNumber;
  IntQuntity get boxes;
}

class BuyIn with BuyInPayment {
  @override
  final int sellerID;
  @override
  final IntMoney amount;
  final bool due;

  BuyIn(this.sellerID, int amount, this.due) : amount = IntMoney(amount);
}

class SellOut with SellOutPayment {
  @override
  final String buyerNumber;
  @override
  final IntMoney amount;
  final bool due;

  SellOut(this.buyerNumber, int amount, this.due) : amount = IntMoney(amount);
}

class DueBoxes with BoxesIn {
  @override
  final String buyerNumber;
  @override
  final IntQuntity boxes;
  final bool due;

  DueBoxes(this.buyerNumber, int boxes, this.due) : boxes = IntQuntity(boxes);
}

enum EntryType {
  buy,
  buyInPayment,
  sell,
  sellOutPayment,
  returnBoxes,
  wallet,
  wasted,
}

EntryType asEntryType(String arg) {
  if (arg == EntryType.buy.name) return EntryType.buy;
  if (arg == EntryType.sell.name) return EntryType.sell;
  if (arg == EntryType.buyInPayment.name) return EntryType.buyInPayment;
  if (arg == EntryType.sellOutPayment.name) return EntryType.sellOutPayment;
  if (arg == EntryType.wallet.name) return EntryType.wallet;
  if (arg == EntryType.returnBoxes.name) return EntryType.returnBoxes;
  return EntryType.wasted;
}

abstract class Entry {
  final String? id;
  final DateTimeString timeStamp;
  final DateTimeString? _belongToDate;
  final String creator;
  final EntryType entryType;
  final bool _isEditable;

  Entry({
    required this.entryType,
  })  : _isEditable = false,
        id = null,
        creator = B2bAuthUser.inUse?.phoneNumber ?? "",
        timeStamp = DateTimeString.fromDateTime(DateTime.now()),
        _belongToDate = null; //DateTimeString(belongToDate);

  Entry._(this.id, RawMap data)
      : _isEditable = true,
        creator = data["-c"].toString(),
        timeStamp = data["-tS"].toDateTimeString(),
        _belongToDate = data["-bTD"].nullOr?.toDateTimeString(),
        entryType = asEntryType(data["-eT"].toString());

  bool get isEditable => _isEditable
      ? DateTime.now()
          .toIso8601String()
          .startsWith(timeStamp.value.padLeft(10).substring(0, 7))
      : false;

  DateTimeString get belongToDate => _belongToDate ?? timeStamp;

  Iterable<ItemQun>? get _inventoryChangesApplyed;
  int? get _walletChanges;
  int? get _boxChanges;
  BuyIn? get buyIn;
  SellOut? get sellOut;
  DueBoxes? get dueBoxes;

  Map<String, Object?> _toJson() {
    final data = <String, Object?>{};
    data["-c"] = creator;
    data["-tS"] = timeStamp.value;
    data["-eT"] = entryType.name;
    data["-bTD"] = _belongToDate?.value;
    return data;
  }

  Future<FirestoreErrors?> addEntryToDoc(BuildContext context) async {
    final now = DateTimeString.fromDateTime(DateTime.now());
    final date = await showDatePicker(
      context: context,
      initialDate: now.dateTime,
      firstDate: now.firstDayOfMonth,
      lastDate: now.lastDayOfMonth,
    );
    if (date == null) return null;
    final json = _toJson();
    json["-bTD"] = date.toIso8601String();
    if (id != null) return null;
    final compneyID = B2bAuthUser.inUse?.compneyIdInUse;
    if (compneyID == null) return null;
    if (B2bAuthUser.inUse?.hasWorkerPermission != true) return null;
    final buyInPayment = buyIn;
    final sellOutPayment = sellOut;
    final boxesInDue = dueBoxes;
    final walletChanges = _walletChanges;
    final boxChanges = _boxChanges;
    final invChanges = <String, FieldValue>{};
    final changesApplyed = _inventoryChangesApplyed;
    if (changesApplyed != null) {
      for (var e in changesApplyed) {
        invChanges["inventory.${e.id}.q"] =
            FieldValue.increment(e.quntity.quntity);
        invChanges["inventory.${e.id}.p"] =
            FieldValue.increment(e.pack.quntity);
      }
    }
    return await firestore.updateDoc(
      docPath: "B2B/$compneyID/DATA/STATE",
      data: {
        "entries": FieldValue.arrayUnion([jsonEncode(json)]),
        ...invChanges,
        if (buyInPayment != null)
          "buyInDue.${buyInPayment.sellerID}": FieldValue.increment(
            (buyInPayment.due ? 1 : -1) * buyInPayment.amount.money,
          ),
        if (sellOutPayment != null)
          "sellOutDue.${sellOutPayment.buyerNumber}.m": FieldValue.increment(
            (sellOutPayment.due ? 1 : -1) * sellOutPayment.amount.money,
          ),
        if (boxesInDue != null)
          "sellOutDue.${boxesInDue.buyerNumber}.b": FieldValue.increment(
            (boxesInDue.due ? 1 : -1) * boxesInDue.boxes.quntity,
          ),
        if (walletChanges != null)
          "walletMoney": FieldValue.increment(walletChanges),
        if (boxChanges != null) "boxes": FieldValue.increment(boxChanges),
      },
    );
  }

  Future<FirestoreErrors?> removeFromDoc() async {
    if (id == null || !isEditable) return null;
    final compneyID = B2bAuthUser.inUse?.compneyIdInUse;
    if (compneyID == null) return null;
    if (B2bAuthUser.inUse?.hasOwnerPermission != true) return null;
    final buyInPayment = buyIn;
    final sellOutPayment = sellOut;
    final boxesInDue = dueBoxes;
    final walletChanges = _walletChanges;
    final boxChanges = _boxChanges;
    final invChanges = <String, FieldValue>{};
    final changesApplyed = _inventoryChangesApplyed;
    if (changesApplyed != null) {
      for (var e in changesApplyed) {
        invChanges["inventory.${e.id}.q"] =
            FieldValue.increment(-e.quntity.quntity);
        invChanges["inventory.${e.id}.p"] =
            FieldValue.increment(-e.pack.quntity);
      }
    }
    return await firestore.updateDoc(
      docPath: "B2B/$compneyID/DATA/STATE",
      data: {
        "entries": FieldValue.arrayRemove([id]),
        ...invChanges,
        if (buyInPayment != null)
          "buyInDue.${buyInPayment.sellerID}": FieldValue.increment(
            (buyInPayment.due ? -1 : 1) * buyInPayment.amount.money,
          ),
        if (sellOutPayment != null)
          "sellOutDue.${sellOutPayment.buyerNumber}.m": FieldValue.increment(
            (sellOutPayment.due ? -1 : 1) * sellOutPayment.amount.money,
          ),
        if (boxesInDue != null)
          "sellOutDue.${boxesInDue.buyerNumber}.b": FieldValue.increment(
            (boxesInDue.due ? -1 : 1) * boxesInDue.boxes.quntity,
          ),
        if (walletChanges != null)
          "walletMoney": FieldValue.increment(-walletChanges),
        if (boxChanges != null) "boxes": FieldValue.increment(-boxChanges),
      },
    );
  }
}

class SoldEntry extends Entry {
  final String buyerNumber;
  final Iterable<ItemSold> itemSold;
  SellOut? _sellOutPayment;

  SoldEntry({
    required this.buyerNumber,
    required this.itemSold,
  }) : super(entryType: EntryType.sell);

  SoldEntry._(String id, RawMap data)
      : buyerNumber = data["bN"].toString(),
        itemSold = data["iS"].toItrable().map((e) => ItemSold._(e.toMap())),
        super._(id, data);

  @override
  Map<String, Object?> _toJson() {
    final data = super._toJson();
    data["bN"] = buyerNumber;
    data["iS"] = itemSold.map((e) => e._toJson()).toList();
    return data;
  }

  @override
  Iterable<ItemQun>? get _inventoryChangesApplyed => itemSold.map((e) => -e);

  @override
  final Null buyIn = null;

  @override
  SellOut get sellOut {
    if (_sellOutPayment != null) return _sellOutPayment!;
    var amount = 0;
    for (var soldItem in itemSold) {
      amount += soldItem.amount.money;
    }
    return _sellOutPayment = SellOut(buyerNumber, amount, true);
  }

  @override
  final Null _walletChanges = null;

  @override
  int get _boxChanges =>
      -itemSold.map((e) => e.quntity.quntity).reduce((a, b) => a + b);

  @override
  DueBoxes get dueBoxes => DueBoxes(buyerNumber, -_boxChanges, true);
}

class ItemSold extends ItemQun {
  final IntMoney rate;
  final IntMoney discountApplyed;

  IntMoney get amount {
    var a = quntity.quntity * (rate.money - discountApplyed.money) ~/ 1000;
    if (pack.quntity * 2 > pckPerBox.quntity) a -= discountApplyed.money;
    a += pack.quntity * rate.money ~/ pckPerBox.quntity;
    return IntMoney(a);
  }

  ItemSold({
    required int id,
    required int quntity,
    required int pack,
    required this.discountApplyed,
    required this.rate,
  }) : super(id, quntity, pack);

  @override
  Map<String, Object?> _toJson() {
    final data = super._toJson();
    data["dA"] = discountApplyed.money;
    data["r"] = rate.money;
    return data;
  }

  ItemSold._(RawMap data)
      : discountApplyed = IntMoney(data["dA"].toInt()),
        rate = IntMoney(data["r"].toInt()),
        super.__(data);
}

class BoughtEntry extends Entry {
  final int sellerID;
  final Iterable<ItemBought> itemBought;
  BuyIn? _buyInPayment;

  BoughtEntry({
    required this.itemBought,
    required this.sellerID,
  }) : super(entryType: EntryType.buy);

  BoughtEntry._(String id, RawMap data)
      : sellerID = data["s"].toInt(),
        itemBought = data["iB"].toItrable().map((e) => ItemBought._(e.toMap())),
        super._(id, data);

  @override
  Map<String, Object?> _toJson() {
    final data = super._toJson();
    data["s"] = sellerID;
    data["iB"] = itemBought.map((e) => e._toJson()).toList();
    return data;
  }

  @override
  Iterable<ItemQun>? get _inventoryChangesApplyed => itemBought;

  @override
  BuyIn get buyIn {
    if (_buyInPayment != null) return _buyInPayment!;
    var amount = 0;
    for (var boughtItem in itemBought) {
      amount += boughtItem.amount.money;
    }
    return _buyInPayment = BuyIn(sellerID, amount, true);
  }

  @override
  final Null _walletChanges = null;
  @override
  final Null sellOut = null;
  @override
  final Null _boxChanges = null;
  @override
  final Null dueBoxes = null;
}

class ItemBought extends ItemQun {
  final IntMoney rate;

  ItemBought({
    required int id,
    required int quntity,
    required int pack,
    required this.rate,
  }) : super(id, quntity, pack);

  IntMoney get amount {
    var a = quntity.quntity * rate.money ~/ 1000;
    a += pack.quntity * rate.money ~/ pckPerBox.quntity;
    return IntMoney(a);
  }

  ItemBought._(RawMap data)
      : rate = IntMoney(data["r"].toInt()),
        super.__(data);

  @override
  Map<String, Object?> _toJson() {
    final data = super._toJson();
    data["r"] = rate.money;
    return data;
  }
}

class WastageEntry extends Entry {
  final Iterable<ItemChanges> wastedItems;

  WastageEntry({
    required this.wastedItems,
  }) : super(entryType: EntryType.wasted);

  WastageEntry._(String id, RawMap data)
      : wastedItems =
            data["iU"].toItrable().map((e) => ItemChanges._(e.toMap())),
        super._(id, data);

  @override
  Map<String, Object?> _toJson() {
    final data = super._toJson();
    data["iU"] = wastedItems.map((e) => e._toJson()).toList();
    return data;
  }

  @override
  final Null buyIn = null;
  @override
  final Null _walletChanges = null;
  @override
  final Null sellOut = null;
  @override
  final Null _boxChanges = null;
  @override
  final Null dueBoxes = null;

  @override
  Iterable<ItemQun>? get _inventoryChangesApplyed => wastedItems.map((e) => -e);
}

class ItemChanges extends ItemQun {
  ItemChanges({
    required int id,
    required int quntity,
    required int pack,
  }) : super(id, quntity, pack);

  ItemChanges._(RawMap data) : super.__(data);

  @override
  Map<String, Object?> _toJson() {
    final data = super._toJson();
    data["id"] = id;
    return data;
  }
}

class BuyInPaymentEntry extends Entry with BuyInPayment {
  BuyInPaymentEntry({
    required int sellerID,
    required int amount,
  })  : buyIn = BuyIn(sellerID, amount, false),
        super(entryType: EntryType.buyInPayment);

  BuyInPaymentEntry._(String id, RawMap data)
      : buyIn = BuyIn(
          data["s"].toInt(),
          data["a"].toInt(),
          false,
        ),
        super._(id, data);

  @override
  Map<String, Object?> _toJson() {
    final data = super._toJson();
    data["s"] = buyIn.sellerID;
    data["a"] = buyIn.amount.money;
    return data;
  }

  @override
  final BuyIn buyIn;

  @override
  final Null _inventoryChangesApplyed = null;
  @override
  final Null sellOut = null;
  @override
  final Null _boxChanges = null;
  @override
  final Null dueBoxes = null;

  @override
  IntMoney get amount => buyIn.amount;
  @override
  int get _walletChanges => -buyIn.amount.money;
  @override
  int get sellerID => buyIn.sellerID;
}

class SellOutPaymentEntry extends Entry with SellOutPayment {
  SellOutPaymentEntry({
    required String buyerNumber,
    required int amount,
  })  : sellOut = SellOut(buyerNumber, amount, false),
        super(entryType: EntryType.sellOutPayment);

  SellOutPaymentEntry._(String id, RawMap data)
      : sellOut = SellOut(
          data["bN"].toString(),
          data["a"].toInt(),
          false,
        ),
        super._(id, data);

  @override
  Map<String, Object?> _toJson() {
    final data = super._toJson();
    data["bN"] = sellOut.buyerNumber;
    data["a"] = sellOut.amount.money;
    return data;
  }

  @override
  final Null buyIn = null;
  @override
  final Null _inventoryChangesApplyed = null;
  @override
  final Null _boxChanges = null;
  @override
  final Null dueBoxes = null;

  @override
  final SellOut sellOut;

  @override
  IntMoney get amount => sellOut.amount;

  @override
  String get buyerNumber => sellOut.buyerNumber;

  @override
  int get _walletChanges => sellOut.amount.money;
}

enum WalletChangeType { expenses, salary, withdrawal, deposit }

extension Utils on WalletChangeType {
  String get title {
    switch (this) {
      case WalletChangeType.expenses:
        return "Add Expenses";
      case WalletChangeType.salary:
        return "Give Salary To Workers";
      case WalletChangeType.withdrawal:
        return "Withdraw Money";
      case WalletChangeType.deposit:
        return "Deposit Money";
    }
  }
}

class WalletChangesEntry extends Entry {
  final WalletChangeType walletChangeType;
  final IntMoney amount;
  final String message;
  WalletChangesEntry({
    required int amount,
    required this.walletChangeType,
    required this.message,
  })  : amount = IntMoney(amount),
        super(entryType: EntryType.wallet);

  WalletChangesEntry._(String id, RawMap data)
      : walletChangeType =
            WalletChangeType.values.elementAt(data["wCT"].toInt()),
        amount = data["a"].toIntMoney(),
        message = data["m"].toString(),
        super._(id, data);

  @override
  final Null buyIn = null;
  @override
  final Null _inventoryChangesApplyed = null;
  @override
  final Null sellOut = null;
  @override
  final Null _boxChanges = null;
  @override
  final Null dueBoxes = null;

  @override
  int get _walletChanges {
    switch (walletChangeType) {
      case WalletChangeType.expenses:
        return -amount.money;
      case WalletChangeType.salary:
        return -amount.money;
      case WalletChangeType.withdrawal:
        return -amount.money;
      case WalletChangeType.deposit:
        return amount.money;
    }
  }

  @override
  Map<String, Object?> _toJson() {
    final data = super._toJson();
    data['a'] = amount.money;
    data['wCT'] = walletChangeType.index;
    data['m'] = message;
    return data;
  }
}

class ReturnBoxesEntry extends Entry with BoxesIn {
  ReturnBoxesEntry({
    required String buyerNumber,
    required int boxes,
  })  : dueBoxes = DueBoxes(buyerNumber, boxes, false),
        super(entryType: EntryType.returnBoxes);

  ReturnBoxesEntry._(String id, RawMap data)
      : dueBoxes = DueBoxes(
          data["bN"].toString(),
          data["b"].toInt(),
          false,
        ),
        super._(id, data);

  @override
  Map<String, Object?> _toJson() {
    final data = super._toJson();
    data["bN"] = dueBoxes.buyerNumber;
    data["b"] = dueBoxes.boxes.quntity;
    return data;
  }

  @override
  final Null buyIn = null;
  @override
  final Null _inventoryChangesApplyed = null;
  @override
  final Null _walletChanges = null;
  @override
  final Null sellOut = null;

  @override
  final DueBoxes dueBoxes;

  @override
  int get _boxChanges => dueBoxes.boxes.quntity;

  @override
  String get buyerNumber => dueBoxes.buyerNumber;

  @override
  IntQuntity get boxes => dueBoxes.boxes;
}
