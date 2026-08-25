import 'dart:convert';
import 'dart:io';

import 'package:profit_from_it_investors/model/logout_response.dart';
import 'package:profit_from_it_investors/model/profile_response.dart';
import 'package:profit_from_it_investors/network/http_request.dart';
import 'package:profit_from_it_investors/provider/authentication/user_provider.dart';
import 'package:profit_from_it_investors/ui/authentication/login_screen/login_screen.dart';
import 'package:profit_from_it_investors/utility/common.dart';
import 'package:profit_from_it_investors/utility/constant.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:profit_from_it_investors/utility/local_storage.dart';
import 'package:profit_from_it_investors/utility/session_manager.dart';
import 'package:provider/provider.dart';

class ProfileProvider extends ChangeNotifier {
  bool _loginLoading = false;

  bool get loginLoading => _loginLoading;

  ProfileResponse? profileResponse;

  // Get Profile Function
  Future<bool> getProfile(BuildContext context) async {
    _loginLoading = true;
    notifyListeners();
    try {
      Response? response = await httpGet(CMD.getProfile);
      _loginLoading = false;
      notifyListeners();
      if (response == null) return false;
      profileResponse = ProfileResponse.fromJson(jsonDecode(response.body));

      if (profileResponse != null && profileResponse!.status == 200 && profileResponse!.data != null) {
        Provider.of<UserProvider>(navigatorKey.currentContext!, listen: false).updateUser(
            name: profileResponse!.data!.name!,
            image: "",
          email: profileResponse!.data!.email!.toString(),
          code: profileResponse!.data!.code!.toString(),
          mobile: profileResponse!.data!.mobile!.toString(),
        );
        notifyListeners();
        // if (profileResponse!.data!.profile != null && profileResponse!.data!.profile != "null") {
        //   await LocalStorage.saveProfileImage(profileResponse!.data!.profile.toString());
        //   Provider.of<UserProvider>(navigatorKey.currentContext!, listen: false).updateUser(profileResponse!.data!.name!, profileResponse!.data!.profile!);
        //   notifyListeners();
        // }
        return true;
      } else {
        return false;
      }
    } catch (e) {
      debugPrint("error when login =======> ${e.toString()}");
      _loginLoading = false;
      notifyListeners();
      if (e is SocketException) {
        showError("No internet connection. Please check your network.");
      } else {
        showError("Something went wrong. Please try again.");
      }
      return false;
    }
  }

  // Future<void> deleteAccount() async {
  //   _loginLoading = true;
  //   notifyListeners();
  //   try {
  //     var body = {};
  //
  //     Response? response = await httpPost(CMD.deleteAccount, body);
  //     _loginLoading = false;
  //     notifyListeners();
  //     if (response == null) return;
  //     LogoutResponse loginResponse = LogoutResponse.fromJson(jsonDecode(response.body));
  //     if (loginResponse.status == 200) {
  //       LocalStorage.clearAll();
  //       showSuccess(loginResponse.message.toString());
  //       nextRoute(
  //         MaterialPageRoute(
  //           builder: (context) {
  //             return LoginScreen();
  //           },
  //         ),
  //         isClearBackRoutes: true,
  //       );
  //     } else {
  //       showError(loginResponse.message.toString());
  //     }
  //   } catch (e) {
  //     debugPrint("error when login =======> ${e.toString()}");
  //     _loginLoading = false;
  //     notifyListeners();
  //     if (e is SocketException) {
  //       showError("No internet connection. Please check your network.");
  //     } else {
  //       showError("Something went wrong. Please try again.");
  //     }
  //   }
  // }

  File? selectedImage;

  Future<void> pickProfileImage(BuildContext context, ImageSource imageSource) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: imageSource);

    if (pickedFile == null) return; // user canceled

    final File imageFile = File(pickedFile.path);
    final int fileSizeInBytes = await imageFile.length();
    final double fileSizeInMB = fileSizeInBytes / (1024 * 1024);

    // const double maxSizeMB = 2.0;
    //
    // if (fileSizeInMB > maxSizeMB) {
    //   showError('Please select an image smaller than 2 MB');
    //   return;
    // }
    // _cropImage(context, imageFile);
    debugPrint('Selected image size: ${fileSizeInMB.toStringAsFixed(2)} MB');

    // selectedImage = File(pickedFile.path);
    // debugPrint("photo url =========> ${selectedImage!.path}");
    // debugPrint("photo url =========> ${selectedImage!.path.split('/').last}");
    // notifyListeners();
    // await uploadProfileImage(context, selectedImage!);
  }

  // Upload image to server
  // Future<void> uploadProfileImage({required BuildContext context, File? imageFile, String? dob, String? address, Map<String, dynamic>? googleAddress}) async {
  //   _loginLoading = true;
  //   notifyListeners();
  //
  //   try {
  //     Map<String, String> body = {};
  //
  //     if (dob != null && dob.isNotEmpty) {
  //       body["dob"] = dob;
  //     }
  //
  //     if (address != null) {
  //       body['address'] = address;
  //     }
  //
  //     if (googleAddress != null) {
  //       body["location"] = jsonEncode(googleAddress);
  //     }
  //
  //     Response? response = await httpMultipart(CMD.updateProfilePhoto, body, fileKeyName: "photo", image: imageFile);
  //     _loginLoading = false;
  //     notifyListeners();
  //     if (response == null) return;
  //     AddAttendanceResponse memberListResponse = AddAttendanceResponse.fromJson(jsonDecode(response.body));
  //
  //     if (memberListResponse.status == 200) {
  //       await getProfile(context);
  //     } else {
  //       showError(memberListResponse.message.toString());
  //     }
  //   } catch (e) {
  //     debugPrint("Error uploading image: $e");
  //   } finally {
  //     _loginLoading = false;
  //     notifyListeners();
  //   }
  // }

  // Future<void> _cropImage(BuildContext context, File imageFile) async {
  //   final croppedFile = await ImageCropper().cropImage(
  //     sourcePath: imageFile.path,
  //     compressFormat: ImageCompressFormat.jpg,
  //     compressQuality: 100,
  //     uiSettings: [
  //       AndroidUiSettings(
  //         toolbarTitle: 'Cropper',
  //         toolbarColor: Colors.deepOrange,
  //         toolbarWidgetColor: Colors.white,
  //         initAspectRatio: CropAspectRatioPreset.square,
  //         lockAspectRatio: false,
  //         aspectRatioPresets: [CropAspectRatioPreset.original, CropAspectRatioPreset.square, CropAspectRatioPreset.ratio4x3, CropAspectRatioPresetCustom()],
  //       ),
  //       IOSUiSettings(title: 'Cropper', aspectRatioPresets: [CropAspectRatioPreset.original, CropAspectRatioPreset.square, CropAspectRatioPreset.ratio4x3, CropAspectRatioPresetCustom()]),
  //     ],
  //   );
  //   if (croppedFile != null) {
  //     File selectedFile = File(croppedFile.path);
  //     final int fileSizeInBytes = await selectedFile.length();
  //     final double fileSizeInMB = fileSizeInBytes / (1024 * 1024);
  //     debugPrint('after crop image size: ${fileSizeInMB.toStringAsFixed(2)} MB');
  //
  //     if (fileSizeInMB > 2) {
  //       final Directory tempDir = await getTemporaryDirectory();
  //       final String targetPath = path.join(tempDir.path, "compressed_${DateTime.now().millisecondsSinceEpoch}.jpg");
  //
  //       int quality = 95;
  //       XFile? compressedFile;
  //       do {
  //         compressedFile = await FlutterImageCompress.compressAndGetFile(selectedFile.path, targetPath, quality: quality);
  //
  //         final int newSize = await compressedFile!.length();
  //         final double newSizeMB = newSize / (1024 * 1024);
  //         debugPrint('compressed ($quality%) → ${newSizeMB.toStringAsFixed(2)} MB');
  //
  //         quality -= 10; // reduce step by step
  //       } while (quality > 10 && (await compressedFile.length()) / (1024 * 1024) > 2);
  //
  //       selectedImage = File(compressedFile.path);
  //     } else {
  //       selectedImage = File(croppedFile.path);
  //     }
  //
  //     selectedImage = await renameFile(selectedImage!, DateTime.now().millisecondsSinceEpoch.toString());
  //     notifyListeners();
  //     debugPrint("photo url =========> ${selectedImage!.path}");
  //     debugPrint("photo url =========> ${selectedImage!.path.split('/').last}");
  //     final int sizeInBytes = await selectedImage!.length();
  //     final double sizeInMB = sizeInBytes / (1024 * 1024);
  //     debugPrint('after crop image size: ${sizeInMB.toStringAsFixed(2)} MB');
  //     notifyListeners();
  //
  //     await uploadProfileImage(context: context, imageFile: selectedImage!);
  //   }
  // }

  Future<File> renameFile(File originalFile, String newFileName) async {
    try {
      final dir = originalFile.parent.path;
      debugPrint("original file path =======> ${originalFile.path}");
      final extension = path.extension(originalFile.path);
      final newPath = path.join(dir, "$newFileName$extension");
      final newFile = await originalFile.copy(newPath);
      return newFile;
    } catch (e) {
      throw Exception("Error renaming file: $e");
    }
  }

  final bool _policyLoading = false;

  bool get policyLoading => _policyLoading;

  int selectedIndex = 0;

  // List<PolicyList> policyList = [];
  //
  // Future<bool> getPolicy() async {
  //   _policyLoading = true;
  //   notifyListeners();
  //   try {
  //     Response? response = await httpGet(CMD.getPolicy);
  //     _policyLoading = false;
  //     notifyListeners();
  //     if (response == null) return false;
  //     PolicyResponse policyResponse = PolicyResponse.fromJson(jsonDecode(response.body));
  //
  //     if (policyResponse.status == 200 && policyResponse.data != null) {
  //       policyList = policyResponse.data!;
  //       return true;
  //     } else {
  //       return false;
  //     }
  //   } catch (e) {
  //     debugPrint("error when login =======> ${e.toString()}");
  //     _policyLoading = false;
  //     notifyListeners();
  //     if (e is SocketException) {
  //       showError("No internet connection. Please check your network.");
  //     } else {
  //       showError("Something went wrong. Please try again.");
  //     }
  //     return false;
  //   }
  // }

  bool _isLogoutLoading = false;

  bool get isLogoutLoading => _isLogoutLoading;


  Future<void> logout() async {
    _isLogoutLoading = true;
    notifyListeners();
    try {
      Response? response = await httpGet(CMD.logout);
      _isLogoutLoading = false;
      notifyListeners();
      if (response == null) return;
      LogoutResponse loginResponse = logoutResponseFromJson(response.body);
      if (loginResponse.status == 200) {
        await SessionManager.resetToLoggedInUser();
        LocalStorage.clearAll();
        showSuccess(loginResponse.message.toString());
        nextRoute(
          MaterialPageRoute(
            builder: (context) {
              return LoginScreen();
            },
          ),
          isClearBackRoutes: true,
        );
      } else {
        showError(loginResponse.message.toString());
      }
    } catch (e) {
      debugPrint("error when login =======> ${e.toString()}");
      _isLogoutLoading = false;
      notifyListeners();
      if (e is SocketException) {
        showError("No internet connection. Please check your network.");
      } else {
        showError("Something went wrong. Please try again.");
      }
    } finally {
      _isLogoutLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteAccount() async {
    _isLogoutLoading = true;
    notifyListeners();
    try {
      Response? response = await httpGet(CMD.deleteAccount);
      _isLogoutLoading = false;
      notifyListeners();
      if (response == null) return;
      LogoutResponse loginResponse = logoutResponseFromJson(response.body);
      if (loginResponse.status == 200) {
        await SessionManager.resetToLoggedInUser();
        LocalStorage.clearAll();
        showSuccess(loginResponse.message.toString());
        nextRoute(
          MaterialPageRoute(
            builder: (context) {
              return LoginScreen();
            },
          ),
          isClearBackRoutes: true,
        );
      } else {
        showError(loginResponse.message.toString());
      }
    } catch (e) {
      debugPrint("error when login =======> ${e.toString()}");
      _isLogoutLoading = false;
      notifyListeners();
      if (e is SocketException) {
        showError("No internet connection. Please check your network.");
      } else {
        showError("Something went wrong. Please try again.");
      }
    } finally {
      _isLogoutLoading = false;
      notifyListeners();
    }
  }

}
