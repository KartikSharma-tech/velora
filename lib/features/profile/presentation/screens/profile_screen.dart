import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../user/presentation/providers/user_provider.dart';

/// View / edit the signed-in user's own profile — name, about,
/// and a photo URL (no image_picker dependency in this project
/// yet, so the photo is set by pasting a hosted image URL).
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  final _aboutController = TextEditingController();
  final _photoController = TextEditingController();

  bool _initialized = false;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _aboutController.dispose();
    _photoController.dispose();
    super.dispose();
  }

  Future<void> _save(String uid) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name cannot be empty')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      await ref.read(userRepositoryProvider).updateProfile(
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
