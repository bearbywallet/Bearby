class AuthService {
  bool _isAuthenticated = false;

  bool get isAuthenticated => _isAuthenticated;

  Future<bool> login(String username, String password) async {
    await Future.delayed(const Duration(seconds: 1)); // TODO: sending message to background.
    _isAuthenticated = (username == 'user' && password == 'password');
    return _isAuthenticated;
  }

  void logout() {
    _isAuthenticated = false;
  }
}

final authService = AuthService();
