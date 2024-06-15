import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:wave_chat/models/chat_user.dart';
import 'package:wave_chat/screens/home_screen.dart';
import 'package:wave_chat/screens/profile_screen.dart';
import 'package:wave_chat/screens/search_group.dart';

import '../api/apis.dart';
import '../helper/dialogs.dart';
import '../widgets/group_card.dart';

class GroupHomeScreen extends StatefulWidget {
  final ChatUser user;

  const GroupHomeScreen({super.key, required this.user});

  @override
  State<GroupHomeScreen> createState() => _GroupHomeScreenState();
}

class _GroupHomeScreenState extends State<GroupHomeScreen> {
  bool _isLoading = false;
  String groupName = "";

  Stream<List<String>>? groupsStream; // Initialize with an empty stream

  String? userName = APIs.user.displayName;

  String? id = FirebaseAuth.instance.currentUser?.email;

  @override
  void initState() {
    super.initState();
    // Initialize the user groups stream
    groupsStream = APIs().getUserGroups();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Groups'),
        actions: [

          //Search Group
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                CupertinoPageRoute(builder: (_) => const SearchGroup()),
              );
            },
            icon: const Icon(Icons.search),
          ),
        ],
      ),

      //Navigating drawer
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
                userName!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.black54, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              const Divider(height: 1),

              //Profile Screen
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
                onTap: () {
                  Navigator.pushReplacement(context,
                      CupertinoPageRoute(builder: (_) => const HomeScreen()));
                },
                selectedColor: Theme.of(context).primaryColor,
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
                onTap: () {},
                selectedColor: Theme.of(context).primaryColor,
                selected: true,
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
          )),
      backgroundColor: const Color.fromRGBO(214, 231, 238, 1.0),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : groupList(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).primaryColor,
        onPressed: () {
          popUpDialog(context);
        },
        child: const Icon(
          Icons.group_add_rounded,
          color: Colors.black,
          size: 30,
        ),
      ),
    );
  }

  //Create group dialog
  popUpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: const Text(
              'Create a Group',
              textAlign: TextAlign.left,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  onChanged: (val) {
                    setState(() {
                      groupName = val;
                    });
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Theme.of(context).primaryColor),
                        borderRadius:
                            const BorderRadius.all(Radius.circular(30))),
                    enabledBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Theme.of(context).primaryColor),
                      borderRadius: const BorderRadius.all(Radius.circular(30)),
                    ),
                  ),
                )
              ],
            ),
            actions: [

              // Cancel button
              MaterialButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),

              //Create button
              MaterialButton(
                onPressed: () async {
                  if (groupName != "") {
                    setState(() {
                      _isLoading = true;
                    });

                    APIs(id: FirebaseAuth.instance.currentUser!.email)
                        .createGroup(userName!, id, groupName)
                        .then((val) {
                      _isLoading = false;
                    });

                    Navigator.of(context).pop();

                    Dialogs.showSnackBar(context, 'Group Created Successfully');
                  }
                },
                child: const Text('Create'),
              )
            ],
          );
        });
      },
    );
  }

  Widget groupList() {
    return StreamBuilder<List<String>>(
      stream: groupsStream,
      builder: (context, snapshot) {
        log("Group Snapshots: $snapshot");
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          // Handle data from the stream
          List<String>? userGroups = snapshot.data;
          if (userGroups != null && userGroups.isNotEmpty) {
            // Render UI with user groups
            return ListView.builder(
              itemCount: userGroups.length,
              itemBuilder: (context, index) {
                // Use the group ID to display group name or details
                int reverseIndex = userGroups.length - index - 1;
                return GroupCard(
                    groupName: getName(userGroups[reverseIndex]),
                    groupId: getId(userGroups[reverseIndex]),
                    userName: APIs.me.name);
              },
            );
          } else {
            // If user has no groups, display a message
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.group_add,
                      size: 40,
                    ),
                    Text(
                      'You have not joined any group, To create a new group tap on Create Group Icon.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
        }
      },
    );
  }

  getName(String res) {
    return res.split('_').last;
  }

  getId(String res) {
    return res.split('_').first;
  }
}
