import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:wave_chat/screens/chat_user_profile.dart';

import '../../main.dart';
import '../../models/chat_user.dart';

class ProfileDialog extends StatelessWidget {
  const ProfileDialog({super.key, required this.user});

  final ChatUser user;
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: EdgeInsets.zero,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: SizedBox(
        width: mq.width * .6,
        height: mq.height * .35,
        child: Stack(
          children: [
            Positioned(
              top: mq.height * .06,
              left: mq.width * .1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                  mq.height * .30,
                ),
                child: CachedNetworkImage(
                  fit: BoxFit.cover,
                  width: mq.width * .57,
                  height: mq.width * .57,
                  imageUrl: user.image,
                ),
              ),
            ),
            Positioned(
              top: mq.height * .015,
              left: mq.width * .04,
              width: mq.width * .55,
              child: Text(
                user.name,
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
              ),
            ),
            Positioned(
              top: mq.height * .002,
              right: 5,
              child: MaterialButton(
                  shape: const CircleBorder(),
                  minWidth: 0,
                  padding: const EdgeInsets.all(0),
                  onPressed: () {
                    Navigator.pop(context);

                    Navigator.push(
                        context,
                        CupertinoPageRoute(
                            builder: (_) => ChatUserProfile(user: user)));
                  },
                  child: const Icon(
                    Icons.info_outline_rounded,
                    color: Colors.blue,
                  )),
            ),
          ],
        ),
      ),
    );
  }
}
