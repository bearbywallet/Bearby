class AuthGuard {
  bool enabled = false;
  bool ready = false;

  Future<void> initialize() async {
    // await Future.delayed(Duration(seconds: 1));
    enabled = false;
    ready = false;
  }
}
