import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:liaison_officer/core/design/app_semantic_colors.dart';
import 'package:liaison_officer/core/design/app_spacing.dart';
import 'package:liaison_officer/core/network/api_error_message.dart';
import 'package:liaison_officer/core/services/device_downloads.dart';
import 'package:liaison_officer/core/services/pick_services.dart';
import 'package:liaison_officer/features/helpdesk/data/helpdesk_repository.dart';
import 'package:liaison_officer/features/helpdesk/domain/helpdesk_models.dart';

void showHelpdeskSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(behavior: SnackBarBehavior.floating, content: Text(message)),
    );
}

/// Downloads a stored attachment with the LO's token (the file is not public),
/// saves it like other downloads in the app (Downloads folder on Android, the
/// share sheet on iOS) and opens it.
Future<void> openHelpdeskAttachment(
  BuildContext context,
  HelpdeskAttachment attachment, {
  HelpdeskRepository? repository,
}) async {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 16),
            Expanded(child: Text('Opening file…')),
          ],
        ),
      ),
    ),
  );
  try {
    final bytes = await (repository ?? HelpdeskRepository()).downloadAttachment(
      attachment.id,
    );
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    final handle = await DeviceDownloads.save(
      bytes: bytes,
      filename: attachment.fileName,
      mimeType: attachment.mimeType,
    );
    if (handle == null || !Platform.isAndroid) return;
    final opened = await DeviceDownloads.open(
      handle,
      mimeType: attachment.mimeType,
    );
    if (!opened && context.mounted) {
      showHelpdeskSnack(
        context,
        'Saved to Downloads. No app on this phone can open it.',
      );
    }
  } catch (error) {
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    showHelpdeskSnack(
      context,
      apiErrorMessage(error, fallback: 'Could not open this attachment.'),
    );
  }
}

/// Lets the user choose an image or a PDF and checks its type and size. The
/// file is not uploaded here: it is sent with the query or comment.
Future<PickedFileBytes?> pickHelpdeskAttachment(
  BuildContext context, {
  List<String> accepted = HelpdeskRepository.acceptedTypes,
  double maxSizeMb = HelpdeskRepository.maxAttachmentMb,
  String? title,
}) async {
  final kind = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null && title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ListTile(
            leading: const Icon(Icons.image_outlined),
            title: const Text('Upload image'),
            onTap: () => Navigator.pop(ctx, 'image'),
          ),
          if (accepted.contains('pdf'))
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text('Upload document'),
              onTap: () => Navigator.pop(ctx, 'document'),
            ),
        ],
      ),
    ),
  );
  if (kind == null || !context.mounted) return null;

  PickedFileBytes? file;
  if (kind == 'image') {
    file = await ImagePickService.pickImageWithChooser(context);
  } else {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      withData: true,
    );
    final f = result?.files.firstOrNull;
    if (f?.bytes != null) {
      file = PickedFileBytes(bytes: f!.bytes!, filename: f.name);
    }
  }
  if (file == null || !context.mounted) return null;

  final ext = file.filename.contains('.')
      ? file.filename.split('.').last.toLowerCase()
      : '';
  if (!accepted.contains(ext)) {
    showHelpdeskSnack(context, 'Only JPEG, JPG, PNG and PDF files can be attached.');
    return null;
  }
  final sizeMb = file.bytes.lengthInBytes / (1024 * 1024);
  if (sizeMb > maxSizeMb) {
    showHelpdeskSnack(
      context,
      'File is too large. Maximum size is ${_mb(maxSizeMb)} MB.',
    );
    return null;
  }
  return file;
}

String _mb(double v) => v == v.roundToDouble() ? v.toInt().toString() : '$v';

class HelpdeskStatusPill extends StatelessWidget {
  const HelpdeskStatusPill({super.key, required this.status});

  final String? status;

  @override
  Widget build(BuildContext context) {
    final label = HelpdeskStatus.label(status);
    if (label == null) return const SizedBox.shrink();
    final color = switch (status) {
      HelpdeskStatus.closed => const Color(0xFF16A34A),
      HelpdeskStatus.inProgress => const Color(0xFF2563EB),
      _ => const Color(0xFFD97706),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Stored attachments, by file name. Tapping one downloads it with the token.
class HelpdeskAttachmentLinks extends StatelessWidget {
  const HelpdeskAttachmentLinks({
    super.key,
    required this.attachments,
    this.repository,
  });

  final List<HelpdeskAttachment> attachments;
  final HelpdeskRepository? repository;

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) return const SizedBox.shrink();
    final colors = context.semantic;
    return Wrap(
      spacing: 4,
      runSpacing: 0,
      children: [
        for (final a in attachments)
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: colors.accent,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              visualDensity: VisualDensity.compact,
            ),
            onPressed: () =>
                openHelpdeskAttachment(context, a, repository: repository),
            icon: const Icon(Icons.attach_file_rounded, size: 16),
            label: Text(a.fileName, overflow: TextOverflow.ellipsis),
          ),
      ],
    );
  }
}

/// Picked files not sent yet, each with a remove button.
class HelpdeskPendingAttachments extends StatelessWidget {
  const HelpdeskPendingAttachments({
    super.key,
    required this.files,
    required this.onRemove,
  });

  final List<PickedFileBytes> files;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.semantic;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < files.length; i++)
          InputChip(
            avatar: Icon(
              Icons.attach_file_rounded,
              size: 16,
              color: colors.accent,
            ),
            label: Text(files[i].filename, overflow: TextOverflow.ellipsis),
            onDeleted: () => onRemove(i),
            deleteButtonTooltipMessage: 'Remove',
          ),
      ],
    );
  }
}

class HelpdeskMessage extends StatelessWidget {
  const HelpdeskMessage({
    super.key,
    required this.icon,
    required this.title,
    this.text,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.semantic;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: colors.textMuted),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (text != null) ...[
              const SizedBox(height: 6),
              Text(
                text!,
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.textSecondary, height: 1.4),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Gradient page background shared by the help desk screens (same as FAQs).
class HelpdeskBackground extends StatelessWidget {
  const HelpdeskBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF070B18), Color(0xFF12182E)]
              : const [Color(0xFFF4F7FC), Color(0xFFE8F1FF)],
        ),
      ),
      child: child,
    );
  }
}

/// Back button + page title row used under the brand header.
class HelpdeskTitleRow extends StatelessWidget {
  const HelpdeskTitleRow({
    super.key,
    required this.title,
    required this.onBack,
    this.trailing,
  });

  final String title;
  final VoidCallback onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.semantic;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back',
            onPressed: onBack,
            icon: Icon(Icons.chevron_left_rounded, color: colors.textPrimary),
          ),
          Expanded(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
