import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;

String uid;
String name;
String userEmail;
String imageUrl;

/// For checking if the user is already signed into the
/// app using Google Sign In
Future<List<String>> getUser() async {
  await Firebase.initializeApp();

  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool authSignedIn = prefs.getBool('auth') ?? false;
  print(authSignedIn);

  if (authSignedIn == true) {
    if (prefs.getStringList('user') != null) {
      return prefs.getStringList('user');
    }
  }
  return null;
}

Future<String> signInWithEmailPassword(String email, String password) async {
  await Firebase.initializeApp();
  User user;
  try {
    UserCredential userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    user = userCredential.user;

    if (user != null) {
      uid = user.uid;
      userEmail = user.email;
      List<String> listeUser = [
        user.uid,
        user.email,
        user.displayName,
        user.phoneNumber,
        user.photoURL,
      ];

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('auth', true);
      await prefs.setStringList('user', listeUser);
      return 'ok';
    }
  } catch (e) {
    if (e.code == 'user-not-found') {
      print('No user found for that email.');
    } else if (e.code == 'wrong-password') {
      print('Wrong password provided.');
    } else {
      print(e);
    }
  }
  return null;
}

Future<String> signOut() async {
  await _auth.signOut();

  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setBool('auth', false);
  prefs.setStringList('user', []);

  uid = null;
  userEmail = null;

  return 'User signed out';
}
