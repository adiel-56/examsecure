import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_client.dart';
import '../../../core/security/local_encryption_service.dart';
import '../../../core/security/screen_security_service.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/purchase.dart';
import '../../../providers/auth_provider.dart';
import '../../../repositories/purchase_repository.dart';

/// Reproduit l'écran « Lecteur sécurisé (hors ligne + filigrane) » de la maquette :
/// barre sombre avec titre + pastille « HORS LIGNE », rendu réel du document PDF
/// déchiffré en mémoire uniquement (jamais de fichier en clair sur le disque),
/// filigrane anti-fraude en surimpression, navigation de pages et « Protections actives ».
class SecureReaderScreen extends StatefulWidget {
  final Purchase purchase;
  const SecureReaderScreen({super.key, required this.purchase});

  @override
  State<SecureReaderScreen> createState() => _SecureReaderScreenState();
}

class _SecureReaderScreenState extends State<SecureReaderScreen> {
  final _purchaseRepo = PurchaseRepository();
  bool _loading = true;
  String? _error;
  int _currentPage = 1;
  int _totalPages = 1;
  PdfController? _pdfController;

  @override
  void initState() {
    super.initState();
    ScreenSecurityService.enableSecure();
    _prepareDocument();
  }

  @override
  void dispose() {
    ScreenSecurityService.disableSecure();
    _pdfController?.dispose();
    super.dispose();
  }

  Future<void> _prepareDocument() async {
    try {
      final deviceIdentifier = await SecureStorage.instance
          .getOrCreateDeviceIdentifier();
      try {
        await _purchaseRepo.registerCurrentDevice(deviceIdentifier);
      } catch (_) {}

      final dir = await getApplicationSupportDirectory();
      // Hash basé sur l'identifiant unique de l'épreuve pour la persistance locale
      final hash = LocalEncryptionService.instance.fileNameHash(
        'epreuve-${widget.purchase.epreuveId}',
      );
      final encryptedFile = File('${dir.path}/exam_$hash.enc');

      Uint8List plainBytes;

      if (await encryptedFile.exists() && (await encryptedFile.length()) > 0) {
        // Mode hors ligne : déchiffrement direct depuis le cache local AES
        plainBytes = await LocalEncryptionService.instance.decryptFromFile(
          encryptedFile,
        );
      } else {
        int purchaseId = widget.purchase.id;
        if (purchaseId <= 0) {
          final purchases = await _purchaseRepo.fetchMyPurchases();
          for (final p in purchases) {
            if (p.epreuveId == widget.purchase.epreuveId) {
              purchaseId = p.id;
              break;
            }
          }
        }

        if (purchaseId <= 0) {
          throw Exception('Achat non confirmé pour ce document.');
        }

        // 1. Demande de token temporaire à usage unique
        final token = await _purchaseRepo.requestDownloadToken(
          purchaseId,
          deviceIdentifier: deviceIdentifier,
        );

        // 2. Téléchargement via l'API sécurisée
        final response = await ApiClient.instance.dio.post(
          '/downloads/file/',
          data: {
            'download_token': token,
            'device_identifier': deviceIdentifier,
          },
          options: Options(responseType: ResponseType.bytes),
        );

        final downloadedBytes = Uint8List.fromList(response.data as List<int>);

        // 3. Chiffrement AES immédiat sur disque
        await LocalEncryptionService.instance.encryptToFile(
          plainBytes: downloadedBytes,
          destination: encryptedFile,
        );

        // 4. Déchiffrement en mémoire
        plainBytes = await LocalEncryptionService.instance.decryptFromFile(
          encryptedFile,
        );
      }

      // Initialiser le moteur de rendu PDF avec les octets déchiffrés
      _pdfController = PdfController(
        document: PdfDocument.openData(plainBytes),
      );

      if (mounted) {
        setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final watermarkText =
        '${auth.currentUser?.fullName ?? ''} · ID ${auth.currentUser?.id ?? ''} · ${_todayLabel()}';

    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 14),
                    Text(
                      'Déchiffrement sécurisé en mémoire…',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              )
            : _error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppColors.danger,
                        size: 40,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _friendlyError(_error!),
                        style: const TextStyle(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _loading = true;
                            _error = null;
                          });
                          _prepareDocument();
                        },
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                ),
              )
            : Column(
                children: [
                  // Barre supérieure sombre : retour, titre, pastille "HORS LIGNE"
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 6, 14, 10),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        Expanded(
                          child: Text(
                            widget.purchase.epreuveTitre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .12),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: .2),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _Dot(),
                              SizedBox(width: 5),
                              Text(
                                'HORS LIGNE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Zone de visualisation du PDF avec filigrane répété
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        children: [
                          if (_pdfController != null)
                            PdfView(
                              controller: _pdfController!,
                              onPageChanged: (page) {
                                setState(() => _currentPage = page);
                              },
                              onDocumentLoaded: (document) {
                                setState(() {
                                  _totalPages = document.pagesCount;
                                  _currentPage = 1;
                                });
                              },
                              builders: PdfViewBuilders<DefaultBuilderOptions>(
                                options: const DefaultBuilderOptions(),
                                documentLoaderBuilder: (_) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                                pageLoaderBuilder: (_) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                            )
                          else
                            const Center(child: Text('Document indisponible')),
                          // Filigrane dynamique anti-fraude en surimpression
                          IgnorePointer(
                            child: Stack(
                              children: [
                                for (final pos in const [
                                  Alignment(-0.6, -0.65),
                                  Alignment(0.5, -0.35),
                                  Alignment(-0.5, 0.0),
                                  Alignment(0.6, 0.35),
                                  Alignment(-0.4, 0.7),
                                ])
                                  Align(
                                    alignment: pos,
                                    child: Transform.rotate(
                                      angle: -0.4,
                                      child: Opacity(
                                        opacity: 0.18,
                                        child: Text(
                                          watermarkText,
                                          style: const TextStyle(
                                            color: Color(0xFFC92A2A),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Pied de page : navigation + indicateur de protection
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        _NavButton(
                          icon: Icons.chevron_left,
                          onTap: () {
                            if (_pdfController != null && _currentPage > 1) {
                              _pdfController!.previousPage(
                                curve: Curves.easeInOut,
                                duration: const Duration(milliseconds: 200),
                              );
                            }
                          },
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .08),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Page $_currentPage / $_totalPages',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _NavButton(
                          icon: Icons.chevron_right,
                          onTap: () {
                            if (_pdfController != null &&
                                _currentPage < _totalPages) {
                              _pdfController!.nextPage(
                                curve: Curves.easeInOut,
                                duration: const Duration(milliseconds: 200),
                              );
                            }
                          },
                        ),
                        const SizedBox(width: 10),
                        const Row(
                          children: [
                            Icon(
                              Icons.shield_outlined,
                              color: AppColors.adminAccent,
                              size: 14,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Protections actives',
                              style: TextStyle(
                                color: AppColors.adminAccent,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  String _friendlyError(String error) {
    if (error.contains('Limite de téléchargement')) {
      return 'Limite de téléchargement atteinte pour cet achat. Veuillez effectuer une demande de déblocage.';
    }
    if (error.contains('appareil')) {
      return 'Impossible d’identifier cet appareil. Veuillez vérifier vos autorisations.';
    }
    if (error.contains('Token') || error.contains('téléchargement')) {
      return 'Le téléchargement n’a pas abouti. Vérifiez votre connexion puis réessayez.';
    }
    return error.replaceAll('Exception:', '').replaceAll('AppException:', '').trim();
  }

  String _todayLabel() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
  }
}

class _Dot extends StatelessWidget {
  const _Dot();
  @override
  Widget build(BuildContext context) => Container(
    width: 6,
    height: 6,
    decoration: const BoxDecoration(
      color: Colors.greenAccent,
      shape: BoxShape.circle,
    ),
  );
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}
