import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/utils.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../domain/entities/transaction.dart';
import '../cubit/transaction_cubit.dart';
import '../cubit/transaction_state.dart';
import '../widgets/summary_card.dart';
import '../widgets/transaction_card.dart';
import '../widgets/expense_pie_chart.dart';
import '../widgets/monthly_bar_chart.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  int _currentNav = 0;
  late AnimationController _fabAnimController;

  @override
  void initState() {
    super.initState();
    _fabAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fabAnimController.forward();
    context.read<TransactionCubit>().loadAll();
  }

  @override
  void dispose() {
    _fabAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentNav,
        children: [
          _buildDashboard(),
          _buildTransactionList(),
          _buildCharts(),
          _buildProfile(),
        ],
      ),
      floatingActionButton: ScaleTransition(
        scale: CurvedAnimation(parent: _fabAnimController, curve: Curves.elasticOut),
        child: FloatingActionButton(
          onPressed: () async {
            final result = await Navigator.of(context).pushNamed('/add-transaction');
            if (result == true && context.mounted) {
              context.read<TransactionCubit>().loadAll();
            }
          },
          child: const Icon(Icons.add, size: 28),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: BottomNavigationBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        currentIndex: _currentNav,
        onTap: (i) => setState(() => _currentNav = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), activeIcon: Icon(Icons.receipt_long), label: 'Transaksi'),
          BottomNavigationBarItem(icon: Icon(Icons.pie_chart_outline), activeIcon: Icon(Icons.pie_chart), label: 'Grafik'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  // ─── DASHBOARD TAB ──────────────────────────────────────
  Widget _buildDashboard() {
    return BlocBuilder<TransactionCubit, TransactionState>(
      builder: (context, state) {
        if (state is TransactionLoading) return _buildShimmer();
        if (state is TransactionError) return _buildError(state.message);
        if (state is TransactionLoaded) {
          return RefreshIndicator(
            onRefresh: () => context.read<TransactionCubit>().loadAll(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              children: [
                SafeArea(child: _buildGreeting()),
                const SizedBox(height: 20),
                SummaryCard(summary: state.summary),
                const SizedBox(height: 24),
                _buildSectionTitle('Transaksi Terbaru'),
                const SizedBox(height: 12),
                if (state.transactions.isEmpty)
                  _buildEmptyState()
                else
                  ...state.transactions.take(5).map(
                    (tx) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: TransactionCard(
                        transaction: tx,
                        onTap: () => _showTransactionDetail(tx),
                        onDelete: () => _confirmDelete(tx),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildGreeting() {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        final name = authState is Authenticated ? authState.user.name : 'User';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Halo, $name! 👋',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              AppFormatters.relativeDate(DateTime.now()),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        );
      },
    );
  }

  // ─── TRANSACTION LIST TAB ───────────────────────────────
  Widget _buildTransactionList() {
    return BlocBuilder<TransactionCubit, TransactionState>(
      builder: (context, state) {
        if (state is TransactionLoading) return _buildShimmer();
        if (state is TransactionError) return _buildError(state.message);
        if (state is TransactionLoaded) {
          if (state.transactions.isEmpty) {
            return Center(child: _buildEmptyState());
          }
          return RefreshIndicator(
            onRefresh: () => context.read<TransactionCubit>().loadAll(),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              itemCount: state.transactions.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        'Semua Transaksi',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                }
                final tx = state.transactions[index - 1];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TransactionCard(
                    transaction: tx,
                    onTap: () => _showTransactionDetail(tx),
                    onDelete: () => _confirmDelete(tx),
                  ),
                );
              },
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  // ─── CHARTS TAB ─────────────────────────────────────────
  Widget _buildCharts() {
    return BlocBuilder<TransactionCubit, TransactionState>(
      builder: (context, state) {
        if (state is TransactionLoading) return _buildShimmer();
        if (state is TransactionError) return _buildError(state.message);
        if (state is TransactionLoaded) {
          return RefreshIndicator(
            onRefresh: () => context.read<TransactionCubit>().loadAll(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              children: [
                SafeArea(
                  child: Text(
                    'Analisis Keuangan',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 20),
                if (state.summary.expenseByCategory.isNotEmpty) ...[
                  _buildSectionTitle('Pengeluaran per Kategori'),
                  const SizedBox(height: 12),
                  ExpensePieChart(breakdown: state.summary.expenseByCategory),
                  const SizedBox(height: 24),
                ],
                if (state.summary.monthlyTrend.isNotEmpty) ...[
                  _buildSectionTitle('Tren Bulanan'),
                  const SizedBox(height: 12),
                  MonthlyBarChart(trend: state.summary.monthlyTrend),
                ],
                if (state.summary.expenseByCategory.isEmpty && state.summary.monthlyTrend.isEmpty)
                  _buildEmptyState(),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  // ─── PROFILE TAB ────────────────────────────────────────
  Widget _buildProfile() {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        final user = authState is Authenticated ? authState.user : null;
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const SizedBox(height: 20),
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(
                    (user?.name ?? 'U').substring(0, 1).toUpperCase(),
                    style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  user?.name ?? 'User',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              Center(
                child: Text(
                  user?.email ?? '',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              _buildProfileTile(
                icon: Icons.dark_mode,
                title: 'Mode Gelap',
                trailing: Switch(
                  value: Theme.of(context).brightness == Brightness.dark,
                  onChanged: (_) => Navigator.of(context).pushNamed('/settings'),
                  activeThumbColor: AppColors.primary,
                ),
              ),
              _buildProfileTile(
                icon: Icons.settings,
                title: 'Pengaturan',
                onTap: () => Navigator.of(context).pushNamed('/settings'),
              ),
              const SizedBox(height: 16),
              _buildProfileTile(
                icon: Icons.logout,
                title: 'Keluar',
                color: AppColors.expense,
                onTap: () => _confirmLogout(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileTile({
    required IconData icon,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
    Color? color,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: color ?? AppColors.primary),
        title: Text(title, style: TextStyle(color: color)),
        trailing: trailing ?? (onTap != null ? Icon(Icons.chevron_right, color: color) : null),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ─── HELPERS ────────────────────────────────────────────

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 64, color: Theme.of(context).dividerColor),
          const SizedBox(height: 16),
          Text(
            'Belum ada transaksi',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap tombol + untuk menambah transaksi',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.expense),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => context.read<TransactionCubit>().loadAll(),
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).dividerColor,
      highlightColor: Theme.of(context).scaffoldBackgroundColor,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: List.generate(5, (i) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            height: i == 0 ? 160 : 72,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        )),
      ),
    );
  }

  void _showTransactionDetail(Transaction tx) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: tx.isIncome ? AppColors.incomeBg : AppColors.expenseBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    tx.isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                    color: tx.isIncome ? AppColors.income : AppColors.expense,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tx.description.isEmpty ? (tx.categoryName ?? 'Transaksi') : tx.description,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                      Text(tx.categoryName ?? '-', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _detailRow('Jumlah', '${tx.isIncome ? "+" : "-"} ${AppFormatters.currency(tx.amount)}',
              valueColor: tx.isIncome ? AppColors.income : AppColors.expense),
            _detailRow('Tipe', tx.isIncome ? 'Pemasukan' : 'Pengeluaran'),
            _detailRow('Tanggal', AppFormatters.date(tx.date)),
            _detailRow('Kategori', tx.categoryName ?? '-'),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.of(context).pushNamed('/edit-transaction', arguments: tx);
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _confirmDelete(tx);
                    },
                    icon: const Icon(Icons.delete),
                    label: const Text('Hapus'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.expense),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).textTheme.bodySmall?.color)),
          Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600, color: valueColor)),
        ],
      ),
    );
  }

  void _confirmDelete(Transaction tx) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Transaksi?'),
        content: const Text('Transaksi yang dihapus tidak dapat dikembalikan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<TransactionCubit>().deleteTransaction(tx.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.expense),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Keluar?'),
        content: const Text('Apakah kamu yakin ingin keluar dari akun?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthCubit>().logout();
              Navigator.of(context).pushReplacementNamed('/login');
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.expense),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }
}
