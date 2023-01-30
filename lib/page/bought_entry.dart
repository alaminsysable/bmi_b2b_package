import 'package:bmi_b2b_package/doc/compney.dart';
import 'package:bmi_b2b_package/doc/product.dart';
import 'package:bmi_b2b_package/doc/state.dart';
import 'package:bmi_global/bmi_global.dart';
import 'package:flutter/material.dart';

List<Widget> buildBoughtEntry({
  required CompneyDoc? compneyDoc,
  required BoughtEntry entry,
  required ProductDoc? productDoc,
}) {
  return [
    ListTile(
      title: const Text("Seller"),
      trailing: Text(
        compneyDoc?.getSeller(entry.sellerID).name ??
            "SellerID: ${entry.sellerID}",
      ),
    ),
    const Divider(height: 30),
    const HeaderTile(title: "Calculation"),
    DisplayTable<ItemBought>(
      fixColumn: "Item Name",
      column: const ["Rate", "Net Qun", "Net Amount"],
      values: entry.itemBought,
      rowBuilder: (e) {
        return DisplayRow.str(
          fixedCell: productDoc?.getItem(e.id.toString())?.name ??
              "ProductID: ${e.id}",
          cells: [
            e.rate.toString(),
            e.toString(),
            e.amount.toString(),
          ],
        );
      },
      trailing: DisplayRow.str(
        fixedCell: "Total",
        cells: [
          "",
          "",
          entry.buyIn.amount.toString(),
        ],
      ),
    ),
  ];
}
