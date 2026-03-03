import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legal_sync/provider/lawyer_provider.dart';
import 'package:legal_sync/model/lawyer_Model.dart';
import 'home_screen.dart';
import 'messages_screen.dart';
import 'case_status_screen.dart';
import 'app_setting_screen.dart';

class LegalCategoriesScreen extends ConsumerStatefulWidget {
  const LegalCategoriesScreen({super.key});

  @override
  ConsumerState<LegalCategoriesScreen> createState() =>
      _LegalCategoriesScreenState();
}

class _LegalCategoriesScreenState extends ConsumerState<LegalCategoriesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, dynamic>> _allCategories = [
    {
      'icon': Icons.gavel,
      'label': 'Civil Law',
      'count': '124 Lawyers',
      'color': Color(0xFFFF6B00),
      'bgColor': Color(0xFF2A1500),
    },
    {
      'icon': Icons.shield_outlined,
      'label': 'Cyber Crime',
      'count': '88 Lawyers',
      'color': Color(0xFF7C3AED),
      'bgColor': Color(0xFF1A0C35),
    },
    {
      'icon': Icons.local_hospital_outlined,
      'label': 'Medical',
      'count': '42 Lawyers',
      'color': Color(0xFF059669),
      'bgColor': Color(0xFF052018),
    },
    {
      'icon': Icons.handshake_outlined,
      'label': 'Criminal',
      'count': '210 Lawyers',
      'color': Color(0xFFDC2626),
      'bgColor': Color(0xFF2A0A0A),
    },
    {
      'icon': Icons.home_outlined,
      'label': 'Property',
      'count': '85 Lawyers',
      'color': Color(0xFF2563EB),
      'bgColor': Color(0xFF0A1428),
    },
    {
      'icon': Icons.family_restroom,
      'label': 'Family',
      'count': '158 Lawyers',
      'color': Color(0xFFD97706),
      'bgColor': Color(0xFF251800),
    },
    {
      'icon': Icons.business_center_outlined,
      'label': 'Corporate',
      'count': '73 Lawyers',
      'color': Color(0xFF0891B2),
      'bgColor': Color(0xFF051820),
    },
    {
      'icon': Icons.lightbulb_outline,
      'label': 'IP Law',
      'count': '36 Lawyers',
      'color': Color(0xFF7C3AED),
      'bgColor': Color(0xFF1A0C35),
    },
  ];

  List<Map<String, dynamic>> get _filteredCategories {
    if (_searchQuery.isEmpty) return _allCategories;
    return _allCategories
        .where(
          (cat) => (cat['label'] as String).toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ),
        )
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  const Text(
                    'Legal Categories',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('No new notifications'),
                          backgroundColor: Color(0xFFFF6B00),
                        ),
                      );
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(
                            Icons.notifications_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFF6B00),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2A2A2A)),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 14),
                    const Icon(
                      Icons.search,
                      color: Color(0xFF6B6B6B),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          setState(() => _searchQuery = val);
                        },
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Search categories...',
                          hintStyle: TextStyle(
                            color: Color(0xFF5A5A5A),
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        child: const Padding(
                          padding: EdgeInsets.only(right: 12),
                          child: Icon(
                            Icons.close,
                            color: Color(0xFF6B6B6B),
                            size: 18,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Categories count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Text(
                    '${_filteredCategories.length} Categories',
                    style: const TextStyle(
                      color: Color(0xFF6B6B6B),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            // Grid
            Expanded(
              child: _filteredCategories.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            color: Color(0xFF3A3A3A),
                            size: 48,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'No categories found',
                            style: TextStyle(
                              color: Color(0xFF6B6B6B),
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Consumer(
                      builder: (context, ref, child) {
                        final lawyersAsync = ref.watch(allLawyersProvider);
                        return lawyersAsync.when(
                          data: (lawyers) {
                            return GridView.builder(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                              physics: const BouncingScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                    childAspectRatio: 1.2,
                                  ),
                              itemCount: _filteredCategories.length,
                              itemBuilder: (context, index) {
                                final cat = _filteredCategories[index];
                                final label = cat['label'] as String;

                                // Calculate dynamic count
                                final count = lawyers
                                    .where(
                                      (l) =>
                                          l.specialization
                                              .toLowerCase()
                                              .trim() ==
                                          label.toLowerCase().trim(),
                                    )
                                    .length;

                                return _CategoryCard(
                                  category: cat,
                                  dynamicCount: count,
                                );
                              },
                            );
                          },
                          loading: () => const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFFF6B00),
                            ),
                          ),
                          error: (e, st) => const Center(
                            child: Text('Error loading lawyer counts'),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    const items = ['Home', 'Lawyer', 'Cases', 'Chat', 'Setting'];
    const icons = [
      Icons.home_outlined,
      Icons.balance_outlined,
      Icons.folder_outlined,
      Icons.chat_bubble_outline,
      Icons.settings_outlined,
    ];
    const activeIcons = [
      Icons.home,
      Icons.balance,
      Icons.folder,
      Icons.chat_bubble,
      Icons.settings,
    ];

    return Container(
      height: 70,
      decoration: const BoxDecoration(
        color: Color(0xFF141414),
        border: Border(top: BorderSide(color: Color(0xFF1E1E1E), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(5, (index) {
          final isActive = index == 1; // Lawyer/Categories is active
          return GestureDetector(
            onTap: () {
              if (index == 0) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                );
              } else if (index == 2) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CaseStatusScreen()),
                );
              } else if (index == 3) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MessagesScreen()),
                );
              } else if (index == 4) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AppSettingScreen()),
                );
              }
            },
            child: Container(
              color: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isActive ? activeIcons[index] : icons[index],
                    color: isActive
                        ? const Color(0xFFFF6B00)
                        : const Color(0xFF5A5A5A),
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    items[index],
                    style: TextStyle(
                      color: isActive
                          ? const Color(0xFFFF6B00)
                          : const Color(0xFF5A5A5A),
                      fontSize: 10,
                      fontWeight: isActive
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _CategoryCard extends ConsumerWidget {
  final Map<String, dynamic> category;
  final int dynamicCount;

  const _CategoryCard({required this.category, required this.dynamicCount});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        ref.read(selectedCategoryProvider.notifier).state =
            category['label'] as String;
        Navigator.pop(context);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF252525)),
        ),
        child: Stack(
          children: [
            // Background accent
            Positioned(
              top: -20,
              right: -20,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: (category['color'] as Color).withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: category['bgColor'] as Color,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: (category['color'] as Color).withOpacity(0.2),
                      ),
                    ),
                    child: Icon(
                      category['icon'] as IconData,
                      color: category['color'] as Color,
                      size: 24,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category['label'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$dynamicCount Lawyers',
                        style: TextStyle(
                          color: category['color'] as Color,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
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
}
