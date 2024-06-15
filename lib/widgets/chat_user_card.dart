import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../api/apis.dart';
import '../helper/date_util.dart';
import '../main.dart';
import '../models/chat_user.dart';
import '../models/message.dart';
import '../screens/chat_screen.dart';
import 'dialogs/profile_dialog.dart';

class ChatUserCard extends StatefulWidget {
  const ChatUserCard({super.key, required this.user});

  final ChatUser user;

  @override
  State<StatefulWidget> createState() {
    return ChatUserCardState();
  }
}

class ChatUserCardState extends State<ChatUserCard> {
  Message? _message;
  @override
  Widget build(BuildContext context) {
    mq = MediaQuery.of(context).size;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 1),
      color: const Color.fromRGBO(214, 231, 238, 1.0),
      elevation: 3,
      child: InkWell(
        onTap: () {
          Navigator.push(
              context,
              CupertinoPageRoute(
                  builder: (_) => ChatScreen(user: widget.user)));
        },
        child: StreamBuilder(
          stream: APIs.getLastMessage(widget.user),
          builder: (context, snapshot) {
            final data = snapshot.data?.docs;
            final list =
                data?.map((e) => Message.fromJson(e.data())).toList() ?? [];

            if (list.isNotEmpty) {
              _message = list[0];
            }

            return ListTile(
                //Name of User
                title: Text(widget.user.name),

                //Last User Message
                subtitle: Text(
                  _message != null
                      ? _message!.type == Type.image
                          ? 'Image'
                          : _message!.type == Type.video
                              ? 'Video'
                              : _message!.msg
                      : '',
                  maxLines: 1,
                ),

                //Profile Picture of User
                leading: InkWell(
                  onTap: () {
                    showDialog(
                        context: context,
                        builder: (_) => ProfileDialog(user: widget.user));
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(mq.height * .03),
                    child: CachedNetworkImage(
                      height: mq.height * .055,
                      width: mq.height * .055,
                      fit: BoxFit.cover,
                      imageUrl: widget.user.image,
                      errorWidget: (context, url, error) =>
                          const CircleAvatar(child: Icon(Icons.person)),
                    ),
                  ),
                ),

                //Last Message Time
                trailing: _message == null
                    ? null //Show nothing when no message sent
                    : _message!.read.isEmpty &&
                            _message!.fromId != APIs.user.email
                        ?
                        //Show for unread messages
                        Container(
                            height: 10,
                            width: 10,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(7),
                                color: const Color.fromARGB(255, 21, 101, 24)))
                        :
                        //Message time
                        Text(
                            DateUtil.getLastMessageTime(
                                context: context, time: _message!.send),
                            style: const TextStyle(color: Colors.black54),
                          ));
          },
        ),
      ),
    );
  }
}
