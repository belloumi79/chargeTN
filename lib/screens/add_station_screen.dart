import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../core/supabase_client.dart';
import '../core/app_colors.dart';

class AddStationScreen extends ConsumerStatefulWidget {
  const AddStationScreen({super.key});
  @override
  ConsumerState<AddStationScreen> createState() => _AddStationScreenState();
}

class _AddStationScreenState extends ConsumerState<AddStationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _powerController = TextEditingController();

  final _picker = ImagePicker();
  XFile? _image;
  bool _isLoading = false;
  LatLng _selectedPos = const LatLng(36.8, 10.1);

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  Future<void> _getLocation() async {
    try {
      Position pos = await Geolocator.getCurrentPosition();
      setState(() => _selectedPos = LatLng(pos.latitude, pos.longitude));
    } catch (e, stack) {
      debugPrint('[AddStationScreen] getCurrentPosition failed: $e');
      debugPrint(stack.toString());
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _powerController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) setState(() => _image = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    // Logic to upload image and insert station (simulated here)
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Déclaration envoyée !')));
      context.pop();
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Déclarer une borne', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        leading: IconButton(icon: const Icon(Icons.close, color: Colors.black), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('1. Choisissez l\'emplacement sur la mini-carte', style: TextStyle(color: Color(0xFF5D7A73), fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Container(
                height: 200,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[200]!)),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: _selectedPos,
                      initialZoom: 13,
                      onTap: (_, latlng) => setState(() => _selectedPos = latlng),
                    ),
                    children: [
                      TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
                      MarkerLayer(markers: [Marker(point: _selectedPos, child: const Icon(Icons.location_on, color: Colors.red, size: 40))]),
                    ],
                  ),
                ),
              ),
              const Center(child: Padding(padding: EdgeInsets.all(8.0), child: Text('Touchez la mini-carte pour déplacer le curseur', style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic)))),
              const SizedBox(height: 24),
              const Text('2. Informations de la borne *', style: TextStyle(color: Color(0xFF5D7A73), fontWeight: FontWeight.bold)),
              const Text('Tous les champs marqués d\'un * sont obligatoires', style: TextStyle(color: Colors.red, fontSize: 11)),
              const SizedBox(height: 16),
              _inputField(Icons.edit, 'Nom de la borne *', _nameController),
              const SizedBox(height: 12),
              _inputField(Icons.map_outlined, 'Adresse *', _addressController),
              const SizedBox(height: 12),
              _inputField(Icons.flash_on, 'Puissance (kW)', _powerController),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const Icon(Icons.gps_fixed, color: Color(0xFF1976D2)),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('COORDONNÉES SÉLECTIONNÉES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1976D2))),
                        Text('${_selectedPos.latitude.toStringAsFixed(6)}, ${_selectedPos.longitude.toStringAsFixed(6)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _Label('Photo de la borne'),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid)),
                  child: _image == null 
                    ? const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo_outlined, color: Colors.grey), Text('Ajouter une photo', style: TextStyle(color: Colors.grey))])
                    : ClipRRect(borderRadius: BorderRadius.circular(12), child: (kIsWeb ? Image.network(_image!.path, fit: BoxFit.cover) : Image.file(File(_image!.path), fit: BoxFit.cover))),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('ENVOYER LA DÉCLARATION', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputField(IconData icon, String hint, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.grey),
        filled: true,
        fillColor: Colors.grey[50],
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.green)),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text, style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)));
}
