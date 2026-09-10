import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/filiere.dart';
import '../../../models/matiere.dart';
import '../../../repositories/admin_repository.dart';
import '../../../repositories/catalogue_repository.dart';

/// Formulaire de création/édition de document avec upload PDF et photo de couverture.
class ExamFormScreen extends StatefulWidget {
  final dynamic existing;
  const ExamFormScreen({super.key, this.existing});

  @override
  State<ExamFormScreen> createState() => _ExamFormScreenState();
}

class _ExamFormScreenState extends State<ExamFormScreen> {
  final _adminRepo = AdminRepository();
  final _catalogueRepo = CatalogueRepository();

  late final _titreCtrl = TextEditingController(
    text: widget.existing?['titre'] ?? '',
  );
  late final _anneeCtrl = TextEditingController(
    text: widget.existing?['annee_academique'] ?? '',
  );
  late final _prixCtrl = TextEditingController(
    text: '${widget.existing?['prix'] ?? ''}',
  );
  late final _pagesCtrl = TextEditingController(
    text: '${widget.existing?['nombre_pages'] ?? ''}',
  );

  List<Filiere> _filieres = [];
  List<Matiere> _matieres = [];
  int? _filiereId;
  final Set<int> _selectedMatiereIds = {};
  String _statut = 'DRAFT';
  bool _saving = false;
  PlatformFile? _pickedFile;
  PlatformFile? _pickedCover;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _filiereId = widget.existing?['filiere'];
    
    // Initialisation des matières sélectionnées
    final rawMatieres = widget.existing?['matieres'];
    if (rawMatieres is List) {
      for (final m in rawMatieres) {
        final id = int.tryParse('$m');
        if (id != null) _selectedMatiereIds.add(id);
      }
    } else if (widget.existing?['matiere'] != null) {
      final id = int.tryParse('${widget.existing['matiere']}');
      if (id != null) _selectedMatiereIds.add(id);
    }

    _statut = widget.existing?['statut'] ?? 'DRAFT';
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    _filieres = await _catalogueRepo.fetchFilieres();
    if (_filiereId != null) {
      _matieres = await _catalogueRepo.fetchMatieres(filiereId: _filiereId);
    }
    setState(() {});
  }

  Future<void> _pickPdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _pickedFile = result.files.first;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du choix du fichier : $e')),
        );
      }
    }
  }

  Future<void> _pickCover() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _pickedCover = result.files.first;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du choix de l\'image : $e')),
        );
      }
    }
  }

  Future<void> _save() async {
    if (_titreCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez renseigner le titre')),
      );
      return;
    }

    if (_filiereId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une filière')),
      );
      return;
    }

    if (_selectedMatiereIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner au moins une matière')),
      );
      return;
    }

    if (!_isEdit && _pickedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un fichier PDF')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final matieresList = _selectedMatiereIds.toList();
      final mapData = <String, dynamic>{
        'titre': _titreCtrl.text.trim(),
        'filiere': _filiereId,
        'matieres': matieresList,
        'matiere': matieresList.first,
        'annee_academique': _anneeCtrl.text.trim(),
        'prix': _prixCtrl.text.trim(),
        'nombre_pages': int.tryParse(_pagesCtrl.text.trim()) ?? 0,
        'statut': _statut,
      };

      final hasPdf = _pickedFile != null && _pickedFile!.path != null;
      final hasCover = _pickedCover != null && _pickedCover!.path != null;

      if (hasPdf || hasCover) {
        final formData = FormData.fromMap(mapData);
        
        // Ajout explicite des champs multiples matieres pour le FormData
        for (final mId in matieresList) {
          formData.fields.add(MapEntry('matieres', mId.toString()));
        }

        if (hasPdf) {
          formData.files.add(
            MapEntry(
              'fichier_original',
              await MultipartFile.fromFile(
                _pickedFile!.path!,
                filename: _pickedFile!.name,
              ),
            ),
          );
        }
        if (hasCover) {
          formData.files.add(
            MapEntry(
              'couverture',
              await MultipartFile.fromFile(
                _pickedCover!.path!,
                filename: _pickedCover!.name,
              ),
            ),
          );
        }

        if (_isEdit) {
          await _adminRepo.updateExam(widget.existing['id'], formData);
        } else {
          await _adminRepo.createExam(formData);
        }
      } else {
        if (_isEdit) {
          await _adminRepo.updateExam(widget.existing['id'], mapData);
        } else {
          await _adminRepo.createExam(mapData);
        }
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

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final String? rawCover = widget.existing?['couverture_url'] ?? widget.existing?['couverture'];
    final String? existingCoverUrl = () {
      if (rawCover == null || rawCover.trim().isEmpty) return null;
      final url = rawCover.trim();
      if (url.startsWith('http://') || url.startsWith('https://')) return url;
      const base = ApiConstants.baseUrl;
      final origin = base.endsWith('/api')
          ? base.substring(0, base.length - 4)
          : (base.endsWith('/api/') ? base.substring(0, base.length - 5) : base);
      return '$origin${url.startsWith('/') ? '' : '/'}$url';
    }();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Modifier le document' : 'Nouveau document'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _titreCtrl,
              decoration: const InputDecoration(labelText: 'Titre'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _filiereId,
              decoration: const InputDecoration(labelText: 'Filière'),
              items: _filieres
                  .map((f) => DropdownMenuItem(value: f.id, child: Text(f.nom)))
                  .toList(),
              onChanged: (v) async {
                setState(() {
                  _filiereId = v;
                  _selectedMatiereIds.clear();
                });
                _matieres = await _catalogueRepo.fetchMatieres(filiereId: v);
                setState(() {});
              },
            ),
            const SizedBox(height: 14),

            // Section Sélection Multi-Matières (Lot d'épreuves)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _selectedMatiereIds.isNotEmpty ? AppColors.primary : AppColors.border,
                  width: _selectedMatiereIds.isNotEmpty ? 1.5 : 1.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.library_books_outlined, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Matières associées (Lot d\'épreuves) *',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                      ),
                      if (_selectedMatiereIds.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${_selectedMatiereIds.length} sélectionnée(s)',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Cochez une ou plusieurs matières pour regrouper plusieurs épreuves dans ce même document.',
                    style: TextStyle(color: AppColors.faint, fontSize: 11),
                  ),
                  const SizedBox(height: 10),
                  if (_filiereId == null)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Veuillez d\'abord choisir une filière ci-dessus.',
                        style: TextStyle(fontStyle: FontStyle.italic, color: AppColors.faint, fontSize: 12),
                      ),
                    )
                  else if (_matieres.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Aucune matière disponible pour cette filière.',
                        style: TextStyle(color: AppColors.faint, fontSize: 12),
                      ),
                    )
                  else ...[
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _selectedMatiereIds.addAll(_matieres.map((m) => m.id));
                            });
                          },
                          icon: const Icon(Icons.select_all, size: 16),
                          label: const Text('Tout cocher', style: TextStyle(fontSize: 11)),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _selectedMatiereIds.clear();
                            });
                          },
                          icon: const Icon(Icons.deselect, size: 16),
                          label: const Text('Tout décocher', style: TextStyle(fontSize: 11)),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _matieres.map((m) {
                        final isSelected = _selectedMatiereIds.contains(m.id);
                        return FilterChip(
                          label: Text(m.nom),
                          selected: isSelected,
                          selectedColor: AppColors.primarySoft,
                          checkmarkColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: isSelected ? AppColors.primary : AppColors.text,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: isSelected ? AppColors.primary : AppColors.border,
                            ),
                          ),
                          onSelected: (bool selected) {
                            setState(() {
                              if (selected) {
                                _selectedMatiereIds.add(m.id);
                              } else {
                                _selectedMatiereIds.remove(m.id);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _anneeCtrl,
              decoration: const InputDecoration(labelText: 'Année académique'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _prixCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Prix (XOF)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pagesCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Nombre de pages'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _statut,
              decoration: const InputDecoration(labelText: 'Statut'),
              items: const [
                DropdownMenuItem(value: 'DRAFT', child: Text('Brouillon')),
                DropdownMenuItem(value: 'PUBLISHED', child: Text('Publié')),
                DropdownMenuItem(value: 'ARCHIVED', child: Text('Archivé')),
              ],
              onChanged: (v) => setState(() => _statut = v ?? 'DRAFT'),
            ),
            const SizedBox(height: 18),

            // Section Photo de Couverture
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _pickedCover != null ? AppColors.primary : AppColors.border,
                  width: _pickedCover != null ? 1.5 : 1.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.image_outlined, color: AppColors.primary, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        _pickedCover != null
                            ? 'Photo de couverture sélectionnée'
                            : (_isEdit ? 'Photo de couverture (facultative)' : 'Photo de couverture (facultative)'),
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_pickedCover != null && _pickedCover!.path != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Stack(
                        alignment: Alignment.topRight,
                        children: [
                          Image.file(
                            File(_pickedCover!.path!),
                            height: 140,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                          IconButton(
                            icon: const CircleAvatar(
                              backgroundColor: Colors.black54,
                              radius: 14,
                              child: Icon(Icons.close, color: Colors.white, size: 16),
                            ),
                            onPressed: () => setState(() => _pickedCover = null),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ] else if (existingCoverUrl != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        existingCoverUrl,
                        height: 140,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  OutlinedButton.icon(
                    onPressed: _pickCover,
                    icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
                    label: Text(_pickedCover == null && existingCoverUrl == null
                        ? 'Choisir une photo de couverture'
                        : 'Changer la photo de couverture'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Section Sélection de fichier PDF
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _pickedFile != null ? AppColors.primary : AppColors.border,
                  width: _pickedFile != null ? 1.5 : 1.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.picture_as_pdf, color: AppColors.primary, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        _pickedFile != null
                            ? 'Fichier PDF sélectionné'
                            : (_isEdit ? 'Remplacer le fichier PDF' : 'Fichier PDF du document *'),
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_pickedFile != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.insert_drive_file, color: AppColors.primary, size: 24),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _pickedFile!.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                                ),
                                Text(
                                  _formatFileSize(_pickedFile!.size),
                                  style: const TextStyle(color: AppColors.faint, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: AppColors.danger, size: 20),
                            onPressed: () => setState(() => _pickedFile = null),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  OutlinedButton.icon(
                    onPressed: _pickPdf,
                    icon: const Icon(Icons.upload_file, size: 18),
                    label: Text(_pickedFile == null ? 'Choisir un fichier PDF' : 'Changer de fichier'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Enregistrement…' : 'Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }
}

