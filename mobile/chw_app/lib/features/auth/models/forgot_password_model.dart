class ForgotPasswordModel {
  final String email;
  final String? statusMessage;
  final bool success;

  ForgotPasswordModel({
    required this.email,
    this.statusMessage,
    this.success = false,
  });

  ForgotPasswordModel copyWith({
    String? email,
    String? statusMessage,
    bool? success,
  }) {
    return ForgotPasswordModel(
      email: email ?? this.email,
      statusMessage: statusMessage ?? this.statusMessage,
      success: success ?? this.success,
    );
  }
}
