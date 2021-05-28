import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart' as firebase_core;
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth.dart';
import 'dart:io' as io;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await firebase_core.Firebase.initializeApp();

  runApp(ChoosenImage());
}

final ImagePicker _picker = ImagePicker();
PickedFile _imagePickerFile;

class ChoosenImage extends StatefulWidget {
  ChoosenImage({Key key}) : super(key: key);

  @override
  _ChoosenImageState createState() => _ChoosenImageState();
}

class _ChoosenImageState extends State<ChoosenImage> {
  User user;
  bool currentUser = false;
  String link;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
            appBar: AppBar(
              title: Text('Choosen Image Upload Firebase Storage'),
              actions: [
                IconButton(
                    icon: Icon(Icons.single_bed),
                    onPressed: () {
                      setState(() {
                        currentUser = true;
                      });
                    })
              ],
            ),
            body: currentUser == false
                ? Center(
                    child: CircularProgressIndicator(),
                  )
                : FutureBuilder(
                    future: signInFirebase(),
                    builder: (BuildContext context, AsyncSnapshot snapshot) {
                      return snapshot.hasError
                          ? Text('Hata oluştu')
                          : snapshot.connectionState ==
                                      ConnectionState.waiting ||
                                  snapshot.connectionState ==
                                      ConnectionState.none
                              ? Center(
                                  child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                        'Giriş yapılıyor lütfen bekleyiniz...'),
                                    CircularProgressIndicator()
                                  ],
                                ))
                              : FutureBuilder(
                                  future: uploadData(_imagePickerFile),
                                  initialData: 0,
                                  builder: (BuildContext context,
                                      AsyncSnapshot snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    }

                                    return Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          choosenImageWidget,
                                          snapshot.data == null
                                              ? Text('')
                                              : Text(snapshot.data.toString())
                                        ]);
                                  },
                                );
                    },
                  )));
  }

  Widget get choosenImageWidget {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
                onPressed: choosenImageWithPicker, child: Text('Choose Image'))
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _imagePickerFile == null
                ? Text('Henüz bir seçim yapılmadı..')
                : SizedBox(
                    width: 100,
                    height: 100,
                    child: Image.network(_imagePickerFile.path),
                  )
          ],
        ),
      ],
    );
  }

  Future<void> choosenImageWithPicker() async {
    try {
      final file = await _picker.getImage(source: ImageSource.gallery);
      setState(() {
        _imagePickerFile = file;
      });
    } catch (err) {
      print(err);
    }
  }

  Future<void> signInFirebase() async {
    String userName = '';
    String pass = '';
    try {
      await signInWithEmailPassword(userName, pass)
          .then((value) => value == null
              ? ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Giriş yapılamadı..')))
              : ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Başarıyla Giriş yapıldı..'))))
          .catchError((err) => {currentUser = false});
    } catch (err) {
      print(err);
    }
  }

  Future<String> uploadData(PickedFile file) async {
    try {
      if (file == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No file was selected')));
        return null;
      }
      firebase_storage.Reference ref = firebase_storage.FirebaseStorage.instance
          .ref('')
          .child('')
          .child('$uid.jpg');
      final metadata = firebase_storage.SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {'picked-file-path': file.path});
      if (kIsWeb) {
        ref.putData(await file.readAsBytes(), metadata);
      } else {
        ref.putFile(io.File(file.path), metadata);
      }
      return ref.getDownloadURL();
    } catch (err) {
      print(err);
      return null;
    }
  }

  Future<void> addUserInfo(Map<String, dynamic> user) async {
    try {
      CollectionReference users =
          FirebaseFirestore.instance.collection('users2');
      return users
          .doc(uid)
          .set(user)
          .then((value) => {
                print('success user added'),
              })
          .catchError((onError) => print(onError));
    } catch (err) {}
  }
}
