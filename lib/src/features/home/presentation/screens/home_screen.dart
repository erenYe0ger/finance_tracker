import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../auth/presentation/providers/auth_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final List<_TransactionEntry> _transactions = [];

  double get _income => _transactions
      .where((transaction) => !transaction.isExpense)
      .fold(0, (total, transaction) => total + transaction.amount);

  double get _expenses => _transactions
      .where((transaction) => transaction.isExpense)
      .fold(0, (total, transaction) => total + transaction.amount);

  Future<void> _addTransaction() async {
    final transaction = await showModalBottomSheet<_TransactionEntry>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _AddTransactionSheet(),
    );

    if (transaction == null || !mounted) return;
    setState(() => _transactions.insert(0, transaction));
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Transaction added')));
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    await ref.read(authProvider.notifier).logout();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final balance = _income - _expenses;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Finance Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Image.asset(
                'assets/images/app_logo.png',
                width: 80,
                height: 80,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Welcome${user != null ? ', ${user.email}' : ''}!',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 28),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Quick Stats',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatItem(
                          label: 'Balance',
                          value: _currency(balance),
                          icon: Icons.account_balance,
                        ),
                        _StatItem(
                          label: 'Income',
                          value: _currency(_income),
                          icon: Icons.trending_up,
                        ),
                        _StatItem(
                          label: 'Expenses',
                          value: _currency(_expenses),
                          icon: Icons.trending_down,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Recent transactions', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            if (_transactions.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'No transactions yet. Tap Add Transaction to add one.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              ..._transactions.map(
                (transaction) => Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: transaction.isExpense
                          ? theme.colorScheme.errorContainer
                          : theme.colorScheme.secondaryContainer,
                      child: Icon(
                        transaction.isExpense
                            ? Icons.south_west
                            : Icons.north_east,
                        color: transaction.isExpense
                            ? theme.colorScheme.error
                            : theme.colorScheme.secondary,
                      ),
                    ),
                    title: Text(transaction.description),
                    subtitle: Text(
                      DateFormat('MMM d').format(transaction.date),
                    ),
                    trailing: Text(
                      '${transaction.isExpense ? '−' : '+'}${_currency(transaction.amount)}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: transaction.isExpense
                            ? theme.colorScheme.error
                            : theme.colorScheme.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addTransaction,
        icon: const Icon(Icons.add),
        label: const Text('Add Transaction'),
      ),
    );
  }

  String _currency(double value) => '₹${value.toStringAsFixed(2)}';
}

class _AddTransactionSheet extends StatefulWidget {
  const _AddTransactionSheet();

  @override
  State<_AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<_AddTransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  bool _isExpense = true;

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      _TransactionEntry(
        description: _descriptionController.text.trim(),
        amount: double.parse(_amountController.text.trim()),
        isExpense: _isExpense,
        date: DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + keyboardInset),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Add transaction', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 20),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('Expense')),
                ButtonSegment(value: false, label: Text('Income')),
              ],
              selected: {_isExpense},
              onSelectionChanged: (selection) =>
                  setState(() => _isExpense = selection.first),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter a description'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '₹ ',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final amount = double.tryParse(value?.trim() ?? '');
                return amount == null || !amount.isFinite || amount <= 0
                    ? 'Enter an amount greater than zero'
                    : null;
              },
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.check),
              label: const Text('Save transaction'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionEntry {
  const _TransactionEntry({
    required this.description,
    required this.amount,
    required this.isExpense,
    required this.date,
  });

  final String description;
  final double amount;
  final bool isExpense;
  final DateTime date;
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, size: 28, color: theme.colorScheme.primary),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
