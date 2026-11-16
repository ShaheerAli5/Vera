 import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/layout/responsive.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/vera_popup.dart';
import '../../../../main.dart' show ApiClientScope;
import '../../data/datasources/moments_remote_data_source.dart';
import '../../data/models/update_moment_params.dart';
import '../../data/repositories/moments_repository_impl.dart';
import '../../domain/entities/moment.dart';
import 'home_screen.dart';

class EditMomentScreen extends StatefulWidget {
  const EditMomentScreen({
    super.key,
    required this.moment,
  });

  final Moment moment;

  @override
  State<EditMomentScreen> createState() => _EditMomentScreenState();
}

class _EditMomentScreenState extends State<EditMomentScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _teaserController;
  late Moment _currentMoment;
  bool _isSaving = false;
  bool _isUploadingMedia = false;
  bool _isPublishing = false;
  bool _isDeleting = false;
  bool _isResendingInvite = false;
  Uint8List? _streamedMediaBytes;

  @override
  void initState() {
    super.initState();
    _currentMoment = widget.moment;
    _titleController = TextEditingController(
      text: widget.moment.title ?? widget.moment.unlockCondition,
    );
    _teaserController = TextEditingController(
      text: widget.moment.teaser ?? '',
    );
    if (_currentMoment.id.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fetchMediaStream());
    }
  }

  Future<void> _fetchMediaStream() async {
    if (_currentMoment.id.isEmpty) return;
    try {
      final client = ApiClientScope.of(context);
      final repo = MomentsRepositoryImpl(MomentsRemoteDataSource(client));
      final stream = await repo.getMomentMedia(_currentMoment.id);
      if (!mounted) return;
      setState(() {
        _streamedMediaBytes = stream.bytes;
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _titleController.dispose();
    _teaserController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadMedia(ImageSource source, {bool isVideo = false}) async {
    if (_currentMoment.id.isEmpty) return;
    final client = ApiClientScope.of(context);

    try {
      final picker = ImagePicker();
      final file = isVideo
          ? await picker.pickVideo(source: source)
          : await picker.pickImage(source: source);
      if (file == null) return;

      final bytes = await file.readAsBytes();
      final maxSize = isVideo ? 25 * 1024 * 1024 : 8 * 1024 * 1024;
      if (bytes.length > maxSize) {
        if (!mounted) return;
        VeraPopup.show(
          context,
          title: 'File too large',
          message: isVideo
              ? 'Videos must be 25 MB or less.'
              : 'Images must be 8 MB or less.',
          icon: Icons.warning_amber_rounded,
          accent: VeraTheme.warning,
        );
        return;
      }

      setState(() => _isUploadingMedia = true);

      final repo = MomentsRepositoryImpl(MomentsRemoteDataSource(client));

      final updatedModel = await repo.uploadMomentMedia(
        momentId: _currentMoment.id,
        version: _currentMoment.version,
        bytes: bytes,
        filename: file.name,
      );

      if (!mounted) return;
      setState(() {
        _isUploadingMedia = false;
        _currentMoment = updatedModel.toEntity();
        _streamedMediaBytes = Uint8List.fromList(bytes);
      });

      VeraPopup.show(
        context,
        title: 'Media uploaded',
        message: 'New media saved (version updated to v${_currentMoment.version}).',
        icon: Icons.check_circle_outline_rounded,
        accent: const Color(0xFF7DF0B0),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploadingMedia = false);

      final errorMsg = e.toString().replaceFirst(RegExp(r'^[A-Za-z]+Exception:\s*'), '');
      VeraPopup.show(
        context,
        title: 'Media upload failed',
        message: errorMsg,
        icon: Icons.error_outline_rounded,
        accent: VeraTheme.warning,
      );
    }
  }

  Future<void> _deleteMedia() async {
    final client = ApiClientScope.of(context);
    setState(() => _isUploadingMedia = true);

    try {
      final repo = MomentsRepositoryImpl(MomentsRemoteDataSource(client));

      final updatedModel = await repo.deleteMomentMedia(
        momentId: _currentMoment.id,
        version: _currentMoment.version,
      );

      if (!mounted) return;
      setState(() {
        _isUploadingMedia = false;
        _currentMoment = updatedModel.toEntity();
        _streamedMediaBytes = null;
      });

      VeraPopup.show(
        context,
        title: 'Media removed',
        message:
            'Media deleted (version updated to v${_currentMoment.version}).',
        icon: Icons.check_circle_outline_rounded,
        accent: const Color(0xFF7DF0B0),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploadingMedia = false);

      final errorMsg =
          e.toString().replaceFirst(RegExp(r'^[A-Za-z]+Exception:\s*'), '');
      VeraPopup.show(
        context,
        title: 'Delete media failed',
        message: errorMsg,
        icon: Icons.error_outline_rounded,
        accent: VeraTheme.warning,
      );
    }
  }

  void _showMediaPickerModal(BuildContext context, double scale) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withAlpha(160),
      builder: (modalContext) {
        final hasMedia = _streamedMediaBytes != null ||
            _currentMoment.backgroundImageUrl.isNotEmpty;
        return ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24 * scale)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: EdgeInsets.fromLTRB(
                  24 * scale, 20 * scale, 24 * scale, 28 * scale),
              decoration: const BoxDecoration(
                color: Color(0xFF16172E),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Media options',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18 * scale,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16 * scale),
                  ListTile(
                    leading: const Icon(Icons.camera_alt_outlined,
                        color: Colors.white),
                    title: const Text('Camera',
                        style: TextStyle(color: Colors.white)),
                    onTap: () {
                      Navigator.of(modalContext).pop();
                      _pickAndUploadMedia(ImageSource.camera);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.photo_library_outlined,
                        color: Colors.white),
                    title: const Text('Photo Gallery',
                        style: TextStyle(color: Colors.white)),
                    onTap: () {
                      Navigator.of(modalContext).pop();
                      _pickAndUploadMedia(ImageSource.gallery);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.videocam_outlined,
                        color: Colors.white),
                    title: const Text('Video Gallery',
                        style: TextStyle(color: Colors.white)),
                    onTap: () {
                      Navigator.of(modalContext).pop();
                      _pickAndUploadMedia(ImageSource.gallery, isVideo: true);
                    },
                  ),
                  if (hasMedia) ...[
                    const Divider(color: Color(0x22FFFFFF)),
                    ListTile(
                      leading: const Icon(Icons.delete_outline_rounded,
                          color: VeraTheme.warning),
                      title: const Text('Remove media',
                          style: TextStyle(color: VeraTheme.warning)),
                      onTap: () {
                        Navigator.of(modalContext).pop();
                        _deleteMedia();
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveChanges() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      VeraPopup.show(
        context,
        title: 'Title required',
        message: 'Please provide a title for your moment.',
        icon: Icons.title_rounded,
        accent: VeraTheme.warning,
      );
      return;
    }

    final teaser = _teaserController.text.trim();

    if (_currentMoment.id.isEmpty) {
      final updated = Moment(
        id: '',
        userName: _currentMoment.userName,
        userAvatarUrl: _currentMoment.userAvatarUrl,
        timeAgo: _currentMoment.timeAgo,
        backgroundImageUrl: _currentMoment.backgroundImageUrl,
        unlockCondition: _currentMoment.unlockCondition,
        title: title,
        teaser: teaser.isNotEmpty ? teaser : null,
        message: _currentMoment.message,
        version: _currentMoment.version,
      );
      Navigator.of(context).pop(updated);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final client = ApiClientScope.of(context);
      final repo = MomentsRepositoryImpl(MomentsRemoteDataSource(client));

      final params = UpdateMomentParams(
        version: _currentMoment.version,
        title: title,
        teaser: teaser.isNotEmpty ? teaser : null,
      );

      final updatedModel = await repo.updateMoment(_currentMoment.id, params);
      final updatedEntity = updatedModel.toEntity();

      if (!mounted) return;
      setState(() => _isSaving = false);

      VeraPopup.show(
        context,
        title: 'Moment updated',
        message: 'Your changes have been saved.',
        icon: Icons.check_circle_outline_rounded,
        accent: const Color(0xFF7DF0B0),
      );

      Navigator.of(context).pop(updatedEntity);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);

      final errorMsg = e.toString().replaceFirst(RegExp(r'^[A-Za-z]+Exception:\s*'), '');
      VeraPopup.show(
        context,
        title: 'Update failed',
        message: errorMsg,
        icon: Icons.error_outline_rounded,
        accent: VeraTheme.warning,
      );
    }
  }

  Future<void> _publishMoment() async {
    if (_currentMoment.id.isEmpty) return;

    setState(() => _isPublishing = true);

    try {
      final client = ApiClientScope.of(context);
      final repo = MomentsRepositoryImpl(MomentsRemoteDataSource(client));

      final publishedModel = await repo.publishMoment(
        momentId: _currentMoment.id,
        version: _currentMoment.version,
      );

      final updatedEntity = publishedModel.toEntity();

      if (!mounted) return;
      setState(() {
        _isPublishing = false;
        _currentMoment = updatedEntity;
      });

      VeraPopup.show(
        context,
        title: 'Submitted for review',
        message: 'Moment submitted (v${updatedEntity.version}). It is now pending admin review.',
        icon: Icons.check_circle_outline_rounded,
        accent: const Color(0xFF7DF0B0),
      );

      Navigator.of(context).pop(updatedEntity);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isPublishing = false);

      final errorMsg = e.toString().replaceFirst(RegExp(r'^[A-Za-z]+Exception:\s*'), '');
      VeraPopup.show(
        context,
        title: 'Publish failed',
        message: errorMsg,
        icon: Icons.error_outline_rounded,
        accent: VeraTheme.warning,
      );
    }
  }

  Future<void> _resendInvite() async {
    if (_isResendingInvite || _currentMoment.id.isEmpty) return;

    setState(() => _isResendingInvite = true);

    try {
      final client = ApiClientScope.of(context);
      final repo = MomentsRepositoryImpl(MomentsRemoteDataSource(client));

      final result = await repo.resendInvite(_currentMoment.id);

      if (!mounted) return;
      setState(() => _isResendingInvite = false);

      final msg = result.message ??
          'Invites sent: ${result.sent}, Attempted: ${result.attempted}, Failed: ${result.failed}';
      VeraPopup.show(
        context,
        title: 'Invites Resent',
        message: msg,
        icon: Icons.mark_email_read_rounded,
        accent: const Color(0xFF7DF0B0),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isResendingInvite = false);

      final errorMsg = e.toString().replaceFirst(RegExp(r'^[A-Za-z]+Exception:\s*'), '');
      VeraPopup.show(
        context,
        title: 'Resend Failed',
        message: errorMsg,
        icon: Icons.error_outline_rounded,
        accent: VeraTheme.warning,
      );
    }
  }

  Future<void> _confirmAndDeleteMoment() async {
    if (_currentMoment.id.isEmpty) return;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withAlpha(160),
      builder: (sheetContext) {
        final scale = (MediaQuery.sizeOf(sheetContext).width / 390).clamp(0.82, 1.2);
        return ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24 * scale)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: EdgeInsets.fromLTRB(24 * scale, 24 * scale, 24 * scale, 32 * scale),
              decoration: const BoxDecoration(
                color: Color(0xFF16172E),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8 * scale),
                        decoration: BoxDecoration(
                          color: VeraTheme.warning.withAlpha(40),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.delete_outline_rounded,
                          color: VeraTheme.warning,
                          size: 22 * scale,
                        ),
                      ),
                      SizedBox(width: 12 * scale),
                      Text(
                        'Delete moment?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18 * scale,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12 * scale),
                  Text(
                    'This will soft-delete this moment. You will no longer see it in your moments list.',
                    style: TextStyle(
                      color: const Color(0xFF8A8EB3),
                      fontSize: 13 * scale,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 24 * scale),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(sheetContext).pop(false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Color(0x33FFFFFF)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12 * scale),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 12 * scale),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      SizedBox(width: 12 * scale),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(sheetContext).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: VeraTheme.warning,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12 * scale),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 12 * scale),
                          ),
                          child: const Text('Delete'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);

    try {
      final client = ApiClientScope.of(context);
      final repo = MomentsRepositoryImpl(MomentsRemoteDataSource(client));

      await repo.deleteMoment(
        momentId: _currentMoment.id,
        version: _currentMoment.version,
      );

      HomeScreen.sentMoments.removeWhere((m) => m.id == _currentMoment.id);

      if (!mounted) return;
      setState(() => _isDeleting = false);

      VeraPopup.show(
        context,
        title: 'Moment deleted',
        message: 'The moment has been deleted.',
        icon: Icons.delete_outline_rounded,
        accent: VeraTheme.warning,
      );

      final deletedSentinel = Moment(
        id: '__DELETED__:${_currentMoment.id}',
        userName: _currentMoment.userName,
        userAvatarUrl: _currentMoment.userAvatarUrl,
        timeAgo: _currentMoment.timeAgo,
        backgroundImageUrl: _currentMoment.backgroundImageUrl,
        unlockCondition: _currentMoment.unlockCondition,
        title: _currentMoment.title,
        teaser: _currentMoment.teaser,
        message: _currentMoment.message,
        version: _currentMoment.version,
      );

      Navigator.of(context).pop(deletedSentinel);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isDeleting = false);

      final errorMsg = e.toString().replaceFirst(RegExp(r'^[A-Za-z]+Exception:\s*'), '');
      VeraPopup.show(
        context,
        title: 'Delete failed',
        message: errorMsg,
        icon: Icons.error_outline_rounded,
        accent: VeraTheme.warning,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final scale = VeraResponsive.scale(screen.width, designWidth: 390);
    final contentWidth = VeraResponsive.contentWidth(screen.width, horizontalPadding: 24 * scale);

    return Scaffold(
      backgroundColor: const Color(0xFF080914),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            SizedBox(
              height: 56 * scale,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16 * scale),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(_currentMoment),
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 18 * scale,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    Text(
                      'Edit moment',
                      style: TextStyle(
                        color: const Color(0xFFF7F5FF),
                        fontSize: 16 * scale,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (_currentMoment.id.isNotEmpty)
                      IconButton(
                        onPressed: (_isSaving || _isPublishing || _isDeleting)
                            ? null
                            : _confirmAndDeleteMoment,
                        icon: _isDeleting
                            ? SizedBox(
                                width: 18 * scale,
                                height: 18 * scale,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: VeraTheme.warning,
                                ),
                              )
                            : Icon(
                                Icons.delete_outline_rounded,
                                color: VeraTheme.warning,
                                size: 22 * scale,
                              ),
                        padding: EdgeInsets.zero,
                      )
                    else
                      SizedBox(width: 40 * scale),
                  ],
                ),
              ),
            ),

            // Form Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(24 * scale, 16 * scale, 24 * scale, 24 * scale),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Moment Title',
                      style: TextStyle(
                        color: const Color(0xFFD4D4E8),
                        fontSize: 14 * scale,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8 * scale),
                    SizedBox(
                      width: contentWidth,
                      height: 48 * scale,
                      child: TextField(
                        controller: _titleController,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14 * scale,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter moment title',
                          hintStyle: TextStyle(
                            color: const Color(0xFF8A8EB3),
                            fontSize: 14 * scale,
                          ),
                          filled: true,
                          fillColor: const Color(0xFF17182D),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16 * scale,
                            vertical: 12 * scale,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12 * scale),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 20 * scale),

                    Text(
                      'Teaser (visible while locked)',
                      style: TextStyle(
                        color: const Color(0xFFD4D4E8),
                        fontSize: 14 * scale,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8 * scale),
                    SizedBox(
                      width: contentWidth,
                      height: 48 * scale,
                      child: TextField(
                        controller: _teaserController,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14 * scale,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter teaser text',
                          hintStyle: TextStyle(
                            color: const Color(0xFF8A8EB3),
                            fontSize: 14 * scale,
                          ),
                          filled: true,
                          fillColor: const Color(0xFF17182D),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16 * scale,
                            vertical: 12 * scale,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12 * scale),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),

                    if (_currentMoment.id.isNotEmpty) ...[
                      SizedBox(height: 20 * scale),
                      Text(
                        'Media',
                        style: TextStyle(
                          color: const Color(0xFFD4D4E8),
                          fontSize: 14 * scale,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8 * scale),
                      Container(
                        padding: EdgeInsets.all(12 * scale),
                        decoration: BoxDecoration(
                          color: const Color(0xFF17182D),
                          borderRadius: BorderRadius.circular(12 * scale),
                          border: Border.all(color: const Color(0x22FFFFFF)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 50 * scale,
                              height: 50 * scale,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8 * scale),
                                color: const Color(0xFF222338),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: _streamedMediaBytes != null
                                  ? Image.memory(
                                      _streamedMediaBytes!,
                                      fit: BoxFit.cover,
                                    )
                                  : (_currentMoment.backgroundImageUrl.isNotEmpty
                                      ? Image.network(
                                          _currentMoment.backgroundImageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  const Icon(
                                            Icons.image_outlined,
                                            color: Colors.white54,
                                            size: 20,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.image_outlined,
                                          color: Colors.white54,
                                          size: 20,
                                        )),
                            ),
                            SizedBox(width: 12 * scale),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Attached Media',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13 * scale,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 2 * scale),
                                  Text(
                                    'JPEG, PNG, WebP or MP4',
                                    style: TextStyle(
                                      color: const Color(0xFF8A8EB3),
                                      fontSize: 11 * scale,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton.icon(
                              onPressed: _isUploadingMedia
                                  ? null
                                  : () => _showMediaPickerModal(context, scale),
                              icon: _isUploadingMedia
                                  ? SizedBox(
                                      width: 14 * scale,
                                      height: 14 * scale,
                                      child: const CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Icon(
                                      Icons.upload_file_rounded,
                                      size: 16 * scale,
                                      color: VeraTheme.purpleBright,
                                    ),
                              label: Text(
                                _isUploadingMedia ? 'Uploading...' : 'Replace',
                                style: TextStyle(
                                  color: VeraTheme.purpleBright,
                                  fontSize: 12 * scale,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    SizedBox(height: 16 * scale),

                    // Version & info chip
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14 * scale,
                        vertical: 10 * scale,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0x3317182D),
                        borderRadius: BorderRadius.circular(12 * scale),
                        border: Border.all(
                          color: const Color(0x22FFFFFF),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                color: const Color(0xFF8A8EB3),
                                size: 16 * scale,
                              ),
                              SizedBox(width: 8 * scale),
                              Expanded(
                                child: Text(
                                  'Current version: v${_currentMoment.version}. Updating saves a new draft version.',
                                  style: TextStyle(
                                    color: const Color(0xFF8A8EB3),
                                    fontSize: 12 * scale,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_currentMoment.id.isNotEmpty) ...[
                            SizedBox(height: 8 * scale),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: (_isSaving || _isPublishing || _isResendingInvite || _isDeleting)
                                    ? null
                                    : _publishMoment,
                                icon: _isPublishing
                                    ? SizedBox(
                                        width: 14 * scale,
                                        height: 14 * scale,
                                        child: const CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Icon(
                                        Icons.publish_rounded,
                                        size: 16 * scale,
                                        color: VeraTheme.purpleBright,
                                      ),
                                label: Text(
                                  _isPublishing
                                      ? 'Publishing...'
                                      : 'Publish draft',
                                  style: TextStyle(
                                    color: VeraTheme.purpleBright,
                                    fontSize: 12 * scale,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    if (!_currentMoment.isPublicSentMoment && _currentMoment.id.isNotEmpty) ...[
                      SizedBox(height: 16 * scale),
                      Container(
                        padding: EdgeInsets.all(14 * scale),
                        decoration: BoxDecoration(
                          color: const Color(0x3317182D),
                          borderRadius: BorderRadius.circular(12 * scale),
                          border: Border.all(color: const Color(0x22FFFFFF)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38 * scale,
                              height: 38 * scale,
                              decoration: BoxDecoration(
                                color: VeraTheme.purpleBright.withAlpha(35),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.mark_email_read_rounded,
                                color: VeraTheme.purpleBright,
                                size: 20 * scale,
                              ),
                            ),
                            SizedBox(width: 12 * scale),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Resend Invites',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13 * scale,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 2 * scale),
                                  Text(
                                    'Re-send email invites to registered recipients.',
                                    style: TextStyle(
                                      color: const Color(0xFF8A8EB3),
                                      fontSize: 11 * scale,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 8 * scale),
                            OutlinedButton(
                              onPressed: (_isSaving || _isPublishing || _isDeleting || _isResendingInvite)
                                  ? null
                                  : _resendInvite,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: VeraTheme.purpleBright,
                                side: BorderSide(
                                  color: VeraTheme.purpleBright.withAlpha(120),
                                  width: 1 * scale,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10 * scale),
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12 * scale,
                                  vertical: 8 * scale,
                                ),
                                minimumSize: Size(0, 34 * scale),
                              ),
                              child: _isResendingInvite
                                  ? SizedBox(
                                      width: 14 * scale,
                                      height: 14 * scale,
                                      child: const CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      'Resend',
                                      style: TextStyle(
                                        fontSize: 12 * scale,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (_currentMoment.id.isNotEmpty) ...[
                      SizedBox(height: 24 * scale),
                      Center(
                        child: TextButton.icon(
                          onPressed: (_isSaving || _isPublishing || _isDeleting)
                              ? null
                              : _confirmAndDeleteMoment,
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            size: 18 * scale,
                            color: VeraTheme.warning,
                          ),
                          label: Text(
                            _isDeleting ? 'Deleting moment...' : 'Delete moment',
                            style: TextStyle(
                              color: VeraTheme.warning,
                              fontSize: 13 * scale,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Save Button Bar
            Container(
              padding: EdgeInsets.fromLTRB(
                24 * scale,
                16 * scale,
                24 * scale,
                24 * scale + MediaQuery.paddingOf(context).bottom,
              ),
              decoration: const BoxDecoration(
                color: Color(0x59090A17),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(44),
                ),
              ),
              child: SizedBox(
                width: contentWidth,
                height: 48 * scale,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: VeraTheme.buttonGradient,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: const [
                      BoxShadow(
                        color: VeraTheme.glowPurple,
                        blurRadius: 22,
                        spreadRadius: 1,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: TextButton(
                    onPressed: _isSaving ? null : _saveChanges,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                    ),
                    child: _isSaving
                        ? SizedBox(
                            width: 20 * scale,
                            height: 20 * scale,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Save changes',
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
      ),
    );
  }
}
