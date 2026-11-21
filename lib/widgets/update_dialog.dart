import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/update_service.dart';
import '../theme/app_theme.dart';

Future<void> showUpdateDialog(BuildContext context, UpdateInfo info) {
  final notes = info.notes.length > 600
      ? '${info.notes.substring(0, 600)}…'
      : info.notes;

  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.system_update_outlined),
          const SizedBox(width: 10),
          Expanded(child: Text('Nova versão: ${info.version}')),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Uma atualização do Ai que fome está disponível.',
            ),
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                notes,
                style: TextStyle(
                  fontSize: 12,
                  color: muted(dialogContext),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Agora não'),
        ),
        if (info.apkUrl.isNotEmpty)
          FilledButton.icon(
            onPressed: () async {
              final uri = Uri.parse(info.apkUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            icon: const Icon(Icons.download_outlined, size: 18),
            label: const Text('Baixar APK'),
          )
        else if (info.releaseUrl.isNotEmpty)
          FilledButton.icon(
            onPressed: () async {
              final uri = Uri.parse(info.releaseUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            icon: const Icon(Icons.open_in_new, size: 18),
            label: const Text('Ver release'),
          ),
      ],
    ),
  );
}
