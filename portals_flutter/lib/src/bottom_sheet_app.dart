import 'package:flutter/material.dart';

class BottomSheetAppRoute extends PopupRoute {
  BottomSheetAppRoute({@required this.app});

  final Widget app;

  @override
  Color get barrierColor => Colors.black45;

  @override
  bool get barrierDismissible => true;

  @override
  String get barrierLabel => null;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    return Center(child: app);
  }

  @override
  Duration get transitionDuration => Duration(milliseconds: 200);
}

extension BottomSheetNavigator on BuildContext {
  _BottomSheetAppState get app =>
      findAncestorStateOfType<_BottomSheetAppState>();
}

class BottomSheetApp extends StatefulWidget {
  const BottomSheetApp({Key key, @required this.home}) : super(key: key);

  final Widget home;

  @override
  _BottomSheetAppState createState() => _BottomSheetAppState();
}

class _BottomSheetAppState extends State<BottomSheetApp> {
  final _history = <Widget>[];
  var _crossFadeState = CrossFadeState.showFirst;
  Widget _firstChild, _secondChild;

  @override
  void initState() {
    super.initState();
    _history.add(widget.home);
    _firstChild = widget.home;
  }

  void _animateToChild(Widget child) {
    setState(() {
      if (_crossFadeState == CrossFadeState.showFirst) {
        _secondChild = child;
        _crossFadeState = CrossFadeState.showSecond;
      } else {
        _firstChild = child;
        _crossFadeState = CrossFadeState.showFirst;
      }
    });
  }

  void push(Widget page) {
    _history.add(page);
    _animateToChild(page);
  }

  void replace(Widget page) {
    _history
      ..removeLast()
      ..add(page);
    _animateToChild(page);
  }

  void pop() {
    _history.removeLast();
    _animateToChild(_history.last);

    if (_history.isEmpty) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final contentPadding =
        MediaQuery.of(context).padding.copyWith(top: 0) + EdgeInsets.all(16);

    return Align(
      alignment: Alignment.bottomCenter,
      child: Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        child: AnimatedCrossFade(
          crossFadeState: _crossFadeState,
          duration: Duration(milliseconds: 2000),
          sizeCurve: Curves.easeInOutCubic,
          firstChild: Padding(padding: contentPadding, child: _firstChild),
          secondChild: Padding(padding: contentPadding, child: _secondChild),
        ),
      ),
    );
  }
}
