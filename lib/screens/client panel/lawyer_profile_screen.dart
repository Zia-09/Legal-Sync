import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legal_sync/model/lawyer_Model.dart';
import 'package:legal_sync/model/review_Model.dart';
import 'package:legal_sync/provider/client_provider.dart';
import 'package:legal_sync/services/appoinment_services.dart';
import 'package:legal_sync/services/notification_services.dart';
import 'package:legal_sync/services/review_service.dart';
import 'chat_detail_screen.dart';
import 'messages_screen.dart';

class LawyerProfileScreen extends ConsumerWidget {
  final LawyerModel? lawyer;
  final String? name;
  final String? specialty;
  final double? rating;
  final int? reviews;
  final String? location;
  final String? experience;
  final bool useProfileImage;

  const LawyerProfileScreen({
    super.key,
    this.lawyer,
    this.name,
    this.specialty,
    this.rating,
    this.reviews,
    this.location,
    this.experience,
    this.useProfileImage = false,
  });

  String get _name => lawyer?.name ?? name ?? 'Lawyer';
  String get _specialty => lawyer?.specialization ?? specialty ?? 'Specialist';
  double get _rating => lawyer?.rating ?? rating ?? 0.0;
  String get _experience => lawyer?.experience ?? experience ?? '8 Years';
  bool get _hasProfileImage =>
      (lawyer?.profileImage != null && lawyer!.profileImage!.isNotEmpty) ||
      useProfileImage;
  String? get _profileImageUrl => lawyer?.profileImage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // App Bar with profile image
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: const Color(0xFF141414),
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Sharing profile link...'),
                        backgroundColor: Color(0xFFFF6B00),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.share_outlined,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  _hasProfileImage
                      ? (_profileImageUrl != null
                            ? Image.network(
                                _profileImageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Image.asset(
                                  'images/profile.jpg',
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Image.asset(
                                'images/profile.jpg',
                                fit: BoxFit.cover,
                              ))
                      : Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF1A1A2E), Color(0xFF2D1B69)],
                            ),
                          ),
                          child: Center(
                            child: Text(
                              _name
                                  .split(' ')
                                  .map((e) => e.isNotEmpty ? e[0] : '')
                                  .take(2)
                                  .join(),
                              style: const TextStyle(
                                color: Color(0xFFFF6B00),
                                fontSize: 72,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                  // Gradient overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 120,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0xFF0F0F0F)],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            title: const Text(
              'Professional Profile',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Profile content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  // Name & Title
                  Text(
                    _name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _specialty,
                    style: const TextStyle(
                      color: Color(0xFF9E9E9E),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Experience Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B00).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFFF6B00).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.workspace_premium_outlined,
                          color: Color(0xFFFF6B00),
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$_experience of Distinguished Experience',
                          style: const TextStyle(
                            color: Color(0xFFFF6B00),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final clientAsync = ref.read(currentClientProvider);
                            final client = clientAsync.valueOrNull;

                            if (client == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please login to book a consultation',
                                  ),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                              return;
                            }

                            if (lawyer == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Error: Lawyer details not found',
                                  ),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                              return;
                            }

                            // Show confirmation dialog
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                backgroundColor: const Color(0xFF1A1A1A),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                title: const Text(
                                  'Book Consultation',
                                  style: TextStyle(color: Colors.white),
                                ),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Book with ${lawyer!.name}',
                                      style: const TextStyle(
                                        color: Color(0xFF9E9E9E),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Fee: PKR ${lawyer!.consultationFee.toInt()}',
                                      style: const TextStyle(
                                        color: Color(0xFFFF6B00),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Scheduled for: Tomorrow',
                                      style: TextStyle(
                                        color: Color(0xFF6B6B6B),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text(
                                      'Cancel',
                                      style: TextStyle(
                                        color: Color(0xFF6B6B6B),
                                      ),
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFF6B00),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text(
                                      'Confirm',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            );

                            if (confirmed != true) return;

                            try {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Requesting consultation...'),
                                  backgroundColor: Color(0xFFFF6B00),
                                ),
                              );

                              final svc = AppointmentService();
                              await svc.requestAppointment(
                                clientId: client.clientId,
                                lawyerId: lawyer!.lawyerId,
                                scheduledAt: DateTime.now().add(
                                  const Duration(days: 1),
                                ),
                                fee: lawyer!.consultationFee > 0
                                    ? lawyer!.consultationFee
                                    : 2500.0,
                              );

                              // Send in-app notification to lawyer
                              final notifSvc = NotificationService();
                              await notifSvc.createNotification(
                                userId: lawyer!.lawyerId,
                                title: '📅 New Consultation Request',
                                message:
                                    '${client.name} has requested a consultation. Please check your appointments.',
                                type: 'appointment',
                                metadata: {
                                  'clientId': client.clientId,
                                  'type': 'consultation_request',
                                },
                              );

                              // Send in-app notification to client
                              await notifSvc.createNotification(
                                userId: client.clientId,
                                title: '✅ Consultation Requested',
                                message:
                                    'Your consultation request with ${lawyer!.name} has been submitted. We\'ll notify you once confirmed.',
                                type: 'appointment',
                                metadata: {
                                  'lawyerId': lawyer!.lawyerId,
                                  'type': 'consultation_sent',
                                },
                              );

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Consultation requested! Lawyer notified. ✅',
                                    ),
                                    backgroundColor: Color(0xFF059669),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Failed to book: ${e.toString()}',
                                    ),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF6B00),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Book Consultation',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            if (lawyer == null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const MessagesScreen(),
                                ),
                              );
                              return;
                            }
                            final client = ref
                                .read(currentClientProvider)
                                .valueOrNull;
                            if (client == null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const MessagesScreen(),
                                ),
                              );
                              return;
                            }
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatDetailScreen(
                                  receiverId: lawyer!.lawyerId,
                                  lawyer: lawyer!,
                                ),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xFF3A3A3A)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Message',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Stats Row
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF252525)),
                    ),
                    child: Row(
                      children: [
                        _StatItem(
                          value: lawyer != null && lawyer!.aiWinRate > 0
                              ? '${(lawyer!.aiWinRate * 100).toStringAsFixed(0)}%'
                              : '${(_rating * 20).toStringAsFixed(0)}%',
                          label: 'Success Rate',
                          icon: Icons.trending_up,
                          color: const Color(0xFF059669),
                        ),
                        _VerticalDivider(),
                        _StatItem(
                          value: lawyer != null
                              ? '${lawyer!.caseIds.length}+'
                              : 'N/A',
                          label: 'Cases Won',
                          icon: Icons.emoji_events_outlined,
                          color: const Color(0xFFFF6B00),
                        ),
                        _VerticalDivider(),
                        _StatItem(
                          value: _rating.toStringAsFixed(1),
                          label: 'Rating',
                          icon: Icons.star,
                          color: const Color(0xFFFFB800),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Practice Areas
                  const Text(
                    'Specialized Practice Areas',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _PracticeAreaItem(
                    icon: Icons.business_center_outlined,
                    title: 'Corporate M&A',
                    subtitle: 'Mergers, acquisitions, and deal structuring',
                    color: const Color(0xFF2563EB),
                  ),
                  _PracticeAreaItem(
                    icon: Icons.gavel,
                    title: 'Litigation',
                    subtitle: 'Complex commercial and civil disputes',
                    color: const Color(0xFFFF6B00),
                  ),
                  _PracticeAreaItem(
                    icon: Icons.lightbulb_outline,
                    title: 'Intellectual Property',
                    subtitle: 'Patents, trademarks, and copyright law',
                    color: const Color(0xFF7C3AED),
                  ),
                  _PracticeAreaItem(
                    icon: Icons.shield_outlined,
                    title: 'Cyber Governance',
                    subtitle: 'Data privacy and cyber compliance',
                    color: const Color(0xFF059669),
                  ),
                  const SizedBox(height: 24),

                  // Credentials
                  const Text(
                    'Credentials & Education',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _CredentialItem(
                    institution: 'Harvard Law School',
                    degree: 'Juris Doctor (JD)',
                    year: '2009',
                    icon: Icons.school_outlined,
                  ),
                  _CredentialItem(
                    institution: 'Yale University',
                    degree: 'B.A. Political Science',
                    year: '2006',
                    icon: Icons.school_outlined,
                  ),
                  _CredentialItem(
                    institution: 'New York Bar Association',
                    degree: 'Licensed Attorney',
                    year: '2010',
                    icon: Icons.verified_outlined,
                  ),
                  const SizedBox(height: 24),

                  // Reviews Section
                  const Text(
                    'Client Reviews',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (lawyer != null)
                    _RealReviewsSection(lawyerId: lawyer!.lawyerId)
                  else
                    _ReviewCard(
                      reviewer: 'Client',
                      review: 'Excellent professional service.',
                      rating: 5,
                    ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF6B6B6B), fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 60, color: const Color(0xFF252525));
  }
}

class _PracticeAreaItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _PracticeAreaItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF252525)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF6B6B6B),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios,
            color: Color(0xFF3A3A3A),
            size: 14,
          ),
        ],
      ),
    );
  }
}

class _CredentialItem extends StatelessWidget {
  final String institution;
  final String degree;
  final String year;
  final IconData icon;

  const _CredentialItem({
    required this.institution,
    required this.degree,
    required this.year,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF252525)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B00).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFFFF6B00), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  institution,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  degree,
                  style: const TextStyle(
                    color: Color(0xFF6B6B6B),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            year,
            style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final String reviewer;
  final String review;
  final int rating;

  const _ReviewCard({
    required this.reviewer,
    required this.review,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF252525)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    reviewer[0],
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reviewer,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      children: List.generate(
                        rating,
                        (_) => const Icon(
                          Icons.star,
                          color: Color(0xFFFFB800),
                          size: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            review,
            style: const TextStyle(
              color: Color(0xFF9E9E9E),
              fontSize: 13,
              height: 1.5,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _RealReviewsSection extends ConsumerWidget {
  final String lawyerId;
  const _RealReviewsSection({required this.lawyerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<List<ReviewModel>>(
      stream: ReviewService().getVisibleApprovedReviews(lawyerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFFF6B00)),
          );
        }
        if (snapshot.hasError) {
          return Text(
            'Error loading reviews: ${snapshot.error}',
            style: const TextStyle(color: Colors.redAccent, fontSize: 12),
          );
        }
        final reviews = snapshot.data ?? [];
        if (reviews.isEmpty) {
          return const Text(
            'No reviews yet for this lawyer.',
            style: TextStyle(color: Color(0xFF6B6B6B), fontSize: 13),
          );
        }

        return Column(
          children: reviews.map((r) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: _ReviewCard(
                reviewer: 'Verified Client', // Default for now
                review: r.comment ?? '',
                rating: r.rating.toInt(),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
