import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/utils/server_time_manager.dart';
import '../../../../core/widgets/vera_popup.dart';
import '../../../../main.dart' show ApiClientScope;
import '../../../account/data/datasources/account_remote_data_source.dart';
import '../../../account/data/models/user_profile.dart';
import '../../../account/data/repositories/account_repository_impl.dart';
import '../../domain/entities/moment.dart';
import '../widgets/moment_card.dart';
import 'home_screen.dart';
import 'locked_moment_screen.dart';
import 'privacy_settings_screen.dart';
import 'unlocked_moment_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.scale,
    required this.onCreate,
    this.moments,
  });

  final double scale;
  final VoidCallback onCreate;
  final List<Moment>? moments;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _selectedTab = 0;
  UserProfile? _profile;
  bool _isLoading = false;
  bool _isUploadingAvatar = false;
  Uint8List? _localAvatarBytes;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    ServerTimeManager.instance.ticker.addListener(_onTick);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfile();
    });
  }

  @override
  void dispose() {
    ServerTimeManager.instance.ticker.removeListener(_onTick);
    super.dispose();
  }

  void _onTick() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadProfile() async {
    final client = ApiClientScope.of(context);
    if (client.authToken == null || client.authToken!.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final repo = AccountRepositoryImpl(AccountRemoteDataSource(client));
    try {
      final profile = await repo.getProfile();
      final avatarBytes = await repo.getAvatar();
      if (mounted) {
        setState(() {
          _profile = profile;
          if (avatarBytes != null && avatarBytes.isNotEmpty) {
            _localAvatarBytes = avatarBytes;
          }
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _showAccountDetailsSheet(BuildContext context, double scale) {
    final profile = _profile;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final bottomPad = MediaQuery.paddingOf(ctx).bottom;
        return Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF1E1735),
                Color(0xFF131024),
              ],
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28 * scale)),
            border: Border.all(color: const Color(0x555C428C), width: 1.2 * scale),
            boxShadow: const [
              BoxShadow(
                color: Color(0x99000000),
                blurRadius: 32,
                offset: Offset(0, -8),
              ),
            ],
          ),
          padding: EdgeInsets.fromLTRB(24 * scale, 16 * scale, 24 * scale, 32 * scale + bottomPad),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44 * scale,
                  height: 5 * scale,
                  decoration: BoxDecoration(
                    color: const Color(0x66C792EA),
                    borderRadius: BorderRadius.circular(2.5 * scale),
                  ),
                ),
              ),
              SizedBox(height: 20 * scale),
              Row(
                children: [
                  Text(
                    'Account Details',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20 * scale,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (_isLoading)
                    SizedBox(
                      width: 18 * scale,
                      height: 18 * scale,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF9044FB),
                      ),
                    )
                  else
                    IconButton(
                      onPressed: () {
                        _loadProfile();
                        Navigator.of(ctx).pop();
                      },
                      icon: Icon(
                        Icons.refresh_rounded,
                        color: const Color(0xFFAAA6C2),
                        size: 20 * scale,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints.tightFor(
                        width: 32 * scale,
                        height: 32 * scale,
                      ),
                    ),
                ],
              ),
              SizedBox(height: 16 * scale),
              _detailRow(
                'Profile Photo',
                (profile?.avatarUrl != null && profile!.avatarUrl!.trim().isNotEmpty)
                    ? 'Custom Photo'
                    : 'Default Avatar',
                scale,
                trailing: IconButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _showAvatarPickerSheet(scale);
                  },
                  icon: Icon(
                    Icons.camera_alt_outlined,
                    color: const Color(0xFFC792EA),
                    size: 16 * scale,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints.tightFor(
                    width: 28 * scale,
                    height: 28 * scale,
                  ),
                  tooltip: 'Change photo',
                ),
              ),
              _detailRow(
                'Display Name',
                profile?.displayName.isNotEmpty == true ? profile!.displayName : 'Not set',
                scale,
                trailing: IconButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _showEditNameSheet(scale);
                  },
                  icon: Icon(
                    Icons.edit_outlined,
                    color: const Color(0xFFC792EA),
                    size: 16 * scale,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints.tightFor(
                    width: 28 * scale,
                    height: 28 * scale,
                  ),
                  tooltip: 'Edit name',
                ),
              ),
              _detailRow(
                'Handle',
                profile != null ? profile.effectiveUsername : '@user',
                scale,
              ),
              _detailRow(
                'Email',
                profile?.email.isNotEmpty == true ? profile!.email : 'Not set',
                scale,
                trailing: profile != null && profile.isEmailVerified
                    ? Container(
                        padding: EdgeInsets.symmetric(horizontal: 8 * scale, vertical: 2 * scale),
                        decoration: BoxDecoration(
                          color: const Color(0x2210B981),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: const Color(0xFF10B981), width: 0.8 * scale),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_rounded, color: const Color(0xFF10B981), size: 12 * scale),
                            SizedBox(width: 4 * scale),
                            Text(
                              'Verified',
                              style: TextStyle(
                                color: const Color(0xFF10B981),
                                fontSize: 11 * scale,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : null,
              ),
              if (profile?.bio != null && profile!.bio!.trim().isNotEmpty)
                _detailRow('Bio', profile.bio!.trim(), scale),
              _detailRow(
                'Linked Providers',
                (profile?.linkedProviders != null && profile!.linkedProviders.isNotEmpty)
                    ? profile.linkedProviders.join(', ')
                    : 'Email & Password',
                scale,
              ),
              if (profile?.createdAt != null)
                _detailRow(
                  'Member Since',
                  '${profile!.createdAt!.day}/${profile.createdAt!.month}/${profile.createdAt!.year}',
                  scale,
                ),
            ],
          ),
        );
      },
    );
  }

  void _showEditNameSheet(double scale) {
    final currentName = _profile?.displayName ?? '';
    final textController = TextEditingController(text: currentName);
    String? localError;
    bool isSaving = false;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF1E1735),
                    Color(0xFF131024),
                  ],
                ),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(28 * scale),
                ),
                border: Border.all(
                  color: const Color(0x555C428C),
                  width: 1.2 * scale,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x99000000),
                    blurRadius: 32,
                    offset: Offset(0, -8),
                  ),
                ],
              ),
              padding: EdgeInsets.fromLTRB(
                24 * scale,
                16 * scale,
                24 * scale,
                MediaQuery.of(modalContext).viewInsets.bottom + 24 * scale + MediaQuery.paddingOf(modalContext).bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44 * scale,
                      height: 5 * scale,
                      decoration: BoxDecoration(
                        color: const Color(0x66C792EA),
                        borderRadius: BorderRadius.circular(2.5 * scale),
                      ),
                    ),
                  ),
                  SizedBox(height: 20 * scale),
                  Row(
                    children: [
                      Text(
                        'Edit Display Name',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20 * scale,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: isSaving ? null : () => Navigator.of(ctx).pop(),
                        icon: Icon(
                          Icons.close_rounded,
                          color: const Color(0xFFAAA6C2),
                          size: 20 * scale,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints.tightFor(
                          width: 32 * scale,
                          height: 32 * scale,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8 * scale),
                  Text(
                    'This name will be shown on your profile and shared moments.',
                    style: TextStyle(
                      color: const Color(0xFFAAA6C2),
                      fontSize: 13 * scale,
                      height: 1.35,
                    ),
                  ),
                  SizedBox(height: 18 * scale),
                  Text(
                    'Display Name',
                    style: TextStyle(
                      color: const Color(0xFFA6A6C1),
                      fontSize: 12 * scale,
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: 8 * scale),
                  TextField(
                    controller: textController,
                    enabled: !isSaving,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    style: TextStyle(color: Colors.white, fontSize: 14 * scale),
                    cursorColor: const Color(0xFFB45BFF),
                    onChanged: (_) {
                      if (localError != null) {
                        setModalState(() => localError = null);
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'Enter your display name',
                      hintStyle: TextStyle(
                        color: const Color(0xFF535370),
                        fontSize: 14 * scale,
                      ),
                      filled: true,
                      fillColor: const Color(0xFF161626),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16 * scale,
                        vertical: 14 * scale,
                      ),
                      suffixIcon: textController.text.isNotEmpty && !isSaving
                          ? IconButton(
                              icon: Icon(
                                Icons.clear_rounded,
                                color: const Color(0xFFAAA6C2),
                                size: 18 * scale,
                              ),
                              onPressed: () {
                                textController.clear();
                                setModalState(() {});
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12 * scale),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12 * scale),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12 * scale),
                        borderSide: BorderSide(
                          color: const Color(0xFFA346FF),
                          width: 1 * scale,
                        ),
                      ),
                    ),
                  ),
                  if (localError != null) ...[
                    SizedBox(height: 8 * scale),
                    Row(
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          color: VeraTheme.error,
                          size: 14 * scale,
                        ),
                        SizedBox(width: 6 * scale),
                        Expanded(
                          child: Text(
                            localError!,
                            style: TextStyle(
                              color: VeraTheme.error,
                              fontSize: 12 * scale,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  SizedBox(height: 24 * scale),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 46 * scale,
                          child: OutlinedButton(
                            onPressed: isSaving ? null : () => Navigator.of(ctx).pop(),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: const Color(0x44AAA6C2),
                                width: scale,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                              foregroundColor: const Color(0xFFE2DCF7),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 14 * scale,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12 * scale),
                      Expanded(
                        child: SizedBox(
                          height: 46 * scale,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF9044FB), Color(0xFF4BBBEA)],
                              ),
                              borderRadius: BorderRadius.circular(999),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x558D42FF),
                                  blurRadius: 16,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: isSaving
                                  ? null
                                  : () async {
                                      final newName = textController.text.trim();
                                      if (newName.isEmpty) {
                                        setModalState(() {
                                          localError = 'Name cannot be empty';
                                        });
                                        return;
                                      }

                                      if (newName == currentName.trim()) {
                                        Navigator.of(ctx).pop();
                                        return;
                                      }

                                      setModalState(() {
                                        isSaving = true;
                                        localError = null;
                                      });

                                      try {
                                        final client = ApiClientScope.of(context);
                                        final repo = AccountRepositoryImpl(
                                          AccountRemoteDataSource(client),
                                        );
                                        final updated = await repo.updateProfile(
                                          name: newName,
                                        );

                                        if (!mounted) return;

                                        final effectiveName =
                                            updated.displayName.isNotEmpty
                                                ? updated.displayName
                                                : newName;

                                        setState(() {
                                          _profile = (_profile != null)
                                              ? _profile!.copyWith(
                                                  displayName: effectiveName,
                                                )
                                              : updated.copyWith(
                                                  displayName: effectiveName,
                                                );
                                        });

                                        if (ctx.mounted) {
                                          Navigator.of(ctx).pop();
                                        }

                                        VeraPopup.show(
                                          context,
                                          title: 'Profile updated',
                                          message:
                                              'Your display name has been updated.',
                                          icon: Icons.check_circle_outline_rounded,
                                          accent: VeraTheme.success,
                                        );

                                        _loadProfile();
                                      } on ApiException catch (error) {
                                        setModalState(() {
                                          isSaving = false;
                                          localError = error.message;
                                        });
                                      } catch (_) {
                                        setModalState(() {
                                          isSaving = false;
                                          localError =
                                              'Could not update name. Please check your connection and try again.';
                                        });
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: const StadiumBorder(),
                                foregroundColor: Colors.white,
                                disabledForegroundColor: Colors.white70,
                              ),
                              child: isSaving
                                  ? SizedBox(
                                      width: 18 * scale,
                                      height: 18 * scale,
                                      child: const CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      'Save',
                                      style: TextStyle(
                                        fontSize: 14 * scale,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAvatarPickerSheet(double scale) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final bottomPad = MediaQuery.paddingOf(ctx).bottom;
        return Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF1E1735),
                Color(0xFF131024),
              ],
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28 * scale)),
            border: Border.all(color: const Color(0x555C428C), width: 1.2 * scale),
            boxShadow: const [
              BoxShadow(
                color: Color(0x99000000),
                blurRadius: 32,
                offset: Offset(0, -8),
              ),
            ],
          ),
          padding: EdgeInsets.fromLTRB(24 * scale, 16 * scale, 24 * scale, 32 * scale + bottomPad),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44 * scale,
                  height: 5 * scale,
                  decoration: BoxDecoration(
                    color: const Color(0x66C792EA),
                    borderRadius: BorderRadius.circular(2.5 * scale),
                  ),
                ),
              ),
              SizedBox(height: 20 * scale),
              Row(
                children: [
                  Text(
                    'Profile Photo',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20 * scale,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: Icon(
                      Icons.close_rounded,
                      color: const Color(0xFFAAA6C2),
                      size: 20 * scale,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints.tightFor(
                      width: 32 * scale,
                      height: 32 * scale,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6 * scale),
              Text(
                'Choose a JPEG, PNG, or WebP file up to 5 MB.',
                style: TextStyle(
                  color: const Color(0xFFAAA6C2),
                  fontSize: 13 * scale,
                  height: 1.35,
                ),
              ),
              SizedBox(height: 20 * scale),
              _avatarPickerOption(
                icon: Icons.photo_library_outlined,
                title: 'Choose from Gallery',
                subtitle: 'Select an image from your device',
                scale: scale,
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickAndUploadAvatar(ImageSource.gallery, scale);
                },
              ),
              SizedBox(height: 12 * scale),
              _avatarPickerOption(
                icon: Icons.camera_alt_outlined,
                title: 'Take Photo',
                subtitle: 'Use your camera to take a photo',
                scale: scale,
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickAndUploadAvatar(ImageSource.camera, scale);
                },
              ),
              if (_localAvatarBytes != null ||
                  (_profile?.avatarUrl != null &&
                      _profile!.avatarUrl!.trim().isNotEmpty)) ...[
                SizedBox(height: 12 * scale),
                _avatarPickerOption(
                  icon: Icons.delete_outline_rounded,
                  title: 'Remove Photo',
                  subtitle: 'Delete current photo and revert to initials',
                  scale: scale,
                  isDestructive: true,
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _deleteAvatar(scale);
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _avatarPickerOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required double scale,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16 * scale),
      child: Container(
        padding: EdgeInsets.all(14 * scale),
        decoration: BoxDecoration(
          color: isDestructive
              ? const Color(0x22EF4444)
              : const Color(0xFF19152B),
          borderRadius: BorderRadius.circular(16 * scale),
          border: Border.all(
            color: isDestructive
                ? const Color(0x55EF4444)
                : const Color(0x33443C68),
            width: scale,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44 * scale,
              height: 44 * scale,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isDestructive
                    ? const LinearGradient(
                        colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                      )
                    : const LinearGradient(
                        colors: [Color(0xFF9044FB), Color(0xFF4BBBEA)],
                      ),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 22 * scale,
              ),
            ),
            SizedBox(width: 14 * scale),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isDestructive
                          ? const Color(0xFFFF6B6B)
                          : Colors.white,
                      fontSize: 15 * scale,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2 * scale),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isDestructive
                          ? const Color(0xCCFF8E8E)
                          : const Color(0xFFAAA6C2),
                      fontSize: 12 * scale,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDestructive
                  ? const Color(0xCCFF8E8E)
                  : const Color(0xFFAAA6C2),
              size: 20 * scale,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteAvatar(double scale) async {
    final client = ApiClientScope.of(context);
    setState(() {
      _isUploadingAvatar = true;
    });

    try {
      final repo = AccountRepositoryImpl(AccountRemoteDataSource(client));
      await repo.deleteAvatar();

      if (!mounted) return;

      setState(() {
        _localAvatarBytes = null;
        if (_profile != null) {
          _profile = _profile!.copyWith(avatarUrl: '');
        }
        _isUploadingAvatar = false;
      });

      _loadProfile();

      if (!mounted) return;
      VeraPopup.show(
        context,
        title: 'Avatar Removed',
        message: 'Your profile photo has been removed successfully.',
        icon: Icons.check_circle_outline_rounded,
        accent: VeraTheme.success,
      );
    } on ApiException catch (e) {
      debugPrint('Avatar delete ApiException: $e');
      if (!mounted) return;
      setState(() {
        _isUploadingAvatar = false;
      });
      VeraPopup.show(
        context,
        title: 'Delete Failed',
        message: e.message,
        icon: Icons.error_outline_rounded,
        accent: VeraTheme.error,
      );
    } catch (e, stackTrace) {
      debugPrint('Avatar delete unexpected error: $e\n$stackTrace');
      if (!mounted) return;
      setState(() {
        _isUploadingAvatar = false;
      });
      VeraPopup.show(
        context,
        title: 'Error',
        message: 'Could not remove profile photo. Please try again.',
        icon: Icons.error_outline_rounded,
        accent: VeraTheme.error,
      );
    }
  }

  Future<void> _pickAndUploadAvatar(ImageSource source, double scale) async {
    final client = ApiClientScope.of(context);
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      final bytes = await pickedFile.readAsBytes();
      final filename = pickedFile.name.isNotEmpty
          ? pickedFile.name
          : 'avatar.jpg';

      // Validate max size 5 MB
      const maxSizeBytes = 5 * 1024 * 1024;
      if (bytes.length > maxSizeBytes) {
        if (!mounted) return;
        VeraPopup.show(
          context,
          title: 'Image Too Large',
          message: 'Please choose an image file up to 5 MB.',
          icon: Icons.error_outline_rounded,
          accent: VeraTheme.error,
        );
        return;
      }

      // Validate format: JPEG, PNG, WebP
      final ext = filename.split('.').last.toLowerCase();
      if (!const {'jpg', 'jpeg', 'png', 'webp'}.contains(ext)) {
        if (!mounted) return;
        VeraPopup.show(
          context,
          title: 'Unsupported Format',
          message: 'Please choose a JPEG, PNG, or WebP image.',
          icon: Icons.error_outline_rounded,
          accent: VeraTheme.error,
        );
        return;
      }

      setState(() {
        _isUploadingAvatar = true;
        _localAvatarBytes = bytes;
      });

      final repo = AccountRepositoryImpl(AccountRemoteDataSource(client));
      final updatedBytes = await repo.uploadAvatar(
        bytes: bytes,
        filename: filename,
      );

      if (!mounted) return;

      setState(() {
        if (updatedBytes != null && updatedBytes.isNotEmpty) {
          _localAvatarBytes = updatedBytes;
        }
        _isUploadingAvatar = false;
      });

      // Refresh in background to sync backend profile and avatar
      _loadProfile();

      if (!mounted) return;
      VeraPopup.show(
        context,
        title: 'Profile Updated',
        message: 'Your profile avatar has been updated successfully.',
        icon: Icons.check_circle_outline_rounded,
        accent: VeraTheme.success,
      );
    } on ApiException catch (e) {
      debugPrint('Avatar upload ApiException: $e');
      if (!mounted) return;
      setState(() {
        _isUploadingAvatar = false;
        _localAvatarBytes = null;
      });
      VeraPopup.show(
        context,
        title: 'Upload Failed',
        message: e.message,
        icon: Icons.error_outline_rounded,
        accent: VeraTheme.error,
      );
    } catch (e, stackTrace) {
      debugPrint('Avatar upload unexpected error: $e\n$stackTrace');
      if (!mounted) return;
      setState(() {
        _isUploadingAvatar = false;
        _localAvatarBytes = null;
      });
      final msg = e.toString().contains('MissingPluginException')
          ? 'Image picker plugin not loaded. Please restart the app.'
          : (e is FormatException
              ? e.message
              : (e.toString().isNotEmpty && !e.toString().startsWith('Instance of')
                  ? e.toString().replaceFirst(RegExp(r'^[A-Za-z]+Exception:\s*'), '')
                  : 'Could not upload avatar. Please try again.'));
      VeraPopup.show(
        context,
        title: 'Upload Error',
        message: msg,
        icon: Icons.error_outline_rounded,
        accent: VeraTheme.error,
      );
    }
  }

  Widget _detailRow(String label, String value, double scale, {Widget? trailing}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 14 * scale),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110 * scale,
            child: Text(
              label,
              style: TextStyle(
                color: const Color(0xFFAAA6C2),
                fontSize: 13 * scale,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: const Color(0xFFF4F2FF),
                fontSize: 14 * scale,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }

  Widget _buildAvatar(double scale) {
    if (_localAvatarBytes != null) {
      return Image.memory(
        _localAvatarBytes!,
        width: 96.67 * scale,
        height: 96.67 * scale,
        fit: BoxFit.cover,
      );
    }
    if (_profile?.avatarUrl != null && _profile!.avatarUrl!.trim().isNotEmpty) {
      return Image.network(
        _profile!.avatarUrl!,
        width: 96.67 * scale,
        height: 96.67 * scale,
        fit: BoxFit.cover,
        errorBuilder: (_, error, stackTrace) => _buildFallbackAvatar(scale),
      );
    }
    return _buildFallbackAvatar(scale);
  }

  Widget _buildFallbackAvatar(double scale) {
    final initial = (_profile?.displayName.isNotEmpty == true)
        ? _profile!.displayName[0].toUpperCase()
        : ((_profile?.email.isNotEmpty == true) ? _profile!.email[0].toUpperCase() : null);

    if (initial != null) {
      return Container(
        width: 96.67 * scale,
        height: 96.67 * scale,
        color: const Color(0xFF2E2244),
        alignment: Alignment.center,
        child: Text(
          initial,
          style: TextStyle(
            color: const Color(0xFFE4DAFF),
            fontSize: 36 * scale,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return Container(
      width: 96.67 * scale,
      height: 96.67 * scale,
      color: const Color(0xFF383145),
      alignment: Alignment.center,
      child: Icon(
        Icons.person,
        color: Colors.white70,
        size: 44 * scale,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scale = widget.scale;
    final createdMoments = widget.moments ?? HomeScreen.sentMoments;
    final receivedMoments = (widget.moments ?? HomeScreen.sentMoments)
        .where((m) => !m.isPublicSentMoment)
        .toList();
    final currentList = _selectedTab == 0 ? createdMoments : receivedMoments;

    final displayName = _profile?.displayName.isNotEmpty == true
        ? _profile!.displayName
        : (_isLoading ? 'Loading...' : 'Sam Rivera');


    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            24 * scale,
            8 * scale,
            12 * scale,
            8 * scale,
          ),
          child: Row(
            children: [
              Text(
                'Profile',
                style: TextStyle(
                  color: const Color(0xFFF4F2FF),
                  fontSize: 28,
                  height: 36 / 28,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => _showAccountDetailsSheet(context, scale),
                icon: Icon(
                  Icons.info_outline_rounded,
                  color: Colors.white,
                  size: 22 * scale,
                ),
                tooltip: 'Account details',
                constraints: BoxConstraints.tightFor(
                  width: 44 * scale,
                  height: 44 * scale,
                ),
                padding: EdgeInsets.zero,
              ),
              IconButton(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const PrivacySettingsScreen(),
                    ),
                  );
                  if (mounted) _loadProfile();
                },
                icon: Icon(
                  Icons.tune_rounded,
                  color: Colors.white,
                  size: 22 * scale,
                ),
                tooltip: 'Privacy & Settings',
                constraints: BoxConstraints.tightFor(
                  width: 44 * scale,
                  height: 44 * scale,
                ),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadProfile,
            color: const Color(0xFF9044FB),
            backgroundColor: const Color(0xFF1B182B),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(bottom: 100 * scale),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    constraints: BoxConstraints(minHeight: 164 * scale),
                    padding: EdgeInsets.symmetric(vertical: 12 * scale),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF211431),
                          Color(0xFF100D1C),
                          Color(0xFF080914),
                        ],
                        stops: [0, .48, 1],
                      ),
                    ),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _isUploadingAvatar ? null : () => _showAvatarPickerSheet(scale),
                          child: Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 96.67 * scale,
                                height: 96.67 * scale,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF9044FB).withValues(alpha: 0.4),
                                    width: 2 * scale,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF9044FB).withValues(alpha: 0.25),
                                      blurRadius: 16,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: _buildAvatar(scale),
                                ),
                              ),
                              if (_isUploadingAvatar)
                                Container(
                                  width: 96.67 * scale,
                                  height: 96.67 * scale,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.black.withValues(alpha: 0.55),
                                  ),
                                  alignment: Alignment.center,
                                  child: SizedBox(
                                    width: 28 * scale,
                                    height: 28 * scale,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFB45BFF)),
                                    ),
                                  ),
                                ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  width: 30 * scale,
                                  height: 30 * scale,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF9044FB), Color(0xFF4BBBEA)],
                                    ),
                                    border: Border.all(
                                      color: const Color(0xFF100D1C),
                                      width: 2 * scale,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x668D42FF),
                                        blurRadius: 6,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  alignment: Alignment.center,
                                  child: Icon(
                                    Icons.camera_alt_rounded,
                                    color: Colors.white,
                                    size: 15 * scale,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 6 * scale),
                        InkWell(
                          onTap: () => _showEditNameSheet(scale),
                          borderRadius: BorderRadius.circular(8 * scale),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10 * scale,
                              vertical: 2 * scale,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    displayName,
                                    style: TextStyle(
                                      color: const Color(0xFFF5F2FF),
                                      fontSize: 24 * scale,
                                      height: 32 / 24,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: -.45,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(width: 6 * scale),
                                Icon(
                                  Icons.edit_rounded,
                                  color: const Color(0xFFC792EA),
                                  size: 15 * scale,
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_errorMessage != null && _profile == null) ...[
                          SizedBox(height: 6 * scale),
                          GestureDetector(
                            onTap: _loadProfile,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10 * scale,
                                vertical: 4 * scale,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0x33EF4444),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: const Color(0xFFEF4444),
                                  width: 0.8 * scale,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.refresh_rounded,
                                    color: const Color(0xFFEF4444),
                                    size: 12 * scale,
                                  ),
                                  SizedBox(width: 4 * scale),
                                  Text(
                                    'Failed to load profile. Tap to retry',
                                    style: TextStyle(
                                      color: const Color(0xFFEF4444),
                                      fontSize: 11 * scale,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        if (_profile?.bio != null && _profile!.bio!.trim().isNotEmpty) ...[
                          SizedBox(height: 6 * scale),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 32 * scale),
                            child: Text(
                              _profile!.bio!.trim(),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: const Color(0xFFD6D3E6),
                                fontSize: 13 * scale,
                                height: 18 / 13,
                              ),
                            ),
                          ),
                        ],
                        if (_profile?.linkedProviders.isNotEmpty == true) ...[
                          SizedBox(height: 8 * scale),
                          Wrap(
                            spacing: 6 * scale,
                            runSpacing: 4 * scale,
                            alignment: WrapAlignment.center,
                            children: _profile!.linkedProviders.map((provider) {
                              return Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8 * scale,
                                  vertical: 3 * scale,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0x229044FB),
                                  borderRadius: BorderRadius.circular(12 * scale),
                                  border: Border.all(
                                    color: const Color(0x449044FB),
                                    width: 0.8 * scale,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      provider.toLowerCase().contains('google')
                                          ? Icons.g_mobiledata_rounded
                                          : provider.toLowerCase().contains('apple')
                                              ? Icons.apple_rounded
                                              : Icons.link_rounded,
                                      color: const Color(0xFFC792EA),
                                      size: 14 * scale,
                                    ),
                                    SizedBox(width: 4 * scale),
                                    Text(
                                      provider[0].toUpperCase() + provider.substring(1),
                                      style: TextStyle(
                                        color: const Color(0xFFE2DCF7),
                                        fontSize: 11 * scale,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24 * scale),
                  child: SizedBox(
                    height: 84 * scale,
                    child: Row(
                      children: [
                        _ProfileStat(
                          iconAsset: 'assets/images/profile_created.png',
                          label: 'Created',
                          value: createdMoments.length.toString(),
                          scale: scale,
                        ),
                        _ProfileStat(
                          iconAsset: 'assets/images/profile_received.png',
                          label: 'Received',
                          value: receivedMoments.length.toString(),
                          scale: scale,
                        ),
                        _ProfileStat(
                          iconAsset: 'assets/images/profile_replies.png',
                          label: 'Replies',
                          value: '0',
                          scale: scale,
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24 * scale),
                  child: Row(
                    children: [
                      _ProfileTab(
                        title: 'Created',
                        selected: _selectedTab == 0,
                        onTap: () => setState(() => _selectedTab = 0),
                        scale: scale,
                      ),
                      _ProfileTab(
                        title: 'Received',
                        selected: _selectedTab == 1,
                        onTap: () => setState(() => _selectedTab = 1),
                        scale: scale,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16 * scale),
                currentList.isEmpty
                    ? Padding(
                        padding: EdgeInsets.fromLTRB(
                          16 * scale,
                          24 * scale,
                          16 * scale,
                          24 * scale,
                        ),
                        child: Column(
                          children: [
                            Text(
                              _selectedTab == 0
                                  ? "You haven't sent a\nmoment yet"
                                  : "You haven't received a\nmoment yet",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: const Color(0xFFF4F2FF),
                                fontSize: 24 * scale,
                                height: 32 / 24,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 16 * scale),
                            Text(
                              _selectedTab == 0
                                  ? 'Moments you create appear here.'
                                  : 'Moments sent to you appear here.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: const Color(0xFFAAA6C2),
                                fontSize: 14 * scale,
                                height: 20 / 14,
                              ),
                            ),
                            SizedBox(height: 16 * scale),
                            SizedBox(
                              width: 181 * scale,
                              height: 46 * scale,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF9044FB), Color(0xFF4BBBEA)],
                                  ),
                                  borderRadius: BorderRadius.circular(999),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x558D42FF),
                                      blurRadius: 20,
                                      offset: Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: TextButton(
                                  onPressed: widget.onCreate,
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    shape: const StadiumBorder(),
                                  ),
                                  child: Text(
                                    'Create a moment',
                                    style: TextStyle(fontSize: 14 * scale),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.symmetric(horizontal: 16 * scale),
                        itemCount: currentList.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: EdgeInsets.only(bottom: 16 * scale),
                            child: MomentCard(
                              moment: currentList[index],
                              showModerationStatus: _selectedTab == 0,
                              scale: scale,
                              onTap: () {
                                final moment = currentList[index];
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => moment.canAccessContent
                                        ? UnlockedMomentScreen(moment: moment)
                                        : LockedMomentScreen(moment: moment),
                                  ),
                                );
                              },
                              showDiscoverActions: false,
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({
    required this.iconAsset,
    required this.label,
    required this.value,
    required this.scale,
  });

  final String iconAsset;
  final String label;
  final String value;
  final double scale;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Image.asset(
          iconAsset,
          width: 24 * scale,
          height: 24 * scale,
          fit: BoxFit.contain,
        ),
        SizedBox(height: 4 * scale),
        Text(
          label,
          style: TextStyle(
            color: const Color(0xFFAAA6C2),
            fontSize: 12 * scale,
            height: 16 / 12,
          ),
        ),
        SizedBox(height: 2 * scale),
        Text(
          value,
          style: TextStyle(
            color: const Color(0xFFF4F2FF),
            fontSize: 24 * scale,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab({
    required this.title,
    required this.selected,
    required this.onTap,
    required this.scale,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;
  final double scale;

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 48 * scale,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? const Color(0xFFA33EFF) : Colors.transparent,
              width: 2.5 * scale,
            ),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: selected ? const Color(0xFFC9C5D8) : const Color(0xFF777487),
            fontSize: 10 * scale,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ),
  );
}
