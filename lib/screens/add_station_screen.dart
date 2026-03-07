import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path/path.dart' as p;
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
  final _priceController = TextEditingController();

  final _picker = ImagePicker();
  File? _image;
  bool _isLoading = false;
  bool _is24h = false;

  String _selectedConnector = 'Type 2';
  String _selectedPower = '22';

  final _connectors = ['Type 2', 'CCS 2', 'CHAdeMO'];
  final _powers = ['7', '11', '22', '50', '150'];

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.primary),
                title: const Text('Appareil photo', style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.primary),
                title: const Text('Galerie', style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
    if (source != null) {
      final picked = await _picker.pickImage(source: source, imageQuality: 80);
      if (picked != null) setState(() => _image = File(picked.path));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_image == null) {
      _snack('Une photo de la station est obligatoire.');
      return;
    }
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) { _snack('Veuillez vous connecter.'); return; }

    setState(() => _isLoading = true);
    try {
      // Géolocalisation
      bool svcEnabled = await Geolocator.isLocationServiceEnabled();
      if (!svcEnabled) { _snack('Service de localisation désactivé.'); return; }
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        _snack('Permission refusée.'); return;
      }
      final pos = await Geolocator.getCurrentPosition();

      // Upload image
      final ext = p.extension(_image!.path);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}$ext';
      final storagePath = '${user.id}/$fileName';
      await SupabaseConfig.client.storage.from('proofs').upload(storagePath, _image!);
      final imageUrl = SupabaseConfig.client.storage.from('proofs').getPublicUrl(storagePath);

      // Insert station
      final stationData = await SupabaseConfig.client.from('stations').insert({
        'name': _nameController.text.trim(),
        'address': _addressController.text.trim(),
        'latitude': pos.latitude,
        'longitude': pos.longitude,
        'puissance_kw': [_selectedPower],
        'type_prise': [_selectedConnector],
        'submitted_by': user.id,
        'verified': false,
      }).select().single();

      await SupabaseConfig.client.from('station_proofs').insert({
        'station_id': stationData['id'],
        'image_url': imageUrl,
        'uploaded_by': user.id,
      });

      if (!mounted) return;
      _snack('Station ajoutée. Elle sera visible après validation.');
      context.pop();
    } catch (e) {
      if (mounted) _snack('Erreur: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // ── Header ────────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => context.pop(),
                      ),
                      const Expanded(
                        child: Text(
                          'Ajouter une borne',
                          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                // ── Body ──────────────────────────────────────────────────────
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                      children: [
                        // Station name
                        _Label('Nom de la station'),
                        _InputField(
                          controller: _nameController,
                          hint: 'Ex: Borne Total La Marsa',
                          validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                        ),
                        const SizedBox(height: 20),
                        // Address
                        _Label('Adresse'),
                        _InputField(
                          controller: _addressController,
                          hint: "Entrez l'adresse",
                          suffixIcon: const Icon(Icons.location_on_outlined, color: AppColors.textSecondary, size: 20),
                          validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                        ),
                        const SizedBox(height: 8),
                        _GhostButton(
                          icon: Icons.map_outlined,
                          label: 'Localiser sur la carte',
                          onTap: () {},
                        ),
                        const SizedBox(height: 20),
                        // Connector + Power grid
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _Label('Connecteur'),
                                  _DropdownField<String>(
                                    value: _selectedConnector,
                                    items: _connectors,
                                    onChanged: (v) => setState(() => _selectedConnector = v!),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _Label('Puissance'),
                                  _DropdownField<String>(
                                    value: _selectedPower,
                                    items: _powers,
                                    itemLabel: (v) => '$v kW',
                                    onChanged: (v) => setState(() => _selectedPower = v!),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Price
                        _Label('Prix (TND/kWh)'),
                        _InputField(
                          controller: _priceController,
                          hint: '0.00',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          suffixWidget: Text(
                            'TND',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // 24h toggle
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceDark,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.borderDark),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.schedule, color: AppColors.primary, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Ouvert 24h/24',
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                    Text('Accès libre en permanence',
                                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _is24h,
                                onChanged: (v) => setState(() => _is24h = v),
                                activeTrackColor: AppColors.primary,
                                activeThumbColor: Colors.white,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Photo upload
                        _Label('Photo de la borne'),
                        GestureDetector(
                          onTap: _pickImage,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: _image == null ? 140 : 200,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceDark.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _image != null
                                    ? AppColors.primary.withValues(alpha: 0.5)
                                    : AppColors.borderDark,
                                width: 2,
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: _image == null
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 48, height: 48,
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.2),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.add_a_photo_outlined,
                                            color: AppColors.textSecondary, size: 24),
                                      ),
                                      const SizedBox(height: 10),
                                      const Text('Ajouter une photo',
                                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 4),
                                      Text('JPG, PNG max 5MB',
                                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                    ],
                                  )
                                : ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.file(_image!, fit: BoxFit.cover, width: double.infinity),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // ── Sticky bottom button ──────────────────────────────────────────
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                decoration: BoxDecoration(
                  color: AppColors.backgroundDark.withValues(alpha: 0.95),
                  border: Border(
                    top: BorderSide(color: AppColors.borderDark.withValues(alpha: 0.5)),
                  ),
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Soumettre', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            SizedBox(width: 8),
                            Icon(Icons.check, size: 20),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared small widgets ────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
  );
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final Widget? suffixIcon;
  final Widget? suffixWidget;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _InputField({
    required this.controller,
    required this.hint,
    this.suffixIcon,
    this.suffixWidget,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
        filled: true,
        fillColor: AppColors.surfaceDark,
        suffixIcon: suffixIcon,
        suffix: suffixWidget,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final String Function(T)? itemLabel;
  final ValueChanged<T?> onChanged;

  const _DropdownField({
    required this.value,
    required this.items,
    this.itemLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          dropdownColor: AppColors.surfaceDark,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          icon: const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
          isExpanded: true,
          items: items.map((item) => DropdownMenuItem<T>(
            value: item,
            child: Text(itemLabel != null ? itemLabel!(item) : item.toString()),
          )).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _GhostButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _GhostButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderDark),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
