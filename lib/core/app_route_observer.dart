import 'package:flutter/widgets.dart';

/// App-wide route observer, so a screen can react when another route
/// covers it or uncovers it again (`RouteAware`). The companion screen
/// uses it to close the microphone while it isn't visible.
final RouteObserver<ModalRoute<void>> appRouteObserver =
    RouteObserver<ModalRoute<void>>();
