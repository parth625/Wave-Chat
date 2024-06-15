import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart';
import 'package:wave_chat/models/groups.dart';
import '../models/chat_user.dart';
import '../models/message.dart';

class APIs {
  static FirebaseAuth auth = FirebaseAuth.instance;
  final String? id;
  APIs({this.id});

  //For Accessing Firestore Database
  static FirebaseFirestore firestore = FirebaseFirestore.instance;

  //For accessing firebase storage for uploading files
  static FirebaseStorage storage = FirebaseStorage.instance;

  //For getting current user
  static User get user => auth.currentUser!;

  //For storing self information
  static late ChatUser me;

  //For accessing firebase messaging
  static FirebaseMessaging fMessaging = FirebaseMessaging.instance;

  ///-------------------------------------------------NOTIFICATION RELATED-------------------------------------------------------------------

  static Future<void> getFirebaseMessagingToken() async {
    try {
      await fMessaging.requestPermission();

      fMessaging.getToken().then((t) {
        if (t != null) {
          me.pushToken = t;
          log('Push Token : $t');
        }
      });

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        log('Got a message whilst in the foreground!');
        log('Message data: ${message.data}');

        if (message.notification != null) {
          log('Message also contained a notification: ${message.notification}');
        }
      });
    } catch (e) {
      log('getFirebaseMessagingTokenE : $e');
    }
  }

  //For sending push notification
  static Future<void> sendPushNotification(
      ChatUser chatUser, String msg) async {
    try {
      final body = {
        "to": chatUser.pushToken,
        "notification": {
          "title": chatUser.name,
          "body": msg,
          "android_channel_id": "chats"
        },
        "data": {
          "Data: ": "User ID : ${me.id}",
        },
      };
      var res = await post(Uri.parse('https://fcm.googleapis.com/fcm/send'),
          headers: {
            HttpHeaders.contentTypeHeader: 'application/json',
            HttpHeaders.authorizationHeader:
                'key=AAAAvUGO2As:APA91bGl-xId3MkTgzZBsp_nLkv58e9UyBp-kxvyQ6gs6NWGg2EkqTjSasutzgXH38nmW8-g86XoZK8mJyaM79BK734RO5PcQKnbMinB85i3jr0TgajqfGpIQmS6JgQEwks9bqa9N7An'
          },
          body: jsonEncode(body));
      log('Response status: ${res.statusCode}');
      log('Response body: ${res.body}');
    } catch (e) {
      log('sendPushNotificationE : $e');
    }
  }

  //------------------------------------------------------------------------------------------------------------

//Function to create user if user not exists
  static Future<void> createUser() async {
    final time = DateTime.now().millisecondsSinceEpoch.toString();
    final chatUser = ChatUser(
        id: user.email!,
        name: user.displayName.toString(),
        email: user.email.toString(),
        about: "Hey there 👋",
        createdAt: time,
        image: user.photoURL.toString(),
        isOnline: false,
        lastActive: time,
        pushToken: '',
        groups: []);

    return await firestore
        .collection('users')
        .doc(user.email)
        .set(chatUser.toJson());
  }


//Function to check whether user exists or not
  static Future<bool> isUserExists() async {
    return (await firestore
            .collection('users')
            .doc(auth.currentUser!.uid)
            .get())
        .exists;
  }

  //For getting self information
  static Future<void> getSelfInfo() async {
    await firestore
        .collection('users')
        .doc(user.email)
        .get()
        .then((user) async {
      if (user.exists) {
        me = ChatUser.fromJson(user.data()!);
        await getFirebaseMessagingToken();

        //For setting user status to active
        APIs.updateActiveStatus(true);
      } else {
        await createUser().then((user) => getSelfInfo());
      }
    });
  }

  //For getting a id of knows users
  static Stream<QuerySnapshot<Map<String, dynamic>>> getChatUsersID() {
    //Display users except itself
    return firestore
        .collection('users')
        .doc(user.email)
        .collection('chat_users')
        .snapshots();
  }

  //For getting all users from firestore database
  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllUsers(
      List<String>? userIDs) {
    log('User IDs : $userIDs');
    if (userIDs != null && userIDs.isNotEmpty) {
      //Display users except itself
      return firestore
          .collection('users')
          .where('id', whereIn: userIDs)
          .snapshots();
    } else {
      return const Stream.empty();
    }
  }

  //For Updating user profile information
  static Future<void> updateUserInfo() async {
    await firestore
        .collection('users')
        .doc(user.email)
        .update({'name': me.name, 'about': me.about});
  }

  static Future<void> sendFirstMessage(
      ChatUser chatUser, String msg, Type type) async {
    await firestore
        .collection('users')
        .doc(chatUser.id)
        .collection('chat_users')
        .doc(user.email)
        .set({}).then((value) => sendMessage(chatUser, msg, type));
  }

  //For Updating user profile picture
  static Future<void> updateProfilePicture(File file) async {
    //getting extension of image
    final ext = file.path.split('.').last;

    //Storage file ref with image path
    final ref = storage.ref().child('profile_pictures/${user.email}.$ext');

    //Uploading image
    await ref
        .putFile(file, SettableMetadata(contentType: 'image/$ext'))
        .then((p0) {
      log('Data Transferred : ${p0.bytesTransferred / 1024} kb');
    });

    //Update image in firestore database
    me.image = await ref.getDownloadURL();
    await firestore
        .collection('users')
        .doc(user.email)
        .update({'image': me.image});
    log('Profile Picture Updated');
  }

  //For getting specific user info
  static Stream<QuerySnapshot<Map<String, dynamic>>> getUserInfo(
      ChatUser chatUser) {
    return firestore
        .collection('users')
        .where('id', isEqualTo: chatUser.id)
        .snapshots();
  }

  //update online or last active status of user
  static Future<void> updateActiveStatus(bool isOnline) async {
    firestore.collection('users').doc(user.email).update({
      'is_online': isOnline,
      'last_active': DateTime.now().millisecondsSinceEpoch.toString(),
      'push_token': me.pushToken
    });
  }



  //-------------------------------Chat Screen related API-------------------------------//

  static String getConversationID(String userEmail, String otherUserEmail) {
    String u1 = userEmail.split('@').first;
    String u2 = otherUserEmail.split('@').first;
    return u1.compareTo(u2) <= 0 ? '${u1}_$u2' : '${u2}_$u1';
  }

// For getting all messages of a specific conversation
  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllMessages(
      ChatUser chatUser) {
    // // Ensure 'chats' collection exists
    // final CollectionReference<Map<String, dynamic>> chatsCollection =
    //     firestore.collection('chats');

    return firestore
        .collection(
            'chats/${getConversationID(user.email!, chatUser.id)}/messages/')
        .orderBy('send', descending: true)
        .snapshots();
  }

// For sending message
  static Future<void> sendMessage(
      ChatUser chatUser, String msg, Type type) async {
    // Ensures 'chats' collection exists
    final CollectionReference<Map<String, dynamic>> chatsCollection =
        firestore.collection('chats');

    // Ensures conversation subcollection exists
    final CollectionReference<Map<String, dynamic>> msgCollection =
        chatsCollection
            .doc(getConversationID(user.email!, chatUser.id))
            .collection('messages');

    // Message sending time (also used as id)
    final time = DateTime.now().millisecondsSinceEpoch.toString();

    // Message to send
    final Message message = Message(
        msg: msg,
        toId: chatUser.id,
        read: '',
        type: type,
        fromId: user.email.toString(),
        send: time);

    await msgCollection.doc(time).set(message.toJson()).then((value) =>
        sendPushNotification(chatUser, type == Type.text ? msg : 'image'));
  }

  //For updating read status of message
  static Future<void> updateMessageReadStatus(Message message) async {
    firestore
        .collection(
            'chats/${getConversationID(message.toId, message.fromId)}/messages/')
        .doc(message.send)
        .update({'read': DateTime.now().millisecondsSinceEpoch.toString()});
  }

  //For getting only last message of specific chat
  static Stream<QuerySnapshot<Map<String, dynamic>>> getLastMessage(
      ChatUser chatUser) {
    return firestore
        .collection(
            'chats/${getConversationID(user.email!, chatUser.id)}/messages/')
        .orderBy('send', descending: true)
        .limit(1)
        .snapshots();
  }

  //For sending image
  static Future<void> sendImage(ChatUser chatUser, File file) async {
    //for getting image file extension
    final ext = file.path.split('.').last;

    final ref = storage.ref().child(
        'images/${getConversationID(user.email!, chatUser.id)}/${DateTime.now().millisecondsSinceEpoch}.$ext');

    //uploading image
    await ref
        .putFile(file, SettableMetadata(contentType: 'image/$ext'))
        .then((p0) {
      log('Data transferred : ${p0.bytesTransferred / 1024}');
    });

    final imageUrl = await ref.getDownloadURL();

    //send image
    await sendMessage(chatUser, imageUrl, Type.image);
  }

  //For sending video
  static Future<void> sendVideo(ChatUser chatUser, File video) async {
    // Get the video file extension
    final ext = video.path.split('.').last;

    // Create a reference in Firebase storage for the video
    final ref = FirebaseStorage.instance.ref().child(
        'videos/${getConversationID(user.email!, chatUser.id)}/${DateTime.now().millisecondsSinceEpoch}.$ext');

    try {
      // Upload the video file to Firebase Storage
      await ref.putFile(video, SettableMetadata(contentType: 'video/$ext'));

      final videoUrl = await ref.getDownloadURL();

      // Send the video message
      await sendMessage(chatUser, videoUrl, Type.video);
    } catch (e) {
      log('Error uploading video: $e');
      rethrow;
    }
  }

  //For deleting message and image
  static Future<void> deleteMessage(Message message) async {
    firestore
        .collection(
            'chats/${getConversationID(message.toId, message.fromId)}/messages/')
        .doc(message.send)
        .delete();

    if (message.type == Type.image) {
      storage.refFromURL(message.msg).delete();
    }
  }

  //For updating a message
  static Future<void> updateMessage(Message message, String updatedMsg) async {
    firestore
        .collection(
            'chats/${getConversationID(message.toId, message.fromId)}/messages/')
        .doc(message.send)
        .update({'msg': updatedMsg});
  }

  //For adding user to chat screen
  static Future<bool> addChatUser(String email) async {
    final data = await firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .get();

    if (data.docs.isNotEmpty && data.docs.first.id != user.email) {
      //user exists

      firestore
          .collection('users')
          .doc(user.email)
          .collection('chat_users')
          .doc(data.docs.first.id)
          .set({});
      return true;
    } else {
      //user does not exists
      return false;
    }
  }

  ///--------------------------------------GROUPS------------------------------

  //For getting all the groups of a particular user
  Stream<List<String>> getUserGroups() {
    return firestore
        .collection('users')
        .doc(user.email)
        .snapshots()
        .map((docSnapshot) {
      if (docSnapshot.exists) {
        // Get the 'groups' field from the user document
        List<dynamic>? groupIds = docSnapshot.data()?['groups'];
        if (groupIds != null && groupIds.isNotEmpty) {
          // Return the list of group IDs as a stream
          return groupIds.cast<String>();
        }
      }
      // Return an empty list if no groups are found
      return [];
    });
  }

  //For Creating a new group
  createGroup(String userName, String? id, String groupName) async {
    try {
      final Groups group = Groups(
          groupName: groupName,
          admin: "${id}_$userName",
          members: [],
          groupId: '',
          recentMessage: '',
          recentMessageTime: '',
          recentMessageSender: ''
          );

      // Add the group document to Firestore
      final groupDocRef =
          await firestore.collection('groups').add(group.toJson());

      // Update the group ID with the document ID generated by Firestore
      await groupDocRef.update({
        'groupId': groupDocRef.id,
        'members': FieldValue.arrayUnion((["${user.email}_$userName"]))
      });

      // Update the user's 'groups' field with the new group
      await firestore.collection('users').doc(user.email).update({
        'groups': FieldValue.arrayUnion(["${groupDocRef.id}_$groupName"]),
      });
    } catch (error) {
      // Handle any errors that occur during the process
      log('Error creating group: $error');
      rethrow; // Rethrow the error to be caught by the caller if needed
    }
  }

  //For getting chats of a particular group
  getGroupChats(String groupId) {
    return firestore
        .collection('groups')
        .doc(groupId)
        .collection('group_messages')
        .orderBy('time')
        .snapshots();
  }

  //For getting name of admin of the group
  Future<String> getGroupAdmin(String groupId) async {
    try {
      DocumentSnapshot groupSnapshot =
          await firestore.collection('groups').doc(groupId).get();
      if (groupSnapshot.exists) {
        Map<String, dynamic>? data =
            groupSnapshot.data() as Map<String, dynamic>?;

        if (data != null && data.containsKey('admin')) {
          return data['admin'] as String;
        } else {
          // Admin field not found or null
          return '';
        }
      } else {
        // Group document not found
        return '';
      }
    } catch (error) {
      log('Error getting group admin: $error');
      return ''; // Return empty string or handle error as needed
    }
  }

  //For getting group members of group
  getGroupMembers(String groupId) {
    return firestore.collection('groups').doc(groupId).snapshots();
  }

  //For searching a particular group
  searchGroupByName(String groupName) {
    return firestore
        .collection('groups')
        .where('groupName', isEqualTo: groupName)
        .get();
  }

  Future<bool> isUserJoined(
      String groupName, String groupId, String userName) async {
    DocumentReference userDocumentReference =
        firestore.collection('users').doc(id);
    DocumentSnapshot documentSnapshot = await userDocumentReference.get();

    List<dynamic> groups = await documentSnapshot['groups'];

    if (groups.contains("${groupId}_$groupName")) {
      return true;
    } else {
      return false;
    }
  }

  //Toggling group join or exit
  Future toggleGroupJoin(
      String userName, String groupName, String groupId) async {
    DocumentReference userDocumentReference =
        firestore.collection('users').doc(id);

    DocumentReference groupDocumentReference =
        firestore.collection('groups').doc(groupId);

    DocumentSnapshot documentSnapshot = await userDocumentReference.get();

    List<dynamic> groups = await documentSnapshot['groups'];

    //If user has our group --> remove them or
    //If user has not our groups --> join them

    if (groups.contains('${groupId}_$groupName')) {
      await userDocumentReference.update({
        'groups': FieldValue.arrayRemove(["${groupId}_$groupName"])
      });

      await groupDocumentReference.update({
        'members': FieldValue.arrayRemove(["${id}_$userName"])
      });
    } else {
      await userDocumentReference.update({
        'groups': FieldValue.arrayUnion(["${groupId}_$groupName"])
      });

      await groupDocumentReference.update({
        'members': FieldValue.arrayUnion(["${id}_$userName"])
      });
    }
  }

  //Sending group message
  sendGroupMessage(String groupId, Map<String, dynamic> chatMessageData) async {
    firestore
        .collection('groups')
        .doc(groupId)
        .collection('group_messages')
        .add(chatMessageData);
    firestore.collection('groups').doc(groupId).update({
      "recentMessage": chatMessageData['message'],
      "recentMessageSender": chatMessageData['sender'],
      "recentMessageTime": chatMessageData['time'].toString()
    });
  }
}
