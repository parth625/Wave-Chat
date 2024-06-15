// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../helper/date_util.dart';
import '../main.dart';
import '../models/chat_user.dart';

//To view the profile of user
class ChatUserProfile extends StatefulWidget {
  final ChatUser user;

  const ChatUserProfile({super.key, required this.user});

  @override
  State<StatefulWidget> createState() {
    return _ChatUserProfileState();
  }
}

class _ChatUserProfileState extends State<ChatUserProfile> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color.fromRGBO(214, 231, 238, 1.0),
        appBar: AppBar(
          title: Text(
            widget.user.name,
            textAlign: TextAlign.center,
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: mq.width * .05),
            child: Column(children: [
              //For adding some space
              SizedBox(width: mq.width, height: mq.height * .03),

              ClipRRect(
                borderRadius: BorderRadius.circular(
                  mq.height * .1,
                ),
                child: CachedNetworkImage(
                  fit: BoxFit.cover,
                  height: mq.height * .2,
                  width: mq.height * .2,
                  imageUrl: widget.user.image,
                ),
              ),

              //For adding some space
              SizedBox(height: mq.height * .03),

              //User email address
              Text(widget.user.email,
                  style: const TextStyle(color: Colors.black, fontSize: 15)),

              //For adding some space
              SizedBox(width: mq.width, height: mq.height * .03),

              //User about
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('About : ',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  Text(
                    widget.user.about,
                    style: const TextStyle(color: Colors.black54, fontSize: 15),
                  )
                ],
              )
            ]),
          ),
        ),

        //User account create date
        floatingActionButton: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text('Joined On : ',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            Text(
              DateUtil.getLastMessageTime(
                  context: context,
                  time: widget.user.createdAt,
                  showYear: true),
              style: const TextStyle(color: Colors.black54, fontSize: 15),
            )
          ],
        ),
      ),
    );
  }
}
