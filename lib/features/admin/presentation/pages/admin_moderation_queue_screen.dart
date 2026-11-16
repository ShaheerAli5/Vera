import 'package:flutter/material.dart';

import '../../../../core/layout/responsive.dart';
import '../../../../main.dart' show ApiClientScope;
import '../../../home/data/models/moment_model.dart';
import '../../data/datasources/admin_remote_data_source.dart';
import '../../data/repositories/admin_repository_impl.dart';
import 'admin_review_moment_screen.dart';

class AdminModerationQueueScreen extends StatefulWidget {
  const AdminModerationQueueScreen({super.key});

  @override
  State<AdminModerationQueueScreen> createState() => _AdminModerationQueueScreenState();
}

class _AdminModerationQueueScreenState extends State<AdminModerationQueueScreen> {
  List<MomentModel> _moments = [];
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchQueue();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchQueue() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final client = ApiClientScope.of(context);
      final repo = AdminRepositoryImpl(AdminRemoteDataSource(client));
      final response = await repo.getPendingMoments(
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );
      if (!mounted) return;
      setState(() {
        _moments = response.moments;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst(RegExp(r'^[A-Za-z]+Exception:\s*'), '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final scale = VeraResponsive.scale(screen.width);

    return RefreshIndicator(
      onRefresh: _fetchQueue,
      color: const Color(0xFF9044FB),
      backgroundColor: const Color(0xFF161626),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16 * scale, 16 * scale, 16 * scale, 8 * scale),
            child: Text(
              'Moderation Queue (${_isLoading ? '...' : _moments.length})',
              style: TextStyle(
                color: const Color(0xFFF7F5FF),
                fontSize: 24 * scale,
                fontWeight: FontWeight.w600,
                letterSpacing: -.3,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16 * scale),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48 * scale,
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(color: Colors.white, fontSize: 14 * scale),
                      cursorColor: const Color(0xFF9044FB),
                      onSubmitted: (val) {
                        setState(() {
                          _searchQuery = val.trim();
                        });
                        _fetchQueue();
                      },
                      decoration: InputDecoration(
                        hintText: 'Search moments...',
                        hintStyle: TextStyle(color: const Color(0xFF535370), fontSize: 14 * scale),
                        filled: true,
                        fillColor: const Color(0xFF161626),
                        prefixIcon: Icon(Icons.search, color: const Color(0xFF535370), size: 20 * scale),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear, color: const Color(0xFF535370), size: 18 * scale),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                  _fetchQueue();
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
                            color: const Color(0xFF9044FB),
                            width: 1 * scale,
                          ),
                        ),
                        contentPadding: EdgeInsets.symmetric(vertical: 14 * scale),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12 * scale),
                Container(
                  height: 48 * scale,
                  width: 48 * scale,
                  decoration: BoxDecoration(
                    color: const Color(0xFF161626),
                    borderRadius: BorderRadius.circular(12 * scale),
                  ),
                  child: IconButton(
                    onPressed: _fetchQueue,
                    icon: Icon(Icons.refresh, color: const Color(0xFFC68CFF), size: 24 * scale),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildBody(scale),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(double scale) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF9044FB)),
      );
    }

    if (_errorMessage != null && _moments.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24 * scale),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: Colors.amber, size: 48 * scale),
              SizedBox(height: 16 * scale),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: const Color(0xFFA2A5C2), fontSize: 14 * scale),
              ),
              SizedBox(height: 16 * scale),
              ElevatedButton.icon(
                onPressed: _fetchQueue,
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text('Retry', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9044FB)),
              ),
            ],
          ),
        ),
      );
    }

    if (_moments.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, color: const Color(0xFFC68CFF), size: 56 * scale),
            SizedBox(height: 16 * scale),
            Text(
              'No moments pending review',
              style: TextStyle(color: Colors.white, fontSize: 18 * scale, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8 * scale),
            Text(
              'All moments are currently moderated.',
              style: TextStyle(color: const Color(0xFFA2A5C2), fontSize: 14 * scale),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16 * scale, 0, 16 * scale, 100 * scale),
      itemCount: _moments.length,
      itemBuilder: (context, index) {
        final moment = _moments[index];
        return _buildQueueItem(context, scale, moment, index);
      },
    );
  }

  Widget _buildQueueItem(BuildContext context, double scale, MomentModel moment, int index) {
    final creator = moment.creatorName ?? 'User';
    final titleOrMsg = (moment.title.isNotEmpty && moment.title != 'Untitled Moment')
        ? moment.title
        : (moment.message?.isNotEmpty == true
            ? moment.message!
            : (moment.teaser?.isNotEmpty == true ? moment.teaser! : 'No caption provided'));

    final mediaUrl = (moment.mediaUrl != null && moment.mediaUrl!.isNotEmpty)
        ? moment.mediaUrl!
        : 'https://vera.aptechmedia.com/api/v1/moments/${moment.id}/media';

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => AdminReviewMomentScreen(
              momentId: moment.id,
              initialMoment: moment,
            ),
          ),
        );
        if (result == true) {
          _fetchQueue();
        }
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 16 * scale),
        padding: EdgeInsets.all(12 * scale),
        decoration: BoxDecoration(
          color: const Color(0xFF161626),
          borderRadius: BorderRadius.circular(16 * scale),
          border: Border.all(color: const Color(0xFF282842)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 80 * scale,
              height: 120 * scale,
              decoration: BoxDecoration(
                color: const Color(0xFF1B152E),
                borderRadius: BorderRadius.circular(12 * scale),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12 * scale),
                child: Image.network(
                  mediaUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Center(
                    child: Icon(Icons.play_circle_outline, color: Colors.white.withValues(alpha: 0.8), size: 32 * scale),
                  ),
                ),
              ),
            ),
            SizedBox(width: 16 * scale),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '@$creator',
                          style: TextStyle(color: Colors.white, fontSize: 16 * scale, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8 * scale, vertical: 4 * scale),
                        decoration: BoxDecoration(
                          color: const Color(0xFF9044FB).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4 * scale),
                        ),
                        child: Text(
                          'Pending',
                          style: TextStyle(color: const Color(0xFFC057FF), fontSize: 10 * scale, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8 * scale),
                  Text(
                    titleOrMsg,
                    style: TextStyle(color: const Color(0xFFA2A5C2), fontSize: 13 * scale, height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 16 * scale),
                  Text(
                    moment.createdAt != null
                        ? 'Uploaded: ${moment.createdAt!.toLocal().toString().split('.').first}'
                        : 'Uploaded: Recently',
                    style: TextStyle(color: const Color(0xFF8A8EB3), fontSize: 11 * scale),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
