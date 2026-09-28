class VeloraContact {
  final String displayName;
  final String phone;
  final bool isOnVelora;

  // On Velora wale ke liye
  final String? uid;
  final String? veloraName;
  final String? photoUrl;
  final String? username;
  final String? existingChatId;

  const VeloraContact({
    required this.displayName,
    required this.phone,
    required this.isOnVelora,
    this.uid,
    this.veloraName,
    this.photoUrl,
    this.username,
    this.existingChatId,
  });
}