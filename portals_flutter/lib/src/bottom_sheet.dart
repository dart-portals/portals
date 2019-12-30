import 'package:flutter/material.dart';
import 'package:portals/portals.dart';
import 'package:portals_flutter/src/choose_side.dart';

import 'animated_bottom_sheet.dart';

extension PortalSetup on BuildContext {
  setupPortal(Portal portal) => _setupPortal(this, portal);
}

void setupPortal({@required BuildContext context, @required Portal portal}) =>
    _setupPortal(context, portal);

void _setupPortal(BuildContext context, Portal portal) {
  assert(context != null);
  assert(portal != null);

  Navigator.of(context, rootNavigator: true).push(_PortalBottomSheetRoute(
    child: PortalBottomSheet(portal: portal),
  ));
}

class _PortalBottomSheetRoute extends PopupRoute {
  _PortalBottomSheetRoute({@required this.child});

  final Widget child;

  @override
  Color get barrierColor => Colors.black45;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    return child;
  }

  @override
  bool get maintainState => true;

  @override
  bool get opaque => false;

  @override
  Duration get transitionDuration => Duration(seconds: 2);

  @override
  bool get barrierDismissible => true;

  @override
  String get barrierLabel => null;
}

class PortalBottomSheet extends StatefulWidget {
  const PortalBottomSheet({Key key, this.portal})
      : assert(portal != null),
        super(key: key);

  final Portal portal;

  @override
  _PortalBottomSheetState createState() => _PortalBottomSheetState();
}

class _PortalBottomSheetState extends State<PortalBottomSheet> {
  void _openPortal() async {
    String code = await widget.portal.open();
  }

  void _linkPortal() async {
    // TODO: get code
    //await widget.portal.openAndLinkTo(code);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBottomSheet(
      child: ChooseAction(
        onFirstTapped: _openPortal,
        onSecondTapped: _linkPortal,
      ),
    );
  }
}
