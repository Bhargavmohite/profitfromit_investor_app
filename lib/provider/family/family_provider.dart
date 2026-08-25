import 'package:flutter/material.dart';
import 'package:profit_from_it_investors/model/dashboard_response.dart';
import 'package:profit_from_it_investors/utility/session_manager.dart';

class FamilyProvider extends ChangeNotifier {
  List<FamilyList> _familyList = [];

  FamilyList? _selectedFamily;

  List<FamilyList> get familyList => _familyList;

  FamilyList? get selectedFamily => _selectedFamily;

  String get selectedUserId => _selectedFamily?.id?.toString() ?? "";

  /// Called after Dashboard API
  void setFamilyList(List<FamilyList> list) {
    _familyList = list;

    if (_familyList.isEmpty) {
      _selectedFamily = null;
      notifyListeners();
      return;
    }
    final currentUserId = SessionManager.userId;
    try {
      _selectedFamily = _familyList.firstWhere((e) => e.id.toString() == currentUserId);
    } catch (_) {
      _selectedFamily = _familyList.first;
    }
    notifyListeners();
  }

  void selectFamily(FamilyList family) {
    _selectedFamily = family;
    SessionManager.changeUser(family.id.toString());
    notifyListeners();
  }

  bool isSelected(FamilyList family) {
    return _selectedFamily?.id == family.id;
  }

  /// Call when user logs out
  void clear() {
    _familyList.clear();
    _selectedFamily = null;
    notifyListeners();
  }
}

// import 'package:flutter/material.dart';
// import 'package:profit_from_it_investors/model/dashboard_response.dart';
// import 'package:profit_from_it_investors/utility/local_storage.dart';
//
// class FamilyProvider extends ChangeNotifier {
//   List<FamilyList> _familyList = [];
//
//   FamilyList? _selectedFamily;
//
//   List<FamilyList> get familyList => _familyList;
//
//   FamilyList? get selectedFamily => _selectedFamily;
//
//   /// Called after Dashboard API
//   Future<void> setFamilyList(List<FamilyList> list) async {
//     _familyList = list;
//
//     if (_familyList.isEmpty) {
//       _selectedFamily = null;
//       notifyListeners();
//       return;
//     }
//
//     final savedId = await LocalStorage.getId();
//
//     if (savedId.isNotEmpty) {
//       try {
//         _selectedFamily = _familyList.firstWhere((e) => e.id.toString() == savedId);
//       } catch (_) {
//         _selectedFamily = _familyList.first;
//       }
//     } else {
//       _selectedFamily = _familyList.first;
//       await LocalStorage.saveId(_selectedFamily!.id.toString());
//     }
//
//     notifyListeners();
//   }
//
//   Future<void> selectFamily(FamilyList family) async {
//     _selectedFamily = family;
//
//     await LocalStorage.saveId(family.id.toString());
//
//     notifyListeners();
//   }
//
//   bool isSelected(FamilyList family) {
//     return family.id == _selectedFamily?.id;
//   }
// }
