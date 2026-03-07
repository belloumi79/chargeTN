import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path/path.dart' as p;
import '../core/supabase_client.dart';
import '../models/station.dart';

class SubmitReportScreen extends StatefulWidget {
  final Station station;

  const SubmitReportScreen({super.key, required this.station});

  @override
  State<SubmitReportScreen> createState() => _SubmitReportScreenState();
}

class _SubmitReportScreenState extends State<SubmitReportScreen> {
  final _picker = ImagePicker();
  File? _image;
  String? _statut;
  String? _encombrement;
  final _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _statut = widget.station.statut;
    _encombrement = widget.station.encombrement;
  }

  Future<void> _pickImage() async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Source de la photo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Appareil photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galerie'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      final picked = await _picker.pickImage(source: source);
      if (picked != null) {
        setState(() => _image = File(picked.path));
      }
    }
  }

  Future<Position?> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    
    if (permission == LocationPermission.deniedForever) return null;
    return await Geolocator.getCurrentPosition();
  }

  Future<void> _submitReport() async {
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Une photo de preuve est obligatoire.')));
      return;
    }

    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez vous connecter pour envoyer un signalement.')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Check GPS (optional step depending on strictness, but we get the pos)
      final pos = await _getCurrentLocation();
      if (pos == null) {
         // handle
      }
      
      // 2. Upload photo
      final fileExtension = p.extension(_image!.path);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}$fileExtension';
      final path = '${user.id}/$fileName';
      
      await SupabaseConfig.client.storage.from('proofs').upload(path, _image!);
      final imageUrl = SupabaseConfig.client.storage.from('proofs').getPublicUrl(path);

      // 3. Insert Proof
      await SupabaseConfig.client.from('station_proofs').insert({
        'station_id': widget.station.id,
        'image_url': imageUrl,
        'uploaded_by': user.id,
      });
      
      // 4. Insert Report
      await SupabaseConfig.client.from('reports').insert({
        'station_id': widget.station.id,
        'user_id': user.id,
        'new_statut': _statut,
        'new_encombrement': _encombrement,
        'notes': _notesController.text,
        'image_url': imageUrl,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Signalement envoyé pour validation administrative')));
      context.pop();

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Signaler - ${widget.station.name}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
                child: _image == null
                    ? const Icon(Icons.camera_alt, size: 50, color: Colors.grey)
                    : Image.file(_image!, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _statut,
              decoration: const InputDecoration(labelText: 'Statut de la station'),
              items: const [
                DropdownMenuItem(value: 'fonctionnelle', child: Text('Fonctionnelle')),
                DropdownMenuItem(value: 'en_panne', child: Text('En panne')),
                DropdownMenuItem(value: 'autre', child: Text('Autre')),
              ],
              onChanged: (val) => setState(() => _statut = val),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _encombrement,
              decoration: const InputDecoration(labelText: 'Encombrement'),
              items: const [
                DropdownMenuItem(value: 'libre', child: Text('Libre')),
                DropdownMenuItem(value: 'petit', child: Text('Petit')),
                DropdownMenuItem(value: 'grand', child: Text('Grand')),
              ],
              onChanged: (val) => setState(() => _encombrement = val),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notes additionnelles'),
              maxLines: 3,
            ),
            const SizedBox(height: 32),
            if (_isLoading)
              const CircularProgressIndicator()
            else
              ElevatedButton.icon(
                onPressed: _submitReport,
                icon: const Icon(Icons.send),
                label: const Text('Envoyer le rapport'),
              ),
          ],
        ),
      ),
    );
  }
}
