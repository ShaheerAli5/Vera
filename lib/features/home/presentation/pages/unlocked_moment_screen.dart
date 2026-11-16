import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/layout/responsive.dart';
import '../../../../core/widgets/vera_popup.dart';
import '../../../../main.dart' show ApiClientScope;
import '../../data/datasources/moments_remote_data_source.dart';
import '../../data/models/chat_message_model.dart';
import '../../data/repositories/moments_repository_impl.dart';
import '../../domain/entities/moment.dart';

class UnlockedMomentScreen extends StatefulWidget {
  const UnlockedMomentScreen({super.key, required this.moment});

  final Moment moment;

  @override
  State<UnlockedMomentScreen> createState() => _UnlockedMomentScreenState();
}

class _UnlockedMomentScreenState extends State<UnlockedMomentScreen> {
  final TextEditingController _replyController = TextEditingController();
  late Moment _currentMoment;
  bool _isLoading = false;
  Uint8List? _mediaBytes;
  bool _isLoadingMedia = false;
  bool? _streamIsVideo;
  bool _isSendingReply = false;
  List<ChatMessageModel> _messages = [];
  bool _isLoadingMessages = false;

  @override
  void initState() {
    super.initState();
    _currentMoment = widget.moment;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchFullMoment();
      _fetchMediaStream();
      _fetchThreadMessages();
    });
  }

  Future<void> _fetchThreadMessages([String? knownThreadId]) async {
    if (_currentMoment.id.isEmpty) return;
    setState(() => _isLoadingMessages = true);

    try {
      final client = ApiClientScope.of(context);
      final repo = MomentsRepositoryImpl(MomentsRemoteDataSource(client));

      final threadId = knownThreadId ??
          (await repo.createOrGetMomentThread(momentId: _currentMoment.id)).id;

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
      setState(() => _isLoadingMessages = false);
    }
  }

  Future<void> _fetchMediaStream() async {
    if (_currentMoment.id.isEmpty || _isLoadingMedia) return;
    setState(() => _isLoadingMedia = true);

    try {
      final client = ApiClientScope.of(context);
      final repo = MomentsRepositoryImpl(MomentsRemoteDataSource(client));
      final stream = await repo.getMomentMedia(_currentMoment.id);

      if (!mounted) return;
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
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final client = ApiClientScope.of(context);
      final repo = MomentsRepositoryImpl(MomentsRemoteDataSource(client));
      final model = await repo.getMomentContent(_currentMoment.id);
      final entity = model.toEntity();

      if (!mounted) return;
      setState(() {
        _currentMoment = entity.copyWith(
          userName: (entity.userName.isNotEmpty && entity.userName != 'You')
              ? entity.userName
              : _currentMoment.userName,
          userAvatarUrl: entity.userAvatarUrl.isNotEmpty
              ? entity.userAvatarUrl
              : _currentMoment.userAvatarUrl,
          timeAgo: entity.timeAgo.isNotEmpty ? entity.timeAgo : _currentMoment.timeAgo,
          message: entity.message ?? _currentMoment.message,
          title: entity.title ?? _currentMoment.title,
          teaser: entity.teaser ?? _currentMoment.teaser,
          backgroundImageUrl: (entity.backgroundImageUrl.isNotEmpty && !entity.backgroundImageUrl.contains('api/v1/moments'))
              ? entity.backgroundImageUrl
              : _currentMoment.backgroundImageUrl,
          openedAt: entity.openedAt ?? _currentMoment.openedAt,
        );
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final moment = _currentMoment;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = VeraResponsive.scale(screenWidth);
    final contentWidth = VeraResponsive.contentWidth(screenWidth, horizontalPadding: 24 * scale);

    return Scaffold(
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
                        onPressed: () => Navigator.of(context).maybePop(),
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
                  ],
                ),
              ),
            ),
            Expanded(
              child: Builder(
                builder: (context) {
                  final bottomPad = MediaQuery.paddingOf(context).bottom;
                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                        24 * scale, 20 * scale, 24 * scale, 104 * scale + bottomPad),
                    child: Column(
                      children: [
                        _SenderBadge(moment: moment, scale: scale),
                        SizedBox(height: 16 * scale),
                        _VideoPreview(
                          moment: moment,
                          scale: scale,
                          mediaBytes: _mediaBytes,
                          isLoadingMedia: _isLoadingMedia,
                          isStreamVideo: _streamIsVideo,
                        ),
                        SizedBox(height: 16 * scale),
                        Container(
                          width: contentWidth,
                          constraints: BoxConstraints(minHeight: 82 * scale),
                          padding: EdgeInsets.all(16 * scale),
                          alignment: Alignment.centerLeft,
                          decoration: BoxDecoration(
                            color: const Color(0x3317182D),
                            borderRadius: BorderRadius.circular(18 * scale),
                            border: Border.all(
                                color: const Color(0xFF373657), width: scale),
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
                              : Text(
                                  (moment.message != null &&
                                          moment.message!.isNotEmpty)
                                      ? moment.message!
                                      : 'No message provided for this moment.',
                                  style: TextStyle(
                                    color: const Color(0xFFF7F5FF),
                                    fontSize: 16 * scale,
                                    fontWeight: FontWeight.w400,
                                    height: 24 / 16,
                                  ),
                                ),
                        ),
                        if (_isLoadingMessages) ...[
                          SizedBox(height: 12 * scale),
                          Center(
                            child: SizedBox(
                              width: 16 * scale,
                              height: 16 * scale,
                              child: const CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: Color(0xFF9044FB),
                              ),
                            ),
                          ),
                        ] else if (_messages.isNotEmpty) ...[
                          SizedBox(height: 16 * scale),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Conversation (${_messages.length})',
                              style: TextStyle(
                                color: const Color(0xFFF7F5FF),
                                fontSize: 14 * scale,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          SizedBox(height: 8 * scale),
                          for (final msg in _messages) ...[
                            Container(
                              width: contentWidth,
                              margin: EdgeInsets.only(bottom: 8 * scale),
                              padding: EdgeInsets.all(12 * scale),
                              decoration: BoxDecoration(
                                color: const Color(0x2217182D),
                                borderRadius: BorderRadius.circular(12 * scale),
                                border: Border.all(
                                    color: const Color(0x33373657), width: scale),
                              ),
                              child: Text(
                                msg.content,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14 * scale,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
            _ReplyBar(
              scale: scale,
              controller: _replyController,
              isSending: _isSendingReply,
              onSend: _handleSendReply,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSendReply() async {
    final reply = _replyController.text.trim();
    if (reply.isEmpty || _isSendingReply) return;

    setState(() => _isSendingReply = true);

    try {
      final client = ApiClientScope.of(context);
      final repo = MomentsRepositoryImpl(MomentsRemoteDataSource(client));

      final thread = await repo.createOrGetMomentThread(
        momentId: _currentMoment.id,
      );

      if (thread.id.isNotEmpty) {
        final sentMsg = await repo.sendThreadMessage(
          chatThreadId: thread.id,
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
      final errorMessage =
          e.toString().replaceFirst(RegExp(r'^[A-Za-z]+Exception:\s*'), '');
      VeraPopup.show(
        context,
        title: 'Error',
        message:
            errorMessage.isNotEmpty ? errorMessage : 'Failed to send reply.',
      );
    }
  }
}

class _SenderBadge extends StatelessWidget {
  const _SenderBadge({required this.moment, required this.scale});

  final Moment moment;
  final double scale;

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
          ClipOval(
            child: moment.userAvatarUrl.isNotEmpty
                ? Image.network(
                    moment.userAvatarUrl,
                    width: 36 * scale,
                    height: 36 * scale,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 36 * scale,
                      height: 36 * scale,
                      color: const Color(0xFF6B42FF),
                      child: Icon(Icons.person,
                          color: Colors.white, size: 18 * scale),
                    ),
                  )
                : Container(
                    width: 36 * scale,
                    height: 36 * scale,
                    color: const Color(0xFF6B42FF),
                    child: Icon(Icons.person,
                        color: Colors.white, size: 18 * scale),
                  ),
          ),
          SizedBox(width: 10 * scale),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'From ${moment.userName}',
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

class _VideoPreview extends StatelessWidget {
  const _VideoPreview({
    required this.moment,
    required this.scale,
    this.mediaBytes,
    this.isLoadingMedia = false,
    this.isStreamVideo,
  });

  final Moment moment;
  final double scale;
  final Uint8List? mediaBytes;
  final bool isLoadingMedia;
  final bool? isStreamVideo;

  @override
  Widget build(BuildContext context) {
    final isVideo = isStreamVideo ?? moment.isVideo;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16 * scale),
      child: SizedBox(
        width: double.infinity,
        height: 430 * scale,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (mediaBytes != null && mediaBytes!.isNotEmpty)
              Image.memory(
                mediaBytes!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildFallbackImage(),
              )
            else
              _buildFallbackImage(),
            if (isLoadingMedia)
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
                        'Streaming...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11 * scale,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (isVideo) ...[
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0x00000000),
                        const Color(0x00000000),
                        const Color(0x55000000),
                      ],
                      stops: const [0, .72, 1],
                    ),
                  ),
                ),
              ),
              Center(
                child: Container(
                  width: 64 * scale,
                  height: 64 * scale,
                  decoration: const BoxDecoration(
                    color: Color(0x99090A17),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.play_arrow_rounded,
                      color: Colors.white, size: 32 * scale),
                ),
              ),
              Positioned(
                left: 16 * scale,
                right: 16 * scale,
                bottom: 14 * scale,
                child: Row(
                  children: [
                    Text('0:00',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12 * scale,
                            fontWeight: FontWeight.w500)),
                    SizedBox(width: 8 * scale),
                    Expanded(
                      child: Container(
                        height: 3 * scale,
                        decoration: BoxDecoration(
                          color: const Color(0x99FFFFFF),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: .14,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7F5FF),
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8 * scale),
                    Text('0:15',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12 * scale,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackImage() {
    return Image.network(
      moment.backgroundImageUrl,
      fit: BoxFit.cover,
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
          SizedBox(
            width: 48 * scale,
            height: 48 * scale,
            child: IconButton(
              onPressed: () {},
              icon: Icon(Icons.add_rounded, color: Colors.white, size: 22 * scale),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0x12F7F5FF),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16 * scale)),
              ),
            ),
          ),
          SizedBox(width: 8 * scale),
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
