// ignore_for_file: use_build_context_synchronously, avoid_print
import 'dart:developer';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wave_chat/screens/group_screen.dart';
import 'package:wave_chat/screens/home_screen.dart';
import '../api/apis.dart';
import '../helper/dialogs.dart';
import '../main.dart';
import '../models/chat_user.dart';
import 'auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final ChatUser user;

  const ProfileScreen({super.key, required this.user});

  @override
  State<StatefulWidget> createState() {
    return _ProfileScreenState();
  }
}

class _ProfileScreenState extends State<ProfileScreen> {
  //For saving form State
  final _formKey = GlobalKey<FormState>();
  String? _image;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color.fromRGBO(214, 231, 238, 1.0),
        appBar: AppBar(
          title: const Text('Profile Screen'),
        ),
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
                  widget.user.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.black54, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                const Divider(height: 1),
                ListTile(
                  onTap: () {},
                  selectedColor: Theme.of(context).primaryColor,
                  selected: true,
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
            )),

        //Log out Button
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: Colors.redAccent,
          onPressed: () async {
            //Showing Progress Bar
            Dialogs.showProgressBar(context);

            await APIs.updateActiveStatus(false).then((value) async {
              //Sign out from app
              await APIs.auth.signOut().then((value) async {
                await GoogleSignIn().signOut().then((value) {
                  //Remove Progress Bar
                  Navigator.pop(context);

                  //Remove Profile Screen
                  Navigator.pop(context);

                  APIs.auth = FirebaseAuth.instance;

                  Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()));
                });
              });
            });
          },
          icon: const Icon(Icons.logout),
          label: const Text('Log Out'),
          shape: const StadiumBorder(),
        ),

        body: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: mq.width * .05),
              child: Column(children: [
                //For adding some space
                SizedBox(width: mq.width, height: mq.height * .03),

                Stack(
                  children: [
                    //User profile picture

                    _image != null
                        ?
                        //Image from gallery
                        ClipRRect(
                            borderRadius: BorderRadius.circular(
                              mq.height * .1,
                            ),
                            child: Image.file(
                              File(_image!),
                              fit: BoxFit.cover,
                              height: mq.height * .2,
                              width: mq.height * .2,
                            ),
                          )
                        :
                        //Image from server
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

                    //Profile Edit Button
                    Positioned(
                      bottom: 0,
                      right: -10,
                      child: MaterialButton(
                          elevation: 1,
                          onPressed: () {
                            _showBottomSheet();
                          },
                          color: Colors.white,
                          shape: const CircleBorder(),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.blue,
                          )),
                    )
                  ],
                ),

                //For adding some space
                SizedBox(height: mq.height * .03),

                //User email address
                Text(widget.user.email,
                    style:
                        const TextStyle(color: Colors.black54, fontSize: 15)),

                //For adding some space
                SizedBox(width: mq.width, height: mq.height * .05),

                //User's name
                TextFormField(
                  initialValue: widget.user.name,
                  onSaved: (val) => APIs.me.name = val ?? '',
                  validator: (val) =>
                      val != null && val.isNotEmpty ? null : 'Name Required',
                  decoration: InputDecoration(
                      focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.blue),
                          borderRadius: BorderRadius.circular(15)),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(color: Colors.blue)),
                      prefixIcon: const Icon(
                        Icons.person,
                        color: Colors.blue,
                      ),
                      hintText: 'eg. John Cena',
                      label: const Text('Name')),
                ),

                //For adding some space
                SizedBox(width: mq.width, height: mq.height * .02),

                //User's about field
                TextFormField(
                  onSaved: (val) => APIs.me.about = val ?? '',
                  validator: (val) =>
                      val != null && val.isNotEmpty ? null : 'About Required',
                  initialValue: widget.user.about,
                  decoration: InputDecoration(
                      focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.blue),
                          borderRadius: BorderRadius.circular(15)),
                      border: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.blue),
                          borderRadius: BorderRadius.circular(15)),
                      prefixIcon: const Icon(Icons.info_outline_rounded,
                          color: Colors.blue),
                      hintText: 'eg. Hey, there!',
                      label: const Text('About')),
                ),

                //For adding some space
                SizedBox(width: mq.width, height: mq.height * .04),

                //Profile update button
                ElevatedButton.icon(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      APIs.updateUserInfo().then((value) {
                        Dialogs.showSnackBar(
                            context, 'Profile Updated Successfully!!');
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      minimumSize: Size(mq.width * .4, mq.height * .055)),
                  icon: const Icon(Icons.edit, color: Colors.white),
                  label: const Text(
                    'UPDATE',
                    style: TextStyle(color: Colors.white, fontSize: 15),
                  ),
                )
              ]),
            ),
          ),
        ),
      ),
    );
  }

  //Bottom shit for picking profile picture for user
  void _showBottomSheet() {
    showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(25), topRight: Radius.circular(25))),
        builder: (_) {
          return ListView(
            padding:
                EdgeInsets.only(top: mq.height * .02, bottom: mq.height * .07),
            shrinkWrap: true,
            children: [
              const Text('Pick Profile Picture',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: mq.height * .02),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                      onPressed: () async {
                        final ImagePicker picker = ImagePicker();

                        //Pick Image
                        final XFile? image = await picker.pickImage(
                            source: ImageSource.gallery, imageQuality: 30);

                        if (image != null) {
                          print('Image Path = ${image.path}');

                          //For hiding Bottom sheet

                          Navigator.pop(context);

                          setState(() {
                            _image = image.path;
                          });

                          APIs.updateProfilePicture(File(_image!));

                          Dialogs.showSnackBar(
                              context, 'Profile Picture Updated');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          fixedSize: Size(mq.width * .3, mq.height * .1),
                          shape: const CircleBorder()),
                      child: Image.asset('assets/images/add_image.png')),
                  ElevatedButton(
                      onPressed: () async {
                        final ImagePicker picker = ImagePicker();

                        final XFile? image = await picker.pickImage(
                            source: ImageSource.camera, imageQuality: 30);

                        if (image != null) {
                          log('Image Path = ${image.path}');

                          //For hiding bottom sheet
                          Navigator.pop(context);
                          setState(() {
                            _image = image.path;
                          });

                          APIs.updateProfilePicture(File(_image!));

                          Dialogs.showSnackBar(
                              context, 'Profile Picture Updated');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          fixedSize: Size(mq.width * .3, mq.height * .1),
                          shape: const CircleBorder()),
                      child: Image.asset('assets/images/camera.png'))
                ],
              )
            ],
          );
        });
  }
}
