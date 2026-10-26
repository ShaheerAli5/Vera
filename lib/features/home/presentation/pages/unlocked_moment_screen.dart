import 'package:flutter/material.dart';

import '../../domain/entities/moment.dart';

class UnlockedMomentScreen extends StatefulWidget {
  const UnlockedMomentScreen({super.key, required this.moment});

  final Moment moment;

  @override
  State<UnlockedMomentScreen> createState() => _UnlockedMomentScreenState();
}

class _UnlockedMomentScreenState extends State<UnlockedMomentScreen> {
  final TextEditingController _replyController = TextEditingController();

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final moment = widget.moment;
    final scale = (MediaQuery.sizeOf(context).width / 393).clamp(.82, 1.12);

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
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                    24 * scale, 20 * scale, 24 * scale, 104 * scale),
                child: Column(
                  children: [
                    _SenderBadge(moment: moment, scale: scale),
                    SizedBox(height: 16 * scale),
                    _VideoPreview(moment: moment, scale: scale),
                    SizedBox(height: 16 * scale),
                    Container(
                      width: 342 * scale,
                      height: 82 * scale,
                      padding: EdgeInsets.all(16 * scale),
                      alignment: Alignment.centerLeft,
                      decoration: BoxDecoration(
                        color: const Color(0x3317182D),
                        borderRadius: BorderRadius.circular(18 * scale),
                        border: Border.all(
                            color: const Color(0xFF373657), width: scale),
                      ),
                      child: Text(
                        moment.message ??
                            'Merry Christmas! I saved this view for you.\n'
                                'Hope it makes your day.',
                        style: TextStyle(
                          color: const Color(0xFFF7F5FF),
                          fontSize: 16 * scale,
                          fontWeight: FontWeight.w400,
                          height: 24 / 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _ReplyBar(
              scale: scale,
              controller: _replyController,
              onSend: () {
                final reply = _replyController.text.trim();
                if (reply.isEmpty) return;
                _replyController.clear();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Reply sent.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
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
            child: Image.network(
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
  const _VideoPreview({required this.moment, required this.scale});

  final Moment moment;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16 * scale),
      child: SizedBox(
        width: double.infinity,
        height: 430 * scale,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
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
            ),
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
  });

  final double scale;
  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88 * scale,
      padding: EdgeInsets.fromLTRB(
          24 * scale, 16 * scale, 24 * scale, 24 * scale),
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
            child: GestureDetector(
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
