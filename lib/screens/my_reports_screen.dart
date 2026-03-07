import 'package:flutter/material.dart';
import '../core/supabase_client.dart';
import '../models/report.dart';
import 'package:go_router/go_router.dart';
class MyReportsScreen extends StatelessWidget {
  const MyReportsScreen({super.key});

  Future<List<Report>> _fetchMyReports() async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) return [];
    
    final res = await SupabaseConfig.client
        .from('reports')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);
        
    return (res as List).map((e) => Report.fromJson(e)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes signalements'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => context.go('/home'),
          ),
        ],
      ),
      body: FutureBuilder<List<Report>>(
        future: _fetchMyReports(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }

          final reports = snapshot.data ?? [];
          if (reports.isEmpty) {
             return const Center(child: Text('Aucun signalement trouvé.'));
          }

          return ListView.builder(
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              return ListTile(
                title: Text('Status: ${report.status}'),
                subtitle: Text('Signalé le: ${report.createdAt}'),
                trailing: Chip(label: Text(report.newStatut ?? 'Info')),
              );
            },
          );
        },
      ),
    );
  }
}
