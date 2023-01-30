import 'package:bmi_b2b_package/doc/compney.dart';
import 'package:bmi_b2b_package/doc/product.dart';
import 'package:bmi_b2b_package/doc/state.dart';
import 'package:bmi_global/bmi_global.dart';
import 'package:flutter/material.dart';

List<Widget> buildSoldEntry({
  required CompneyDoc? compneyDoc,
  required SoldEntry entry,
  required ProductDoc? productDoc,
}) {
  return [
    ListTile(
      title: const Text("Buyer"),
      trailing: Text(
        compneyDoc?.getBuyer(entry.buyerNumber).name ?? entry.buyerNumber,
      ),
    ),
    const Divider(height: 30),
    const HeaderTile(title: "Calculation"),
    DisplayTable<ItemSold>(
      fixColumn: "Item Name",
      column: const ["Rate (-Dis.)", "Net Qun", "Net Amount"],
      values: entry.itemSold,
      rowBuilder: (e) {
        return DisplayRow.str(
          fixedCell: productDoc?.getItem(e.id.toString())?.name ??
              "ProductID: ${e.id}",
          cells: [
            '${e.rate.toString(trail: false)} ( -${e.discountApplyed.toString(trail: false, lead: false)} )',
            e.toString(),
            e.amount.toString(),
          ],
        );
      },
      trailing: DisplayRow.str(
        fixedCell: "Total",
        cells: [
          "",
          "Box: ${entry.dueBoxes.boxes}",
          entry.sellOut.amount.toString(),
        ],
      ),
    ),
  ];
}
