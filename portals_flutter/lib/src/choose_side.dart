import 'dart:math';

import 'package:flutter/material.dart';

class ChooseAction extends StatefulWidget {
  const ChooseAction({
    Key key,
    @required this.onFirstTapped,
    @required this.onSecondTapped,
  }) : super(key: key);

  final VoidCallback onFirstTapped;
  final VoidCallback onSecondTapped;

  @override
  _ChooseActionState createState() => _ChooseActionState();
}

class _ChooseActionState extends State<ChooseAction> {
  Color color;
  double height;

  @override
  void initState() {
    // TODO: implement initState
    color = [Colors.yellow, Colors.red, Colors.green][Random().nextInt(3)];
    height = 20 + Random().nextInt(500).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    // return Container(
    //   color: color,
    //   height: height,
    //   child: InkWell(onTap: widget.onTap),
    // );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text('Choose different colors on both devices.'),
        SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Spacer(),
            ActionButton(
              color: Color(0xff29339b),
              label: '1',
              onPressed: widget.onFirstTapped,
            ),
            Spacer(),
            ActionButton(
              color: Color(0xffff5964),
              label: '2',
              onPressed: widget.onSecondTapped,
            ),
            Spacer(),
          ],
        ),
      ],
    );
  }
}

class ActionButton extends StatelessWidget {
  const ActionButton({
    Key key,
    @required this.color,
    @required this.label,
    @required this.onPressed,
  }) : super(key: key);

  final Color color;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Material(
          color: color,
          shape: CircleBorder(),
          child: Container(
            width: 52,
            height: 52,
            child: InkWell(
              onTap: onPressed,
              child: Center(
                child: Text(label, style: TextStyle(color: Colors.white)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
