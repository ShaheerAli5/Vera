import 'package:flutter/material.dart';

class AdminReviewMomentMediaScreen extends StatefulWidget {
  final String momentId;
  const AdminReviewMomentMediaScreen({super.key, required this.momentId});

  @override
  State<AdminReviewMomentMediaScreen> createState() => _AdminReviewMomentMediaScreenState();
}

class _AdminReviewMomentMediaScreenState extends State<AdminReviewMomentMediaScreen> {
  bool _isPlaying = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Dummy Media
          Image.network(
            'https://picsum.photos/600/1000',
            fit: BoxFit.cover,
          ),

          // Play/Pause Overlay
          GestureDetector(
            onTap: () {
              setState(() {
                _isPlaying = !_isPlaying;
              });
            },
            child: Container(
              color: Colors.transparent,
              child: Center(
                child: !_isPlaying
                    ? const Icon(Icons.play_arrow, color: Colors.white70, size: 80)
                    : const SizedBox.shrink(),
              ),
            ),
          ),

          // Top Bar
          Positioned(
            top: MediaQuery.paddingOf(context).top,
            left: 0,
            right: 0,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const Text('Media Review', style: TextStyle(color: Colors.white, fontSize: 18)),
              ],
            ),
          ),

          // Bottom Actions
          Positioned(
            bottom: 32,
            left: 16,
            right: 16,
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // In a real app, this might show the reject dialog and then pop back further.
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Reject', style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // Handle approve logic
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Approve', style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
