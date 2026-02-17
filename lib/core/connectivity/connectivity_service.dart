import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity;

  ConnectivityService({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  Stream<bool> get onlineStatus$ =>
      _connectivity.onConnectivityChanged.map(_toOnlineStatus).distinct();

  Future<bool> get isOnline async {
    final result = await _connectivity.checkConnectivity();
    return _toOnlineStatus(result);
  }

  bool _toOnlineStatus(Object result) {
    if (result is List<ConnectivityResult>) {
      return result.any((item) => item != ConnectivityResult.none);
    }
    if (result is ConnectivityResult) {
      return result != ConnectivityResult.none;
    }
    return false;
  }

  void dispose() {}
}
