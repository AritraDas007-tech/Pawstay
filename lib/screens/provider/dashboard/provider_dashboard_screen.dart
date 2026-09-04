import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_application_1/services/api/api_service.dart';

// ---------------------------------------------------------------------------
// THEME CONSTANTS & COLOR SYSTEM
// ---------------------------------------------------------------------------
class AppColors {
  static const Color primary = Color(0xFFA55233);
  static const Color primaryDark = Color(0xFF7D3920);
  static const Color primaryLight = Color(0xFFD48265);
  static const Color background = Color(0xFFFFF8F3);
  static const Color card = Colors.white;
  static const Color accent = Color(0xFFF7E8DD);
  static const Color accentLight = Color(0xFFFDF4EE);

  static const Color textDark = Color(0xFF241915);
  static const Color textMedium = Color(0xFF6B5850);
  static const Color textLight = Color(0xFFA09088);

  static const Color statusGreen = Color(0xFF2E7D32);
  static const Color statusGreenBg = Color(0xFFE8F5E9);
  static const Color statusOrange = Color(0xFFED6C02);
  static const Color statusOrangeBg = Color(0xFFFFF3E0);
  static const Color statusBlue = Color(0xFF0288D1);
  static const Color statusBlueBg = Color(0xFFE1F5FE);
  static const Color statusRed = Color(0xFFD32F2F);
  static const Color statusRedBg = Color(0xFFFFEBEE);

  static const Color border = Color(0xFFEFE4DC);
}

// ---------------------------------------------------------------------------
// HOVER INTERACTION HELPER
// ---------------------------------------------------------------------------
class HoverAnimatedContainer extends StatefulWidget {
  final Widget Function(bool isHovered) builder;
  const HoverAnimatedContainer({super.key, required this.builder});

  @override
  State<HoverAnimatedContainer> createState() => _HoverAnimatedContainerState();
}

class _HoverAnimatedContainerState extends State<HoverAnimatedContainer> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: widget.builder(_isHovered),
    );
  }
}

// ---------------------------------------------------------------------------
// MAIN DASHBOARD SCREEN
// ---------------------------------------------------------------------------
class ProviderDashboardScreen extends StatefulWidget {
  final String? providerLookup;
  const ProviderDashboardScreen({super.key, this.providerLookup});

  @override
  State<ProviderDashboardScreen> createState() => _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState extends State<ProviderDashboardScreen> {
  int _selectedNavIndex = 0;
  bool _isOnline = true;
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String _providerName = 'Priya Rathore';
  int _unreadNotifsCount = 3;

  // Dynamic Data Lists
  List<Map<String, dynamic>> _notifications = [];
  List<Map<String, dynamic>> _services = [];
  List<Map<String, dynamic>> _bookings = [];
  List<Map<String, dynamic>> _reviews = [];

  // Dynamic Stats & Analytics
  Map<String, String> _statsMap = {
    'todayBookings': '8 Active',
    'todayBookingsSub': '+2 new check-ins',
    'activePets': '12 Pets',
    'activePetsSub': '8 Dogs, 4 Cats',
    'monthlyEarnings': '₹84,250',
    'monthlyEarningsSub': '+18.4% this month',
    'rating': '4.95 ★',
    'ratingSub': '210 verified reviews',
    'pendingRequests': '3 Requests',
    'pendingRequestsSub': 'Requires approval',
    'upcomingVisits': '15 Scheduled',
    'upcomingVisitsSub': 'Next 7 days',
    'occupancyRate': '80%',
    'occupancySub': '12/15 Slots full',
  };

  Map<String, String> _incomeMap = {
    'today': '₹6,499',
    'todaySub': '+12% vs yesterday',
    'weekly': '₹28,850',
    'weeklySub': '24 completed stays',
    'monthly': '₹84,250',
    'monthlySub': 'Target: ₹1,00,000',
  };

  List<double> _revenuePoints = [20, 35, 28, 50, 42, 68, 55, 78, 85, 74, 95, 110];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final lookup = widget.providerLookup;

      // Parallel fetch all data from MySQL backend
      final results = await Future.wait([
        ApiService.fetchDashboardStats(providerLookup: lookup),
        ApiService.fetchProviderServices(providerLookup: lookup),
        ApiService.fetchProviderBookings(providerLookup: lookup),
        ApiService.fetchProviderReviews(providerLookup: lookup),
        ApiService.fetchNotifications(userLookup: lookup),
      ]);

      if (mounted) {
        setState(() {
          // Dashboard Stats
          final statsData = results[0] as Map<String, dynamic>?;
          if (statsData != null) {
            if (statsData['provider'] != null) {
              _providerName = statsData['provider']['name'] ?? _providerName;
              _isOnline = statsData['provider']['isOnline'] ?? _isOnline;
            }
            if (statsData['stats'] != null) {
              final s = Map<String, dynamic>.from(statsData['stats']);
              _statsMap = s.map((k, v) => MapEntry(k, v.toString()));
            }
            if (statsData['incomeBreakdown'] != null) {
              final inc = Map<String, dynamic>.from(statsData['incomeBreakdown']);
              _incomeMap = inc.map((k, v) => MapEntry(k, v.toString()));
            }
            if (statsData['revenuePoints'] != null) {
              _revenuePoints = List<double>.from(
                (statsData['revenuePoints'] as List).map((x) => (x as num).toDouble()),
              );
            }
          }

          // Services
          final servicesList = results[1] as List<Map<String, dynamic>>?;
          if (servicesList != null && servicesList.isNotEmpty) {
            _services = servicesList;
          }

          // Bookings
          final bookingsList = results[2] as List<Map<String, dynamic>>?;
          if (bookingsList != null && bookingsList.isNotEmpty) {
            _bookings = bookingsList;
          }

          // Reviews
          final reviewsList = results[3] as List<Map<String, dynamic>>?;
          if (reviewsList != null && reviewsList.isNotEmpty) {
            _reviews = reviewsList;
          }

          // Notifications
          final notifsData = results[4] as Map<String, dynamic>?;
          if (notifsData != null) {
            _unreadNotifsCount = notifsData['unreadCount'] ?? 0;
            if (notifsData['notifications'] != null) {
              _notifications = List<Map<String, dynamic>>.from(notifsData['notifications']);
            }
          }

          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[DASHBOARD ERROR] _loadDashboardData: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openAddServiceModal({Map<String, dynamic>? initialService}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'AddServiceModal',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (context, anim1, anim2) => AddServiceModalDialog(
        initialService: initialService,
        onServiceSaved: () => _loadDashboardData(),
      ),
      transitionBuilder: (context, anim1, anim2, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8 * anim1.value, sigmaY: 8 * anim1.value),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1.0).animate(
              CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic),
            ),
            child: FadeTransition(opacity: anim1, child: child),
          ),
        );
      },
    );
  }

  Future<void> _toggleServiceStatus(Map<String, dynamic> svc) async {
    final currentStatus = svc['status']?.toString() ?? 'Active';
    final newStatus = currentStatus == 'Active' ? 'Paused' : 'Active';

    final success = await ApiService.updateServiceStatus(svc['id'] as int, newStatus);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus == 'Active'
                ? '✅ Service resumed! Now visible on customer dashboard.'
                : '⏸️ Service paused. Hidden from customer dashboard.',
            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          backgroundColor: newStatus == 'Active' ? AppColors.statusGreen : AppColors.statusOrange,
        ),
      );
      _loadDashboardData();
    }
  }

  Future<void> _deleteService(Map<String, dynamic> svc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Service', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text(
          'Are you sure you want to delete "${svc['title']}"? This will soft-delete the service and remove it from all customer listings.',
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.poppins(color: AppColors.textMedium)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Delete', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ApiService.deleteService(svc['id'] as int);
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '🗑️ Service deleted successfully.',
              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppColors.statusRed,
          ),
        );
        _loadDashboardData();
      }
    }
  }

  Future<void> _updateBookingStatus(Map<String, dynamic> booking, String newStatus) async {
    final bookingId = booking['db_id'] ?? int.tryParse(booking['id'].toString().replaceAll('PS-', '')) ?? 1;
    final success = await ApiService.updateBookingStatus(bookingId as int, newStatus);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Booking #${booking['id']} marked as $newStatus.',
            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          backgroundColor: newStatus == 'Confirmed'
              ? AppColors.statusGreen
              : newStatus == 'Completed'
                  ? AppColors.statusBlue
                  : AppColors.statusRed,
        ),
      );
      _loadDashboardData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1200;
    final isTablet = screenWidth >= 850 && screenWidth < 1200;
    final isMobile = screenWidth < 850;

    return Theme(
      data: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        primaryColor: AppColors.primary,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          surface: Colors.white,
          surfaceTint: Colors.transparent,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
      ),
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: AppColors.background,
        drawer: isMobile ? _buildMobileDrawer() : null,
        floatingActionButton: _buildFloatingActionButton(),
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMobile) _buildNavigationSidebar(isTablet: isTablet),
            Expanded(
              child: Column(
                children: [
                  _buildTopAppBar(isMobile: isMobile),
                  if (_isLoading)
                    const LinearProgressIndicator(
                      minHeight: 2.5,
                      color: AppColors.primary,
                      backgroundColor: Colors.transparent,
                    ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _loadDashboardData,
                      color: AppColors.primary,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 16 : 28,
                          vertical: 24,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isDesktop)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 7,
                                    child: _buildSelectedTabContent(),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    flex: 3,
                                    child: _buildRightSidebar(),
                                  ),
                                ],
                              )
                            else
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSelectedTabContent(),
                                  const SizedBox(height: 32),
                                  _buildRightSidebar(),
                                ],
                              ),
                            const SizedBox(height: 60),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return HoverAnimatedContainer(
      builder: (isHovered) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: isHovered ? 0.45 : 0.3),
                blurRadius: isHovered ? 24 : 16,
                offset: Offset(0, isHovered ? 8 : 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _openAddServiceModal(),
              borderRadius: BorderRadius.circular(30),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Add New Service',
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopAppBar({required bool isMobile}) {
    return Container(
      height: 76,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: [
          if (isMobile) ...[
            IconButton(
              icon: const Icon(Icons.menu_rounded, color: AppColors.textDark),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Container(
              height: 44,
              constraints: const BoxConstraints(maxWidth: 420),
              decoration: BoxDecoration(
                color: AppColors.accentLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textDark),
                decoration: InputDecoration(
                  hintText: 'Search bookings, guests, pet services...',
                  hintStyle: GoogleFonts.poppins(fontSize: 12.5, color: AppColors.textLight),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textLight, size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Live Facility Status Toggle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _isOnline ? AppColors.statusGreenBg : AppColors.accentLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isOnline ? AppColors.statusGreen.withValues(alpha: 0.3) : AppColors.border,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _isOnline ? AppColors.statusGreen : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _isOnline ? 'Host Online' : 'Host Offline',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _isOnline ? AppColors.statusGreen : Colors.grey.shade700,
                  ),
                ),
                Transform.scale(
                  scale: 0.7,
                  child: Switch(
                    value: _isOnline,
                    activeThumbColor: AppColors.statusGreen,
                    onChanged: (val) async {
                      setState(() => _isOnline = val);
                      await ApiService.updateProviderOnlineStatus(val, providerLookup: widget.providerLookup);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _buildNotificationButton(),
          const SizedBox(width: 14),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                child: const CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.accent,
                  child: Icon(Icons.person, color: AppColors.primary, size: 20),
                ),
              ),
              if (!isMobile) ...[
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          _providerName,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.verified_rounded, color: AppColors.primary, size: 14),
                      ],
                    ),
                    Text(
                      'PawStay SuperHost',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppColors.textMedium,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationButton() {
    return PopupMenuButton<int>(
      offset: const Offset(0, 50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.white,
      elevation: 10,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: AppColors.accentLight,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.notifications_outlined, color: AppColors.textDark, size: 20),
          ),
          if (_unreadNotifsCount > 0)
            Positioned(
              top: 2,
              right: 2,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$_unreadNotifsCount',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: SizedBox(
            width: 300,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Notifications',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    Navigator.pop(context);
                    await ApiService.markNotificationsRead(userLookup: widget.providerLookup);
                    _loadDashboardData();
                  },
                  child: Text(
                    'Mark all read',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const PopupMenuDivider(),
        ..._notifications.map((n) {
          IconData iconData = Icons.bookmark_add_rounded;
          Color iconColor = AppColors.statusGreen;
          if (n['type'] == 'payment') {
            iconData = Icons.account_balance_wallet_rounded;
            iconColor = AppColors.primary;
          } else if (n['type'] == 'review') {
            iconData = Icons.star_rounded;
            iconColor = Colors.amber;
          }

          return PopupMenuItem(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(iconData, color: iconColor, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        n['title']?.toString() ?? 'Notification',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        n['body']?.toString() ?? '',
                        style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textMedium),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        n['time']?.toString() ?? 'Recent',
                        style: GoogleFonts.poppins(fontSize: 9.5, color: AppColors.textLight),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildNavigationSidebar({required bool isTablet, bool isDrawer = false}) {
    final navItems = [
      {'icon': Icons.dashboard_rounded, 'label': 'Dashboard'},
      {'icon': Icons.home_repair_service_rounded, 'label': 'My Services'},
      {'icon': Icons.calendar_month_rounded, 'label': 'Bookings'},
      {'icon': Icons.event_note_rounded, 'label': 'Calendar'},
      {'icon': Icons.chat_bubble_outline_rounded, 'label': 'Messages'},
      {'icon': Icons.rate_review_outlined, 'label': 'Reviews'},
      {'icon': Icons.account_balance_wallet_outlined, 'label': 'Payments'},
      {'icon': Icons.insights_rounded, 'label': 'Analytics'},
      {'icon': Icons.settings_outlined, 'label': 'Settings'},
    ];

    return Container(
      width: isDrawer ? double.infinity : (isTablet ? 80 : 240),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 12 : 20,
              vertical: 20,
            ),
            child: Row(
              mainAxisAlignment: isTablet ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.pets_rounded, color: Colors.white, size: 20),
                ),
                if (!isTablet) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PawStay',
                          style: GoogleFonts.poppins(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'HOST DASHBOARD',
                          style: GoogleFonts.poppins(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textLight,
                            letterSpacing: 1.1,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: navItems.length,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemBuilder: (context, index) {
                final item = navItems[index];
                final isSelected = _selectedNavIndex == index;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: HoverAnimatedContainer(
                    builder: (isHovered) {
                      return InkWell(
                        onTap: () {
                          setState(() => _selectedNavIndex = index);
                          if (isDrawer) Navigator.pop(context);
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 10 : 14,
                            vertical: 11,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : isHovered
                                    ? AppColors.accentLight
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisAlignment: isTablet ? MainAxisAlignment.center : MainAxisAlignment.start,
                            children: [
                              Icon(
                                item['icon'] as IconData,
                                color: isSelected
                                    ? Colors.white
                                    : isHovered
                                        ? AppColors.primary
                                        : AppColors.textMedium,
                                size: 19,
                              ),
                              if (!isTablet) ...[
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    item['label'] as String,
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                      color: isSelected
                                          ? Colors.white
                                          : isHovered
                                              ? AppColors.primary
                                              : AppColors.textDark,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: InkWell(
              onTap: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 8 : 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.statusRedBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: isTablet ? MainAxisAlignment.center : MainAxisAlignment.start,
                  children: [
                    const Icon(Icons.logout_rounded, color: AppColors.statusRed, size: 18),
                    if (!isTablet) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Exit Dashboard',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.statusRed,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: _buildNavigationSidebar(isTablet: false, isDrawer: true),
      ),
    );
  }

  Widget _buildSelectedTabContent() {
    switch (_selectedNavIndex) {
      case 1: // My Services
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPublishedServicesSection(),
          ],
        );
      case 2: // Bookings
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBookingOverviewTable(),
          ],
        );
      case 3: // Calendar
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCalendarScheduleSection(),
          ],
        );
      case 5: // Reviews
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRecentReviewsSection(),
          ],
        );
      case 6: // Payments
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEarningsHighlightCard(),
          ],
        );
      case 0: // Overview Dashboard
      default:
        return _buildMainDashboardSections();
    }
  }

  Widget _buildMainDashboardSections() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome back, $_providerName! 🐾',
          style: GoogleFonts.poppins(
            fontSize: 21,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
        Text(
          'Here is your live facility status and booking requests for today.',
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            color: AppColors.textMedium,
          ),
        ),
        const SizedBox(height: 20),
        _buildStatisticCardsGrid(),
        const SizedBox(height: 24),
        _buildEarningsHighlightCard(),
        const SizedBox(height: 24),
        _buildPublishedServicesSection(),
        const SizedBox(height: 24),
        _buildBookingOverviewTable(),
        const SizedBox(height: 24),
        _buildCalendarScheduleSection(),
        const SizedBox(height: 24),
        _buildRecentReviewsSection(),
      ],
    );
  }

  Widget _buildStatisticCardsGrid() {
    final stats = [
      {
        'title': 'Today\'s Bookings',
        'value': _statsMap['todayBookings'] ?? '8 Active',
        'sub': _statsMap['todayBookingsSub'] ?? '+2 new check-ins',
        'icon': Icons.calendar_today_rounded,
        'gradient': [const Color(0xFFF7E8DD), const Color(0xFFECD3C1)],
        'sparkColor': AppColors.primary,
        'sparkData': [3.0, 5.0, 4.0, 7.0, 6.0, 8.0],
      },
      {
        'title': 'Active Pets',
        'value': _statsMap['activePets'] ?? '12 Pets',
        'sub': _statsMap['activePetsSub'] ?? '8 Dogs, 4 Cats',
        'icon': Icons.pets_rounded,
        'gradient': [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)],
        'sparkColor': AppColors.statusGreen,
        'sparkData': [6.0, 8.0, 9.0, 10.0, 11.0, 12.0],
      },
      {
        'title': 'Monthly Earnings',
        'value': _statsMap['monthlyEarnings'] ?? '₹84,250',
        'sub': _statsMap['monthlyEarningsSub'] ?? '+18.4% this month',
        'icon': Icons.monetization_on_rounded,
        'gradient': [const Color(0xFFFFF3E0), const Color(0xFFFFE0B2)],
        'sparkColor': AppColors.statusOrange,
        'sparkData': [40.0, 55.0, 50.0, 72.0, 68.0, 84.0],
      },
      {
        'title': 'Rating',
        'value': _statsMap['rating'] ?? '4.95 ★',
        'sub': _statsMap['ratingSub'] ?? '210 verified reviews',
        'icon': Icons.star_rounded,
        'gradient': [const Color(0xFFFFFDE7), const Color(0xFFFFF9C4)],
        'sparkColor': Colors.amber.shade800,
        'sparkData': [4.8, 4.85, 4.9, 4.92, 4.93, 4.95],
      },
      {
        'title': 'Pending Requests',
        'value': _statsMap['pendingRequests'] ?? '3 Requests',
        'sub': _statsMap['pendingRequestsSub'] ?? 'Requires approval',
        'icon': Icons.hourglass_top_rounded,
        'gradient': [const Color(0xFFFFEBEE), const Color(0xFFFFCDD2)],
        'sparkColor': AppColors.statusRed,
        'sparkData': [5.0, 4.0, 2.0, 6.0, 4.0, 3.0],
      },
      {
        'title': 'Upcoming Visits',
        'value': _statsMap['upcomingVisits'] ?? '15 Scheduled',
        'sub': _statsMap['upcomingVisitsSub'] ?? 'Next 7 days',
        'icon': Icons.directions_walk_rounded,
        'gradient': [const Color(0xFFE1F5FE), const Color(0xFFB3E5FC)],
        'sparkColor': AppColors.statusBlue,
        'sparkData': [8.0, 10.0, 12.0, 11.0, 14.0, 15.0],
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 850
            ? 3
            : constraints.maxWidth > 520
                ? 2
                : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.68,
          ),
          itemCount: stats.length,
          itemBuilder: (context, index) {
            final st = stats[index];
            return HoverAnimatedContainer(
              builder: (isHovered) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  transform: Matrix4.translationValues(0.0, isHovered ? -3.0 : 0.0, 0.0),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isHovered ? AppColors.primaryLight : AppColors.border,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isHovered ? 0.06 : 0.02),
                        blurRadius: isHovered ? 14 : 6,
                        offset: Offset(0, isHovered ? 5 : 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: st['gradient'] as List<Color>,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              st['icon'] as IconData,
                              color: st['sparkColor'] as Color,
                              size: 19,
                            ),
                          ),
                          SizedBox(
                            width: 60,
                            height: 24,
                            child: CustomPaint(
                              painter: MiniSparklinePainter(
                                data: st['sparkData'] as List<double>,
                                lineColor: st['sparkColor'] as Color,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            st['value'] as String,
                            style: GoogleFonts.poppins(
                              fontSize: 18.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark,
                            ),
                          ),
                          Text(
                            st['title'] as String,
                            style: GoogleFonts.poppins(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMedium,
                            ),
                          ),
                          Text(
                            st['sub'] as String,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: AppColors.textLight,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildEarningsHighlightCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Earnings & Payouts',
                            style: GoogleFonts.poppins(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                          Text(
                            'Direct transfers configured to Bank Account',
                            style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textLight),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Payout requested! Processing to bank account.', style: GoogleFonts.poppins()),
                      backgroundColor: AppColors.statusGreen,
                    ),
                  );
                },
                icon: const Icon(Icons.arrow_outward_rounded, size: 15, color: Colors.white),
                label: Text(
                  'Withdraw Funds',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildIncomeStatBox('Today\'s Income', _incomeMap['today'] ?? '₹6,499', _incomeMap['todaySub'] ?? '+12%', AppColors.statusGreen),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildIncomeStatBox('Weekly Income', _incomeMap['weekly'] ?? '₹28,850', _incomeMap['weeklySub'] ?? 'Recent stays', AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildIncomeStatBox('Monthly Income', _incomeMap['monthly'] ?? '₹84,250', _incomeMap['monthlySub'] ?? 'Target: ₹1,00,000', AppColors.statusBlue),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            height: 120,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.accentLight.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(14),
            ),
            child: CustomPaint(
              painter: SmoothRevenueChartPainter(
                points: _revenuePoints,
                lineColor: AppColors.primary,
                fillGradient: [
                  AppColors.primary.withValues(alpha: 0.25),
                  AppColors.primary.withValues(alpha: 0.01),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeStatBox(String title, String amount, String subtitle, Color badgeColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accentLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textMedium,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            amount,
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: badgeColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPublishedServicesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Published Services',
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  'Manage and monitor live pet boarding packages',
                  style: GoogleFonts.poppins(fontSize: 11.5, color: AppColors.textLight),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: () => _openAddServiceModal(),
              icon: const Icon(Icons.add, color: AppColors.primary, size: 16),
              label: Text(
                'Add Service',
                style: GoogleFonts.poppins(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 900
                ? 3
                : constraints.maxWidth > 580
                    ? 2
                    : 1;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.74,
              ),
              itemCount: _services.length,
              itemBuilder: (context, index) => _buildServiceCard(_services[index]),
            );
          },
        ),
      ],
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> svc) {
    final bool isActive = svc['status'] == 'Active';

    return HoverAnimatedContainer(
      builder: (isHovered) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.translationValues(0.0, isHovered ? -4.0 : 0.0, 0.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isHovered ? AppColors.primaryLight : AppColors.border,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isHovered ? 0.07 : 0.02),
                blurRadius: isHovered ? 14 : 6,
                offset: Offset(0, isHovered ? 6 : 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Container(
                      height: 135,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFEFE4DC), Color(0xFFF7E8DD)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Center(
                        child: Icon(Icons.pets_rounded, color: AppColors.primary, size: 36),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: isActive ? AppColors.statusGreen : Colors.grey.shade800,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          svc['status']?.toString() ?? 'Active',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 13),
                            const SizedBox(width: 3),
                            Text(
                              '${svc['rating'] ?? 5.0} (${svc['reviewsCount'] ?? 0})',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              svc['title']?.toString() ?? 'Pet Service',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₹${(svc['pricePerDay'] ?? 0).toInt()}/day  •  ₹${(svc['pricePerHour'] ?? 0).toInt()}/hr',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 5,
                              children: ((svc['petsAccepted'] as List<dynamic>?) ?? ['Dogs']).map((pet) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.accentLight,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    pet.toString(),
                                    style: GoogleFonts.poppins(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            const Divider(height: 10, color: AppColors.border),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '${svc['views'] ?? 0} Views • ${svc['bookings'] ?? 0} Bookings',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      color: AppColors.textLight,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Slots: ${svc['availableSlots'] ?? 0}/${svc['totalSlots'] ?? 4}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => _openAddServiceModal(initialService: svc),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 6),
                                      side: const BorderSide(color: AppColors.border),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text(
                                      'Edit',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: AppColors.textDark,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => _toggleServiceStatus(svc),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 6),
                                      side: BorderSide(
                                        color: isActive ? AppColors.statusOrange : AppColors.statusGreen,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text(
                                      isActive ? 'Pause' : 'Resume',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: isActive ? AppColors.statusOrange : AppColors.statusGreen,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                InkWell(
                                  onTap: () => _deleteService(svc),
                                  child: Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                      color: AppColors.statusRedBg,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.delete_outline_rounded,
                                        size: 15, color: AppColors.statusRed),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBookingOverviewTable() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent Bookings Overview',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    'Direct customer boarding & daycare requests',
                    style: GoogleFonts.poppins(fontSize: 11.5, color: AppColors.textLight),
                  ),
                ],
              ),
              OutlinedButton(
                onPressed: () => setState(() => _selectedNavIndex = 2),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'View All',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 24,
              horizontalMargin: 8,
              headingRowColor: WidgetStateProperty.all(AppColors.accentLight),
              dataRowMaxHeight: 64,
              columns: [
                DataColumn(label: Text('Pet', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 12))),
                DataColumn(label: Text('Owner', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 12))),
                DataColumn(label: Text('Package', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 12))),
                DataColumn(label: Text('Date & Time', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 12))),
                DataColumn(label: Text('Status', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 12))),
                DataColumn(label: Text('Payment', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 12))),
                DataColumn(label: Text('Actions', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 12))),
              ],
              rows: _bookings.map((b) {
                Color statusColor;
                Color statusBg;
                final statusStr = b['status']?.toString() ?? 'Pending';
                switch (statusStr) {
                  case 'Confirmed':
                    statusColor = AppColors.statusGreen;
                    statusBg = AppColors.statusGreenBg;
                    break;
                  case 'Pending':
                    statusColor = AppColors.statusOrange;
                    statusBg = AppColors.statusOrangeBg;
                    break;
                  case 'Completed':
                    statusColor = AppColors.statusBlue;
                    statusBg = AppColors.statusBlueBg;
                    break;
                  default:
                    statusColor = AppColors.statusRed;
                    statusBg = AppColors.statusRedBg;
                }

                return DataRow(
                  cells: [
                    DataCell(
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 16,
                            backgroundColor: AppColors.accent,
                            child: Icon(Icons.pets, size: 16, color: AppColors.primary),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                b['petName']?.toString() ?? 'Pet',
                                style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 12.5),
                              ),
                              Text(
                                b['petBreed']?.toString() ?? '',
                                style: GoogleFonts.poppins(fontSize: 10.5, color: AppColors.textLight),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 14,
                            backgroundColor: AppColors.accentLight,
                            child: Icon(Icons.person, size: 14, color: AppColors.primaryDark),
                          ),
                          const SizedBox(width: 8),
                          Text(b['ownerName']?.toString() ?? 'Customer', style: GoogleFonts.poppins(fontSize: 12)),
                        ],
                      ),
                    ),
                    DataCell(Text(b['package']?.toString() ?? 'Standard', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500))),
                    DataCell(
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(b['date']?.toString() ?? '', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
                          Text(b['time']?.toString() ?? '', style: GoogleFonts.poppins(fontSize: 10.5, color: AppColors.textLight)),
                        ],
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          statusStr,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ),
                    DataCell(Text(b['payment']?.toString() ?? 'Paid', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600))),
                    DataCell(
                      Row(
                        children: [
                          if (statusStr == 'Pending') ...[
                            IconButton(
                              icon: const Icon(Icons.check_circle_outline_rounded, size: 18, color: AppColors.statusGreen),
                              onPressed: () => _updateBookingStatus(b, 'Confirmed'),
                              tooltip: 'Accept Booking',
                            ),
                            IconButton(
                              icon: const Icon(Icons.cancel_outlined, size: 18, color: AppColors.statusRed),
                              onPressed: () => _updateBookingStatus(b, 'Rejected'),
                              tooltip: 'Reject Booking',
                            ),
                          ] else if (statusStr == 'Confirmed') ...[
                            IconButton(
                              icon: const Icon(Icons.task_alt_rounded, size: 18, color: AppColors.statusBlue),
                              onPressed: () => _updateBookingStatus(b, 'Completed'),
                              tooltip: 'Complete Stay',
                            ),
                          ],
                          IconButton(
                            icon: const Icon(Icons.remove_red_eye_outlined, size: 16, color: AppColors.textMedium),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  title: Text('Booking Details #${b['id']}', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Owner: ${b['ownerName']} (${b['customerEmail'] ?? ""})', style: GoogleFonts.poppins(fontSize: 13)),
                                      const SizedBox(height: 6),
                                      Text('Pet: ${b['petName']} (${b['petBreed'] ?? ""})', style: GoogleFonts.poppins(fontSize: 13)),
                                      const SizedBox(height: 6),
                                      Text('Dates: ${b['date']} (${b['time']})', style: GoogleFonts.poppins(fontSize: 13)),
                                      const SizedBox(height: 6),
                                      Text('Amount: ${b['payment']}', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                      if (b['notes'] != null && b['notes'].toString().isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Text('Notes: ${b['notes']}', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textLight)),
                                      ],
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: Text('Close', style: GoogleFonts.poppins(color: AppColors.primary)),
                                    ),
                                  ],
                                ),
                              );
                            },
                            tooltip: 'View Details',
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarScheduleSection() {
    final days = [
      {'day': 'Mon', 'date': '24', 'active': true, 'pets': 8},
      {'day': 'Tue', 'date': '25', 'active': false, 'pets': 10},
      {'day': 'Wed', 'date': '26', 'active': false, 'pets': 12},
      {'day': 'Thu', 'date': '27', 'active': false, 'pets': 7},
      {'day': 'Fri', 'date': '28', 'active': false, 'pets': 9},
      {'day': 'Sat', 'date': '29', 'active': false, 'pets': 14},
      {'day': 'Sun', 'date': '30', 'active': false, 'pets': 12},
    ];

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Weekly Schedule & Calendar',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    'October 2026 • Live Booking Calendar',
                    style: GoogleFonts.poppins(fontSize: 11.5, color: AppColors.textLight),
                  ),
                ],
              ),
              const Icon(Icons.calendar_month_outlined, color: AppColors.primary),
            ],
          ),
          const SizedBox(height: 18),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: days.map((d) {
                final bool isActive = d['active'] as bool;
                return Container(
                  width: 72,
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primary : AppColors.accentLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isActive ? AppColors.primaryDark : AppColors.border,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        d['day'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isActive ? Colors.white70 : AppColors.textLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        d['date'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isActive ? Colors.white : AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isActive ? Colors.white.withValues(alpha: 0.2) : AppColors.accent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${d['pets']} pets',
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: isActive ? Colors.white : AppColors.primaryDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentReviewsSection() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent Verified Reviews',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    'Real guest ratings after completed stay',
                    style: GoogleFonts.poppins(fontSize: 11.5, color: AppColors.textLight),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    _statsMap['rating'] ?? '4.95 ★',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            children: _reviews.map((r) {
              final ratingVal = r['rating'] is num ? (r['rating'] as num).toInt() : 5;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.accentLight.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 16,
                              backgroundColor: AppColors.accent,
                              child: Icon(Icons.person, color: AppColors.primary, size: 18),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  r['name']?.toString() ?? 'Verified Guest',
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 13),
                                ),
                                Text(
                                  r['pet']?.toString() ?? 'Pet Parent',
                                  style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textLight),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Row(
                          children: List.generate(
                            ratingVal,
                            (index) => const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      r['comment']?.toString() ?? '',
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        color: AppColors.textMedium,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRightSidebar() {
    final occupancyPct = double.tryParse((_statsMap['occupancyRate'] ?? '80').replaceAll('%', '')) ?? 80.0;

    return Column(
      children: [
        // Occupancy Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Live Capacity & Occupancy',
                style: GoogleFonts.poppins(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.textDark),
              ),
              Text(
                'Real-time space occupancy',
                style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textLight),
              ),
              const SizedBox(height: 20),
              Center(
                child: SizedBox(
                  width: 140,
                  height: 140,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(140, 140),
                        painter: CircularProgressChartPainter(
                          progress: occupancyPct / 100.0,
                          activeColor: AppColors.primary,
                          backgroundColor: AppColors.accentLight,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _statsMap['occupancyRate'] ?? '80%',
                            style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textDark),
                          ),
                          Text(
                            'Occupied',
                            style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textLight, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accentLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Active Slots',
                        style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textMedium),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _statsMap['occupancySub'] ?? '12/15 Available',
                      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Live Activity Log
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Live Host Activity',
                      style: GoogleFonts.poppins(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.textDark),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.stream_rounded, color: AppColors.statusGreen, size: 18),
                ],
              ),
              const SizedBox(height: 16),
              ..._notifications.take(4).map((n) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppColors.accentLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.pets, size: 14, color: AppColors.primary),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              n['title']?.toString() ?? 'Activity',
                              style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textDark),
                            ),
                            Text(
                              n['body']?.toString() ?? '',
                              style: GoogleFonts.poppins(fontSize: 10.5, color: AppColors.textMedium),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// ADD / EDIT SERVICE FULL PRODUCTION MODAL DIALOG
// ---------------------------------------------------------------------------
class AddServiceModalDialog extends StatefulWidget {
  final Map<String, dynamic>? initialService;
  final VoidCallback? onServiceSaved;

  const AddServiceModalDialog({super.key, this.initialService, this.onServiceSaved});

  @override
  State<AddServiceModalDialog> createState() => _AddServiceModalDialogState();
}

class _AddServiceModalDialogState extends State<AddServiceModalDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  // Controllers
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _priceHourController;
  late TextEditingController _priceDayController;
  late TextEditingController _maxPetsController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _pincodeController;
  late TextEditingController _notesController;

  // State Selections
  final List<String> _petTypes = ['Dogs', 'Cats', 'Birds', 'Rabbit', 'Others'];
  late Set<String> _selectedPetTypes;

  final List<String> _petSizes = ['Small', 'Medium', 'Large'];
  late Set<String> _selectedPetSizes;

  bool _foodIncluded = true;
  late Set<String> _selectedFoodTypes;

  bool _medicineSupport = true;
  bool _pickupDrop = false;
  bool _outdoorWalks = true;
  bool _emergencyVet = true;

  final TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  final TimeOfDay _endTime = const TimeOfDay(hour: 20, minute: 0);

  String _bookingDuration = '1 Week';

  final List<String> _amenities = [
    'Air Conditioning',
    'CCTV',
    'Play Area',
    'Separate Rooms',
    'Open Garden',
    'Pet Toys',
    'Bath Included',
    'Training Available',
    'Vaccinated Pets Only',
  ];
  late Set<String> _selectedAmenities;

  bool _liveAvailability = true;
  bool _instantBooking = true;

  @override
  void initState() {
    super.initState();
    final init = widget.initialService;
    _titleController = TextEditingController(text: init?['title']?.toString() ?? '');
    _descController = TextEditingController(text: init?['description']?.toString() ?? '');
    _priceHourController = TextEditingController(text: (init?['pricePerHour'] ?? 199).toString());
    _priceDayController = TextEditingController(text: (init?['pricePerDay'] ?? 1499).toString());
    _maxPetsController = TextEditingController(text: (init?['maxPets'] ?? 4).toString());
    _addressController = TextEditingController(text: init?['address']?.toString() ?? '');
    _cityController = TextEditingController(text: init?['city']?.toString() ?? 'Mumbai');
    _pincodeController = TextEditingController(text: init?['pincode']?.toString() ?? '400001');
    _notesController = TextEditingController(text: init?['notes']?.toString() ?? '');

    _selectedPetTypes = init?['petsAccepted'] != null
        ? Set<String>.from(init!['petsAccepted'] as List)
        : {'Dogs', 'Cats'};

    _selectedPetSizes = init?['petSizes'] != null
        ? Set<String>.from(init!['petSizes'] as List)
        : {'Small', 'Medium'};

    _selectedFoodTypes = init?['foodTypes'] != null
        ? Set<String>.from(init!['foodTypes'] as List)
        : {'Homemade', 'Dry Food'};

    _selectedAmenities = init?['amenities'] != null
        ? Set<String>.from(init!['amenities'] as List)
        : {'Air Conditioning', 'CCTV', 'Play Area', 'Open Garden', 'Vaccinated Pets Only'};

    if (init != null) {
      _foodIncluded = init['foodIncluded'] ?? true;
      _medicineSupport = init['medicineSupport'] ?? true;
      _pickupDrop = init['pickupDrop'] ?? false;
      _outdoorWalks = init['outdoorWalks'] ?? true;
      _emergencyVet = init['emergencyVet'] ?? true;
      _liveAvailability = init['liveAvailability'] ?? true;
      _instantBooking = init['instantBooking'] ?? true;
      _bookingDuration = init['bookingDuration']?.toString() ?? '1 Week';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priceHourController.dispose();
    _priceDayController.dispose();
    _maxPetsController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final payload = {
      'title': _titleController.text.trim(),
      'description': _descController.text.trim(),
      'price_per_day': double.tryParse(_priceDayController.text) ?? 1499.0,
      'price_per_hour': double.tryParse(_priceHourController.text) ?? 199.0,
      'max_pets': int.tryParse(_maxPetsController.text) ?? 4,
      'address': _addressController.text.trim(),
      'city': _cityController.text.trim(),
      'pincode': _pincodeController.text.trim(),
      'notes': _notesController.text.trim(),
      'food_included': _foodIncluded,
      'medicine_support': _medicineSupport,
      'pickup_drop': _pickupDrop,
      'outdoor_walks': _outdoorWalks,
      'emergency_vet': _emergencyVet,
      'live_availability': _liveAvailability,
      'instant_booking': _instantBooking,
      'booking_duration': _bookingDuration,
      'start_time': '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
      'end_time': '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}',
      'pets_accepted': _selectedPetTypes.toList(),
      'pet_sizes': _selectedPetSizes.toList(),
      'food_types': _selectedFoodTypes.toList(),
      'amenities': _selectedAmenities.toList(),
      'status': widget.initialService?['status'] ?? 'Active',
      'packages': [
        {
          'title': '${_titleController.text.trim()} Deluxe',
          'duration': _bookingDuration,
          'price': (double.tryParse(_priceDayController.text) ?? 1499.0) * 3,
          'features': ['Dedicated Suite', 'Custom Meals', 'Daily Play & Video'],
        }
      ],
    };

    Map<String, dynamic>? res;
    if (widget.initialService != null && widget.initialService!['id'] != null) {
      res = await ApiService.updateService(widget.initialService!['id'] as int, payload);
    } else {
      res = await ApiService.createService(payload);
    }

    setState(() => _isSaving = false);

    if (res != null && mounted) {
      Navigator.of(context).pop();
      widget.onServiceSaved?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.initialService != null
                ? '🎉 Pet Service Updated Successfully!'
                : '🎉 Pet Service Created & Published to Customer Dashboard!',
            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          backgroundColor: AppColors.statusGreen,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save service. Please verify fields and try again.', style: GoogleFonts.poppins()),
          backgroundColor: AppColors.statusRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;

    return Center(
      child: Container(
        width: isMobile ? screenWidth * 0.95 : 780,
        height: MediaQuery.of(context).size.height * 0.90,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              scrolledUnderElevation: 0,
              automaticallyImplyLeading: false,
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.add_business_rounded, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.initialService != null ? 'Edit Pet Boarding Service' : 'Create Pet Boarding Service',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Publish your boarding home details to receive verified bookings',
                          style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textLight),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: AppColors.textDark),
                ),
                const SizedBox(width: 8),
              ],
              bottom: const PreferredSize(
                preferredSize: Size.fromHeight(1),
                child: Divider(height: 1, color: AppColors.border),
              ),
            ),
            body: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('1. Basic Service Information', Icons.info_outline_rounded),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _titleController,
                      label: 'Service Title',
                      hint: 'e.g. Canine Villa & Private Garden Boarding',
                      validator: (v) => v == null || v.trim().isEmpty ? 'Title is required' : null,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _descController,
                      label: 'Description',
                      hint: 'Describe your boarding home, routine, care standards...',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _priceDayController,
                            label: 'Price per Day (₹)',
                            hint: '1499',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _buildTextField(
                            controller: _priceHourController,
                            label: 'Price per Hour (₹)',
                            hint: '199',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _buildTextField(
                            controller: _maxPetsController,
                            label: 'Max Pet Slots',
                            hint: '4',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSectionHeader('2. Location & Facility Address', Icons.location_on_outlined),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _addressController,
                      label: 'Street Address',
                      hint: 'Bungalow 14, Silver Oak Estate',
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _cityController,
                            label: 'City',
                            hint: 'Mumbai',
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _buildTextField(
                            controller: _pincodeController,
                            label: 'Pincode',
                            hint: '400050',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSectionHeader('3. Pets Accepted & Sizing', Icons.pets_rounded),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: _petTypes.map((type) {
                        final isSel = _selectedPetTypes.contains(type);
                        return FilterChip(
                          label: Text(type, style: GoogleFonts.poppins(fontSize: 12, color: isSel ? Colors.white : AppColors.textDark)),
                          selected: isSel,
                          selectedColor: AppColors.primary,
                          backgroundColor: AppColors.accentLight,
                          checkmarkColor: Colors.white,
                          onSelected: (val) {
                            setState(() {
                              if (val) {
                                _selectedPetTypes.add(type);
                              } else {
                                _selectedPetTypes.remove(type);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    Text('Accepted Pet Sizes:', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: _petSizes.map((size) {
                        final isSel = _selectedPetSizes.contains(size);
                        return FilterChip(
                          label: Text(size, style: GoogleFonts.poppins(fontSize: 12, color: isSel ? Colors.white : AppColors.textDark)),
                          selected: isSel,
                          selectedColor: AppColors.primary,
                          backgroundColor: AppColors.accentLight,
                          checkmarkColor: Colors.white,
                          onSelected: (val) {
                            setState(() {
                              if (val) {
                                _selectedPetSizes.add(size);
                              } else {
                                _selectedPetSizes.remove(size);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    _buildSectionHeader('4. Care Inclusions & Amenities', Icons.verified_outlined),
                    const SizedBox(height: 10),
                    _buildSwitchTile('Food Included in Stay', _foodIncluded, (v) => setState(() => _foodIncluded = v)),
                    _buildSwitchTile('Medical / Medication Support', _medicineSupport, (v) => setState(() => _medicineSupport = v)),
                    _buildSwitchTile('Pick-up & Drop Facility', _pickupDrop, (v) => setState(() => _pickupDrop = v)),
                    _buildSwitchTile('Daily Outdoor Walks & Exercise', _outdoorWalks, (v) => setState(() => _outdoorWalks = v)),
                    _buildSwitchTile('24/7 Emergency Vet On Call', _emergencyVet, (v) => setState(() => _emergencyVet = v)),
                    const SizedBox(height: 14),
                    Text('Amenities & Features:', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: _amenities.map((amenity) {
                        final isSel = _selectedAmenities.contains(amenity);
                        return FilterChip(
                          label: Text(amenity, style: GoogleFonts.poppins(fontSize: 11.5, color: isSel ? Colors.white : AppColors.textDark)),
                          selected: isSel,
                          selectedColor: AppColors.primary,
                          backgroundColor: AppColors.accentLight,
                          checkmarkColor: Colors.white,
                          onSelected: (val) {
                            setState(() {
                              if (val) {
                                _selectedAmenities.add(amenity);
                              } else {
                                _selectedAmenities.remove(amenity);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
            bottomNavigationBar: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.border, width: 1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('Cancel', style: GoogleFonts.poppins(color: AppColors.textDark, fontWeight: FontWeight.w600)),
                  ),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            widget.initialService != null ? 'Update Service' : 'Publish Service',
                            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textDark),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(fontSize: 12.5, color: AppColors.textLight),
            filled: true,
            fillColor: AppColors.accentLight.withValues(alpha: 0.4),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile(String title, bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accentLight.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w500)),
          Switch(
            value: value,
            activeThumbColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CUSTOM CHART PAINTERS
// ---------------------------------------------------------------------------
class MiniSparklinePainter extends CustomPainter {
  final List<double> data;
  final Color lineColor;

  MiniSparklinePainter({required this.data, required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final minVal = data.reduce(math.min);
    final maxVal = data.reduce(math.max);
    final range = (maxVal - minVal == 0) ? 1.0 : (maxVal - minVal);

    final path = Path();
    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final y = size.height - (((data[i] - minVal) / range) * (size.height - 4) + 2);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class SmoothRevenueChartPainter extends CustomPainter {
  final List<double> points;
  final Color lineColor;
  final List<Color> fillGradient;

  SmoothRevenueChartPainter({
    required this.points,
    required this.lineColor,
    required this.fillGradient,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final maxVal = points.reduce(math.max);
    final minVal = points.reduce(math.min);
    final range = (maxVal - minVal == 0) ? 1.0 : (maxVal - minVal);

    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < points.length; i++) {
      final x = (i / (points.length - 1)) * size.width;
      final y = size.height - (((points[i] - minVal) / range) * (size.height - 20) + 10);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        final prevX = ((i - 1) / (points.length - 1)) * size.width;
        final prevY = size.height - (((points[i - 1] - minVal) / range) * (size.height - 20) + 10);
        final controlX1 = prevX + (x - prevX) / 2;
        path.cubicTo(controlX1, prevY, controlX1, y, x, y);
        fillPath.cubicTo(controlX1, prevY, controlX1, y, x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: fillGradient,
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class CircularProgressChartPainter extends CustomPainter {
  final double progress;
  final Color activeColor;
  final Color backgroundColor;

  CircularProgressChartPainter({
    required this.progress,
    required this.activeColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke;

    final activePaint = Paint()
      ..color = activeColor
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, bgPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
