import 'package:bmi_b2b_package/doc/compney.dart';
import 'package:bmi_b2b_package/doc/product.dart';
import 'package:bmi_b2b_package/doc/state.dart';
import 'package:bmi_global/bmi_global.dart';
import 'package:flutter/material.dart';

extension on WalletChangeType {
  bool get isRemoved {
    switch (this) {
      case WalletChangeType.expenses:
        return true;
      case WalletChangeType.salary:
        return true;
      case WalletChangeType.withdrawal:
        return true;
      case WalletChangeType.deposit:
        return false;
    }
  }
}

List<Widget> buildWalletChangesEntry({
  required CompneyDoc? compneyDoc,
  required WalletChangesEntry entry,
  required ProductDoc? productDoc,
}) {
  return [
    const Divider(height: 30),
    HeaderTile(
      title: "Wallet Changes (${entry.walletChangeType.isRemoved ? "-" : "+"})",
      trailing: Text(entry.amount.toString()),
    ),
    HeaderTile(
      title: "Type",
      trailing: Text(entry.walletChangeType.title),
    ),
    if (entry.message.trim().isNotEmpty)
      ListTile(
        title: const Text("Message"),
        subtitle: Text(entry.message),
      ),
  ];
}
