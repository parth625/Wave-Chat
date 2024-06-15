// ignore_for_file: avoid_print, use_build_context_synchronously

import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:wave_chat/main.dart';
import '../../api/apis.dart';
import '../../helper/dialogs.dart';
import '../home_screen.dart';
// import '../home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isAnimate = false;
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _isAnimate = true;
      });
    });
  }

  //Google Log in Button
  _handleGoogleButtonClick() {
    //For Showing Progress Bar
    Dialogs.showProgressBar(context);
    _signInWithGoogle().then((user) async {
      //For Close Progress Bar
      Navigator.pop(context);

      if (user != null) {
        print('User : ${user.user}');
        print('User Additional Info : ${user.additionalUserInfo}');

        if (await APIs.isUserExists()) {
          Navigator.pushReplacement(
              context, CupertinoPageRoute(builder: (_) => const HomeScreen()));
        } else {
          APIs.createUser().then((value) {
            Navigator.pushReplacement(
                context,
                CupertinoPageRoute(
                  builder: (_) => const HomeScreen(),
                ));
          });
        }
      }
    });
  }

  Future<UserCredential?> _signInWithGoogle() async {
    try {
      await InternetAddress.lookup('google.com');
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      // Obtain the auth details from the request
      final GoogleSignInAuthentication? googleAuth =
          await googleUser?.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );

      // Once signed in, return the UserCredential
      return await APIs.auth.signInWithCredential(credential);
    } catch (exp) {
      log('\n_signInWithGoogle : $exp');
      Dialogs.showSnackBar(context, 'Something Went Wrong(Check Internet)');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    mq = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: const Color.fromRGBO(214, 231, 238, 1.0),
      appBar: AppBar(
        title: const Text('Welcome to Wave Chat'),
      ),
      body: Stack(
        children: [
          //Animated Logo
          AnimatedPositioned(
              duration: const Duration(seconds: 1),
              top: mq.height * .15,
              width: mq.width * .5,
              right: _isAnimate ? mq.width * .25 : -mq.width * .5,
              child: Image.asset('assets/images/icon.png')),
          Positioned(
              bottom: mq.height * .15,
              width: mq.width * .90,
              height: mq.height * .06,
              right: mq.width * .05,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    elevation: 2, backgroundColor: Colors.lightGreen),
                onPressed: () {
                  _handleGoogleButtonClick();
                },
                //Google Icon
                icon: Image.asset('assets/images/google.png',
                    height: mq.height * .04),
                label: RichText(
                  text: const TextSpan(
                      //Default Style for Font
                      style: TextStyle(color: Colors.black, fontSize: 15),
                      children: <TextSpan>[
                        TextSpan(text: 'Sign in With '),
                        TextSpan(
                            text: 'Google',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ]),
                ),
              )),
        ],
      ),
    );
  }
}
