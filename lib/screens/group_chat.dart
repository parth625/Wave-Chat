// ignore_for_file: deprecated_member_use
import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:wave_chat/screens/group_info.dart';
import 'package:wave_chat/widgets/group_message_card.dart';
import '../api/apis.dart';

class GroupChatScreen extends StatefulWidget {
  final String groupId;
  final String groupName;
  final String userName;
  const GroupChatScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.userName,
  });

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  Stream<QuerySnapshot>? chats;
  String admin = "";
  bool _showEmoji = false;
  TextEditingController messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    initializeChatAndAdmin();
  }

  initializeChatAndAdmin() async {
    try {
      // Fetch group chats
      final groupChatsStream = await APIs().getGroupChats(widget.groupId);
      setState(() {
        chats = groupChatsStream;

      });

      // Fetch group admin
      final groupAdmin = await APIs().getGroupAdmin(widget.groupId);
      setState(() {
        admin = groupAdmin;
      });
    } catch (error) {
      // Handle any errors that occur during initialization
      log('Error initializing chat and admin: $error');
    }
  }

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
              title: Text(widget.groupName),
              actions: [
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (_) => GroupInfoScreen(
                          admin: admin,
                          groupId: widget.groupId,
                          groupName: widget.groupName,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.info),
                )
              ],
            ),
            backgroundColor: const Color.fromRGBO(214, 231, 238, 1.0),
            body: Column(
              // Use Column as the parent widget
              children: [
                Expanded(
                  child: chatMessage(),
                ),
                chatInput(),
                if (_showEmoji)
                  SizedBox(
                    height: MediaQuery.of(context).size.height * .35,
                    child: EmojiPicker(
                      textEditingController: messageController,
                      config: Config(
                        height: 256,
                        emojiViewConfig: EmojiViewConfig(
                          emojiSizeMax: 28 * (Platform.isIOS ? 1.20 : 1.0),
                          columns: 8,
                          backgroundColor: const Color.fromRGBO(214, 231, 238, 1.0),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget chatInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
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
                      onTap: () => setState(() {
                        if(_showEmoji){
                          _showEmoji = !_showEmoji;
                        }
                      }),
                      controller: messageController,
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      style: const TextStyle(color: Colors.blueAccent),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Send a message...',
                        hintStyle: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          MaterialButton(
            onPressed: () {
              if (messageController.text.isNotEmpty) {
                sendMessage();
              }
            },
            padding: const EdgeInsets.all(12),
            minWidth: 0,
            shape: const CircleBorder(),
            color: const Color.fromARGB(255, 77, 171, 80),
            child: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }

  Widget chatMessage() {
    // print('Chats: $chats');
    return StreamBuilder<QuerySnapshot>(
      stream: chats,
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        } else if (snapshot.hasData) {
          return Expanded(
            child: ListView.builder(
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                return GroupMessageCard(
                  message: snapshot.data!.docs[index]['message'],
                  sender: snapshot.data!.docs[index]['sender'],
                  isSendByMe:
                      widget.userName == snapshot.data!.docs[index]['sender'],
                );
              },
            ),
          );
        } else {
          return const Center(
            child: Text('No group messages available'),
          );
        }
      },
    );
  }

  sendMessage() {
    if (messageController.text.isNotEmpty) {
      Map<String, dynamic> chatMessageMap = {
        "message": messageController.text,
        "sender": widget.userName,
        "time": DateTime.now().millisecondsSinceEpoch
      };

      APIs().sendGroupMessage(widget.groupId, chatMessageMap);
      setState(() {
        messageController.clear();
      });
    }
  }
}
