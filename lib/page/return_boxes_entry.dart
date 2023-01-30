import 'package:bmi_b2b_package/doc/compney.dart';
import 'package:bmi_b2b_package/doc/product.dart';
import 'package:bmi_b2b_package/doc/state.dart';
import 'package:bmi_global/bmi_global.dart';
import 'package:flutter/material.dart';

List<Widget> buildReturnBoxesEntry({
  required CompneyDoc? compneyDoc,
  required ReturnBoxesEntry entry,
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
    HeaderTile(
      title: "Boxes Reurned (+)",
      trailing: Text(entry.boxes.toString()),
    )
  ];
}
