import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class FinancialManagementPage extends StatefulWidget {
  const FinancialManagementPage({super.key});

  @override
  State<FinancialManagementPage> createState() =>
      _FinancialManagementPageState();
}

class _FinancialManagementPageState extends State<FinancialManagementPage>
    with SingleTickerProviderStateMixin {
  
  late TabController _tabController;
  String selectedFilter = 'This Month';
  DateTimeRange? customRange;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  DateTime? _getStartDate() {
    final now = DateTime.now();
    if (selectedFilter == 'Today') {
      return DateTime(now.year, now.month, now.day);
    }
    if (selectedFilter == 'This Month') return DateTime(now.year, now.month, 1);
    return null;
  }

  DateTime _getEndDate() {
    final now = DateTime.now();
    if (selectedFilter == 'Today') {
      return DateTime(now.year, now.month, now.day, 23, 59, 59);
    }
    return DateTime(now.year, now.month, now.day, 23, 59, 59);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Financials',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Theme.of(context).cardColor,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.5),
          indicatorColor: Theme.of(context).colorScheme.primary,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Payment Packages'),
            Tab(text: 'Revenue Overview'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildPackagesTab(), _buildRevenueOverviewStream()],
      ),
    );
  }

  // Local state for package prices
  final Map<String, String> _packagePrices = {
    'Session-based Packages': '500',
    'Monthly Rehab Packages': '15,000',
    'Pediatric Therapy Packages': 'Custom',
    'Hybrid Therapy Packages': 'Flexible',
    'Online Consulting': '999',
  };

  Future<void> _editPrice(String title, String currentPrice) async {
    final controller = TextEditingController(text: currentPrice);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Update Price',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Set new price for $title',
              style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                prefixText: '₹ ',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.outfit(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final newPrice = controller.text;
              Navigator.pop(context); // close dialog immediately for UX
              try {
                await ApiService.post('/settings', {
                  'key': 'pkg_$title',
                  'value': newPrice,
                }, includeAuth: true);
                if (mounted) setState(() {});
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to update: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Save Price',
              style: GoogleFonts.outfit(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackagesTab() {
    return FutureBuilder(
      future: ApiService.get('/settings', includeAuth: true),
      builder: (context, snapshot) {
        final settings = {
          for (var s in ((snapshot.data as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? <Map<String, dynamic>>[])) s['key']: s['value'],
        };
        
        String getPrice(String title) {
          return settings['pkg_$title']?.toString() ?? _packagePrices[title]!;
        }

        return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildPackageCategory(
          'Session-based Packages',
          'Pay-per-session or bulk session credits',
          Icons.calendar_month_rounded,
          const Color(0xFF6366F1),
          getPrice('Session-based Packages'),
        ),
        const SizedBox(height: 16),
        _buildPackageCategory(
          'Monthly Rehab Packages',
          'Comprehensive monthly recovery programs',
          Icons.healing_rounded,
          const Color(0xFF10B981),
          getPrice('Monthly Rehab Packages'),
        ),
        const SizedBox(height: 16),
        _buildPackageCategory(
          'Pediatric Therapy Packages',
          'Specialized therapy for children',
          Icons.child_care_rounded,
          const Color(0xFFEC4899),
          getPrice('Pediatric Therapy Packages'),
        ),
        const SizedBox(height: 16),
        _buildPackageCategory(
          'Hybrid Therapy Packages',
          'Combination of in-clinic & home visits',
          Icons.home_work_rounded,
          const Color(0xFFF59E0B),
          getPrice('Hybrid Therapy Packages'),
        ),
        const SizedBox(height: 16),
        _buildPackageCategory(
          'Online Consulting',
          'Virtual assessment and guidance',
          Icons.videocam_rounded,
          const Color(0xFF3B82F6),
          getPrice('Online Consulting'),
        ),
      ],
    );
      },
    );
  }

  Widget _buildPackageCategory(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    String priceInfo,
  ) {
    return InkWell(
      onTap: () => _editPrice(title, priceInfo),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withValues(alpha: 0.08)
                : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 80,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    (double.tryParse(priceInfo.replaceAll(',', '')) != null)
                        ? '₹$priceInfo'
                        : priceInfo,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: Color(0xFFCBD5E1),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueOverviewStream() {
    return Column(
      children: [
        _buildDateFilter(),
        Expanded(
          child: FutureBuilder(
            future: ApiService.get('/sessions', includeAuth: true),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.wifi_off_rounded,
                        size: 48,
                        color: Colors.redAccent.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Financial Data Offline',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w700,
                          color: Colors.redAccent,
                        ),
                      ),
                      Text(
                        'Please reconnect to see revenue overview',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                );
              }
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final allSessions = (snapshot.data as List?)?.cast<Map<String, dynamic>>() ?? [];
              final startDate = _getStartDate();
              final endDate = _getEndDate();

              final filteredSessions = allSessions.where((s) {
                DateTime? sessionDate;
                try {
                  if (s['scheduled_date'] != null) {
                    sessionDate = DateTime.parse(s['scheduled_date']);
                  }
                } catch (_) {}
                sessionDate ??= DateTime.tryParse(s['created_at'] ?? '');
                if (sessionDate == null) return false;

                if (selectedFilter == 'Custom' && customRange != null) {
                  return sessionDate.isAfter(
                        customRange!.start.subtract(const Duration(seconds: 1)),
                      ) &&
                      sessionDate.isBefore(
                        customRange!.end.add(const Duration(days: 1)),
                      );
                }

                if (startDate != null) {
                  return sessionDate.isAfter(
                        startDate.subtract(const Duration(seconds: 1)),
                      ) &&
                      sessionDate.isBefore(
                        endDate.add(const Duration(seconds: 1)),
                      );
                }
                return true;
              }).toList();

              return _buildRevenueTabContent(filteredSessions, allSessions);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDateFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: Colors.transparent,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _filterChip('Today'),
            const SizedBox(width: 8),
            _filterChip('This Month'),
            const SizedBox(width: 8),
            _filterChip('Custom'),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label) {
    final isSelected = selectedFilter == label;
    return GestureDetector(
      onTap: () async {
        if (label == 'Custom') {
          final picked = await showDateRangePicker(
            context: context,
            firstDate: DateTime(2024),
            lastDate: DateTime.now().add(const Duration(days: 30)),
            builder: (context, child) {
              return Theme(
                data: ThemeData.light().copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: Color(0xFF0F172A),
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: Color(0xFF0F172A),
                  ),
                  appBarTheme: const AppBarTheme(
                    systemOverlayStyle: SystemUiOverlayStyle.dark,
                  ),
                ),
                child: child!,
              );
            },
          );
          if (picked != null) {
            setState(() {
              selectedFilter = label;
              customRange = picked;
            });
          }
        } else {
          setState(() {
            selectedFilter = label;
            customRange = null;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected
                ? Colors.white
                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }

  Widget _buildRevenueTabContent(
    List<Map<String, dynamic>> sessions,
    List<Map<String, dynamic>> allSessions,
  ) {
    double totalPaid = 0;
    double totalPending = 0;
    double lifetimeRegistryRevenue = 0;

    for (var s in allSessions) {
      double amount =
          double.tryParse(s['fee_charged']?.toString() ?? '') ??
          double.tryParse(s['payment_amount']?.toString() ?? '') ??
          0;
      if (s['status'] == 'completed') lifetimeRegistryRevenue += amount;
    }

    for (var s in sessions) {
      double amount =
          double.tryParse(s['fee_charged']?.toString() ?? '') ??
          double.tryParse(s['payment_amount']?.toString() ?? '') ??
          0;
      if (s['status'] == 'completed') {
        totalPaid += amount;
      } else {
        totalPending += amount;
      }
    }

    double totalValue = totalPaid + totalPending;
    double recoveryRate = totalValue > 0 ? (totalPaid / totalValue) * 100 : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _lifetimeCard(lifetimeRegistryRevenue),
          const SizedBox(height: 32),
          _sectionTitle('PERIOD PERFORMANCE'),
          const SizedBox(height: 16),
          _statCard(
            'Paid in Period',
            '₹${totalPaid.toStringAsFixed(0)}',
            Icons.check_circle_rounded,
            const Color(0xFF10B981),
          ),
          const SizedBox(height: 16),
          _statCard(
            'Pending in Period',
            '₹${totalPending.toStringAsFixed(0)}',
            Icons.pending_rounded,
            const Color(0xFFF59E0B),
          ),
          const SizedBox(height: 16),
          _statCard(
            'Projected Revenue',
            '₹${totalValue.toStringAsFixed(0)}',
            Icons.account_balance_wallet_rounded,
            const Color(0xFF6366F1),
          ),
          const SizedBox(height: 32),
          _collectionRateCard(recoveryRate, totalPaid, totalValue),
        ],
      ),
    );
  }

  Widget _lifetimeCard(double amount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LIFETIME REGISTRY REVENUE',
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: Colors.white.withValues(alpha: 0.6),
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '₹${amount.toStringAsFixed(0)}',
            style: GoogleFonts.outfit(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          Text(
            'Total earnings from all clinical records',
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: const Color(0xFF3B82F6),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.onSurface,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _collectionRateCard(double rate, double paid, double total) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFF1F5F9),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Collection Rate',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              Text(
                '${rate.toStringAsFixed(1)}%',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: total > 0 ? paid / total : 0,
              minHeight: 12,
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.05)
                  : const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(
                rate > 80 ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Vulnerability (At Risk)',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              Text(
                '₹${(total - paid).toStringAsFixed(0)}',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
