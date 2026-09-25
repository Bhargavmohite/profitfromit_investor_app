import 'package:flutter/material.dart';
import 'package:profit_from_it_investors/model/dashboard_response.dart';
import 'package:profit_from_it_investors/utility/session_manager.dart';

class ClientSwitchProvider extends ChangeNotifier {
  List<ClientList> _clientList = [];
  ClientList? _selectedClient;

  String _ctype = '';
  int? _partnerId;

  int _isReadonlyAdmin = 0;
  bool _canSwitchClients = false;
  int? _masterClientId;
  int? _activeClientId;
  bool _isClientImpersonating = false;
  bool _isSwitching = false;
  int? _switchingClientId;

  List<ClientList> get clientList => _clientList;
  ClientList? get selectedClient => _selectedClient;
  String get ctype => _ctype;
  int? get partnerId => _partnerId;

  int get isReadonlyAdmin => _isReadonlyAdmin;
  bool get canSwitchClients => _canSwitchClients;
  int? get masterClientId => _masterClientId;
  int? get activeClientId => _activeClientId;
  bool get isClientImpersonating => _isClientImpersonating;
  bool get isSwitching => _isSwitching;
  int? get switchingClientId => _switchingClientId;

  bool get isPartner => _ctype.trim().toLowerCase() == 'partner';

  /// Preserve the OLD readonly-admin rule exactly:
  /// readonly admin was a Client account with is_readonly_admin = 1.
  bool get isReadonlyAdminClient =>
      _ctype.trim().toLowerCase() == 'client' && _isReadonlyAdmin == 1;

  /// PARTNER flow:
  /// Partner can see only the client list returned by the backend.
  bool get canShowSwitchMember =>
      isPartner && _canSwitchClients && _clientList.isNotEmpty;

  /// OLD READONLY ADMIN flow:
  /// Keep the existing "Switch User" behavior.
  bool get canShowSwitchUser =>
      isReadonlyAdminClient && _canSwitchClients && _clientList.isNotEmpty;

  /// Used internally when either switching mode is allowed.
  bool get canShowAnyClientSwitch => canShowSwitchMember || canShowSwitchUser;

  /// Called after Dashboard API.
  ///
  /// Dashboard is the source of truth for:
  /// - logged-in account ctype
  /// - partner relationship
  /// - switch permission
  /// - master/partner account
  /// - active client
  /// - allowed client list
  void syncFromDashboard(Data? data) {
    if (data == null) {
      clear(notify: true);
      return;
    }

    _ctype = data.ctype ?? '';
    _partnerId = data.partnerId;

    _isReadonlyAdmin = data.isReadonlyAdmin ?? 0;
    _canSwitchClients = data.canSwitchClients == true;
    _masterClientId = data.masterClientId;
    _activeClientId = data.activeClientId;
    _isClientImpersonating = data.isClientImpersonating == true;
    _clientList = data.clientList ?? <ClientList>[];

    if (!canShowAnyClientSwitch) {
      _selectedClient = null;
      notifyListeners();
      return;
    }

    final String effectiveId =
        (_activeClientId ??
                int.tryParse(SessionManager.userId) ??
                _masterClientId ??
                0)
            .toString();

    try {
      _selectedClient = _clientList.firstWhere(
        (client) => client.id?.toString() == effectiveId,
      );
    } catch (_) {
      try {
        _selectedClient = _clientList.firstWhere(
          (client) => client.id == _masterClientId,
        );
      } catch (_) {
        _selectedClient = _clientList.first;
      }
    }

    notifyListeners();
  }

  bool isSelected(ClientList client) {
    return _selectedClient?.id == client.id;
  }

  /// Switches the effective client used by all API requests.
  ///
  /// IMPORTANT:
  /// We intentionally DO NOT call /client/impersonate here.
  /// The authenticated Sanctum token must remain the original/master client.
  ///
  /// The app already sends SessionManager.userId as the `user-id` header on
  /// API requests. DashboardAPIController validates that selected id against
  /// the authenticated master user on every Dashboard request.
  ///
  /// This is the same proven mechanism already used by FamilyProvider.
  Future<bool> selectClient(ClientList client) async {
    final int? targetId = client.id;

    if (targetId == null) {
      return false;
    }

    // Allow BOTH supported switching modes:
    // 1) Partner -> assigned clients
    // 2) Readonly Admin Client -> existing allowed client list
    //
    // A normal Client satisfies neither condition.
    if (!canShowAnyClientSwitch) {
      return false;
    }

    if (_selectedClient?.id == targetId) {
      return false;
    }

    _isSwitching = true;
    _switchingClientId = targetId;
    notifyListeners();

    try {
      // This is the only state change required for switching.
      // httpGet/httpPost automatically send this as `user-id`.
      SessionManager.changeUser(targetId.toString());

      _activeClientId = targetId;
      _isClientImpersonating =
          _masterClientId != null && targetId != _masterClientId;
      _selectedClient = client;

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('client switch error =======> $e');
      return false;
    } finally {
      _isSwitching = false;
      _switchingClientId = null;
      notifyListeners();
    }
  }

  /// Return to the original/master client locally.
  /// The next Dashboard request validates and confirms the state.
  Future<bool> returnToMaster() async {
    final int? masterId = _masterClientId;

    if (masterId == null) {
      return false;
    }

    ClientList? masterClient;

    try {
      masterClient = _clientList.firstWhere((client) => client.id == masterId);
    } catch (_) {
      masterClient = null;
    }

    if (masterClient == null) {
      return false;
    }

    return selectClient(masterClient);
  }

  void clear({bool notify = true}) {
    _clientList = [];
    _selectedClient = null;
    _ctype = '';
    _partnerId = null;
    _isReadonlyAdmin = 0;
    _canSwitchClients = false;
    _masterClientId = null;
    _activeClientId = null;
    _isClientImpersonating = false;
    _isSwitching = false;
    _switchingClientId = null;

    if (notify) {
      notifyListeners();
    }
  }
}
