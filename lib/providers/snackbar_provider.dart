import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'snackbar_provider.g.dart';

/// Global messenger key attached to the root [MaterialApp] in MainApp,
/// so that providers (which have no BuildContext) can show SnackBars.
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

/// Shows a global SnackBar from anywhere (e.g. mutation notifiers).
@riverpod
class Snackbar extends _$Snackbar {
  @override
  void build() {}

  void show(String message) {
    rootScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
