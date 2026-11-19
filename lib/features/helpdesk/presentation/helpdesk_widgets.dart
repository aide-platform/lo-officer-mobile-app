import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liaison_officer/core/design/app_semantic_colors.dart';
import 'package:liaison_officer/core/design/app_spacing.dart';
import 'package:liaison_officer/core/network/api_error_message.dart';
import 'package:liaison_officer/core/services/pick_services.dart';
import 'package:liaison_officer/core/session/session_store.dart';
import 'package:liaison_officer/features/helpdesk/data/helpdesk_repository.dart';
import 'package:liaison_officer/features/helpdesk/domain/helpdesk_models.dart';
import 'package:liaison_officer/features/liaison_officer/presentation/bloc/lo_portal_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

/// The LO as a help desk author, from the portal profile.
HelpdeskUser helpdeskUserOf(BuildContext context, {String email = ''}) {
  final profile = context.read<LoPortalBloc>().state.profile;
  String? pick(List<String?> values) {
    for (final v in values) {
      if (v != null && v.trim().isNotEmpty) return v.trim();
    }
    return null;
  }

  var first = profile?.firstName;
  var last = profile?.lastName;
  if ((first == null || first.trim().isEmpty) && profile != null) {
    final parts = profile.displayName.trim().split(RegExp(r'\s+'));
    if (parts.isNotEmpty && parts.first.isNotEmpty) {
      first = parts.first;
      last = parts.length > 1 ? parts.sublist(1).join(' ') : last;
    }
  }
  return HelpdeskUser(
    firstName: first,
    lastName: last,
    email: pick([
      profile?.officialEmail,
      profile?.personalEmail,
      email,
      SessionStore.current?.email,
    ]),
    contactNo: pick([profile?.officialContact, profile?.personalContact]),
  );
}

void showHelpdeskSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(behavior: SnackBarBehavior.floating, content: Text(message)),
    );
}

Future<void> openHelpdeskAttachment(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  var opened = false;
  if (uri != null) {
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }
  if (!opened && context.mounted) {
    showHelpdeskSnack(context, 'Could not open this attachment.');
  }
}

/// Lets the user choose an image or a document (limited to [accepted]
/// extensions), checks the size, and uploads it. Returns the CDN URL.
Future<String?> pickAndUploadHelpdeskAttachment(
  BuildContext context, {
  required HelpdeskRepository repository,
  List<String> accepted = const ['jpeg', 'jpg', 'png', 'pdf'],
  double maxSizeMb = 5,
  String? title,
}) async {
  const images = {'jpg', 'jpeg', 'png', 'gif', 'webp', 'heic'};
  const documents = {
    'pdf',
    'txt',
    'doc',
    'docx',
    'xls',
    'xlsb',
    'xlsm',
    'xlsx',
    'csv',
    'cdr',
  };
  const videos = {'mp4', 'webm', '3gp'};
  final allowsImage = accepted.any(images.contains);
  final allowsDocument = accepted.any(documents.contains);
  final allowsVideo = accepted.any(videos.contains);

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
          if (allowsImage)
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: const Text('Upload image'),
              onTap: () => Navigator.pop(ctx, 'image'),
            ),
          if (allowsDocument)
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text('Upload document'),
              onTap: () => Navigator.pop(ctx, 'document'),
            ),
          if (allowsVideo)
            ListTile(
              leading: const Icon(Icons.videocam_outlined),
              title: const Text('Upload video'),
              onTap: () => Navigator.pop(ctx, 'video'),
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
    final extensions = accepted
        .where((e) => (kind == 'video' ? videos : documents).contains(e))
        .toList();
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: extensions,
      withData: true,
    );
    final f = result?.files.firstOrNull;
    if (f?.bytes != null) {
      file = PickedFileBytes(bytes: f!.bytes!, filename: f.name);
    }
  }
  if (file == null || !context.mounted) return null;

  final sizeMb = file.bytes.lengthInBytes / (1024 * 1024);
  if (sizeMb > maxSizeMb) {
    showHelpdeskSnack(
      context,
      'File is too large. Maximum size is ${_mb(maxSizeMb)} MB.',
    );
    return null;
  }

  final progress = ValueNotifier<double>(0);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => PopScope(
      canPop: false,
      child: AlertDialog(
        content: ValueListenableBuilder<double>(
          valueListenable: progress,
          builder: (context, value, _) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Uploading attachment…'),
              const SizedBox(height: 16),
              LinearProgressIndicator(value: value == 0 ? null : value),
            ],
          ),
        ),
      ),
    ),
  );
  try {
    final url = await repository.uploadAttachment(
      bytes: file.bytes,
      filename: file.filename,
      onProgress: (p) => progress.value = p,
    );
    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
    return url;
  } catch (error) {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      showHelpdeskSnack(
        context,
        apiErrorMessage(error, fallback: 'Could not upload the file.'),
      );
    }
    return null;
  }
  // `progress` is not disposed: the dialog may still be animating out and
  // listening to it. It is garbage-collected with the dialog.
}

String _mb(double v) => v == v.roundToDouble() ? v.toInt().toString() : '$v';

class HelpdeskStatusPill extends StatelessWidget {
  const HelpdeskStatusPill({super.key, required this.status});

  final int? status;

  @override
  Widget build(BuildContext context) {
    final label = HelpdeskStatus.label(status);
    if (label == null) return const SizedBox.shrink();
    final color = status == HelpdeskStatus.closed
        ? const Color(0xFF16A34A)
        : const Color(0xFFD97706);
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

/// "Attachment 1", "Attachment 2"… links that open in the browser.
class HelpdeskAttachmentLinks extends StatelessWidget {
  const HelpdeskAttachmentLinks({super.key, required this.urls});

  final List<String> urls;

  @override
  Widget build(BuildContext context) {
    if (urls.isEmpty) return const SizedBox.shrink();
    final colors = context.semantic;
    return Wrap(
      spacing: 4,
      runSpacing: 0,
      children: [
        for (var i = 0; i < urls.length; i++)
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: colors.accent,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              visualDensity: VisualDensity.compact,
            ),
            onPressed: () => openHelpdeskAttachment(context, urls[i]),
            icon: const Icon(Icons.attach_file_rounded, size: 16),
            label: Text(
              urls.length == 1 ? 'Attachment' : 'Attachment ${i + 1}',
            ),
          ),
      ],
    );
  }
}

/// Uploaded-but-not-sent attachments, each with a remove button.
class HelpdeskPendingAttachments extends StatelessWidget {
  const HelpdeskPendingAttachments({
    super.key,
    required this.urls,
    required this.onRemove,
  });

  final List<String> urls;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.semantic;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < urls.length; i++)
          InputChip(
            avatar: Icon(
              Icons.attach_file_rounded,
              size: 16,
              color: colors.accent,
            ),
            label: Text('Attachment ${i + 1}'),
            onPressed: () => openHelpdeskAttachment(context, urls[i]),
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
