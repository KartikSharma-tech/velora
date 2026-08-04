import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/phone_utils.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../user/presentation/providers/user_provider.dart';

/// View / edit the signed-in user's own profile — name, about, a
/// photo URL (no image_picker dependency in this project yet, so
/// the photo is set by pasting a hosted image URL), plus phone
/// number and username.
///
/// BUG FIX / GAP: phone number and username are what the whole
/// contacts-discovery + username-search system is built on top of
/// (`PhoneUtils.matchKey` for contact matching,
/// `searchByUsername` for search) — but nothing in the app ever
/// let a user actually set either one. Without this, discovery
/// would never surface anybody, no matter how well the matching
/// logic itself worked.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  final _aboutController = TextEditingController();
  final _photoController = TextEditingController();
  final _phoneController = TextEditingController();
  final _usernameController = TextEditingController();

  bool _initialized = false;
  bool _saving = false;
  String? _usernameError;

  @override
  void dispose() {
    _nameController.dispose();
    _aboutController.dispose();
    _photoController.dispose();
    _phoneController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  String _normalizeUsername(String raw) {
    return raw.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '');
  }

  Future<void> _save(String uid, String originalUsername) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name cannot be empty')),
      );
      return;
    }

    final username = _normalizeUsername(_usernameController.text);
    final phoneRaw = _phoneController.text.trim();

    if (phoneRaw.isNotEmpty && !PhoneUtils.isValid(phoneRaw)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid 10-digit phone number')),
      );
      return;
    }

    setState(() {
      _saving = true;
      _usernameError = null;
    });

    try {
      final repo = ref.read(userRepositoryProvider);

      if (username.isNotEmpty && username != originalUsername) {
        final available =
            await repo.isUsernameAvailable(username, excludeUid: uid);
        if (!available) {
          if (mounted) {
            setState(() {
              _saving = false;
              _usernameError = 'That username is already taken';
            });
          }
          return;
        }
        await repo.updateUsername(uid: uid, username: username);
      }

      if (phoneRaw.isNotEmpty) {
        await repo.updatePhoneNumber(
          uid: uid,
          phoneNumber: PhoneUtils.matchKey(phoneRaw),
        );
      }

      await repo.updateProfile(
        uid: uid,
        name: name,
        about: _aboutController.text.trim(),
        photoUrl: _photoController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to update profile')),
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
            _phoneController.text = user.phoneNumber;
            _usernameController.text = user.username;
            _initialized = true;
          }

          final photoUrl = _photoController.text.trim();

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 52,
                  backgroundColor: AppColors.avatarBackground,
                  backgroundImage:
                      photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                  child: photoUrl.isEmpty
                      ? Text(
                          _nameController.text.isEmpty
                              ? '?'
                              : _nameController.text[0].toUpperCase(),
                          style: const TextStyle(fontSize: 32),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  user?.email ?? '',
                  style: TextStyle(
                    color: AppColors.textHint,
                    fontSize: 13,
                  ),
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
              const Text('Username', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              const Text(
                "Lets people find you by search, without sharing your number.",
                style: TextStyle(fontSize: 12, color: AppColors.textHint),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _usernameController,
                onChanged: (_) {
                  if (_usernameError != null) {
                    setState(() => _usernameError = null);
                  }
                },
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  prefixText: '@',
                  hintText: 'username',
                  errorText: _usernameError,
                ),
              ),
              const SizedBox(height: 20),
              const Text('Phone Number',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              const Text(
                "Used to match you with people who already have your number "
                "saved as a contact.",
                style: TextStyle(fontSize: 12, color: AppColors.textHint),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '10-digit phone number',
                ),
              ),
              const SizedBox(height: 20),
              const Text('About', style: TextStyle(fontWeight: FontWeight.w600)),
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
              const Text('Photo URL', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: _photoController,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'https://...',
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed:
                      _saving ? null : () => _save(userId, user?.username ?? ''),
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
