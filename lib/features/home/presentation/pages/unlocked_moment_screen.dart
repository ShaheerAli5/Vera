import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/layout/responsive.dart';
import '../../../../core/realtime/moment_realtime_route.dart';
import '../../../../core/realtime/moment_realtime_service.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../../../core/widgets/vera_popup.dart';
import '../../../../core/network/api_client.dart';
import '../../../../main.dart' show ApiClientScope;
import '../widgets/creator_avatar.dart';
import '../widgets/moment_image_shimmer.dart';
import '../../../account/data/datasources/account_remote_data_source.dart';
import '../../../account/data/repositories/account_repository_impl.dart';
import '../../data/datasources/moments_remote_data_source.dart';
import '../../data/models/chat_message_model.dart';
import '../../data/repositories/moments_repository_impl.dart';
import '../../domain/entities/moment.dart';
import 'edit_moment_screen.dart';
import 'locked_moment_screen.dart';

class UnlockedMomentScreen extends StatefulWidget {
  const UnlockedMomentScreen({super.key, required this.moment});

  final Moment moment;

  @override
  State<UnlockedMomentScreen> createState() => _UnlockedMomentScreenState();
}

class _UnlockedMomentScreenState extends State<UnlockedMomentScreen> with MomentRealtimeRoute<UnlockedMomentScreen> {
  final TextEditingController _replyController = TextEditingController();
  late Moment _currentMoment;
  bool _realtimeNavigationScheduled = false;
  @override
  String get realtimeMomentId => widget.moment.id;

  @override
  void onMomentRealtime(MomentRealtimeUpdate update) {
    final updated = update.apply(_currentMoment);
    setState(() => _currentMoment = updated);
    if (update.deleted ||
        _realtimeNavigationScheduled ||
        !(!updated.canAccessContent && (update.isUnlocked == false || update.isApproved == false || update.canPreview == false))) {
      return;
    }
    _realtimeNavigationScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _realtimeNavigationScheduled = false;
      if (!mounted ||
          realtimeDeleted ||
          ModalRoute.of(context)?.isCurrent != true) {
        return;
      }
      final latest = applyRealtime(_currentMoment);
      if (latest.canAccessContent) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => LockedMomentScreen(moment: latest),
        ),
      );
    });
  }

  bool _isLoading = false;
  Uint8List? _mediaBytes;
  bool _isLoadingMedia = false;
  bool? _streamIsVideo;
  bool _isSendingReply = false;
  List<ChatMessageModel> _messages = [];
  bool _isLoadingMessages = false;
  String _displayName = '';
  String? _currentUserId;
  bool _conversationReady = false;
  bool _isCreator = false;
  String? _threadId;
  String? _selectedRecipientId;
  String? _conversationError;
  final Map<String, String> _recipientLabels = {};
  final Map<String, String> _recipientThreadIds = {};


  @override
  void initState() {
    super.initState();
    _currentMoment = widget.moment;
    _displayName = widget.moment.userName;
    PushNotificationService.instance.latestForegroundMessage.addListener(_onNewForegroundMessage);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_currentMoment.canAccessContent) {
        Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
          builder: (_) => LockedMomentScreen(moment: _currentMoment),
        ));
        return;
      }
      _fetchMediaStream();
      _initializeConversation();
    });
  }

  @override
  void dispose() {
    PushNotificationService.instance.latestForegroundMessage.removeListener(_onNewForegroundMessage);
    _replyController.dispose();
    super.dispose();
  }

  void _onNewForegroundMessage() {
    if (!mounted) return;
    _fetchThreadMessages();
  }

  Future<void> _initializeConversation() async {
    if (!mounted || !_currentMoment.canAccessContent) return;
    setState(() {
      _conversationReady = false;
      _conversationError = null;
    });
    try {
      final client = ApiClientScope.of(context);
      final accountRepo = AccountRepositoryImpl(AccountRemoteDataSource(client));
      final profile = await accountRepo.getProfile();
      if (!mounted) return;
      if (profile.id.isEmpty) throw const FormatException('Missing user identity');
      _currentUserId = profile.id;
      await _fetchFullMoment();
      if (!mounted || !applyRealtime(_currentMoment).canAccessContent) return;
      setState(() {
        _isCreator = _currentMoment.creatorId != null
            ? _currentMoment.creatorId == profile.id
            : widget.moment.userName.trim().toLowerCase() == 'you';
        _displayName = _isCreator ? profile.displayName : _currentMoment.userName;
        _recipientLabels.remove(profile.id);
        _conversationReady = true;
      });
      await _fetchThreadMessages();
    } catch (_) {
      if (!mounted) return;
      setState(() => _conversationError = 'Could not load your conversation. Please retry.');
    }
  }

  String _recipientLabel(String id, [Map<String, dynamic>? raw]) {
    final data = raw?['data'] is Map ? raw!['data'] as Map : raw;
    final person = data?['recipient'] ?? data?['recipientUser'];
    if (person is Map) {
      for (final key in ['displayName', 'name', 'username', 'email']) {
        final name = person[key]?.toString().trim();
        if (name != null && name.isNotEmpty) return name;
      }
    }
    return _recipientLabels[id] ?? 'Recipient ${_recipientLabels.length + 1}';
  }

  String _formatMessageTime(DateTime dt) {
    final local = dt.toLocal();
    final hour = local.hour > 12 ? local.hour - 12 : (local.hour == 0 ? 12 : local.hour);
    final min = local.minute.toString().padLeft(2, '0');
    final ampm = local.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$min $ampm';
  }

  Future<void> _fetchThreadMessages([String? knownThreadId]) async {
    if (!applyRealtime(_currentMoment).canAccessContent) return;
    if (!mounted || !_conversationReady || _isLoadingMessages ||
        _isSendingReply || _currentMoment.id.isEmpty) {
      return;
    }
    setState(() {
      _isLoadingMessages = true;
      _conversationError = null;
    });

    try {
      final client = ApiClientScope.of(context);
      final repo = MomentsRepositoryImpl(MomentsRemoteDataSource(client));

      if (_isCreator && _selectedRecipientId == null) {
        // A creator must choose an actual recipient; never create a self-thread.
        String? cursor;
        final seenCursors = <String>{};
        do {
          final page = await repo.getChatThreads(box: 'SENT', limit: 20, cursor: cursor);
          if (!mounted) return;
          for (final thread in page.items) {
            final recipient = thread.recipientUserId;
            if (thread.momentId != _currentMoment.id || recipient == null ||
                recipient.isEmpty || recipient == _currentUserId) {
              continue;
            }
            _recipientLabels[recipient] = _recipientLabel(recipient, thread.raw);
            if (thread.id.isNotEmpty) _recipientThreadIds[recipient] = thread.id;
          }
          cursor = page.hasMore ? page.nextCursor : null;
        } while (cursor != null && cursor.isNotEmpty && seenCursors.add(cursor));
        setState(() => _isLoadingMessages = false);
        return;
      }
      final threadId = knownThreadId ?? _threadId ??
          _recipientThreadIds[_selectedRecipientId] ??
          (await repo.createOrGetMomentThread(
            momentId: _currentMoment.id,
            recipientUserId: _isCreator ? _selectedRecipientId : null,
          )).id;
      _threadId = threadId;

      if (threadId.isNotEmpty) {
        final history = await repo.getThreadMessages(
          chatThreadId: threadId,
          limit: 50,
        );

        if (history.items.isNotEmpty) {
          final lastMsgId = history.items.last.id;
          if (lastMsgId.isNotEmpty) {
            repo.markThreadAsRead(
              chatThreadId: threadId,
              messageId: lastMsgId,
            ).catchError((_) {});
          }
        }

        if (!mounted) return;
        setState(() {
          _messages = history.items;
          _isLoadingMessages = false;
        });
      } else {
        if (!mounted) return;
        setState(() => _isLoadingMessages = false);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingMessages = false;
        _conversationError = 'Could not load the conversation. Please retry.';
      });
    }
  }

  Future<void> _fetchMediaStream() async {
    if (!_currentMoment.canAccessContent || _currentMoment.id.isEmpty || _isLoadingMedia || !_currentMoment.hasMedia) return;
    setState(() => _isLoadingMedia = true);

    try {
      final client = ApiClientScope.of(context);
      final repo = MomentsRepositoryImpl(MomentsRemoteDataSource(client));
      final stream = await repo.getMomentMedia(_currentMoment.id);

      if (!mounted || !applyRealtime(_currentMoment).canAccessContent) return;
      setState(() {
        _mediaBytes = stream.bytes;
        _isLoadingMedia = false;
        if (stream.contentType != null && stream.contentType!.isNotEmpty) {
          _streamIsVideo = stream.isVideo;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingMedia = false);
    }
  }

  Future<void> _fetchFullMoment() async {
    if (!_currentMoment.canAccessContent) return;
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final client = ApiClientScope.of(context);
      final repo = MomentsRepositoryImpl(MomentsRemoteDataSource(client));
      final before = client.momentRealtime.latest(_currentMoment.id);
      final model = await repo.getMomentContent(_currentMoment.id);
      final entity = model.toEntity();

      if (!mounted) return;
      setState(() {
        for (final id in model.recipientUserIds) {
          if (id.isNotEmpty && id != _currentUserId) {
            _recipientLabels.putIfAbsent(id, () => _recipientLabel(id));
          }
        }
        final recipients = model.raw['recipients'];
        if (recipients is List) {
          for (final person in recipients.whereType<Map>()) {
            final id = (person['recipientUserId'] ?? person['id'])?.toString();
            if (id != null && id.isNotEmpty && id != _currentUserId) {
              _recipientLabels[id] = _recipientLabel(id, {'recipient': person});
            }
          }
        }
        _currentMoment = entity.copyWith(
          invitationStatus: entity.invitationStatus ?? _currentMoment.invitationStatus,
          isReadyToOpen: model.serverIsUnlocked ?? _currentMoment.isReadyToOpen,
          isApproved: model.serverIsApproved ?? _currentMoment.isApproved,
          canPreview: model.serverCanPreview ?? model.serverIsCreator ?? _currentMoment.canPreview,
          creatorId: entity.creatorId ?? _currentMoment.creatorId,
          userName: (entity.userName.isNotEmpty && entity.userName != 'You')
              ? entity.userName
              : _currentMoment.userName,
          userAvatarUrl: entity.userAvatarUrl.isNotEmpty
              ? entity.userAvatarUrl
              : _currentMoment.userAvatarUrl,
          timeAgo: entity.timeAgo.isNotEmpty ? entity.timeAgo : _currentMoment.timeAgo,
          message: entity.message ?? _currentMoment.message,
          title: (entity.title != null && entity.title!.isNotEmpty && entity.title != 'Untitled Moment')
              ? entity.title
              : _currentMoment.title,
          teaser: entity.teaser ?? _currentMoment.teaser,
          backgroundImageUrl: (entity.backgroundImageUrl.isNotEmpty && !entity.backgroundImageUrl.contains('api/v1/moments'))
              ? entity.backgroundImageUrl
              : _currentMoment.backgroundImageUrl,
          openedAt: entity.openedAt ?? _currentMoment.openedAt,
          hasMedia: entity.hasMedia || _currentMoment.hasMedia,
          isVideo: entity.isVideo || _currentMoment.isVideo,
        );
        _currentMoment = model.serverIsUnlocked != null || model.serverIsApproved != null
            ? client.momentRealtime.reconcileRest(_currentMoment, before)
            : applyRealtime(_currentMoment);
        _isLoading = false;
      });
      if (!_currentMoment.canAccessContent) {
        onMomentRealtime(MomentRealtimeUpdate(momentId: _currentMoment.id, isUnlocked: false));
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (realtimeDeleted) return deletedMomentView();
    if (!applyRealtime(_currentMoment).canAccessContent) {
      return Scaffold(appBar: AppBar(title: const Text('Locked moment')),
        body: const Center(child: Icon(Icons.lock_outline)));
    }
    _currentMoment = applyRealtime(_currentMoment);
    final moment = _currentMoment;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = VeraResponsive.scale(screenWidth);
    final contentWidth = VeraResponsive.contentWidth(screenWidth, horizontalPadding: 24 * scale);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          Navigator.of(context).pop(_currentMoment);
        }
      },
      child: Scaffold(
      backgroundColor: const Color(0xFF080914),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SizedBox(
              height: 56 * scale,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16 * scale),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(_currentMoment),
                        icon: Icon(Icons.arrow_back_rounded,
                            color: Colors.white, size: 22 * scale),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints.tightFor(
                            width: 40 * scale, height: 40 * scale),
                      ),
                    ),
                    Text(
                      'Moment unlocked',
                      style: TextStyle(
                        color: const Color(0xFFF7F5FF),
                        fontSize: 16 * scale,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        onPressed: () => _showSafetyMenu(context, scale),
                        icon: Icon(Icons.more_horiz_rounded,
                            color: Colors.white, size: 22 * scale),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints.tightFor(
                            width: 40 * scale, height: 40 * scale),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Builder(
                builder: (context) {
                  final bottomPad = MediaQuery.paddingOf(context).bottom;
                  final client = ApiClientScope.of(context);
                  final repo = MomentsRepositoryImpl(MomentsRemoteDataSource(client));
                  final streamUrl = repo.getMomentMediaStreamUrl(moment.id);
                  final streamHeaders = repo.getMomentMediaHeaders();
                  final bool hasMediaAttachment = moment.hasMedia && moment.contentType?.toUpperCase() != 'TEXT';

                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                        24 * scale, 20 * scale, 24 * scale, 104 * scale + bottomPad),
                    child: Column(
                      children: [
                        _SenderBadge(moment: _currentMoment, scale: scale, displayName: _displayName),
                        if (hasMediaAttachment) ...[
                          SizedBox(height: 16 * scale),
                          _VideoPreview(
                            moment: moment,
                            scale: scale,
                            mediaBytes: _mediaBytes,
                            isLoadingMedia: _isLoadingMedia,
                            isStreamVideo: _streamIsVideo,
                            streamUrl: streamUrl,
                            streamHeaders: streamHeaders,
                          ),
                        ],
                        SizedBox(height: 16 * scale),
                        Container(
                          width: contentWidth,
                          constraints: BoxConstraints(minHeight: 88 * scale),
                          padding: EdgeInsets.all(18 * scale),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF1E1A3A),
                                Color(0xFF141526),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20 * scale),
                            border: Border.all(
                              color: const Color(0xFF9044FB).withValues(alpha: 0.35),
                              width: 1.5 * scale,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF9044FB).withValues(alpha: 0.1),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: _isLoading
                              ? Center(
                                  child: SizedBox(
                                    width: 20 * scale,
                                    height: 20 * scale,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF9044FB),
                                    ),
                                  ),
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.format_quote_rounded,
                                          color: const Color(0xFFC057FF),
                                          size: 18 * scale,
                                        ),
                                        SizedBox(width: 8 * scale),
                                        Text(
                                          'Moment Message',
                                          style: TextStyle(
                                            color: const Color(0xFFC057FF),
                                            fontSize: 12 * scale,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 10 * scale),
                                    Text(
                                      (moment.message != null &&
                                              moment.message!.isNotEmpty)
                                          ? moment.message!
                                          : 'No message provided for this moment.',
                                      style: TextStyle(
                                        color: const Color(0xFFF7F5FF),
                                        fontSize: 15.5 * scale,
                                        fontWeight: FontWeight.w400,
                                        height: 1.45,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                        SizedBox(height: 16 * scale),
                        if (_isCreator && _recipientLabels.isNotEmpty) ...[
                          DropdownButton<String>(
                            key: const ValueKey('conversation-recipient'),
                            value: _selectedRecipientId,
                            hint: const Text('Choose a recipient'),
                            isExpanded: true,
                            dropdownColor: const Color(0xFF17182D),
                            items: _recipientLabels.entries.map((entry) => DropdownMenuItem(
                              value: entry.key,
                              child: Text(entry.value),
                            )).toList(),
                            onChanged: _isLoadingMessages || _isSendingReply ? null : (id) {
                              setState(() {
                                _selectedRecipientId = id;
                                _threadId = null;
                                _messages = [];
                                _replyController.clear();
                              });
                              _fetchThreadMessages();
                            },
                          ),
                          SizedBox(height: 8 * scale),
                        ],
                        if (_conversationError != null)
                          Column(children: [
                            Text(_conversationError!, style: const TextStyle(color: Color(0xFFB4B4CD))),
                            TextButton(
                              onPressed: _isLoadingMessages ? null : () {
                                if (_conversationReady) {
                                  _fetchThreadMessages();
                                } else {
                                  _initializeConversation();
                                }
                              },
                              child: const Text('Retry conversation'),
                            ),
                          ]),
                        Row(
                          children: [
                            Text(
                              'Conversation (${_messages.length})',
                              style: TextStyle(
                                color: const Color(0xFFF7F5FF),
                                fontSize: 14 * scale,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              tooltip: 'Refresh conversation',
                              icon: const Icon(Icons.refresh_rounded),
                              onPressed: _isLoadingMessages || _isSendingReply ? null : () {
                                if (_conversationReady) {
                                  _fetchThreadMessages();
                                } else {
                                  _initializeConversation();
                                }
                              },
                            ),
                            if (_isLoadingMessages) ...[
                              SizedBox(width: 8 * scale),
                              SizedBox(
                                width: 12 * scale,
                                height: 12 * scale,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: Color(0xFF9044FB),
                                ),
                              ),
                            ],
                          ],
                        ),
                        SizedBox(height: 8 * scale),
                        if (_messages.isEmpty && _conversationError == null)
                          Container(
                            width: contentWidth,
                            padding: EdgeInsets.all(16 * scale),
                            decoration: BoxDecoration(
                              color: const Color(0x1A17182D),
                              borderRadius: BorderRadius.circular(12 * scale),
                              border: Border.all(color: const Color(0x22373657)),
                            ),
                            child: Text(
                              _isLoadingMessages
                                  ? 'Loading conversation...'
                                  : !_conversationReady
                                      ? 'Loading conversation...'
                                      : _isCreator && _selectedRecipientId == null
                                          ? (_recipientLabels.isEmpty
                                              ? 'Recipient conversations will appear here when someone replies.'
                                              : 'Choose a recipient to view or start a conversation.')
                                          : 'No messages yet. Send a reply below to start the conversation!',
                              style: TextStyle(
                                color: const Color(0xFF8A8EB3),
                                fontSize: 13 * scale,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          )
                        else
                          for (final msg in _messages) ...[
                            Builder(
                              builder: (context) {
                                final isMe = _currentUserId != null && _currentUserId!.isNotEmpty
                                    ? msg.senderId == _currentUserId
                                    : false;

                                return Align(
                                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                                  child: Container(
                                    constraints: BoxConstraints(maxWidth: contentWidth * 0.78),
                                    margin: EdgeInsets.only(bottom: 8 * scale),
                                    padding: EdgeInsets.symmetric(horizontal: 14 * scale, vertical: 10 * scale),
                                    decoration: BoxDecoration(
                                      color: isMe ? const Color(0xFF9044FB) : const Color(0xFF1E1E2F),
                                      gradient: isMe
                                          ? const LinearGradient(
                                              colors: [Color(0xFF9044FB), Color(0xFF6B42FF)],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            )
                                          : null,
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(16 * scale),
                                        topRight: Radius.circular(16 * scale),
                                        bottomLeft: Radius.circular(isMe ? 16 * scale : 4 * scale),
                                        bottomRight: Radius.circular(isMe ? 4 * scale : 16 * scale),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.15),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          msg.content,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14 * scale,
                                            height: 1.35,
                                          ),
                                        ),
                                        if (msg.createdAt != null) ...[
                                          SizedBox(height: 4 * scale),
                                          Text(
                                            _formatMessageTime(msg.createdAt!),
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 10 * scale,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                      ],
                    ),
                  );
                },
              ),
            ),
            if (_conversationReady && (!_isCreator || _selectedRecipientId != null))
              _ReplyBar(
              scale: scale,
              controller: _replyController,
              isSending: _isSendingReply,
              onSend: _handleSendReply,
            ),
          ],
        ),
      ),
    ),
    );
  }

  Future<void> _handleSendReply() async {
    if (!applyRealtime(_currentMoment).canAccessContent) return;
    final reply = _replyController.text.trim();
    if (reply.isEmpty || _isSendingReply || _isLoadingMessages ||
        !_conversationReady || (_isCreator && _selectedRecipientId == null)) {
      return;
    }

    setState(() => _isSendingReply = true);

    try {
      final client = ApiClientScope.of(context);
      final repo = MomentsRepositoryImpl(MomentsRemoteDataSource(client));

      final threadId = _threadId ?? (await repo.createOrGetMomentThread(
        momentId: _currentMoment.id,
        recipientUserId: _isCreator ? _selectedRecipientId : null,
      )).id;
      if (threadId.isEmpty) throw const FormatException('Missing conversation');
      _threadId = threadId;

      if (threadId.isNotEmpty) {
        final sentMsg = await repo.sendThreadMessage(
          chatThreadId: threadId,
          text: reply,
        );

        if (!mounted) return;
        _replyController.clear();
        setState(() {
          _messages.add(sentMsg);
          _isSendingReply = false;
        });

        VeraPopup.show(
          context,
          title: 'Reply sent',
          message: 'Your message has been sent.',
        );
      } else {
        if (!mounted) return;
        _replyController.clear();
        setState(() => _isSendingReply = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSendingReply = false);
      final errorMessage = e is ApiException
          ? e.message
          : 'Your reply could not be sent. Please try again.';
      VeraPopup.show(
        context,
        title: 'Could not send reply',
        icon: Icons.error_outline_rounded,
        accent: const Color(0xFFFFC46B),
        message: errorMessage.isNotEmpty ? errorMessage : 'Failed to send reply.',
      );
    }
  }

  void _showSafetyMenu(BuildContext context, double scale) {
    final client = ApiClientScope.of(context);
    final isAuthor = (_currentMoment.creatorId != null &&
            client.currentUserId != null &&
            _currentMoment.creatorId == client.currentUserId) ||
        _currentMoment.userName.trim().toLowerCase() == 'you';

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0xB3090A17),
      builder: (sheetContext) => Container(
        padding: EdgeInsets.fromLTRB(24 * scale, 16 * scale, 24 * scale, 32 * scale),
        decoration: BoxDecoration(
          color: const Color(0xFF17182D),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24 * scale)),
          border: Border.all(color: const Color(0xFF373657)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36 * scale,
              height: 4 * scale,
              margin: EdgeInsets.only(bottom: 20 * scale),
              decoration: BoxDecoration(
                color: const Color(0xFF454B70),
                borderRadius: BorderRadius.circular(2 * scale),
              ),
            ),
            if (isAuthor) ...[
              ListTile(
                leading: const Icon(Icons.edit_outlined, color: Colors.white),
                title: const Text('Edit moment', style: TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  final updated = await Navigator.of(context).push<Moment>(
                    MaterialPageRoute<Moment>(
                      builder: (_) => EditMomentScreen(moment: _currentMoment),
                    ),
                  );
                  if (updated != null && mounted) {
                    setState(() => _currentMoment = updated);
                  }
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.flag_outlined, color: Colors.white),
              title: const Text('Report moment', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _showReportSheet(context, scale);
              },
            ),
            if (!isAuthor) ...[
              ListTile(
                leading: const Icon(Icons.person_off_outlined, color: Color(0xFFFFA05C)),
                title: Text('Report ${_currentMoment.userName}',
                    style: const TextStyle(color: Color(0xFFFFA05C))),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _showReportUserSheet(context, scale);
                },
              ),
              ListTile(
                leading: const Icon(Icons.block, color: Color(0xFFFF4D4F)),
                title: Text('Block ${_currentMoment.userName}',
                    style: const TextStyle(color: Color(0xFFFF4D4F))),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _showBlockConfirmation(context, scale);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showReportUserSheet(BuildContext context, double scale) {
    final client = ApiClientScope.of(context);
    final accountRepo = AccountRepositoryImpl(AccountRemoteDataSource(client));
    final targetUserId = _currentMoment.creatorId;

    if (targetUserId == null || targetUserId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot identify user to report.')),
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0xB3090A17),
      builder: (sheetCtx) => Container(
        padding: EdgeInsets.fromLTRB(24 * scale, 16 * scale, 24 * scale, 32 * scale),
        decoration: BoxDecoration(
          color: const Color(0xFF17182D),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24 * scale)),
          border: Border.all(color: const Color(0xFF373657)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Report ${_currentMoment.userName}',
                style: TextStyle(color: Colors.white, fontSize: 18 * scale, fontWeight: FontWeight.bold)),
            SizedBox(height: 16 * scale),
            for (final entry in const [
              MapEntry('Harassment or bullying', 'HARASSMENT'),
              MapEntry('Spam or scam', 'SPAM'),
              MapEntry('Hate speech', 'HATE_SPEECH'),
              MapEntry('Explicit or inappropriate content', 'EXPLICIT_CONTENT'),
              MapEntry('Something else', 'OTHER'),
            ])
              ListTile(
                title: Text(entry.key, style: const TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.of(sheetCtx).pop();
                  String? details;
                  if (entry.value == 'OTHER') {
                    details = await _promptReportDetails(context, scale);
                    if (details == null || details.trim().isEmpty) return;
                  }
                  try {
                    await accountRepo.reportUser(
                      userId: targetUserId,
                      reason: entry.value,
                      details: details,
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Report against ${_currentMoment.userName} submitted. Thank you.'),
                          backgroundColor: const Color(0xFF6B42FF),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to submit report: $e')),
                      );
                    }
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showBlockConfirmation(BuildContext context, double scale) {
    final client = ApiClientScope.of(context);
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF17182D),
        title: Text('Block ${_currentMoment.userName}?',
            style: const TextStyle(color: Colors.white)),
        content: Text(
          "You won't receive new invitations or notifications from ${_currentMoment.userName}. You can unblock them in Privacy settings.",
          style: const TextStyle(color: Color(0xFFA2A5C2)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFFA2A5C2))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF4D4F)),
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              final targetId = _currentMoment.creatorId;
              if (targetId == null || targetId.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cannot block this user.')),
                );
                return;
              }
              try {
                final repo = AccountRepositoryImpl(AccountRemoteDataSource(client));
                await repo.blockUser(targetId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${_currentMoment.userName} has been blocked.')),
                  );
                  Navigator.of(context).pop(_currentMoment.copyWith(
                    id: '__DELETED__:${_currentMoment.id}',
                  ));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to block user: $e')),
                  );
                }
              }
            },
            child: const Text('Block', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showReportSheet(BuildContext context, double scale) {
    final client = ApiClientScope.of(context);
    final repo = MomentsRepositoryImpl(MomentsRemoteDataSource(client));
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0xB3090A17),
      builder: (sheetCtx) => Container(
        padding: EdgeInsets.fromLTRB(24 * scale, 16 * scale, 24 * scale, 32 * scale),
        decoration: BoxDecoration(
          color: const Color(0xFF17182D),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24 * scale)),
          border: Border.all(color: const Color(0xFF373657)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Why are you reporting this?',
                style: TextStyle(color: Colors.white, fontSize: 18 * scale, fontWeight: FontWeight.bold)),
            SizedBox(height: 16 * scale),
            for (final entry in const [
              MapEntry('Spam', 'SPAM'),
              MapEntry('Inappropriate content', 'INAPPROPRIATE_CONTENT'),
              MapEntry('Harassment', 'HARASSMENT'),
              MapEntry('Something else', 'OTHER'),
            ])
              ListTile(
                title: Text(entry.key, style: const TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.of(sheetCtx).pop();
                  String? details;
                  if (entry.value == 'OTHER') {
                    details = await _promptReportDetails(context, scale);
                    if (details == null || details.trim().isEmpty) return;
                  }
                  try {
                    await repo.reportMoment(
                      momentId: _currentMoment.id,
                      reason: entry.value,
                      details: details,
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Report submitted. Thank you for keeping Vera safe.')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to submit report: $e')),
                      );
                    }
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<String?> _promptReportDetails(BuildContext context, double scale) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF17182D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20 * scale)),
        title: Text(
          'Report details',
          style: TextStyle(color: Colors.white, fontSize: 18 * scale),
        ),
        content: TextField(
          controller: controller,
          maxLines: 3,
          style: TextStyle(color: Colors.white, fontSize: 14 * scale),
          decoration: InputDecoration(
            hintText: 'Please describe the issue...',
            hintStyle: TextStyle(color: const Color(0xFFA2A5C2), fontSize: 14 * scale),
            filled: true,
            fillColor: const Color(0xFF0F1021),
            contentPadding: EdgeInsets.all(16 * scale),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12 * scale),
              borderSide: const BorderSide(color: Color(0x1AFFFFFF)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12 * scale),
              borderSide: const BorderSide(color: Color(0xFF9044FB)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text('Cancel', style: TextStyle(color: const Color(0xFFA2A5C2), fontSize: 14 * scale)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9044FB)),
            onPressed: () => Navigator.of(dialogCtx).pop(controller.text.trim()),
            child: Text('Submit', style: TextStyle(color: Colors.white, fontSize: 14 * scale)),
          ),
        ],
      ),
    );
  }
}

class _SenderBadge extends StatelessWidget {
  const _SenderBadge({required this.moment, required this.scale, required this.displayName});

  final Moment moment;
  final double scale;
  final String displayName;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48 * scale,
      padding: EdgeInsets.symmetric(horizontal: 12 * scale),
      decoration: BoxDecoration(
        color: const Color(0x22090A17),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x443F4356), width: scale),
      ),
      child: Row(
        children: [
          CreatorAvatar(
            name: displayName,
            avatarUrl: moment.userAvatarUrl,
            size: 36 * scale,
          ),
          SizedBox(width: 10 * scale),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'From $displayName',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13 * scale,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 2 * scale),
              Text(
                moment.timeAgo,
                style: TextStyle(
                  color: const Color(0xFFF7F5FF),
                  fontSize: 11 * scale,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VideoPreview extends StatefulWidget {
  const _VideoPreview({
    required this.moment,
    required this.scale,
    this.mediaBytes,
    this.isLoadingMedia = false,
    this.isStreamVideo,
    required this.streamUrl,
    required this.streamHeaders,
  });

  final Moment moment;
  final double scale;
  final Uint8List? mediaBytes;
  final bool isLoadingMedia;
  final bool? isStreamVideo;
  final String streamUrl;
  final Map<String, String> streamHeaders;

  @override
  State<_VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<_VideoPreview> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  bool _isPlaying = false;

  late ApiClient _client;
  late MomentsRepositoryImpl _repo;
  bool _didInitClient = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInitClient) {
      _client = ApiClientScope.of(context);
      _repo = MomentsRepositoryImpl(MomentsRemoteDataSource(_client));
      _didInitClient = true;
      _checkAndInitVideo();
    }
  }

  @override
  void didUpdateWidget(covariant _VideoPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.moment.id != oldWidget.moment.id) {
      _controller?.pause();
      _controller?.dispose();
      _controller = null;
      _isInitialized = false;
      _hasError = false;
      _isLoading = false;
      _checkAndInitVideo();
    } else if (!_isInitialized &&
        !_isLoading &&
        widget.mediaBytes != null &&
        widget.mediaBytes!.isNotEmpty &&
        widget.mediaBytes != oldWidget.mediaBytes) {
      _checkAndInitVideo();
    }
  }

  @override
  void dispose() {
    _controller?.pause();
    _controller?.dispose();
    super.dispose();
  }

  bool get _shouldPlayVideo {
    return widget.isStreamVideo == true ||
        widget.moment.isVideo ||
        widget.moment.contentType?.toUpperCase() == 'VIDEO';
  }

  Future<void> _checkAndInitVideo() async {
    if (!_shouldPlayVideo) return;
    if (_controller != null || _isLoading) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      VideoPlayerController? controller;

      // 1. If we already have the media bytes, write to a temp file and play via VideoPlayerController.file
      if (widget.mediaBytes != null && widget.mediaBytes!.isNotEmpty) {
        final tempFile = File('${Directory.systemTemp.path}/moment_${widget.moment.id}.mp4');
        await tempFile.writeAsBytes(widget.mediaBytes!, flush: true);
        final fileCtrl = VideoPlayerController.file(tempFile);
        await fileCtrl.initialize().timeout(const Duration(seconds: 10));
        controller = fileCtrl;
      } else {
        // 2. Try fetching the media directly via ApiClient (reliable file stream with auth)
        try {
          final stream = await _repo.getMomentMedia(widget.moment.id).timeout(const Duration(seconds: 15));
          if (stream.bytes.isNotEmpty) {
            final tempFile = File('${Directory.systemTemp.path}/moment_${widget.moment.id}.mp4');
            await tempFile.writeAsBytes(stream.bytes, flush: true);
            final fileCtrl = VideoPlayerController.file(tempFile);
            await fileCtrl.initialize().timeout(const Duration(seconds: 10));
            controller = fileCtrl;
          }
        } catch (_) {
          // 3. Fallback to direct networkUrl streaming
          if (widget.streamUrl.isNotEmpty) {
            final netController = VideoPlayerController.networkUrl(
              Uri.parse(widget.streamUrl),
              httpHeaders: _repo.getMomentMediaHeaders(),
            );
            await netController.initialize().timeout(const Duration(seconds: 8));
            controller = netController;
          } else {
            rethrow;
          }
        }
      }

      if (controller == null) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Failed to load video stream';
        });
        return;
      }

      _controller = controller;
      controller.setLooping(true);
      await controller.play();
      if (!mounted) return;
      setState(() {
        _isInitialized = true;
        _isLoading = false;
        _isPlaying = true;
      });
      controller.addListener(() {
        if (!mounted) return;
        final playing = controller!.value.isPlaying;
        if (playing != _isPlaying) {
          setState(() => _isPlaying = playing);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString().replaceFirst(RegExp(r'^[A-Za-z]+Exception:\s*'), '');
      });
    }
  }

  void _togglePlayPause() {
    if (_controller == null || !_isInitialized) return;
    if (_controller!.value.isPlaying) {
      _controller!.pause();
      setState(() => _isPlaying = false);
    } else {
      _controller!.play();
      setState(() => _isPlaying = true);
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final isVideo = _shouldPlayVideo;
    final scale = widget.scale;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16 * scale),
      child: Container(
        width: double.infinity,
        height: 430 * scale,
        color: const Color(0xFF0F101E),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (isVideo) ...[
              if (_isInitialized && _controller != null)
                Center(
                  child: AspectRatio(
                    aspectRatio: _controller!.value.aspectRatio > 0
                        ? _controller!.value.aspectRatio
                        : 9 / 16,
                    child: VideoPlayer(_controller!),
                  ),
                )
              else if (_isLoading)
                const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Color(0xFF9044FB)),
                      SizedBox(height: 12),
                      Text(
                        'Loading video stream...',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                )
              else if (_hasError)
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(16 * scale),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline_rounded,
                            color: Colors.redAccent, size: 40 * scale),
                        SizedBox(height: 8 * scale),
                        Text(
                          'Failed to load video stream',
                          style: TextStyle(color: Colors.white, fontSize: 14 * scale, fontWeight: FontWeight.bold),
                        ),
                        if (_errorMessage != null) ...[
                          SizedBox(height: 4 * scale),
                          Text(
                            _errorMessage!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white60, fontSize: 11 * scale),
                          ),
                        ],
                        SizedBox(height: 12 * scale),
                        ElevatedButton.icon(
                          onPressed: () {
                            _controller?.dispose();
                            _controller = null;
                            _checkAndInitVideo();
                          },
                          icon: const Icon(Icons.refresh, color: Colors.white, size: 16),
                          label: const Text('Retry', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF9044FB),
                            padding: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 8 * scale),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                _buildFallbackImage(),

              // Center Play/Pause button
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _togglePlayPause,
                child: Center(
                  child: AnimatedOpacity(
                    opacity: !_isPlaying && _isInitialized ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      width: 64 * scale,
                      height: 64 * scale,
                      decoration: const BoxDecoration(
                        color: Color(0x99090A17),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.play_arrow_rounded,
                          color: Colors.white, size: 36 * scale),
                    ),
                  ),
                ),
              ),

              // Bottom Video Timeline Bar
              if (_isInitialized && _controller != null)
                Positioned(
                  left: 16 * scale,
                  right: 16 * scale,
                  bottom: 14 * scale,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ValueListenableBuilder<VideoPlayerValue>(
                        valueListenable: _controller!,
                        builder: (context, val, _) {
                          return Row(
                            children: [
                              Text(
                                _formatDuration(val.position),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12 * scale,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                _formatDuration(val.duration),
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12 * scale,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      SizedBox(height: 4 * scale),
                      VideoProgressIndicator(
                        _controller!,
                        allowScrubbing: true,
                        colors: const VideoProgressColors(
                          playedColor: Color(0xFF9044FB),
                          bufferedColor: Colors.white24,
                          backgroundColor: Colors.white10,
                        ),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
            ] else ...[
              // Photo / Image rendering
              if (widget.mediaBytes != null && widget.mediaBytes!.isNotEmpty)
                Image.memory(
                  widget.mediaBytes!,
                  fit: BoxFit.cover,
                  frameBuilder: momentImageLoadingFrame,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildFallbackImage(),
                )
              else if (widget.streamUrl.isNotEmpty)
                Image.network(
                  widget.streamUrl,
                  headers: widget.streamHeaders,
                  fit: BoxFit.cover,
                  frameBuilder: momentImageLoadingFrame,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildFallbackImage(),
                )
              else
                _buildFallbackImage(),
            ],

            // Top Status Badge (Streaming indicator)
            if (widget.isLoadingMedia && !isVideo)
              Positioned(
                top: 14 * scale,
                right: 14 * scale,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10 * scale,
                    vertical: 4 * scale,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0x99000000),
                    borderRadius: BorderRadius.circular(20 * scale),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 10 * scale,
                        height: 10 * scale,
                        child: const CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 6 * scale),
                      Text(
                        'Loading...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11 * scale,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackImage() {
    final bgUrl = widget.moment.backgroundImageUrl;
    if (bgUrl.isNotEmpty && (bgUrl.startsWith('http://') || bgUrl.startsWith('https://'))) {
      return Image.network(
        bgUrl,
        headers: widget.streamHeaders,
        fit: BoxFit.cover,
        frameBuilder: momentImageLoadingFrame,
        errorBuilder: (context, error, stackTrace) => const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF124552), Color(0xFF51352F)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      );
    }
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF124552), Color(0xFF51352F)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }
}

class _ReplyBar extends StatelessWidget {
  const _ReplyBar({
    required this.scale,
    required this.controller,
    required this.onSend,
    this.isSending = false,
  });

  final double scale;
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isSending;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    return Container(
      height: (88 * scale) + bottomPad,
      padding: EdgeInsets.fromLTRB(
          24 * scale, 16 * scale, 24 * scale, 24 * scale + bottomPad),
      decoration: BoxDecoration(
        color: const Color(0xD9090A17),
        border: Border(
          top: BorderSide(color: const Color(0x334B3B70), width: scale),
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(44 * scale),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48 * scale,
              decoration: BoxDecoration(
                color: const Color(0x22090A17),
                borderRadius: BorderRadius.circular(16 * scale),
                border: Border.all(color: const Color(0x443F4356)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                controller: controller,
                enabled: !isSending,
                textAlignVertical: TextAlignVertical.center,
                maxLines: 1,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14 * scale,
                  height: 24 / 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Write a reply...',
                  hintStyle: TextStyle(
                    color: const Color(0xFF8A8EB3),
                    fontSize: 14 * scale,
                    height: 24 / 14,
                  ),
                  isDense: true,
                  contentPadding: EdgeInsets.fromLTRB(
                      12 * scale, 8 * scale, 12 * scale, 8 * scale),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          SizedBox(width: 8 * scale),
          SizedBox(
            width: 48 * scale,
            height: 48 * scale,
            child: isSending
                ? Center(
                    child: SizedBox(
                      width: 24 * scale,
                      height: 24 * scale,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF9044FB),
                      ),
                    ),
                  )
                : GestureDetector(
                    key: const ValueKey('send-moment-reply'),
                    onTap: onSend,
                    child: Image.asset(
                      'assets/images/reply_send_button.png',
                      width: 48 * scale,
                      height: 48 * scale,
                      fit: BoxFit.contain,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
