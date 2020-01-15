import 'package:flutter/material.dart';

import '../model/user.dart';
import '../util/constants.dart';

class UserItem extends StatelessWidget {
  UserItem({Key key, @required this.user}) : super(key: key);

  final User user;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Container(
            padding: EdgeInsets.all(UIConstants.SMALLER_PADDING),
            child: Text(
              user.displayName,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: UIConstants.BIGGER_FONT_SIZE,
                  color: Colors.blueAccent),
            ),
          ),
        ),
      ],
    );
  }
}
