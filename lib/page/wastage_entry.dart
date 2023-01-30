import 'package:bmi_b2b_package/doc/compney.dart';
import 'package:bmi_b2b_package/doc/product.dart';
import 'package:bmi_b2b_package/doc/state.dart';
import 'package:bmi_global/bmi_global.dart';
import 'package:flutter/material.dart';

List<Widget> buildWastageEntry({
  required CompneyDoc? compneyDoc,
  required WastageEntry entry,
  required ProductDoc? productDoc,
}) {
  return [
    const HeaderTile(title: "Inventory (-)"),
    DisplayTable<ItemChanges>(
      fixColumn: "Item Name",
      column: const ["Box", "Pack"],
      values: entry.wastedItems,
      rowBuilder: (e) {
        return DisplayRow.str(
          fixedCell: productDoc?.getItem(e.id.toString())?.name ??
              "ProductID: ${e.id}",
          cells: [
            e.quntity.toString(),
            e.pack.toString(),
          ],
        );
      },
    ),
  ];
}
