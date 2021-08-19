import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/progressbar.dart';
import '../models/user.dart';
import '../screens/homescreen.dart';


class LoginScreen extends StatefulWidget {
  LoginScreen({ Key key}) : super(key: key);

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  SharedPreferences preferences;

  bool isLoggedIn = false;
  bool isLoading = false;
  FirebaseUser currentUser;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    isSignedIn();
  }
  void isSignedIn() async{
    this.setState(() {
      isLoggedIn = true;
    });

    preferences = await SharedPreferences.getInstance();
    isLoggedIn = await googleSignIn.isSignedIn();

    if(isLoggedIn){
      Navigator.push(context, MaterialPageRoute(builder: (context) => HomeScreen(currentUserId: preferences.getString("id"))));
    }

    this.setState(() {
      isLoading = false;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [Colors.lightBlueAccent , Colors.purpleAccent]
            )),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              "Chat Buddy",
              style: TextStyle(
                fontSize: 60.0,
                color: Colors.white,
              ),
            ),
            GestureDetector(
              onTap: ControlSignIn,
              child: Center(
                child: Column(
                  children: <Widget>[
                    Container(
                        width: 270.0,
                        height: 70.0,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image:
                            AssetImage("assets/images/google_signin_button.png"),
                            fit: BoxFit.cover,
                          ),
                        )),
                    Padding(
                      padding: EdgeInsets.all(10),
                      child: isLoading ? circularProgress() : Container(),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<Null> ControlSignIn() async {
    preferences = await SharedPreferences.getInstance();
    this.setState(() {
      isLoading = true;
    });
    GoogleSignInAccount googleUser = await googleSignIn.signIn();
    GoogleSignInAuthentication googleSignInAuthentication =
    await googleUser.authentication;

    final AuthCredential credential = GoogleAuthProvider.getCredential(
        idToken: googleSignInAuthentication.idToken,
        accessToken: googleSignInAuthentication.accessToken);

    FirebaseUser firebaseUser =
        (await firebaseAuth.signInWithCredential(credential)).user;

    if (firebaseUser !=  null) {
      final QuerySnapshot resultQuery = await Firestore.instance
          .collection("users")
          .where("id", isEqualTo: firebaseUser.uid)
          .getDocuments();
      final List<DocumentSnapshot> documentSnapshots = resultQuery.documents;
      if(documentSnapshots.length == 0)
      {
        Firestore.instance.collection("users").document(firebaseUser.uid).setData({
          "nickname" : firebaseUser.displayName,
          "photoUrl" : firebaseUser.photoUrl,
          "id" : firebaseUser.uid,
          "aboutMe": " I am using Chatter Box",
          "createdAt": DateTime.now().millisecondsSinceEpoch.toString(),
          "chattingWith": null,
        });
        currentUser = firebaseUser;
        await preferences.setString("id", currentUser.uid);
        await preferences.setString("nickname", currentUser.displayName);
        await preferences.setString("photoUrl", currentUser.photoUrl);


      }
      else
      {
        currentUser = firebaseUser;
        await preferences.setString("id", documentSnapshots[0]["id"]);
        await preferences.setString("nickname", documentSnapshots[0]["nickname"]);
        await preferences.setString("photoUrl", documentSnapshots[0]["photoUrl"]);
        await preferences.setString("aboutMe", documentSnapshots[0]["aboutMe"]);

        Fluttertoast.showToast(msg: " signin Success");
        this.setState(() {
          isLoading = false;
        });
        Navigator.push(context, MaterialPageRoute(builder: (context) => HomeScreen(currentUserId: firebaseUser.uid)));

      }
    }
    else {
      Fluttertoast.showToast(msg: "try again , signin failed");
      this.setState(() {
        isLoading = false;
      });
    }
  }
}
