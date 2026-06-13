import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../core/app_colors.dart';
import '../core/supabase_client.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/responsive_wrapper.dart';
import '../models/station.dart';
import '../providers/posts_feed_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────

class PostItem {
  final String id;
  final String userId;
  final String content;
  final String? imageUrl;
  final String? stationId;
  final String? stationName;
  final int likesCount;
  final int commentsCount;
  final DateTime createdAt;
  final String? authorEmail;
  final String? authorName;
  bool likedByMe;

  PostItem({
    required this.id,
    required this.userId,
    required this.content,
    this.imageUrl,
    this.stationId,
    this.stationName,
    required this.likesCount,
    required this.commentsCount,
    required this.createdAt,
    this.authorEmail,
    this.authorName,
    this.likedByMe = false,
  });

  factory PostItem.fromJson(Map<String, dynamic> j) => PostItem(
        id: j['id'],
        userId: j['user_id'],
        content: j['content'],
        imageUrl: j['image_url'],
        stationId: j['station_id'],
        stationName: j['station_name'],
        likesCount: j['likes_count'] ?? 0,
        commentsCount: j['comments_count'] ?? 0,
        createdAt: DateTime.parse(j['created_at']),
        authorEmail: j['author_email'],
        authorName: j['author_name'],
      );
}

class CommentItem {
  final String id;
  final String userId;
  final String content;
  final DateTime createdAt;
  final String? userEmail;

  CommentItem({
    required this.id,
    required this.userId,
    required this.content,
    required this.createdAt,
    this.userEmail,
  });

  factory CommentItem.fromJson(Map<String, dynamic> j) => CommentItem(
        id: j['id'],
        userId: j['user_id'],
        content: j['content'],
        createdAt: DateTime.parse(j['created_at']),
        userEmail: j['user_email'],
      );
}

// ─────────────────────────────── Main Screen ─────────────────────────────────

class SocialScreen extends ConsumerStatefulWidget {
  const SocialScreen({super.key});

  @override
  ConsumerState<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends ConsumerState<SocialScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _currentUser = SupabaseConfig.client.auth.currentUser;
  Set<String> _myLikes = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMyLikes();
  }

  Future<void> _loadMyLikes() async {
    if (_currentUser == null) return;
    try {
      final res = await SupabaseConfig.client
          .from('post_likes')
          .select('post_id')
          .eq('user_id', _currentUser.id);
      if (mounted) {
        setState(() {
          _myLikes = {for (final r in res) r['post_id'] as String};
        });
      }
    } catch (e, stack) {
      debugPrint('[SocialScreen] _loadMyLikes failed: $e');
      debugPrint(stack.toString());
    }
  }

  Future<void> _toggleLike(PostItem post) async {
    if (_currentUser == null) {
      context.push('/auth');
      return;
    }
    try {
      final res = await SupabaseConfig.client
          .rpc('toggle_post_like', params: {'p_post_id': post.id});
      final liked = res[0]['liked'] as bool;
      setState(() {
        if (liked) {
          _myLikes.add(post.id);
        } else {
          _myLikes.remove(post.id);
        }
      });
    } catch (e, stack) {
      debugPrint('[SocialScreen] _toggleLike(${post.id}) failed: $e');
      debugPrint(stack.toString());
    }
  }

  Future<void> _deletePost(String postId) async {
    try {
      await SupabaseConfig.client.from('posts').delete().eq('id', postId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _openCreatePost() {
    if (_currentUser == null) {
      context.push('/auth');
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreatePostSheet(
        onPosted: () => _loadMyLikes(),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: ResponsiveWrapper(
          child: Column(
            children: [
              // ── Header ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Communauté',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w900)),
                        Text('EV Tunisie 🇹🇳',
                            style: TextStyle(
                                color: AppColors.primary, fontSize: 13)),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryDark],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.add, color: Colors.black, size: 22),
                        onPressed: _openCreatePost,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Tabs ─────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Colors.black,
                    unselectedLabelColor: AppColors.textSecondary,
                    labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(text: 'Fil d\'actu'),
                      Tab(text: 'Tendances'),
                    ],
                  ),
                ),
              ),

              // ── Feed ─────────────────────────────────────────────────────
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildFeed(false),
                    _buildFeed(true),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 3,
        onTap: (i) {
          if (i == 3) return;
          if (i == 0) context.go('/home');
          if (i == 1) context.go('/search');
          if (i == 2) context.go('/favs');
          if (i == 4) context.go('/profile');
        },
      ),
    );
  }

  Widget _buildFeed(bool sortByLikes) {
    final feedAsync = ref.watch(postsFeedProvider);
    final posts = feedAsync.maybeWhen(
      data: (data) {
        if (sortByLikes) {
          final sorted = [...data];
          sorted.sort((a, b) => b.likesCount.compareTo(a.likesCount));
          return sorted;
        }
        return data;
      },
      orElse: () => const <PostItem>[],
    );

    if (feedAsync.isLoading && posts.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.chat_bubble_outline, size: 60, color: Colors.white10),
            const SizedBox(height: 16),
            const Text('Soyez le premier à publier !',
                style: TextStyle(color: Colors.white38, fontSize: 15)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _openCreatePost,
              icon: const Icon(Icons.add),
              label: const Text('Créer un post'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surfaceDark,
      onRefresh: _loadMyLikes,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: posts.length,
        itemBuilder: (context, i) => _PostCard(
          post: posts[i],
          isLiked: _myLikes.contains(posts[i].id),
          isOwner: _currentUser?.id == posts[i].userId,
          onLike: () => _toggleLike(posts[i]),
          onDelete: () => _deletePost(posts[i].id),
          onComment: () => _openComments(posts[i]),
        ),
      ),
    );
  }

  void _openComments(PostItem post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CommentsSheet(post: post, currentUserId: _currentUser?.id),
    );
  }
}

// ─────────────────────────────── Post Card ───────────────────────────────────

class _PostCard extends StatelessWidget {
  final PostItem post;
  final bool isLiked;
  final bool isOwner;
  final VoidCallback onLike;
  final VoidCallback onDelete;
  final VoidCallback onComment;

  const _PostCard({
    required this.post,
    required this.isLiked,
    required this.isOwner,
    required this.onLike,
    required this.onDelete,
    required this.onComment,
  });

  String _authorInitial() {
    final name = post.authorName ?? post.authorEmail ?? '?';
    return name[0].toUpperCase();
  }

  String _authorDisplay() {
    if (post.authorName != null && post.authorName!.isNotEmpty) return post.authorName!;
    final email = post.authorEmail ?? 'Anonyme';
    return email.contains('@') ? email.split('@')[0] : email;
  }

  String _timeAgo() {
    final diff = DateTime.now().difference(post.createdAt);
    if (diff.inSeconds < 60) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes}min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours}h';
    return DateFormat('dd MMM', 'fr').format(post.createdAt);
  }

  void _goToStation(BuildContext context) async {
    if (post.stationId == null) return;
    try {
      final res = await SupabaseConfig.client
          .from('stations')
          .select()
          .eq('id', post.stationId!)
          .single();
      if (context.mounted) {
        context.push('/station/${post.stationId}', extra: Station.fromJson(res));
      }
    } catch (e, stack) {
      debugPrint('[SocialScreen] _goToStation(${post.stationId}) failed: $e');
      debugPrint(stack.toString());
    }
  }

  void _showLikers(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => FutureBuilder(
        future: SupabaseConfig.client
            .from('post_likes')
            .select('profiles(email, display_name)')
            .eq('post_id', post.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final likers = snapshot.data as List? ?? [];
          return AlertDialog(
            backgroundColor: AppColors.surfaceDark,
            title: const Text('Aimé par', style: TextStyle(color: Colors.white, fontSize: 16)),
            content: SizedBox(
              width: double.maxFinite,
              child: likers.isEmpty
                  ? const Text('Aucun like pour le moment', style: TextStyle(color: Colors.white38))
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: likers.length,
                      itemBuilder: (context, i) {
                        final email = likers[i]['profiles']?['email'] ?? 'Utilisateur';
                        return ListTile(
                          leading: const CircleAvatar(
                              radius: 14, backgroundColor: AppColors.primary, child: Icon(Icons.person, size: 14, color: Colors.black)),
                          title: Text(email, style: const TextStyle(color: Colors.white, fontSize: 13)),
                        );
                      },
                    ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Author row ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                  child: Text(_authorInitial(),
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_authorDisplay(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                      Row(
                        children: [
                          Text(_timeAgo(),
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                          if (post.stationName != null) ...[
                            const Text(' · ', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                            GestureDetector(
                              onTap: () => _goToStation(context),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.ev_station, size: 11, color: AppColors.primary),
                                  const SizedBox(width: 3),
                                  Flexible(
                                    child: Text(post.stationName!,
                                        style: const TextStyle(
                                            color: AppColors.primary,
                                            fontSize: 11,
                                            decoration: TextDecoration.underline),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (isOwner)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white38, size: 20),
                    color: AppColors.surfaceDark,
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, color: Colors.red, size: 16),
                            SizedBox(width: 8),
                            Text('Supprimer', style: TextStyle(color: Colors.red, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (v) {
                      if (v == 'delete') onDelete();
                    },
                  ),
              ],
            ),
          ),

          // ── Content ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(14),
            child: Text(
              post.content,
              style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
            ),
          ),

          if (post.imageUrl != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: Image.network(
                    post.imageUrl!,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),

          // ── Actions ──────────────────────────────────────────────────
          const Divider(color: Colors.white12, height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                _ActionBtn(
                  icon: isLiked ? Icons.favorite : Icons.favorite_border,
                  label: '${post.likesCount}',
                  color: isLiked ? Colors.red : AppColors.textSecondary,
                  onTap: onLike,
                  onLongPress: () => _showLikers(context),
                ),
                const SizedBox(width: 24),
                _ActionBtn(
                  icon: Icons.chat_bubble_outline,
                  label: '${post.commentsCount}',
                  color: AppColors.textSecondary,
                  onTap: onComment,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.share_outlined, size: 20, color: AppColors.textSecondary),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _ActionBtn({required this.icon, required this.label, required this.color, required this.onTap, this.onLongPress});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 5),
              Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      );
}

// ────────────────────────── Create Post Sheet ────────────────────────────────

class _CreatePostSheet extends StatefulWidget {
  final VoidCallback onPosted;
  const _CreatePostSheet({required this.onPosted});

  @override
  State<_CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<_CreatePostSheet> {
  final _controller = TextEditingController();
  bool _isPosting = false;
  String? _imageUrl;
  bool _isUploadingImage = false;
  String? _selectedStationId;
  String? _selectedStationName;

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (picked == null) return;

    setState(() => _isUploadingImage = true);
    try {
      final bytes = await picked.readAsBytes();
      final ext = picked.name.split('.').last;
      final path = 'posts/${DateTime.now().millisecondsSinceEpoch}.$ext';
      await SupabaseConfig.client.storage.from('reports').uploadBinary(path, bytes);
      final url = SupabaseConfig.client.storage.from('reports').getPublicUrl(path);
      if (mounted) setState(() => _imageUrl = url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur image: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  void _pickStation() async {
    final res = await showModalBottomSheet<Map<String, String>>(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      builder: (_) => _StationPicker(),
    );
    if (res != null && mounted) {
      setState(() {
        _selectedStationId = res['id'];
        _selectedStationName = res['name'];
      });
    }
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _isPosting = true);
    try {
      final user = SupabaseConfig.client.auth.currentUser!;
      await SupabaseConfig.client.from('posts').insert({
        'user_id': user.id,
        'content': text,
        'image_url': _imageUrl,
        'station_id': _selectedStationId,
      });
      widget.onPosted();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
        setState(() => _isPosting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  const Text('Nouveau post',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _isPosting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isPosting
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Publier', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white12, height: 24),
            // Text input
            Expanded(
              child: SingleChildScrollView(
                controller: ctrl,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _controller,
                      maxLines: 8,
                      maxLength: 500,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      decoration: const InputDecoration(
                        counterStyle: TextStyle(color: Colors.white24),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Selected Station
                    if (_selectedStationName != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.ev_station, color: AppColors.primary, size: 18),
                            const SizedBox(width: 8),
                            Text(_selectedStationName!, style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => setState(() {
                                _selectedStationId = null;
                                _selectedStationName = null;
                              }),
                              child: const Icon(Icons.close, color: AppColors.primary, size: 16),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    if (_imageUrl != null)
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(_imageUrl!, height: 180, width: double.infinity, fit: BoxFit.cover),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () => setState(() => _imageUrl = null),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                child: const Icon(Icons.close, color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            // Bottom toolbar
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.white12))),
              child: Row(
                children: [
                  IconButton(
                    icon: _isUploadingImage
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.image_outlined, color: AppColors.primary),
                    onPressed: _isUploadingImage ? null : _pickAndUploadImage,
                    tooltip: 'Ajouter une photo',
                  ),
                  const Text('Photo', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(width: 20),
                  IconButton(
                    icon: const Icon(Icons.ev_station_outlined, color: AppColors.primary),
                    onPressed: _pickStation,
                    tooltip: 'Associer une station',
                  ),
                  const Text('Station', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────── Comments Sheet ───────────────────────────────

class _CommentsSheet extends StatefulWidget {
  final PostItem post;
  final String? currentUserId;

  const _CommentsSheet({required this.post, this.currentUserId});

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final _ctrl = TextEditingController();
  bool _isSending = false;
  late Future<List<CommentItem>> _commentsFuture;

  @override
  void initState() {
    super.initState();
    _commentsFuture = _fetchComments();
  }

  Future<List<CommentItem>> _fetchComments() async {
    final res = await SupabaseConfig.client
        .from('post_comments')
        .select('id, user_id, content, created_at, profiles(email)')
        .eq('post_id', widget.post.id)
        .order('created_at', ascending: true);

    return (res as List).map((e) {
      final profileEmail = e['profiles']?['email'];
      return CommentItem(
        id: e['id'],
        userId: e['user_id'],
        content: e['content'],
        createdAt: DateTime.parse(e['created_at']),
        userEmail: profileEmail,
      );
    }).toList();
  }

  Future<void> _sendComment() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || widget.currentUserId == null) return;

    setState(() => _isSending = true);
    try {
      await SupabaseConfig.client.from('post_comments').insert({
        'post_id': widget.post.id,
        'user_id': widget.currentUserId,
        'content': text,
      });
      // Update comment count
      await SupabaseConfig.client
          .from('posts')
          .update({'comments_count': widget.post.commentsCount + 1})
          .eq('id', widget.post.id);
      _ctrl.clear();
      setState(() {
        _commentsFuture = _fetchComments();
        _isSending = false;
      });
    } catch (e) {
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Row(
                children: [
                  const Text('Commentaires',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Text('(${widget.post.commentsCount})',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                ],
              ),
            ),
            const Divider(color: Colors.white12, height: 1),
            Expanded(
              child: FutureBuilder<List<CommentItem>>(
                future: _commentsFuture,
                builder: (ctx, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                  }
                  final comments = snap.data ?? [];
                  if (comments.isEmpty) {
                    return const Center(
                      child: Text('Aucun commentaire. Soyez le premier !',
                          style: TextStyle(color: Colors.white38)),
                    );
                  }
                  return ListView.builder(
                    controller: ctrl,
                    padding: const EdgeInsets.all(16),
                    itemCount: comments.length,
                    itemBuilder: (_, i) => _CommentTile(comment: comments[i]),
                  );
                },
              ),
            ),
            // Input
            Container(
              padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).viewInsets.bottom + 16),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.white12))),
              child: widget.currentUserId == null
                  ? Center(
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          context.push('/auth');
                        },
                        child: const Text('Connectez-vous pour commenter'),
                      ),
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _ctrl,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Votre commentaire...',
                              hintStyle: const TextStyle(color: Colors.white38),
                              filled: true,
                              fillColor: AppColors.backgroundDark,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: _isSending ? null : _sendComment,
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: _isSending
                                ? const Padding(
                                    padding: EdgeInsets.all(10),
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                  )
                                : const Icon(Icons.send, color: Colors.black, size: 20),
                          ),
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

class _CommentTile extends StatelessWidget {
  final CommentItem comment;
  const _CommentTile({required this.comment});

  @override
  Widget build(BuildContext context) {
    final email = comment.userEmail ?? 'Anonyme';
    final initial = email[0].toUpperCase();
    final name = email.contains('@') ? email.split('@')[0] : email;
    final diff = DateTime.now().difference(comment.createdAt);
    final timeStr = diff.inMinutes < 60
        ? 'il y a ${diff.inMinutes}min'
        : diff.inHours < 24
            ? 'il y a ${diff.inHours}h'
            : DateFormat('dd/MM', 'fr').format(comment.createdAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary.withValues(alpha: 0.2),
            child: Text(initial, style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
                    const SizedBox(width: 8),
                    Text(timeStr, style: const TextStyle(color: Colors.white38, fontSize: 10)),
                  ],
                ),
                const SizedBox(height: 3),
                Text(comment.content, style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StationPicker extends StatefulWidget {
  @override
  State<_StationPicker> createState() => _StationPickerState();
}

class _StationPickerState extends State<_StationPicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Chercher une station...',
              hintStyle: const TextStyle(color: Colors.white38),
              prefixIcon: const Icon(Icons.search, color: Colors.white38),
              filled: true,
              fillColor: AppColors.backgroundDark,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        Expanded(
          child: FutureBuilder(
            future: SupabaseConfig.client
                .from('stations')
                .select('id, name')
                .ilike('name', '%$_query%')
                .limit(20),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final list = snapshot.data as List? ?? [];
              if (list.isEmpty) {
                return const Center(child: Text('Aucune station trouvée', style: TextStyle(color: Colors.white38)));
              }
              return ListView.builder(
                itemCount: list.length,
                itemBuilder: (context, i) {
                  final s = list[i];
                  return ListTile(
                    leading: const Icon(Icons.ev_station, color: AppColors.primary),
                    title: Text(s['name'] ?? 'Inconnu', style: const TextStyle(color: Colors.white)),
                    onTap: () => Navigator.pop(context, {'id': s['id'].toString(), 'name': s['name']}),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
