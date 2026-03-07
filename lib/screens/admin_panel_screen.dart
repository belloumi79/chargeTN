import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/supabase_client.dart';
import '../core/app_colors.dart';
import '../models/report.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  Future<List<Report>> _fetchPendingReports() async {
    final res = await SupabaseConfig.client
        .from('reports')
        .select()
        .eq('status', 'pending')
        .order('created_at', ascending: true);
        
    return (res as List).map((e) => Report.fromJson(e)).toList();
  }

  Future<List<Map<String, dynamic>>> _fetchPendingStations() async {
    final res = await SupabaseConfig.client
        .from('stations')
        .select('*, station_proofs(image_url)')
        .eq('verified', false)
        .order('created_at', ascending: true);
    
    return List<Map<String, dynamic>>.from(res);
  }

  Future<void> _approveReport(Report report) async {
    setState(() => _isLoading = true);
    try {
      await SupabaseConfig.client
          .from('reports')
          .update({'status': 'approved'})
          .eq('id', report.id);

      final updates = <String, dynamic>{};
      if (report.newStatut != null) updates['statut'] = report.newStatut;
      if (report.newEncombrement != null) updates['encombrement'] = report.newEncombrement;
      
      if (updates.isNotEmpty) {
        await SupabaseConfig.client
            .from('stations')
            .update(updates)
            .eq('id', report.stationId!);
      }
      _snack('Rapport approuvé');
      setState(() {});
    } catch (e) {
      _snack('Erreur: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _rejectReport(String id) async {
    setState(() => _isLoading = true);
    try {
      await SupabaseConfig.client.from('reports').update({'status': 'rejected'}).eq('id', id);
      _snack('Rapport rejeté');
      setState(() {});
    } catch (e) {
      _snack('Erreur: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyStation(String id) async {
    setState(() => _isLoading = true);
    try {
      await SupabaseConfig.client.from('stations').update({'verified': true}).eq('id', id);
      _snack('Station vérifiée et publiée');
      setState(() {});
    } catch (e) {
      _snack('Erreur: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Administration', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: 'Signalements', icon: Icon(Icons.report_problem_outlined)),
            Tab(text: 'Nouvelles Bornes', icon: Icon(Icons.ev_station)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReportsList(),
          _buildStationsList(),
        ],
      ),
    );
  }

  Widget _buildReportsList() {
    return FutureBuilder<List<Report>>(
      future: _fetchPendingReports(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final reports = snapshot.data ?? [];
        if (reports.isEmpty) return _buildEmpty('Aucun signalement en attente');
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: reports.length,
          itemBuilder: (context, i) => _ReportCard(
            report: reports[i],
            onApprove: () => _approveReport(reports[i]),
            onReject: () => _rejectReport(reports[i].id),
          ),
        );
      },
    );
  }

  Widget _buildStationsList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchPendingStations(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final stations = snapshot.data ?? [];
        if (stations.isEmpty) return _buildEmpty('Aucune borne à vérifier');
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: stations.length,
          itemBuilder: (context, i) => _StationVerificationCard(
            station: stations[i],
            onVerify: () => _verifyStation(stations[i]['id']),
          ),
        );
      },
    );
  }

  Widget _buildEmpty(String t) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.inbox, size: 64, color: Colors.white10),
        const SizedBox(height: 16),
        Text(t, style: const TextStyle(color: Colors.white38)),
      ],
    ),
  );
}

class _ReportCard extends StatelessWidget {
  final Report report;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _ReportCard({required this.report, required this.onApprove, required this.onReject});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (report.imageUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              child: Image.network(
                report.imageUrl!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(height: 100, color: Colors.black26, child: const Icon(Icons.broken_image)),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Signalement de changement', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                const SizedBox(height: 8),
                if (report.newStatut != null) _DetailRow('Nouveau Statut', report.newStatut!),
                if (report.newEncombrement != null) _DetailRow('Encombrement', report.newEncombrement!),
                if (report.notes != null && report.notes!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('Notes: ${report.notes}', style: const TextStyle(fontSize: 13, color: Colors.white70)),
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onReject,
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Rejeter'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onApprove,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        child: const Text('Approuver'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StationVerificationCard extends StatelessWidget {
  final Map<String, dynamic> station;
  final VoidCallback onVerify;

  const _StationVerificationCard({required this.station, required this.onVerify});

  @override
  Widget build(BuildContext context) {
    final proofs = station['station_proofs'] as List?;
    final imageUrl = proofs != null && proofs.isNotEmpty ? proofs.first['image_url'] as String? : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              child: Image.network(imageUrl, height: 180, width: double.infinity, fit: BoxFit.cover),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(station['name'] ?? 'Nouvelle Borne', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(station['address'] ?? 'Adresse non spécifiée', style: const TextStyle(color: Colors.white54, fontSize: 13)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _Badge(station['type_prise']?[0] ?? '?', color: AppColors.primary),
                    const SizedBox(width: 8),
                    _Badge('${station['puissance_kw']?[0] ?? '?'} kW', color: Colors.blue),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onVerify,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.black),
                    child: const Text('Vérifier et Publier', style: TextStyle(fontWeight: FontWeight.bold)),
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

class _DetailRow extends StatelessWidget {
  final String label, value;
  const _DetailRow(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 13)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    ),
  );
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge(this.text, {required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
  );
}
