import 'package:flutter/material.dart';

import '../../../models/filiere.dart';
import '../../../repositories/admin_repository.dart';
import '../../../repositories/catalogue_repository.dart';

class MatiereFormScreen extends StatefulWidget {
  final dynamic existing;
  const MatiereFormScreen({super.key, this.existing});

  @override
  State<MatiereFormScreen> createState() => _MatiereFormScreenState();
}

class _MatiereFormScreenState extends State<MatiereFormScreen> {
  final _adminRepo = AdminRepository();
  final _catalogueRepo = CatalogueRepository();
  late final _nomCtrl = TextEditingController(
    text: widget.existing?['nom'] ?? '',
  );
  List<Filiere> _filieres = [];
  int? _selectedFiliereId;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _selectedFiliereId = widget.existing?['filiere'];
    _loadFilieres();
  }

  Future<void> _loadFilieres() async {
    _filieres = await _catalogueRepo.fetchFilieres();
    setState(() {});
  }

  Future<void> _save() async {
    if (_selectedFiliereId == null) return;
    setState(() => _saving = true);
    try {
      final data = {'nom': _nomCtrl.text.trim(), 'filiere': _selectedFiliereId};
      if (_isEdit) {
        await _adminRepo.updateMatiere(widget.existing['id'], data);
      } else {
        await _adminRepo.createMatiere(data);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Modifier la matière' : 'Nouvelle matière'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _nomCtrl,
                decoration: const InputDecoration(labelText: 'Nom'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _selectedFiliereId,
                decoration: const InputDecoration(labelText: 'Filière'),
                items: _filieres
                    .map(
                      (f) => DropdownMenuItem(value: f.id, child: Text(f.nom)),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedFiliereId = v),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Enregistrement…' : 'Enregistrer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
