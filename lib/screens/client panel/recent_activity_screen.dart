import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legal_sync/provider/client_provider.dart';
import 'package:legal_sync/provider/document_provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class RecentActivityScreen extends ConsumerWidget {
  const RecentActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF121212) : const Color(0xFFF7F9FC);
    final cardColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? const Color(0xFF9E9E9E) : Colors.grey.shade600;

    final clientAsync = ref.watch(currentClientProvider);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Icon(Icons.arrow_back_ios_new, color: textColor, size: 16),
            ),
          ),
        ),
        title: Text(
          'Legal Documents',
          style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: clientAsync.when(
        data: (client) {
          if (client == null) {
            return Center(
              child: Text(
                'User not found',
                style: TextStyle(color: textColor),
              ),
            );
          }

          final docsAsync = ref.watch(documentsByClientProvider(client.clientId));

          return docsAsync.when(
            data: (documents) => _buildActivityList(
              context,
              ref,
              documents,
              cardColor,
              textColor,
              subtitleColor,
              isDark,
              client.clientId,
            ),
            loading: () => const Center(
              child: CircularProgressIndicator(color: Color(0xFFDC2626)),
            ),
            error: (err, st) => Center(
              child: Text('Error: $err', style: TextStyle(color: textColor)),
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFFDC2626)),
        ),
        error: (err, st) => Center(
          child: Text('Error: $err'),
        ),
      ),
    );
  }

  Widget _buildActivityList(
    BuildContext context,
    WidgetRef ref,
    List documents,
    Color cardColor,
    Color textColor,
    Color subtitleColor,
    bool isDark,
    String currentClientId,
  ) {
    if (documents.isEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.folder_open, color: subtitleColor, size: 32),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No documents yet',
                    style: TextStyle(color: subtitleColor, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Group documents by date
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final weekAgo = today.subtract(const Duration(days: 7));

    final groupedDocs = <String, List>{
      'TODAY': [],
      'YESTERDAY': [],
      'LAST WEEK': [],
      'OLDER': [],
    };

    for (var doc in documents) {
      final docDate = DateTime(doc.uploadedAt.year, doc.uploadedAt.month, doc.uploadedAt.day);
      if (docDate == today) {
        groupedDocs['TODAY']!.add(doc);
      } else if (docDate == yesterday) {
        groupedDocs['YESTERDAY']!.add(doc);
      } else if (docDate.isAfter(weekAgo)) {
        groupedDocs['LAST WEEK']!.add(doc);
      } else {
        groupedDocs['OLDER']!.add(doc);
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          ...groupedDocs.entries
              .where((e) => e.value.isNotEmpty)
              .expand((entry) => [
                    _buildSectionHeader(entry.key, subtitleColor),
                    const SizedBox(height: 16),
                    ...entry.value.map((doc) => _buildActivityItem(
                          context,
                          ref,
                          doc,
                          doc.fileName ?? 'Document',
                          'Uploaded by ${doc.uploadedBy == currentClientId ? "you" : "lawyer"}',
                          _timeAgo(doc.uploadedAt),
                          _getIconForFileType(doc.fileType),
                          _getColorForFileType(doc.fileType),
                          cardColor,
                          textColor,
                          subtitleColor,
                          isDark,
                          doc.uploadedBy == currentClientId,
                        )),
                    const SizedBox(height: 24),
                  ]),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inDays > 7) {
      return DateFormat('MMM d, yyyy').format(dateTime);
    } else if (diff.inDays >= 1) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours >= 1) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes >= 1) {
      return '${diff.inMinutes}m ago';
    }
    return 'Just now';
  }

  IconData _getIconForFileType(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'image':
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image_outlined;
      case 'zip':
      case 'rar':
        return Icons.folder_zip_outlined;
      case 'doc':
      case 'docx':
      case 'word':
        return Icons.article_outlined;
      case 'xls':
      case 'xlsx':
      case 'excel':
        return Icons.table_view_outlined;
      default:
        return Icons.description;
    }
  }

  Color _getColorForFileType(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return Colors.red;
      case 'image':
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Colors.orange;
      case 'zip':
      case 'rar':
        return Colors.blue;
      case 'doc':
      case 'docx':
      case 'word':
        return Colors.red;
      case 'xls':
      case 'xlsx':
      case 'excel':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  Widget _buildSectionHeader(String title, Color subtitleColor) {
    return Text(
      title,
      style: TextStyle(color: subtitleColor, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0),
    );
  }

  Future<void> _launchInBrowser(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open document')));
    }
  }

  Widget _buildActivityItem(
    BuildContext context,
    WidgetRef ref,
    dynamic doc,
    String title, 
    String subtitle, 
    String time, 
    IconData icon, 
    Color iconColor, 
    Color cardColor, 
    Color textColor, 
    Color subtitleColor, 
    bool isDark,
    bool canDelete,
  ) {
    return GestureDetector(
      onTap: () {
        if (doc.fileUrl != null && doc.fileUrl.toString().isNotEmpty) {
           _launchInBrowser(context, doc.fileUrl);
        } else {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Document URL not available'))
           );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(color: subtitleColor, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  time,
                  style: TextStyle(color: subtitleColor.withValues(alpha: 0.7), fontSize: 11),
                ),
                if (canDelete) ...[
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete Document'),
                          content: const Text('Are you sure you want to delete this document?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Delete', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await ref.read(documentStateProvider.notifier).deleteDocument(doc.documentId);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Document deleted')),
                          );
                        }
                      }
                    },
                    child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                  ),
                ]
              ],
            ),
          ],
        ),
      ),
    );
  }
}

