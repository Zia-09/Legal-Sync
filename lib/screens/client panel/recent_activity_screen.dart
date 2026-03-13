import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RecentActivityScreen extends ConsumerWidget {
  const RecentActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF121212) : const Color(0xFFF7F9FC);
    final cardColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? const Color(0xFF9E9E9E) : Colors.grey.shade600;

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
          'Recent Activity',
          style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {},
            icon: Container(
               padding: const EdgeInsets.all(8),
               decoration: BoxDecoration(
                 color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                 shape: BoxShape.circle,
               ),
               child: Icon(Icons.search, color: textColor, size: 20),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _buildSectionHeader('TODAY', subtitleColor),
            const SizedBox(height: 16),
            _buildActivityItem(
              'Engagement_Letter_Final.pdf',
              'Modified by Sarah Jenkins • Corporate Law',
              '2h ago',
              Icons.description,
              Colors.red,
              cardColor, textColor, subtitleColor, isDark,
            ),
            _buildActivityItem(
              'Case_Evidence_Photos.zip',
              'Uploaded by You • Real Estate Dispute',
              '5h ago',
              Icons.folder_zip_outlined,
              Colors.blue,
              cardColor, textColor, subtitleColor, isDark,
            ),
            const SizedBox(height: 24),
            _buildSectionHeader('YESTERDAY', subtitleColor),
            const SizedBox(height: 16),
            _buildActivityItem(
              'Contract_Draft_V2.docx',
              'Reviewed by Mark Thompson • IP Firm',
              '1d ago',
              Icons.article_outlined,
              Colors.green,
              cardColor, textColor, subtitleColor, isDark,
            ),
            _buildActivityItem(
              'ID_Verification_Scan.jpg',
              'Uploaded by You • General Profile',
              '1d ago',
              Icons.image_outlined,
              Colors.orange,
              cardColor, textColor, subtitleColor, isDark,
            ),
            const SizedBox(height: 24),
            _buildSectionHeader('LAST WEEK', subtitleColor),
            const SizedBox(height: 16),
            _buildActivityItem(
              'Settlement_Calculator.xlsx',
              'Modified by Finance Dept • Legal Aid',
              '4d ago',
              Icons.table_view_outlined,
              Colors.blue.shade900,
              cardColor, textColor, subtitleColor, isDark,
            ),
            _buildActivityItem(
              'Court_Summons_Copy.pdf',
              'Uploaded by Sarah Jenkins • Civil Case',
              '6d ago',
              Icons.description,
              Colors.red,
              cardColor, textColor, subtitleColor, isDark,
            ),
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
                    child: Icon(Icons.history, color: subtitleColor, size: 32),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No more notifications for the last 30 days',
                    style: TextStyle(color: subtitleColor, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 100), // Space for FAB
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFFDC2626),
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color subtitleColor) {
    return Text(
      title,
      style: TextStyle(color: subtitleColor, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0),
    );
  }

  Widget _buildActivityItem(String title, String subtitle, String time, IconData icon, Color iconColor, Color cardColor, Color textColor, Color subtitleColor, bool isDark) {
    return Container(
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
          Text(
            time,
            style: TextStyle(color: subtitleColor.withValues(alpha: 0.7), fontSize: 11),
          ),
        ],
      ),
    );
  }
}
