import 'package:bmi_b2b_package/doc/compney.dart';
import 'package:bmi_b2b_package/doc/product.dart';
import 'package:bmi_b2b_package/doc/state.dart';
import 'package:bmi_global/bmi_global.dart';
import 'package:flutter/material.dart';

List<Widget> buildSellOutPaymentEntry({
  required CompneyDoc? compneyDoc,
  required SellOutPaymentEntry entry,
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
      title: "Wallet Changes (+)",
      trailing: Text(entry.amount.toString()),
    )
  ];
}
