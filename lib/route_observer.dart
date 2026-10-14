// lib/route_observer.dart
import 'package:flutter/material.dart';

/// Dipasang di MaterialApp.navigatorObservers; dipakai Beranda untuk tahu
/// kapan ia tampil lagi (didPopNext) supaya datanya di-refresh.
final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();
