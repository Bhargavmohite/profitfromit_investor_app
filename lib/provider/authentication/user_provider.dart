
// ignore_for_file: dead_code, dead_null_aware_expression

import 'package:flutter/material.dart';

import '../../utility/local_storage.dart';

class UserProvider extends ChangeNotifier {

  String _name = "";
  String _image = "";
  String _code = "";
  String _email = "";
  String _mobile = "";

  String get name => _name;
  String get image => _image;
  String get code => _code;
  String get email => _email;
  String get mobile => _mobile;

  UserProvider() {
    loadUserInfo();
  }

  Future<void> loadUserInfo() async {
    _name = await LocalStorage.getName() ?? "";
    _image = await LocalStorage.getProfileImage() ?? "";
    _code = await LocalStorage.getCode() ?? "";
    _email = await LocalStorage.getEmail() ?? "";
    _mobile = await LocalStorage.getMobile() ?? "";
    notifyListeners();
  }

  void updateUser({ required String name, required String image, required String code, required String email, required String mobile}) {
    _name = name;
    _image = image;
    _code = code;
    _email = email;
    _mobile = mobile;

    debugPrint("Name =======> $name");
    debugPrint("image =======> $image");
    LocalStorage.saveName(name);
    LocalStorage.saveProfileImage(image);
    LocalStorage.saveCode(code);
    LocalStorage.saveEmail(email);
    LocalStorage.saveMobile(mobile);
    notifyListeners();
  }
}