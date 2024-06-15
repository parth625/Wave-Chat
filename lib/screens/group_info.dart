import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'group_screen.dart';
import '../api/apis.dart';

class GroupInfoScreen extends StatefulWidget {
  final String groupId;
  final String groupName;
  final String admin;
  const GroupInfoScreen(
      {super.key,
      required this.admin,
      required this.groupId,
      required this.groupName});

  @override
  State<GroupInfoScreen> createState() => _GroupInfoScreenState();
}

class _GroupInfoScreenState extends State<GroupInfoScreen> {
  Stream<DocumentSnapshot>? members;

  @override
  void initState() {
    super.initState();
    getGroupMembers();
  }

  void getGroupMembers() async {
    try {
      var val = APIs().getGroupMembers(widget.groupId);
      setState(() {
        log('Users $val');
        members = val;
      });
    } catch (error) {
      log('Error fetching group members: $error');
      // Handle the error accordingly
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color.fromRGBO(214, 231, 238, 1.0),
        appBar: AppBar(
          title: Text(widget.groupName),
          actions: [
            IconButton(
                onPressed: () {
                  showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('Exit'),
                          content: const Text(
                              'Are you sure you want to exit the group?'),
                          actions: [
                            IconButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                icon: const Icon(
                                  Icons.cancel,
                                  color: Colors.green,
                                )),
                            IconButton(
                                onPressed: () {
                                  APIs(
                                          id: FirebaseAuth
                                              .instance.currentUser!.email)
                                      .toggleGroupJoin(getName(widget.admin),
                                          widget.groupName, widget.groupId)
                                      .whenComplete(() {
                                    Navigator.pushReplacement(
                                        context,
                                        CupertinoPageRoute(
                                            builder: (_) => GroupHomeScreen(
                                                  user: APIs.me,
                                                )));
                                  });
                                },
                                icon: const Icon(
                                  Icons.done,
                                  color: Colors.red,
                                ))
                          ],
                        );
                      });
                },
                icon: const Icon(Icons.exit_to_app))
          ],
        ),
        body: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color:
                      const Color.fromRGBO(89, 213, 224, 1.0).withOpacity(.3),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.blue,
                      child: Text(
                        widget.groupName.substring(0, 1).toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Group: ${widget.groupName}'),
                        const SizedBox(height: 5),
                        Text('Admin: ${getName(widget.admin)}')
                      ],
                    )
                  ],
                ),
              ),
              memberList()
            ],
          ),
        ));
  }

  Widget memberList() {
    return Expanded(
      child: StreamBuilder<DocumentSnapshot>(
        stream: members,
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>?;

            if (data != null && data['members'] != null) {
              final List<dynamic> members = data['members'];

              if (members.isNotEmpty) {
                return ListView.builder(
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.blue,
                        child: Text(
                          getSubName(data['members'][index]),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                      title: Text(getName(members[index])),
                      subtitle: Text(getId(data['members'][index])),
                    );
                  },
                );
              } else {
                return const Center(child: Text('No Members'));
              }
            } else {
              return const Center(child: Text('No Members'));
            }
          } else if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else {
            return const Center(child: Text('Failed to fetch group members'));
          }
        },
      ),
    );
  }

  getName(String name) {
    return name.split('_').last;
  }

  getId(String name) {
    return name.split('_').first;
  }

  getSubName(String name) {
    return name.split('_').last.substring(0, 1).toUpperCase();
  }
}
