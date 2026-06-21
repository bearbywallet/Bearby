/// Security-related timing and behavior constants.
class SecuritySettings {
  /// Delay (in seconds) before a revealed secret (private key or mnemonic
  /// phrase) is shown after successful authentication. Applies to both the
  /// private-key reveal page and the BIP39 phrase reveal page.
  static const int revealDelaySeconds = 1800;

  /// How long the "copied" confirmation state stays visible after the user
  /// copies a revealed secret, before reverting to the default icon.
  static const Duration copyFeedbackDuration = Duration(seconds: 1);

  /// How long an error state is shown on the submit button before it resets
  /// to its idle state, on the reveal pages.
  static const Duration errorResetDuration = Duration(seconds: 1);
}
