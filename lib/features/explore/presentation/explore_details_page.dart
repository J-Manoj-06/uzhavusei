import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config.dart';
import '../../../localization/app_localizations.dart';
import '../../../models/marketplace_equipment_model.dart';
import '../../../providers/locale_provider.dart';
import '../../../widgets/image_loader.dart';

String generateYoutubeUrl(String category, String lang) {
  final normalizedCategory = category.trim();
  final normalizedLang = lang.trim().toLowerCase();
  final languageName = switch (normalizedLang) {
    'ta' => 'tamil',
    'hi' => 'hindi',
    _ => 'english',
  };
  final query = 'how to use $normalizedCategory $languageName';
  return 'https://www.youtube.com/results?search_query=${Uri.encodeQueryComponent(query)}';
}

class ExploreDetailsPage extends StatefulWidget {
  const ExploreDetailsPage({
    super.key,
    required this.equipment,
  });

  final MarketplaceEquipmentModel equipment;

  @override
  State<ExploreDetailsPage> createState() => _ExploreDetailsPageState();
}

class _ExploreDetailsPageState extends State<ExploreDetailsPage> {
  bool _isOpeningTutorial = false;
  bool _isGeneratingGuide = false;
  String? _guide;
  String? _guideError;

  Future<void> _openTutorialVideo() async {
    final l10n = AppLocalizations.of(context);
    final languageCode = context.read<LocaleProvider>().languageCode;
    final category = widget.equipment.categoryForLanguage(languageCode);
    final fallbackUrl = generateYoutubeUrl(category, languageCode);
    final directVideo = widget.equipment.videoUrl.trim();
    final targetUrl = directVideo.isNotEmpty ? directVideo : fallbackUrl;
    final uri = Uri.tryParse(targetUrl);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.tr('unable_open_video'))),
      );
      return;
    }

    setState(() {
      _isOpeningTutorial = true;
    });

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.tr('unable_open_video'))),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.tr('unable_open_video'))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isOpeningTutorial = false;
        });
      }
    }
  }

  Future<void> _generateGuide() async {
    final l10n = AppLocalizations.of(context);
    final languageCode = context.read<LocaleProvider>().languageCode;
    final title = widget.equipment.titleForLanguage(languageCode);
    final category = widget.equipment.categoryForLanguage(languageCode);
    final description = widget.equipment.descriptionForLanguage(languageCode);
    setState(() {
      _isGeneratingGuide = true;
      _guideError = null;
    });

    try {
      final model = GenerativeModel(
        model: Config.modelName,
        apiKey: Config.apiKey,
      );

      final prompt = '''
You are an agricultural equipment trainer.
Generate a practical equipment guide in bullet points for this machine.

Equipment title: $title
Category: $category
Description: $description

Cover:
1) How to use this equipment
2) Safety tips
3) Best practices
4) When to use it
5) Maintenance tips
''';

      final response = await model.generateContent([Content.text(prompt)]);
      final text = (response.text ?? '').trim();
      if (text.isEmpty) {
        setState(() {
          _guideError = l10n.tr('unable_generate_guide');
        });
      } else {
        setState(() {
          _guide = text;
        });
      }
    } catch (_) {
      setState(() {
        _guideError = l10n.tr('unable_generate_guide');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingGuide = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageCode = context.watch<LocaleProvider>().languageCode;
    final item = widget.equipment;
    final title = item.titleForLanguage(languageCode);
    final category = item.categoryForLanguage(languageCode);
    final description = item.descriptionForLanguage(languageCode);
    final image =
        item.imageUrls.isNotEmpty ? item.imageUrls.first : 'assets/logo.jpg';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tr('explore_details')),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              height: 220,
              child: buildSmartImage(image, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(category, style: TextStyle(color: Colors.grey.shade700)),
          const SizedBox(height: 8),
          Text(description.isEmpty ? '-' : description),
          const SizedBox(height: 12),
          _line(l10n.tr('price'),
              '₹${item.pricePerDay.toStringAsFixed(0)} / day'),
          _line(l10n.tr('location'), item.location),
          _line(l10n.tr('status'), item.status),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isOpeningTutorial ? null : _openTutorialVideo,
              icon: _isOpeningTutorial
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.play_arrow_rounded),
              label: Text(l10n.tr('watch_tutorial_video')),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.tr('ai_guide'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isGeneratingGuide ? null : _generateGuide,
                      icon: _isGeneratingGuide
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.auto_awesome_rounded),
                      label: Text(l10n.tr('generate_equipment_guide')),
                    ),
                  ),
                  if (_guideError != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _guideError!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                  if ((_guide ?? '').isNotEmpty) ...[
                    const SizedBox(height: 10),
                    ExpansionTile(
                      title: Text(l10n.tr('ai_generated_guide')),
                      initiallyExpanded: true,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          child: Text(_guide!),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _line(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: TextStyle(color: Colors.grey.shade700)),
          ),
          const Text(': '),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
