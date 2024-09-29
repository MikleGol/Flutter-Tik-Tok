import 'dart:io';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_tiktok/constants.dart';
import 'package:flutter_tiktok/views/screens/auth/login_screen.dart';
import 'package:flutter_tiktok/views/screens/home_screen.dart';
import 'package:get/get.dart';
import 'package:flutter_tiktok/models/user.dart' as model;
import 'package:image_picker/image_picker.dart';

class AuthController extends GetxController {
  static AuthController instance = Get.find();
  late Rx<User?> _user;
  late Rx<File> _pickedImage;

  File get profilePhoto => _pickedImage.value;
  User get user => _user.value!;

  @override
  void onReady() {
    super.onReady();
    _user = Rx<User?>(firebaseAuth.currentUser);
    _user.bindStream(firebaseAuth.authStateChanges());
    ever(_user, _setInitialScreen);
  }

  _setInitialScreen(User? user){
    if(user == null){
      Get.offAll(() => LoginScreen());
    } else{
      Get.offAll(() => const HomeScreen());
    }
  }

  void pickImage() async {
    final pickedImage =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      Get.snackbar(
        'Profile Picture',
        'You have successfully selected your profile picture!',
      );
      _pickedImage = Rx<File>(File(pickedImage!.path));
    }
  }

  // Upload to Firestore
  Future<String> _uploadToStorage(File image) async {
    try {
      Reference ref = firebaseStorage
          .ref()
          .child('profilePics')
          .child(firebaseAuth.currentUser!.uid);

      //UploadTask uploadTask = await ref.putFile(image);
      TaskSnapshot snap = await ref.putFile(image);
      String downloadUrl = await snap.ref.getDownloadURL();
      print('Image uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('Upload failed: $e');
      throw Exception('Error uploading image: $e');
    }
  }

  // Registration
  void registerUser(
      String username, String email, String password, File image) async {
    print(username + " " + email + " " + password);
    try {
      if (username.isNotEmpty &&
          email.isNotEmpty &&
          password.isNotEmpty &&
          image != null) {
        //Save
        UserCredential cred = await firebaseAuth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        String downloadUrl = await _uploadToStorage(image);
        print(image);
        model.User user = model.User(
          name: username,
          email: email,
          uid: cred.user!.uid,
          profilePhoto: downloadUrl,
        );
        await firestore
            .collection('users')
            .doc(cred.user!.uid)
            .set(user.toJson());
      } else {
        Get.snackbar(
          'Error Creating Account',
          'Please enter all the fields',
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error Creating Account',
        e.toString(),
      );
    }
  }

  // Login
  void loginUser(String email, String password) async {
    try {
      if (email.isNotEmpty && password.isNotEmpty) {
        await firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
        print('Logging success');

      } else{
        Get.snackbar(
          'Error Logging In',
          'Please enter all the fields',
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error Logging In',
        e.toString(),
      );
    }
  }

  void signOut() async{
    await firebaseAuth.signOut();
  }
}
