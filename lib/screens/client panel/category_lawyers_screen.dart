import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legal_sync/model/lawyer_Model.dart';
import 'package:legal_sync/provider/lawyer_provider.dart';
import 'lawyer_profile_screen.dart';

class CategoryLawyersScreen extends ConsumerStatefulWidget {
  final String category;
  final Color categoryColor;
  final IconData categoryIcon;

  const CategoryLawyersScreen({
    super.key,
    required this.category,
    required this.categoryColor,
    required this.categoryIcon,
  });

  @override
  ConsumerState<CategoryLawyersScreen> createState() =>
      _CategoryLawyersScreenState();
}

class _CategoryLawyersScreenState extends ConsumerState<CategoryLawyersScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _sort = 'rating'; // 'rating', 'fee', 'experience'

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<LawyerModel> _filterAndSort(List<LawyerModel> all) {
    final cat = widget.category.toLowerCase();
    var filtered = all
        .where(
          (l) =>
              l.isApproved &&
              l.specialization.toLowerCase().contains(cat) &&
              (l.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  l.specialization.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  )),
        )
        .toList();

    if (_sort == 'rating') {
      filtered.sort((a, b) => b.rating.compareTo(a.rating));
    } else if (_sort == 'fee') {
      filtered.sort((a, b) => a.consultationFee.compareTo(b.consultationFee));
    } else if (_sort == 'experience') {
      filtered.sort((a, b) => b.experienceYears.compareTo(a.experienceYears));
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final lawyersAsync = ref.watch(allLawyersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: widget.categoryColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      widget.categoryIcon,
                      color: widget.categoryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.category} Lawyers',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Verified & Approved',
                          style: TextStyle(
                            color: widget.categoryColor,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Search & Sort row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF2A2A2A)),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 12),
                          const Icon(
                            Icons.search,
                            color: Color(0xFF6B6B6B),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchCtrl,
                              onChanged: (v) =>
                                  setState(() => _searchQuery = v),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Search by name...',
                                hintStyle: TextStyle(
                                  color: Color(0xFF5A5A5A),
                                  fontSize: 13,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  PopupMenuButton<String>(
                    onSelected: (v) => setState(() => _sort = v),
                    color: const Color(0xFF1E1E1E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Container(
                      height: 44,
                      width: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF2A2A2A)),
                      ),
                      child: const Icon(
                        Icons.sort,
                        color: Color(0xFF9E9E9E),
                        size: 20,
                      ),
                    ),
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'rating',
                        child: Text(
                          '⭐ Top Rated',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'fee',
                        child: Text(
                          '💰 Lowest Fee',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'experience',
                        child: Text(
                          '🏅 Most Experienced',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Lawyer List
            Expanded(
              child: lawyersAsync.when(
                data: (all) {
                  final lawyers = _filterAndSort(all);

                  if (lawyers.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            widget.categoryIcon,
                            color: const Color(0xFF3A3A3A),
                            size: 52,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'No ${widget.category} lawyers found',
                            style: const TextStyle(
                              color: Color(0xFF6B6B6B),
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Check back soon!',
                            style: TextStyle(
                              color: Color(0xFF3A3A3A),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          '${lawyers.length} Lawyer${lawyers.length != 1 ? 's' : ''} Available',
                          style: const TextStyle(
                            color: Color(0xFF6B6B6B),
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: lawyers.length,
                          itemBuilder: (_, i) => _LawyerCard(
                            lawyer: lawyers[i],
                            accentColor: widget.categoryColor,
                          ),
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: Color(0xFFFF6B00)),
                ),
                error: (e, _) => Center(
                  child: Text(
                    'Error loading lawyers',
                    style: TextStyle(color: Colors.red.shade400),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LawyerCard extends StatelessWidget {
  final LawyerModel lawyer;
  final Color accentColor;

  const _LawyerCard({required this.lawyer, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final successRate = lawyer.aiWinRate > 0
        ? '${(lawyer.aiWinRate * 100).toStringAsFixed(0)}%'
        : 'N/A';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => LawyerProfileScreen(lawyer: lawyer)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF252525)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: accentColor.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: lawyer.profileImageUrl.isNotEmpty
                    ? Image.network(
                        lawyer.profileImageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Text(
                            lawyer.name.isNotEmpty ? lawyer.name[0] : 'L',
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          lawyer.name.isNotEmpty ? lawyer.name[0] : 'L',
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lawyer.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (lawyer.isVerified)
                        const Icon(
                          Icons.verified,
                          color: Color(0xFF2563EB),
                          size: 16,
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    lawyer.specialization,
                    style: TextStyle(color: accentColor, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: Color(0xFFFFB800),
                        size: 13,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${lawyer.rating.toStringAsFixed(1)} (${lawyer.totalReviews})',
                        style: const TextStyle(
                          color: Color(0xFF9E9E9E),
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.location_on_outlined,
                        color: Color(0xFF6B6B6B),
                        size: 13,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          lawyer.location ?? 'Pakistan',
                          style: const TextStyle(
                            color: Color(0xFF6B6B6B),
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _MiniStat(
                        label: 'Success',
                        value: successRate,
                        color: const Color(0xFF059669),
                      ),
                      const SizedBox(width: 10),
                      _MiniStat(
                        label: 'Cases',
                        value: '${lawyer.caseIds.length}',
                        color: const Color(0xFFFF6B00),
                      ),
                      const SizedBox(width: 10),
                      _MiniStat(
                        label: 'Fee',
                        value: lawyer.consultationFee > 0
                            ? 'PKR ${lawyer.consultationFee.toInt()}'
                            : 'Free',
                        color: const Color(0xFF7C3AED),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFF3A3A3A),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF6B6B6B), fontSize: 9),
          ),
        ],
      ),
    );
  }
}
