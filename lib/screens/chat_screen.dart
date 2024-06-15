// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wave_chat/screens/chat_user_profile.dart';
import '../api/apis.dart';
import '../helper/date_util.dart';
import '../main.dart';
import '../models/chat_user.dart';
import '../models/message.dart';
import '../widgets/message_card.dart';

class ChatScreen extends StatefulWidget {
  final ChatUser user;

  const ChatScreen({super.key, required this.user});

  @override
  State<StatefulWidget> createState() {
    return ChatScreenState();
  }
 }

class ChatScreenState extends State<ChatScreen> {
  //List of messages
  List<Message> list = [];

  //For handing message text changes
  final _textController = TextEditingController();

  //_showEmoji : For storing the value of emoji for showing and hiding
  //_isUploading : For checking if image is upload or not
  bool _showEmoji = false, _isUploding = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: WillPopScope(
        onWillPop: () {
          if (_showEmoji) {
            setState(() {
              _showEmoji = !_showEmoji;
            });
            return Future.value(false);
          } else {
            return Future.value(true);
          }
        },
        child: SafeArea(
          child: Scaffold(
              appBar: AppBar(
                automaticallyImplyLeading: false,
                flexibleSpace: _appBar(),
              ),
              backgroundColor: const Color.fromRGBO(214, 231, 238, 1.0),
              body: Column(children: [
                Expanded(
                  child: StreamBuilder(
                    stream: APIs.getAllMessages(widget.user),
                    builder: (context, snapshot) {
                      switch (snapshot.connectionState) {
                        case ConnectionState.active:
                        //If data is loading
                        case ConnectionState.waiting:
                        case ConnectionState.none:
                        // return const Center(child: CircularProgressIndicator());

                        //If data is retrieved
                        case ConnectionState.done:
                          final data = snapshot.data?.docs;
                          list = data
                                  ?.map((e) => Message.fromJson(e.data()))
                                  .toList() ??
                              [];

                          if (list.isNotEmpty) {
                            return ListView.builder(
                                itemCount: list.length,
                                reverse: true,
                                physics: const BouncingScrollPhysics(),
                                itemBuilder: (context, index) {
                                  return MessageCard(message: list[index]);
                                });
                          } else {
                            return const Center(
                                child: Text(
                              'Say Hi! 👋',
                              style: TextStyle(fontSize: 20),
                            ));
                          }
                      }
                    },
                  ),
                ),

                //Progress indicator for showing uploding
                if (_isUploding)
                  const Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding:
                            EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                        child: CircularProgressIndicator(
                          color: Colors.blue,
                          strokeWidth: 3,
                        ),
                      )),

                _chatInput(),

                //Show and hide emojis on keyboard emoji button click
                if (_showEmoji)
                  SizedBox(
                    height: mq.height * .35,
                    child: EmojiPicker(
                      textEditingController: _textController,
                      config: Config(
                        height: 256,
                        emojiViewConfig: EmojiViewConfig(
                            emojiSizeMax: 28 * (Platform.isIOS ? 1.20 : 1.0),
                            columns: 8,
                            backgroundColor:
                                const Color.fromRGBO(214, 231, 238, 1.0)),
                      ),
                    ),
                  )
              ])),
        ),
      ),
    );
  }

  Widget _appBar() {
    return InkWell(
        onTap: () {
          Navigator.push(
              context,
              CupertinoPageRoute(
                  builder: (_) => ChatUserProfile(user: widget.user)));
        },
        child: StreamBuilder(
            stream: APIs.getUserInfo(widget.user),
            builder: (context, snapshot) {
              final data = snapshot.data?.docs;
              final list =
                  data?.map((e) => ChatUser.fromJson(e.data())).toList() ?? [];
              return Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  //Back button
                  IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon:
                          const Icon(Icons.arrow_back, color: Colors.black45)),

                  //User profile picture
                  ClipRRect(
                      borderRadius: BorderRadius.circular(mq.height * .03),
                      child: CachedNetworkImage(
                        height: mq.height * .05,
                        width: mq.height * .05,
                        fit: BoxFit.cover,
                        imageUrl:
                            list.isNotEmpty ? list[0].image : widget.user.image,
                        placeholder: (context, url) =>
                            const CircularProgressIndicator(),
                        errorWidget: (context, url, error) =>
                            const CircleAvatar(child: Icon(Icons.person)),
                      )),

                  //For adding some space
                  const SizedBox(width: 10),

                  Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        //User name
                        Text(list.isNotEmpty ? list[0].name : widget.user.name,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87)),

                        //User last seen time
                        Text(
                            list.isNotEmpty
                                ? list[0].isOnline
                                    ? 'Online'
                                    : DateUtil.getLastActiveTime(
                                        context: context,
                                        lastActive: list[0].lastActive)
                                : DateUtil.getLastActiveTime(
                                    context: context,
                                    lastActive: widget.user.lastActive),
                            style: const TextStyle(
                                fontSize: 13, color: Colors.black54))
                      ])
                ],
              );
            }));
  }

  Widget _chatInput() {
    return Padding(
      padding: EdgeInsets.symmetric(
          vertical: mq.height * .01, horizontal: mq.width * .025),
      child: Row(
        children: [
          Expanded(
            child: Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              child: Row(
                children: [
                  // Emoji Button
                  IconButton(
                    onPressed: () {
                      FocusScope.of(context).unfocus();
                      setState(() {
                        _showEmoji = !_showEmoji;
                      });
                    },
                    icon: const Icon(Icons.emoji_emotions, color: Colors.blue),
                  ),

                  // Message field
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      // maxLines: 10,
                      onTap: () {
                        // For showing and hiding emoji keyboard
                        if (_showEmoji) {
                          setState(() {
                            _showEmoji = !_showEmoji;
                          });
                        }
                      },
                      style: const TextStyle(color: Colors.blueAccent),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Message',
                        hintStyle: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ),

                  // Gallery image button
                  IconButton(
                    onPressed: () async {
                      _showBottomSheet();
                    },
                    icon: const Icon(Icons.attachment_rounded,
                        color: Colors.blue),
                  ),

                  // Pick image from camera to send
                  IconButton(
                    onPressed: () async {
                      final ImagePicker picker = ImagePicker();

                      // Pick an image
                      final XFile? image = await picker.pickImage(
                        source: ImageSource.camera,
                        imageQuality: 60,
                      );

                      if (image != null) {
                        log('Image path : ${image.path}');
                        setState(() {
                          _isUploding = true;
                        });
                        await APIs.sendImage(widget.user, File(image.path));
                        setState(() {
                          _isUploding = false;
                        });
                      }
                    },
                    icon: const Icon(Icons.camera_alt_rounded,
                        color: Colors.blue),
                  ),
                  SizedBox(width: mq.width * .02),
                ],
              ),
            ),
          ),

          // Send message button
          MaterialButton(
            onPressed: () {
              if (_textController.text.isNotEmpty) {
                if (list.isEmpty) {
                  APIs.sendFirstMessage(
                      widget.user, _textController.text, Type.text);
                } else {
                  APIs.sendMessage(
                      widget.user, _textController.text, Type.text);
                }
                _textController.text = '';
              }
            },
            padding:
                const EdgeInsets.only(top: 12, bottom: 12, left: 12, right: 8),
            minWidth: 0,
            shape: const CircleBorder(),
            color: const Color.fromARGB(255, 77, 171, 80),
            child: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }

  void _showBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      builder: (_) {
        return ListView(
          padding: EdgeInsets.only(
            top: mq.height * .02,
            bottom: mq.height * .07,
          ),
          shrinkWrap: true,
          children: [
            SizedBox(height: mq.height * .02),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    final ImagePicker picker = ImagePicker();
                    final List<XFile> images =
                        await picker.pickMultiImage(imageQuality: 30);
                    for (var i in images) {
                      log('Image path : ${i.path}');
                      setState(() {
                        _isUploding = true;
                      });
                      await APIs.sendImage(widget.user, File(i.path))
                          .then((value) {});
                      setState(() {
                        _isUploding = false;
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    fixedSize: Size(mq.width * .3, mq.height * .1),
                    shape: const CircleBorder(),
                  ),
                  child: const Icon(
                    Icons.image,
                    color: Colors.blue,
                    size: 40,
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    try {
                      FilePickerResult? result =
                          await FilePicker.platform.pickFiles(
                        type: FileType.video,
                        allowMultiple: true,
                      );
                      if (result != null) {
                        for (var filePicker in result.files) {
                          File file = File(filePicker.path!);
                          setState(() {
                            _isUploding = true;
                          });
                          await APIs.sendVideo(widget.user, file).then((value) {
                            setState(() {
                              _isUploding = false;
                            });
                          });
                        }
                      }
                    } catch (e) {
                      log('Error picking videos: $e');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    fixedSize: Size(mq.width * .3, mq.height * .1),
                    shape: const CircleBorder(),
                  ),
                  child: const Icon(
                    Icons.videocam_rounded,
                    color: Colors.blue,
                    size: 40,
                  ),
                )
              ],
            )
          ],
        );
      },
    );
  }
}
