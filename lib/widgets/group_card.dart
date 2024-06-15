import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:wave_chat/screens/group_chat.dart';

class GroupCard extends StatefulWidget {
  final String userName;
  final String groupName;
  final String groupId;

  const GroupCard(
      {super.key,
      required this.groupName,
      required this.groupId,
      required this.userName});

  @override
  State<GroupCard> createState() => _GroupCardState();
}

class _GroupCardState extends State<GroupCard> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            CupertinoPageRoute(
                builder: (_) => GroupChatScreen(
                      groupId: widget.groupId,
                      groupName: widget.groupName,
                      userName: widget.userName,
                    )));
      },
      child: Card(
          margin: const EdgeInsets.symmetric(vertical: 1),
          color: const Color.fromRGBO(214, 231, 238, 1.0),
          elevation: 3,
          child: InkWell(
              onTap: () {
                Navigator.push(
                    context,
                    CupertinoPageRoute(
                        builder: (_) => GroupChatScreen(
                              groupId: widget.groupId,
                              groupName: widget.groupName,
                              userName: widget.userName,
                            )));
              },
              child: ListTile(
                //Name of User
                title: Text(widget.groupName),
                subtitle: Text(
                  'Join the conversation as ${widget.userName}',
                  style: const TextStyle(fontSize: 13),
                ),

                ///Profile Picture of User

                leading: CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.blue,
                  child: Text(
                    widget.groupName.substring(0, 1).toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
              ))),
    );
  }
}
