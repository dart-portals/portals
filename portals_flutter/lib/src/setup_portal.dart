import 'package:flutter/material.dart';
import 'package:portals/portals.dart';

import 'bottom_sheet_app.dart';
import 'pages/choose_side.dart';

export 'bottom_sheet_app.dart';

extension SetupPortal on BuildContext {
  setupPortal(Portal portal) => _setupPortal(this, portal);
}

void setupPortal({@required BuildContext context, @required Portal portal}) =>
    _setupPortal(context, portal);

void _setupPortal(BuildContext context, Portal portal) {
  assert(context != null);
  assert(portal != null);

  Navigator.of(context, rootNavigator: true).push(BottomSheetAppRoute(
    app: PortalProvider(
      portal: portal,
      child: BottomSheetApp(home: ChooseSidePage()),
    ),
  ));
}

extension PortalContext on BuildContext {
  Portal get portal => findAncestorWidgetOfExactType<PortalProvider>().portal;
}

class PortalProvider extends StatelessWidget {
  const PortalProvider({
    Key key,
    @required this.portal,
    @required this.child,
  }) : super(key: key);

  final Portal portal;
  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}
