import 'package:bmi_b2b_package/doc/compney.dart';
import 'package:bmi_b2b_package/doc/product.dart';
import 'package:bmi_b2b_package/doc/state.dart';
import 'package:bmi_global/bmi_global.dart';
import 'package:flutter/material.dart';

List<Widget> buildBuyInPaymentEntry({
  required CompneyDoc? compneyDoc,
  required BuyInPaymentEntry entry,
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
    HeaderTile(
      title: "Wallet Changes (-)",
      trailing: Text(entry.amount.toString()),
    )
  ];
}
