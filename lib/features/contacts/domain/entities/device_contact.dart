class DeviceContact {
  final String displayName;
  final List<String> normalizedPhones;
  final String? photoUrl;

  const DeviceContact({
    required this.displayName,
    required this.normalizedPhones,
    this.photoUrl,
  });
}