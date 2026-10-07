import 'package:flutter/material.dart';
import 'package:profit_from_it_investors/model/dashboard_response.dart';
import 'package:profit_from_it_investors/utility/session_manager.dart';

class FamilyProvider extends ChangeNotifier {
  List<FamilyList> _familyList = [];
  FamilyList? _selectedFamily;

  // Family switching is transactional, just like Client switching.
  // We do not consider the switch complete until the destination Dashboard
  // has successfully loaded and confirmed the selected active_client_id.
  bool _isSwitching = false;
  int? _switchingFamilyId;
  bool _hasPendingSwitch = false;
  String _previousUserId = '';
  FamilyList? _previousSelectedFamily;

  List<FamilyList> get familyList => _familyList;
  FamilyList? get selectedFamily => _selectedFamily;
  String get selectedUserId => _selectedFamily?.id?.toString() ?? '';

  bool get isSwitching => _isSwitching;
  int? get switchingFamilyId => _switchingFamilyId;

  /// Called after Dashboard API.
  ///
  /// SessionManager.userId remains the source of truth for the currently
  /// requested family account. While a switch is pending, this method may
  /// update the visible family list but it does not finalize the transaction;
  /// HomeScreen confirms it only after Dashboard succeeds.
  void setFamilyList(List<FamilyList> list) {
    _familyList = list;

    if (_familyList.isEmpty) {
      _selectedFamily = null;
      notifyListeners();
      return;
    }

    final currentUserId = SessionManager.userId;

    try {
      _selectedFamily = _familyList.firstWhere(
        (family) => family.id?.toString() == currentUserId,
      );
    } catch (_) {
      _selectedFamily = _familyList.first;
    }

    notifyListeners();
  }

  bool isSelected(FamilyList family) {
    return _selectedFamily?.id == family.id;
  }

  /// Starts a family-member switch locally.
  ///
  /// All API requests already send SessionManager.userId in the `user-id`
  /// header. The switch remains pending until HomeScreen loads the Dashboard
  /// successfully and calls [confirmPendingSwitch].
  Future<bool> selectFamily(FamilyList family) async {
    final int? targetId = family.id;

    if (targetId == null || _isSwitching) {
      return false;
    }

    if (_selectedFamily?.id == targetId &&
        SessionManager.userId == targetId.toString()) {
      return false;
    }

    // Save the previous family selection before changing the effective user.
    _hasPendingSwitch = true;
    _previousUserId = SessionManager.userId;
    _previousSelectedFamily = _selectedFamily;

    _isSwitching = true;
    _switchingFamilyId = targetId;
    notifyListeners();

    try {
      SessionManager.changeUser(targetId.toString());
      _selectedFamily = family;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('family switch error =======> $e');
      rollbackPendingSwitch();
      return false;
    }
  }

  /// Finalizes the selected family member after the Dashboard confirms it.
  void confirmPendingSwitch() {
    if (!_hasPendingSwitch && !_isSwitching) {
      return;
    }

    _clearPendingSwitchSnapshot();
    _isSwitching = false;
    _switchingFamilyId = null;
    notifyListeners();
  }

  /// Restores the previous family member if Dashboard fails or times out.
  void rollbackPendingSwitch() {
    if (_hasPendingSwitch) {
      if (_previousUserId.isNotEmpty) {
        SessionManager.changeUser(_previousUserId);
      }

      _selectedFamily = _previousSelectedFamily;
    }

    _clearPendingSwitchSnapshot();
    _isSwitching = false;
    _switchingFamilyId = null;
    notifyListeners();
  }

  void _clearPendingSwitchSnapshot() {
    _hasPendingSwitch = false;
    _previousUserId = '';
    _previousSelectedFamily = null;
  }

  /// Call when user logs out.
  void clear() {
    _familyList.clear();
    _selectedFamily = null;
    _isSwitching = false;
    _switchingFamilyId = null;
    _clearPendingSwitchSnapshot();
    notifyListeners();
  }
}
