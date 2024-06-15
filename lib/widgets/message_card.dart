// ignore_for_file: prefer_const_constructors
import 'dart:developer';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:wave_chat/helper/date_util.dart';
import 'package:wave_chat/widgets/video_player.dart';
import '../api/apis.dart';
import '../helper/dialogs.dart';
import '../main.dart';
import '../models/message.dart';

class MessageCard extends StatefulWidget {
  const MessageCard({super.key, required this.message});

  final Message message;

  @override
  State<StatefulWidget> createState() {
    return MessageCardState();
  }
}

class MessageCardState extends State<MessageCard> {
  @override
  Widget build(BuildContext context) {
    bool isMe = APIs.user.email == widget.message.fromId;

    return InkWell(
      child: isMe ? ourMessage() : othersMessage(),
      onLongPress: () {
        _showBottomSheet(isMe);
      },
    );
  }

  //sender or other user message
  Widget othersMessage() {
    //update last read status if sender and receiver are different
    if (widget.message.read.isEmpty) {
      APIs.updateMessageReadStatus(widget.message);
      // print('Read Time Updated');
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        //Other user Message
        Flexible(
          child: Container(
            padding: EdgeInsets.all(widget.message.type == Type.text
                ? mq.width * .04
                : mq.width * .02),
            margin: EdgeInsets.symmetric(
                horizontal: mq.width * .04, vertical: mq.height * .01),
            decoration: BoxDecoration(
                color: const Color.fromARGB(255, 190, 219, 233),
                border:
                    Border.all(color: const Color.fromARGB(255, 208, 239, 255)),
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                    bottomRight: Radius.circular(30))),

            //Message
            child: widget.message.type == Type.text
                ?
                //Show text
                Text(
                    widget.message.msg,
                    style: const TextStyle(fontSize: 15, color: Colors.black87),
                  )
                : widget.message.type == Type.image
                    ?
                    //Show image
                    ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: CachedNetworkImage(
                          imageUrl: widget.message.msg,
                          placeholder: (context, url) =>
                              const CircularProgressIndicator(strokeWidth: 3),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.image, size: 70),
                        ),
                      )
                    : IconButton(
                        onPressed: () {
                          VideoPlayerScreen(
                            videoUrl: widget.message.msg,
                          );
                        },
                        icon: Icon(Icons.videocam_rounded),
                      ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(right: mq.width * .04),

          //Message send time
          child: Text(
            DateUtil.getFormattedTime(
                context: context, time: widget.message.send),
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
        )
      ],
    );
  }

  //other user message
  Widget ourMessage() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            //For adding some space
            SizedBox(width: mq.width * .03),

            //Double tick blue icon for message read
            if (widget.message.read.isNotEmpty)
              const Icon(
                Icons.done_all_rounded,
                color: Colors.blue,
                size: 20,
              ),

            //For adding some space
            const SizedBox(width: 2),

            Text(
              DateUtil.getFormattedTime(
                  context: context, time: widget.message.send),
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ],
        ),
        Flexible(
          child: Container(
            padding: EdgeInsets.all(widget.message.type == Type.image
                ? mq.width * .02
                : widget.message.type == Type.image
                    ? mq.width * .02
                    : mq.width * .04),
            margin: EdgeInsets.symmetric(
                horizontal: mq.width * .04, vertical: mq.height * .005),
            decoration: BoxDecoration(
                color: const Color.fromRGBO(183, 231, 238, 1.0),
                border:
                    Border.all(color: const Color.fromRGBO(183, 231, 238, 1.0)),
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                    bottomLeft: Radius.circular(30))),
            child: widget.message.type == Type.text
                ?
                //Show text
                Text(
                    widget.message.msg,
                    style: const TextStyle(fontSize: 15, color: Colors.black87),
                  )
                : widget.message.type == Type.image
                    ?
                    //Show image
                    //Show image
                    ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: CachedNetworkImage(
                          imageUrl: widget.message.msg,
                          placeholder: (context, url) =>
                              const CircularProgressIndicator(strokeWidth: 3),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.image, size: 70),
                        ),
                      )
                    : IconButton(
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => VideoPlayerScreen(
                                        videoUrl: widget.message.msg,
                                      )));
                        },
                        icon: Icon(
                          Icons.videocam_rounded,
                          size: 50,
                        ),
                      ),
          ),
        ),
      ],
    );
  }

  //Bottom sheet for modifying message
  void _showBottomSheet(bool isMe) {
    showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(25), topRight: Radius.circular(25))),
        builder: (_) {
          return ListView(
            padding:
                EdgeInsets.only(top: mq.height * .01, bottom: mq.height * .07),
            shrinkWrap: true,
            children: [
              Container(
                height: 4,
                margin: EdgeInsets.symmetric(
                    vertical: mq.height * .015, horizontal: mq.width * .4),
                decoration: BoxDecoration(
                    color: Colors.grey, borderRadius: BorderRadius.circular(8)),
              ),

              widget.message.type == Type.text
                  ?
                  //Copy text
                  _OptionItem(
                      icon: Icon(Icons.copy_all_rounded,
                          color: Colors.blue, size: 26),
                      name: 'Copy Text',
                      onTap: () async {
                        await Clipboard.setData(
                            ClipboardData(text: widget.message.msg))
                            .then((value) {
                          //for hiding bottom sheet
                          Navigator.pop(context);

                          Dialogs.showSnackBar(context, 'Text Copied!');
                        });
                      })
                  :
                  //Save image
                  widget.message.type == Type.image
                      ? _OptionItem(
                          icon: Icon(Icons.download_rounded,
                              color: Colors.blue, size: 26),
                          name: 'Save Image',
                          onTap: () async {
                            try {
                              await GallerySaver.saveImage(widget.message.msg,
                                      albumName: 'Wave Chat')
                                  .then((success) {
                                //For hiding bottom sheet
                                Navigator.pop(context);

                                if (success != null && success) {
                                  Dialogs.showSnackBar(
                                      context, 'Image Saved Successfully');
                                }
                              });
                            } catch (e) {
                              log('ErrorDownloadingImage: $e');
                            }
                          })

                      //Download Video
                      : _OptionItem(
                          icon: Icon(Icons.download_rounded,
                              color: Colors.blue, size: 26),
                          name: 'Save Video',
                          onTap: () async {
                            try {
                              await GallerySaver.saveVideo(widget.message.msg,
                                      albumName: 'Wave Chat')
                                  .then((success) {
                                //For hiding bottom sheet
                                Navigator.pop(context);

                                if (success != null && success) {
                                  Dialogs.showSnackBar(
                                      context, 'Video Saved Successfully');
                                }
                              });
                            } catch (e) {
                              log('ErrorDownloadingImage: $e');
                            }
                          }),
              if(isMe)
              Divider(
                endIndent: mq.width * .04,
                indent: mq.width * .04,
              ),

              if (widget.message.type == Type.text && isMe)
                //Edit message
                _OptionItem(
                    icon: Icon(Icons.edit, size: 26, color: Colors.blue),
                    name: 'Edit Message',
                    onTap: () {
                      Navigator.pop(context);

                      _showUpdateMessageDialog();
                    }),

              if (isMe)
                //Delete message
                _OptionItem(
                    icon: Icon(Icons.delete_forever, color: Colors.red),
                    name: 'Delete Message',
                    onTap: () async {
                      await APIs.deleteMessage(widget.message).then((value) {
                        Navigator.pop(context);

                        Dialogs.showSnackBar(context, "Message Deleted");
                      });
                    }),

              Divider(
                endIndent: mq.width * .04,
                indent: mq.width * .04,
              ),

              //Send time
              _OptionItem(
                  icon: Icon(Icons.remove_red_eye, color: Colors.blue),
                  name:
                      'Sent at: ${DateUtil.getMessageTime(context: context, time: widget.message.send)}',
                  onTap: () {}),

              //Read time
              _OptionItem(
                  icon:
                      Icon(Icons.remove_red_eye, color: Colors.green, size: 26),
                  name: widget.message.read.isEmpty
                      ? 'Read at: Not seen yet'
                      : 'Read at: ${DateUtil.getMessageTime(context: context, time: widget.message.read)}',
                  onTap: () {}),
            ],
          );
        });
  }

  void _showUpdateMessageDialog() {
    String updatedMsg = widget.message.msg;

    showDialog(
        context: context,
        builder: (_) => AlertDialog(
                contentPadding:
                    EdgeInsets.only(left: 24, right: 24, top: 20, bottom: 10),
                title: Row(
                  children: const [
                    Icon(
                      Icons.message_rounded,
                      color: Colors.blue,
                      size: 28,
                    ),
                    Text(
                      ' Update Message',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                    )
                  ],
                ),
                content: TextFormField(
                  initialValue: updatedMsg,
                  maxLines: null,
                  onChanged: (value) => updatedMsg = value,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15)),
                  ),
                ),
                actions: [
                  //Cancel button
                  MaterialButton(
                    onPressed: () {
                      //For hiding bottom sheet
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Cancel',
                      style: TextStyle(fontSize: 16, color: Colors.blue),
                    ),
                  ),

                  //Update button
                  MaterialButton(
                    onPressed: () {
                      //For hiding bottom sheet
                      Navigator.pop(context);

                      APIs.updateMessage(widget.message, updatedMsg);

                      Dialogs.showSnackBar(context, "Message Updated");
                    },
                    child: Text('Update',
                        style: TextStyle(fontSize: 16, color: Colors.blue)),
                  )
                ]));
  }
}

class _OptionItem extends StatelessWidget {
  final Icon icon;
  final String name;
  final VoidCallback onTap;
  const _OptionItem(
      {required this.icon, required this.name, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTap(),
      child: Padding(
        padding: EdgeInsets.only(
            left: mq.width * .04,
            top: mq.height * .015,
            bottom: mq.height * .015),
        child: Row(children: [
          icon,
          Flexible(
              child: Text(
            '   $name',
            style: TextStyle(
                fontSize: 15, color: Colors.black54, letterSpacing: 0.5),
          ))
        ]),
      ),
    );
  }
}
