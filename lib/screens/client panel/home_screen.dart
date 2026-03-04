import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legal_sync/provider/client_provider.dart';
import 'package:legal_sync/provider/lawyer_provider.dart';
import 'legal_categories_screen.dart';
import 'messages_screen.dart';
import 'case_status_screen.dart';
import 'search_filter_screen.dart';
import 'app_setting_screen.dart';
import 'widgets/home_widgets.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 0;
  final TextEditingController _searchCtrl = TextEditingController();
  Map<String, dynamic>? _activeFilters;

  final List<Map<String, dynamic>> _categories = [
    {'icon': Icons.gavel, 'label': 'Civil', 'color': const Color(0xFFFF6B00)},
    {
      'icon': Icons.shield_outlined,
      'label': 'Cyber',
      'color': const Color(0xFF7C3AED),
    },
    {
      'icon': Icons.local_hospital_outlined,
      'label': 'Medical',
      'color': const Color(0xFF059669),
    },
    {
      'icon': Icons.handshake_outlined,
      'label': 'Criminal',
      'color': const Color(0xFFDC2626),
    },
    {
      'icon': Icons.home_outlined,
      'label': 'Property',
      'color': const Color(0xFF2563EB),
    },
    {
      'icon': Icons.family_restroom,
      'label': 'Family',
      'color': const Color(0xFFD97706),
    },
    {
      'icon': Icons.business_center_outlined,
      'label': 'Corporate',
      'color': const Color(0xFF0891B2),
    },
    {
      'icon': Icons.lightbulb_outline,
      'label': 'IP Law',
      'color': const Color(0xFF7C3AED),
    },
  ];

  final List<Map<String, dynamic>> _lawyers = [
    {
      'name': 'Hamad Khan',
      'specialty': 'Criminal Lawyer',
      'rating': 4.9,
      'reviews': 200,
      'location': 'Islamabad, PK',
      'experience': '8 Years',
      'useProfile': false,
    },
    {
      'name': 'Zaid Salar',
      'specialty': 'Corporate Lawyer',
      'rating': 4.8,
      'reviews': 145,
      'location': 'Lahore, PK',
      'experience': '6 Years',
      'useProfile': false,
    },
    {
      'name': 'Jonathan Sterling',
      'specialty': 'Senior Partner | Corporate Law',
      'rating': 4.9,
      'reviews': 320,
      'location': 'Karachi, PK',
      'experience': '15+ Years',
      'useProfile': true,
    },
    {
      'name': 'Sara Malik',
      'specialty': 'Family Lawyer',
      'rating': 4.7,
      'reviews': 98,
      'location': 'Rawalpindi, PK',
      'experience': '5 Years',
      'useProfile': false,
    },
    {
      'name': 'Adv. Zia Ullah',
      'specialty': 'Civil Law Specialist',
      'rating': 4.8,
      'reviews': 180,
      'location': 'Peshawar, PK',
      'experience': '12 Years',
      'useProfile': false,
    },
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openFilter() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const SearchFilterScreen()),
    );
    if (result != null) {
      setState(() => _activeFilters = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF0F0F0F),
      drawer: const HomeDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => _scaffoldKey.currentState?.openDrawer(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.menu,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const Text(
                    'LegalSync',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Consumer(
                    builder: (context, ref, child) {
                      final clientAsync = ref.watch(currentClientProvider);
                      return clientAsync.when(
                        data: (client) => GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AppSettingScreen(),
                              ),
                            );
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(
                                  0xFFFF6B00,
                                ).withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child:
                                  (client?.profileImage != null &&
                                      client!.profileImage!.isNotEmpty)
                                  ? Image.network(
                                      client.profileImage!,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Image.asset(
                                                'images/profile.jpg',
                                                fit: BoxFit.cover,
                                              ),
                                    )
                                  : Image.asset(
                                      'images/profile.jpg',
                                      fit: BoxFit.cover,
                                    ),
                            ),
                          ),
                        ),
                        loading: () => Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFFFF6B00),
                              ),
                            ),
                          ),
                        ),
                        error: (_, __) => const Icon(
                          Icons.account_circle,
                          color: Colors.white,
                          size: 40,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1E1E),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFF2A2A2A),
                                ),
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
                                    child: Consumer(
                                      builder: (context, ref, child) {
                                        return TextField(
                                          controller: _searchCtrl,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                          ),
                                          onChanged: (val) {
                                            ref
                                                    .read(
                                                      lawyerSearchQueryProvider
                                                          .notifier,
                                                    )
                                                    .state =
                                                val;
                                            setState(() {});
                                          },
                                          decoration: const InputDecoration(
                                            hintText:
                                                'Search lawyers, cases...',
                                            hintStyle: TextStyle(
                                              color: Color(0xFF5A5A5A),
                                              fontSize: 14,
                                            ),
                                            border: InputBorder.none,
                                            isDense: true,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  if (_searchCtrl.text.isNotEmpty)
                                    Consumer(
                                      builder: (context, ref, child) {
                                        return GestureDetector(
                                          onTap: () {
                                            _searchCtrl.clear();
                                            ref
                                                    .read(
                                                      lawyerSearchQueryProvider
                                                          .notifier,
                                                    )
                                                    .state =
                                                '';
                                            setState(() {});
                                          },
                                          child: const Padding(
                                            padding: EdgeInsets.only(right: 8),
                                            child: Icon(
                                              Icons.close,
                                              color: Color(0xFF6B6B6B),
                                              size: 18,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: _openFilter,
                            child: Stack(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: _activeFilters != null
                                        ? const Color(0xFFFF6B00)
                                        : const Color(0xFF1E1E1E),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _activeFilters != null
                                          ? const Color(0xFFFF6B00)
                                          : const Color(0xFF2A2A2A),
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.tune,
                                    color: _activeFilters != null
                                        ? Colors.white
                                        : const Color(0xFF9E9E9E),
                                    size: 20,
                                  ),
                                ),
                                if (_activeFilters != null)
                                  Positioned(
                                    top: 6,
                                    right: 6,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Active filter chips
                    if (_activeFilters != null) ...[
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.filter_list,
                              color: Color(0xFFFF6B00),
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Filters active',
                              style: TextStyle(
                                color: Color(0xFFFF6B00),
                                fontSize: 12,
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _activeFilters = null),
                              child: const Text(
                                'Clear',
                                style: TextStyle(
                                  color: Color(0xFF9E9E9E),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),

                    // Categories Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Categories',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LegalCategoriesScreen(),
                              ),
                            ),
                            child: const Text(
                              'See all',
                              style: TextStyle(
                                color: Color(0xFFFF6B00),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Categories horizontal scroll
                    SizedBox(
                      height: 88,
                      child: Consumer(
                        builder: (context, ref, child) {
                          final selectedCat = ref.watch(
                            selectedCategoryProvider,
                          );
                          return ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            physics: const BouncingScrollPhysics(),
                            itemCount: _categories.length,
                            itemBuilder: (context, index) {
                              final cat = _categories[index];
                              final isSelected =
                                  selectedCat == cat['label'] as String;
                              return GestureDetector(
                                onTap: () {
                                  final newCat = isSelected
                                      ? null
                                      : cat['label'] as String;
                                  ref
                                          .read(
                                            selectedCategoryProvider.notifier,
                                          )
                                          .state =
                                      newCat;
                                },
                                child: Container(
                                  width: 72,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(
                                            0xFFFF6B00,
                                          ).withValues(alpha: 0.1)
                                        : const Color(0xFF1A1A1A),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFFFF6B00)
                                          : const Color(0xFF252525),
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: (cat['color'] as Color)
                                              .withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Icon(
                                          cat['icon'] as IconData,
                                          color: cat['color'] as Color,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        cat['label'] as String,
                                        style: TextStyle(
                                          color: isSelected
                                              ? const Color(0xFFFF6B00)
                                              : const Color(0xFFCCCCCC),
                                          fontSize: 11,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Featured Lawyers
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Featured Lawyers',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LegalCategoriesScreen(),
                              ),
                            ),
                            child: const Text(
                              'See all',
                              style: TextStyle(
                                color: Color(0xFFFF6B00),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Lawyer cards from Riverpod
                    Consumer(
                      builder: (context, ref, child) {
                        final lawyersAsync = ref.watch(filteredLawyersProvider);
                        return lawyersAsync.when(
                          data: (realLawyers) {
                            if (realLawyers.isEmpty) {
                              final searchQuery = ref.watch(
                                lawyerSearchQueryProvider,
                              );
                              final selectedCat = ref.watch(
                                selectedCategoryProvider,
                              );

                              // If filtering/searching, show "No results"
                              if (searchQuery.isNotEmpty ||
                                  selectedCat != null) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 40),
                                  child: Center(
                                    child: Text(
                                      'No lawyers found matching your filters',
                                      style: TextStyle(
                                        color: Color(0xFF6B6B6B),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                );
                              }

                              return _buildLawyerList(
                                _lawyers,
                                isFallback: true,
                              );
                            }
                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              itemCount: realLawyers.length,
                              itemBuilder: (context, index) {
                                final lawyer = realLawyers[index];
                                return LawyerCard(lawyer: lawyer);
                              },
                            );
                          },
                          loading: () => const Center(
                            child: Padding(
                              padding: EdgeInsets.all(30.0),
                              child: CircularProgressIndicator(
                                color: Color(0xFFFF6B00),
                              ),
                            ),
                          ),
                          error: (e, st) =>
                              _buildLawyerList(_lawyers, isFallback: true),
                        );
                      },
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  // Helper to build lawyer cards from hardcoded data (fallback)
  Widget _buildLawyerList(
    List<Map<String, dynamic>> lawyers, {
    bool isFallback = false,
  }) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: lawyers.length,
      itemBuilder: (context, index) {
        return DemoLawyerCard(lawyer: lawyers[index], isFallback: isFallback);
      },
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
          final isActive = _currentIndex == index;
          return GestureDetector(
            onTap: () {
              setState(() => _currentIndex = index);
              if (index == 1) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LegalCategoriesScreen(),
                  ),
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
              color: Colors.transparent, // Fixes tap detection
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
