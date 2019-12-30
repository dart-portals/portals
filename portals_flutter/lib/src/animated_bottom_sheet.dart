import 'package:flutter/material.dart';

class AnimatedBottomSheet extends StatefulWidget {
  const AnimatedBottomSheet({Key key, this.child}) : super(key: key);

  final Widget child;

  @override
  _AnimatedBottomSheetState createState() => _AnimatedBottomSheetState();
}

class _AnimatedBottomSheetState extends State<AnimatedBottomSheet> {
  var _crossFadeState = CrossFadeState.showFirst;
  Widget _firstChild, _secondChild;
  Widget get _activeChild =>
      _crossFadeState == CrossFadeState.showFirst ? _firstChild : _secondChild;

  @override
  void initState() {
    super.initState();
    _firstChild = widget.child;
  }

  @override
  void didUpdateWidget(Widget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.child != _activeChild) {
      _animateToChild(widget.child);
    }
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
          crossFadeState: CrossFadeState.showFirst,
          duration: Duration(milliseconds: 2000),
          sizeCurve: Curves.easeInOutCubic,
          firstChild: Padding(padding: contentPadding, child: _firstChild),
          secondChild: Padding(padding: contentPadding, child: _secondChild),
        ),
      ),
    );
  }
}
