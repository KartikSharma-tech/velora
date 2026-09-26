import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
// import 'package:firebase_storage/firebase_storage.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../user/presentation/providers/user_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  final _aboutController = TextEditingController();
  final _photoController = TextEditingController();
  final _usernameController = TextEditingController();

  bool _initialized = false;
  bool _saving = false;
  String? _usernameError;
  bool _checkingUsername = false;

  @override
  void dispose() {
    _nameController.dispose();
    _aboutController.dispose();
    _photoController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  final ImagePicker _picker = ImagePicker();

 Future<void> _pickImage() async {
  final file = await _picker.pickImage(
    source: ImageSource.gallery,
    imageQuality: 80,
  );

  if (file == null) return;

  setState(() => _saving = true);

  try {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;

    // Cloudinary upload
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/wve0mvba/image/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = 'velora_profile'
      ..fields['public_id'] = 'profile_$uid'
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final response = await request.send();
    final responseData = await response.stream.bytesToString();
    final json = jsonDecode(responseData);

    if (response.statusCode != 200) {
      throw Exception(json['error']['message'] ?? 'Upload failed');
    }

    final downloadUrl = json['secure_url'] as String;

    await ref.read(userRepositoryProvider).updateProfile(
          uid: uid,
          name: _nameController.text.trim(),
          about: _aboutController.text.trim(),
          photoUrl: downloadUrl,
          username: _usernameController.text.trim(),
        );

    setState(() {
      _photoController.text = downloadUrl;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile photo updated!')),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  } finally {
    if (mounted) setState(() => _saving = false);
  }
}
  Future<void> _checkUsername(String username) async {
    if (username.isEmpty) {
      setState(() => _usernameError = null);
      return;
    }

    setState(() {
      _checkingUsername = true;
      _usernameError = null;
    });

    try {
      final uid = ref.read(currentUserIdProvider);
      if (uid == null) return;

      final user = await ref.read(currentUserProvider(uid).future);
      if (user == null) return;

      if (username == user.username) {
        setState(() {
          _checkingUsername = false;
          _usernameError = null;
        });
        return;
      }

      final taken = await ref
          .read(userRepositoryProvider)
          .isUsernameTaken(username);

      setState(() {
        _checkingUsername = false;
        _usernameError = taken ? 'Username already taken' : null;
      });
    } catch (_) {
      setState(() {
        _checkingUsername = false;
        _usernameError = 'Unable to check username';
      });
    }
  }

  Future<void> _save(String uid) async {
    final name = _nameController.text.trim();
    final username = _usernameController.text.trim();

    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username cannot be empty')),
      );
      return;
    }

    final usernameRegex = RegExp(r'^[a-z0-9_]{4,20}$');
    if (!usernameRegex.hasMatch(username)) {
      setState(() {
        _usernameError =
            'Username must be 4-20 characters and contain only lowercase letters, numbers, or _';
      });
      return;
    }

    setState(() => _usernameError = null);

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name cannot be empty')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      await ref
          .read(userRepositoryProvider)
          .updateProfile(
            uid: uid,
            name: name,
            about: _aboutController.text.trim(),
            photoUrl: _photoController.text.trim(),
            username: _usernameController.text.trim(),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserIdProvider);

    if (userId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final userAsync = ref.watch(currentUserProvider(userId));

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (user) {
          if (!_initialized && user != null) {
            _nameController.text = user.name;
            _aboutController.text = user.about;
            _photoController.text = user.photoUrl;
            _usernameController.text = user.username ?? '';
            _initialized = true;
          }

          final photoUrl = _photoController.text.trim();

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const SizedBox(height: 28),

              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 55,
                      backgroundColor: AppColors.avatarBackground,
                      backgroundImage: photoUrl.isEmpty
                          ? null
                          : (photoUrl.startsWith('http')
                                ? NetworkImage(photoUrl)
                                : FileImage(File(photoUrl)))
                              as ImageProvider,
                      child: photoUrl.isEmpty
                          ? Text(
                              _nameController.text.isEmpty
                                  ? '?'
                                  : _nameController.text[0].toUpperCase(),
                              style: const TextStyle(fontSize: 34),
                            )
                          : null,
                    ),

                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        onTap: _saving ? null : _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: _saving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              Center(
                child: Text(
                  user?.email ?? '',
                  style: TextStyle(color: AppColors.textHint, fontSize: 13),
                ),
              ),

              const SizedBox(height: 28),

              const Text('Name', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Your name',
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Phone Number',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: TextEditingController(
                  text: user?.phoneNumber ?? '',
                ),
                readOnly: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Username',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _usernameController,
                onChanged: (value) {
                  final normalized = value.toLowerCase().replaceAll(' ', '_');
                  if (normalized != value) {
                    _usernameController.value = TextEditingValue(
                      text: normalized,
                      selection: TextSelection.collapsed(
                        offset: normalized.length,
                      ),
                    );
                  }
                },
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  prefixText: '@',
                  hintText: 'Choose a username',
                  errorText: _usernameError,
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'About',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _aboutController,
                maxLines: 3,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Tell people a bit about yourself',
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _saving ? null : () => _save(userId),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save changes'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}