import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/supabase_client.dart';
import '../screens/social_screen.dart' show PostItem;

/// Real-time stream of social feed posts.
/// `autoDispose` ensures the underlying Supabase WebSocket is released when
/// the screen unmounts (no more leaked subscriptions).
final postsFeedProvider = StreamProvider.autoDispose<List<PostItem>>((ref) {
  return SupabaseConfig.client
      .from('posts_detailed')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false)
      .map((rows) => rows.map(PostItem.fromJson).toList());
});
