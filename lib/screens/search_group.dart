import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:wave_chat/screens/group_chat.dart';

import '../api/apis.dart';
import '../helper/dialogs.dart';

class SearchGroup extends StatefulWidget {
  const SearchGroup({super.key});

  @override
  State<SearchGroup> createState() => _SearchGroupState();
}

class _SearchGroupState extends State<SearchGroup> {
  bool isLoading = false;
  TextEditingController searchController = TextEditingController();
  QuerySnapshot? searchSnapshot;
  bool hasUserSearched = false;
  String? userName = FirebaseAuth.instance.currentUser?.displayName;

  bool isJoined = false;
  User? user;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
  }

  getName(String res) {
    return res.split('_').last;
  }

  getId(String res) {
    return res.split('_').first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(214, 231, 238, 1.0),
      appBar: AppBar(
        title: const Text("Search Groups"),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            color: const Color.fromRGBO(89, 213, 224, 1.0),
            child: Row(
              children: [
                Expanded(
                    child: TextField(
                  controller: searchController,
                  decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: "Search Group....",
                      hintStyle: TextStyle(fontSize: 16)),
                )),
                GestureDetector(
                  onTap: () {
                    initiateSearchMethod();
                  },
                  child: Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.2),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: const Icon(Icons.search),
                  ),
                )
              ],
            ),
          ),
          isLoading
              ? Center(
                  child: CircularProgressIndicator(
                  color: Theme.of(context).primaryColor,
                ))
              : groupList()
        ],
      ),
    );
  }

  initiateSearchMethod() {
    if (searchController.text.isNotEmpty) {
      setState(() {
        isLoading = true;
      });

      APIs().searchGroupByName(searchController.text).then((snapshot) {
        setState(() {
          searchSnapshot = snapshot;
          // print('Search Snapshot: $searchSnapshot');
          isLoading = false;
          hasUserSearched = true;
        });
      });
    }
  }

  groupList() {
    return hasUserSearched
        ? ListView.builder(
            shrinkWrap: true,
            itemCount: searchSnapshot!.docs.length,
            itemBuilder: (context, index) {
              return groupTile(
                  userName!,
                  searchSnapshot!.docs[index]['groupName'],
                  searchSnapshot!.docs[index]['groupId'],
                  searchSnapshot!.docs[index]['admin']);
            })
        : Container();
  }

  joinedOrNot(
      String userName, String groupId, String groupName, String admin) async {
    await APIs(id: user!.email)
        .isUserJoined(groupName, groupId, userName)
        .then((value) {
      setState(() {
        isJoined = value;
      });
    });
  }

  groupTile(String userName, String groupName, String groupId, String admin) {
    joinedOrNot(userName, groupId, groupName, admin);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      leading: CircleAvatar(
        radius: 30,
        backgroundColor: Colors.blue,
        child: Text(groupName.substring(0, 1).toUpperCase()),
      ),
      title: Text(
        groupName,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        'Admin: ${getName(admin)}',
        style: const TextStyle(color: Colors.black54),
      ),
      trailing: InkWell(
          onTap: () async {
            await APIs(id: user!.email)
                .toggleGroupJoin(userName, groupName, groupId);

            if (isJoined) {
              setState(() {
                isJoined = !isJoined;
                Dialogs.showSnackBar(context, "Group joined successfully");
              });

              Future.delayed(const Duration(seconds: 2), () {
                Navigator.push(
                    context,
                    CupertinoPageRoute(
                        builder: (_) => GroupChatScreen(
                            groupId: groupId,
                            groupName: groupName,
                            userName: userName)));
              });
            } else {
              setState(() {
                isJoined = !isJoined;
                Dialogs.showSnackBar(context, "Left the group $groupName");
              });
            }
          },
          child: isJoined
              ? Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.black,
                      border: Border.all(color: Colors.white, width: 1)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: const Text(
                    'Joined',
                    style: TextStyle(color: Colors.white),
                  ),
                )
              : Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Theme.of(context).primaryColor,
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: const Text(
                    'Join',
                    style: TextStyle(color: Colors.white),
                  ),
                )),
    );
  }
}
