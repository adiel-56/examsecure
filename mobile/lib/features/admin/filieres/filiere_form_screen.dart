import 'package:flutter/material.dart';
import '../../../repositories/admin_repository.dart';

class FiliereFormScreen extends StatefulWidget {
  final dynamic existing;
  const FiliereFormScreen({super.key, this.existing});

  @override
  State<FiliereFormScreen> createState() => _FiliereFormScreenState();
}

class _FiliereFormScreenState extends State<FiliereFormScreen> {
  final _repo = AdminRepository();
  late final _nomCtrl = TextEditingController(text: widget.existing?['nom'] ?? '');
  late final _descCtrl = TextEditingController(text: widget.existing?['description'] ?? '');
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final data = {'nom': _nomCtrl.text.trim(), 'description': _descCtrl.text.trim()};
      if (_isEdit) {
        await _repo.updateFiliere(widget.existing['id'], data);
      } else {
        await _repo.createFiliere(data);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Modifier la filière' : 'Nouvelle filière')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(controller: _nomCtrl, decoration: const InputDecoration(labelText: 'Nom')),
              const SizedBox(height: 12),
              TextField(controller: _descCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Description')),
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
