import 'package:bmi_b2b_package/doc/compney.dart';
import 'package:bmi_b2b_package/doc/product.dart';
import 'package:bmi_b2b_package/doc/state.dart';
import 'package:bmi_b2b_package/page/entries.dart';
import 'package:bmi_b2b_package/user.dart';
import 'package:bmi_global/bmi_global.dart';
import 'package:flutter/material.dart';

extension on EntryType {
  String get title {
    switch (this) {
      case EntryType.buy:
        return "Compney Bought";
      case EntryType.buyInPayment:
        return "Compney Payed";
      case EntryType.sell:
        return "Compney Sold";
      case EntryType.sellOutPayment:
        return "Compney Earned";
      case EntryType.returnBoxes:
        return "Box Returned";
      case EntryType.wallet:
        return "Waller Changes";
      case EntryType.wasted:
        return "Stock Wasted";
    }
  }
}

class EntryPage extends StatefulWidget {
  const EntryPage({
    Key? key,
    required this.entry,
    required this.showOptions,
    required this.compneyDoc,
    required this.productDoc,
  }) : super(key: key);
  final Entry entry;
  final ProductDoc? productDoc;
  final CompneyDoc? compneyDoc;
  final bool showOptions;

  @override
  State<EntryPage> createState() => _EntryPageState();
}

enum _Options { delete }

class _EntryPageState extends State<EntryPage> {
  var loading = false;
  var deleted = false;

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final compneyDoc = widget.compneyDoc;
    final productDoc = widget.productDoc;
    final hasOwnerPermission = B2bAuthUser.inUse?.hasOwnerPermission == true;
    return Scaffold(
      appBar: AppBar(
        title: Text("${entry.entryType.title} Entry"),
        actions: widget.showOptions
            ? [
                PopupMenuButton<_Options>(
                  itemBuilder: (context) {
                    return [
                      PopupTile(
                        enabled:
                            !deleted && entry.isEditable && hasOwnerPermission,
                        child: "Delete",
                        value: _Options.delete,
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                      ),
                    ];
                  },
                  onSelected: (option) async {
                    if (option == _Options.delete) {
                      if (!await proceed(
                        context,
                        "Are You Sure To Remove",
                        "Warning, once deleted can't be undone!",
                      )) return;
                      setState(() {
                        loading = true;
                      });
                      final res = await entry.removeFromDoc();
                      if (mounted) {
                        if (res == null) {
                          setState(() {
                            loading = false;
                            deleted = true;
                          });
                        } else {
                          res.showAlertDialog(context: context);
                          setState(() {
                            loading = false;
                          });
                        }
                      }
                    }
                  },
                ),
              ]
            : null,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: [
            if (loading) const LinearProgressIndicator(),
            if (deleted) const ErrorTile("Entry Successfully deleted!"),
            ListTile(
              title: const Text("Creator"),
              trailing: Text(
                compneyDoc?.getUser(entry.creator).name ?? entry.creator,
              ),
            ),
            ListTile(
              title: const Text("Entry Date"),
              trailing: Text(entry.belongToDate.formateDate()),
            ),
            ListTile(
              title: const Text("Created At"),
              trailing: Text(entry.timeStamp.formateTime()),
              subtitle: Text(entry.timeStamp.formateDate()),
            ),
            if (entry is BoughtEntry)
              ...buildBoughtEntry(
                  entry: entry, compneyDoc: compneyDoc, productDoc: productDoc),
            if (entry is BuyInPaymentEntry)
              ...buildBuyInPaymentEntry(
                  compneyDoc: compneyDoc, entry: entry, productDoc: productDoc),
            if (entry is SellOutPaymentEntry)
              ...buildSellOutPaymentEntry(
                  compneyDoc: compneyDoc, entry: entry, productDoc: productDoc),
            if (entry is ReturnBoxesEntry)
              ...buildReturnBoxesEntry(
                  compneyDoc: compneyDoc, entry: entry, productDoc: productDoc),
            if (entry is SoldEntry)
              ...buildSoldEntry(
                  compneyDoc: compneyDoc, entry: entry, productDoc: productDoc),
            if (entry is WastageEntry)
              ...buildWastageEntry(
                  compneyDoc: compneyDoc, entry: entry, productDoc: productDoc),
            if (entry is WalletChangesEntry)
              ...buildWalletChangesEntry(
                  compneyDoc: compneyDoc, entry: entry, productDoc: productDoc),
          ],
        ),
      ),
    );
  }
}
