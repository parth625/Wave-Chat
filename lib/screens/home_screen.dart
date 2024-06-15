import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wave_chat/screens/group_screen.dart';
import 'package:wave_chat/screens/profile_screen.dart';
import 'package:wave_chat/widgets/chat_user_card.dart';
import '../api/apis.dart';
import '../helper/dialogs.dart';
import '../models/chat_user.dart';
// import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<StatefulWidget> createState() {
    return HomeScreenState();
  }
}

class HomeScreenState extends State<HomeScreen> {
  //For storing all users
  List<ChatUser> _list = [];

  //For storing searched item
  final List<ChatUser> _searchList = [];

  //For storing search status
  bool _isSearching = false;

  String? userName = FirebaseAuth.instance.currentUser!.displayName;

  @override
  void initState() {
    super.initState();
    APIs.getSelfInfo();

    SystemChannels.lifecycle.setMessageHandler((message) {
      log(message!);

      //For updating user active status according to lifecycle event
      //resume -> active or online
      //pause -> inactive or offline
      //If user is logged in only then updat e status
      if (APIs.auth.currentUser != null) {
        if (message.contains('resume')) APIs.updateActiveStatus(true);
        if (message.contains('pause')) APIs.updateActiveStatus(false);
      }
      return Future.value(message);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(

        //For hiding keyboard when touch detect on screen

        onTap: FocusScope.of(context).unfocus,
        // ignore: deprecated_member_use
        child: WillPopScope(
          onWillPop: () {
            if (_isSearching) {
              setState(() {
                _isSearching = !_isSearching;
              });
              return Future.value(false);
            } else {
              return Future.value(true);
            }
          },
          child: Scaffold(
            backgroundColor: const Color.fromRGBO(214, 231, 238, 1.0),
            appBar: AppBar(
                centerTitle: true,
                title: _isSearching
                    ? TextField(
                        decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Name, Email...'),
                        autofocus: true,
                        style:
                            const TextStyle(fontSize: 16, letterSpacing: 0.5),
                        onChanged: (val) {
                          //Search logic
                          _searchList.clear();
                          for (var i in _list) {
                            if (i.name
                                    .toLowerCase()
                                    .contains(val.toLowerCase()) ||
                                i.email
                                    .toLowerCase()
                                    .contains(val.toLowerCase())) {
                              _searchList.add(i);
                            }
                            setState(() {
                              _searchList;
                            });
                          }
                        },
                      )
                    : const Text('Wave Chat'),
                actions: [
                  //Search user button
                  IconButton(
                      onPressed: () {
                        setState(() {
                          _isSearching = !_isSearching;
                        });
                      },
                      icon: Icon(_isSearching
                          ? CupertinoIcons.clear_circled_solid
                          : Icons.search)),
                ]),

            drawer: Drawer(
              backgroundColor: const Color.fromRGBO(214, 231, 238, 1.0),
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 50),
                children: <Widget>[
                  Icon(Icons.account_circle,
                      size: 150, color: Colors.grey.shade600),
                  const SizedBox(
                    height: 15,
                  ),
                  Text(
                    APIs.me.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.black54, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  const Divider(height: 1),
                  ListTile(
                    onTap: () {
                      Navigator.pushReplacement(
                          context,
                          CupertinoPageRoute(
                              builder: (_) => ProfileScreen(
                                    user: APIs.me,
                                  )));
                    },
                    selectedColor: Theme.of(context).primaryColor,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    leading: const Icon(
                      Icons.person,
                      size: 25,
                    ),
                    title: const Text(
                      "Profile",
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                  ListTile(
                    onTap: () {},
                    selectedColor: Theme.of(context).primaryColor,
                    selected: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    leading: const Icon(
                      Icons.home,
                      size: 25,
                    ),
                    title: const Text(
                      "Home",
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                  ListTile(
                    onTap: () {
                      Navigator.push(
                          context,
                          CupertinoPageRoute(
                              builder: (_) => GroupHomeScreen(user: APIs.me)));
                    },
                    selectedColor: Theme.of(context).primaryColor,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    leading: const Icon(
                      Icons.group,
                      size: 25,
                    ),
                    title: const Text(
                      "Groups",
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),

            //Getting IDs of only known users
            body: StreamBuilder(
              stream: APIs.getChatUsersID(),
              builder: (context, snapshot) {
                switch (snapshot.connectionState) {
                  case ConnectionState.active:
                  //If data is loading
                  case ConnectionState.waiting:
                  case ConnectionState.none:
                  // return const Center(child: CircularProgressIndicator());
                  //If data is retrieved
                  case ConnectionState.done:
                    return StreamBuilder(
                      //Get only those user, whose ids are provided
                      stream: APIs.getAllUsers(
                          snapshot.data?.docs.map((e) => e.id).toList() ?? []),
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

                            _list = data
                                    ?.map((e) => ChatUser.fromJson(e.data()))
                                    .toList() ??
                                [];

                            if (_list.isNotEmpty) {
                              return ListView.builder(
                                  itemCount: _isSearching
                                      ? _searchList.length
                                      : _list.length,
                                  physics: const BouncingScrollPhysics(),
                                  itemBuilder: (context, index) {
                                    return ChatUserCard(
                                        user: _isSearching
                                            ? _searchList[index]
                                            : _list[index]);
                                  });
                            } else {
                              return const Center(
                                  child: Text(
                                'No Connections Found',
                                style: TextStyle(fontSize: 20),
                              ));
                            }
                        }
                      },
                    );
                }
              },
            ),

            //Add user button
            floatingActionButton: FloatingActionButton(
              elevation: 1,
              backgroundColor: const Color.fromRGBO(89, 213, 224, 1.0),
              child: const Icon(Icons.comment_rounded),
              onPressed: () {
                _showAddUserDialog();
              },
            ),
          ),
        ));
  }

  void _showAddUserDialog() {
    String email = '';

    showDialog(
        context: context,
        builder: (_) => AlertDialog(
                contentPadding: const EdgeInsets.only(
                    left: 24, right: 24, top: 20, bottom: 10),
                title: const Row(
                  children: [
                    Icon(
                      Icons.person,
                      color: Colors.blue,
                      size: 28,
                    ),
                    Text(
                      ' Add User',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                    )
                  ],
                ),
                content: TextFormField(
                  maxLines: null,
                  onChanged: (value) => email = value,
                  decoration: InputDecoration(
                    hintText: 'Email',
                    prefixIcon: const Icon(
                      Icons.email,
                      color: Colors.blue,
                    ),
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
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontSize: 16, color: Colors.blue),
                    ),
                  ),

                  //Update button
                  MaterialButton(
                    onPressed: () async {
                      //For hiding bottom sheet
                      Navigator.pop(context);

                      if (email.isNotEmpty) {
                        await APIs.addChatUser(email).then((value) {
                          if (!value) {
                            Dialogs.showSnackBar(
                                context, 'User does not exists!');
                          }
                        });
                      }
                    },
                    child: const Text('Add',
                        style: TextStyle(fontSize: 16, color: Colors.blue)),
                  )
                ]));
  }
}
