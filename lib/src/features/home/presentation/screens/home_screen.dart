import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/errors/app_exceptions.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../transactions/data/transaction_repository.dart';
import '../../../transactions/domain/transaction_record.dart';

enum _DateFilter { thisMonth, allDates, customRange }

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  List<TransactionRecord> _transactions = const [];
  _DateFilter _dateFilter = _DateFilter.thisMonth;
  DateTimeRange? _customRange;
  TransactionType? _typeFilter;
  String? _categoryFilter;
  bool _isLoading = true;
  bool _isMutating = false;
  Object? _loadError;
  int _loadRequest = 0;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  DateTime? get _startDate {
    switch (_dateFilter) {
      case _DateFilter.thisMonth:
        final now = DateTime.now();
        return DateTime(now.year, now.month);
      case _DateFilter.customRange:
        return _customRange?.start;
      case _DateFilter.allDates:
        return null;
    }
  }

  DateTime? get _endDate {
    switch (_dateFilter) {
      case _DateFilter.thisMonth:
        return DateTime.now();
      case _DateFilter.customRange:
        return _customRange?.end;
      case _DateFilter.allDates:
        return null;
    }
  }

  Future<void> _loadTransactions() async {
    final request = ++_loadRequest;
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final transactions = await ref.read(transactionRepositoryProvider).list(
            startDate: _startDate,
            endDate: _endDate,
            type: _typeFilter,
            category: _categoryFilter,
          );
      if (!mounted || request != _loadRequest) return;
      setState(() {
        _transactions = transactions;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted || request != _loadRequest) return;
      setState(() {
        _loadError = error;
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDateFilter(_DateFilter? filter) async {
    if (filter == null) return;
    if (filter == _DateFilter.customRange) {
      final now = DateTime.now();
      final selected = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2000),
        lastDate: now,
        initialDateRange: _customRange ??
            DateTimeRange(start: DateTime(now.year, now.month), end: now),
      );
      if (selected == null || !mounted) return;
      setState(() {
        _customRange = selected;
        _dateFilter = _DateFilter.customRange;
      });
    } else {
      setState(() => _dateFilter = filter);
    }
    _loadTransactions();
  }

  Future<void> _addTransaction() => _editTransaction();

  Future<void> _editTransaction([TransactionRecord? transaction]) async {
    final draft = await showModalBottomSheet<TransactionDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _TransactionFormSheet(transaction: transaction),
    );
    if (draft == null || !mounted) return;

    setState(() => _isMutating = true);
    try {
      final repository = ref.read(transactionRepositoryProvider);
      if (transaction == null) {
        await repository.create(draft);
      } else {
        await repository.update(transaction.id, draft);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(transaction == null
              ? 'Transaction added'
              : 'Transaction updated'),
        ),
      );
      await _loadTransactions();
    } catch (error) {
      if (mounted) _showMessage('Could not save transaction: ${_errorText(error)}');
    } finally {
      if (mounted) setState(() => _isMutating = false);
    }
  }

  Future<void> _deleteTransaction(TransactionRecord transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete transaction?'),
        content: Text('“${transaction.description}” will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isMutating = true);
    try {
      await ref.read(transactionRepositoryProvider).delete(transaction.id);
      if (!mounted) return;
      _showMessage('Transaction deleted');
      await _loadTransactions();
    } catch (error) {
      if (mounted) _showMessage('Could not delete transaction: ${_errorText(error)}');
    } finally {
      if (mounted) setState(() => _isMutating = false);
    }
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

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _errorText(Object error) {
    if (error is AppException) return error.message;
    if (error is DioException && error.error is AppException) {
      return (error.error as AppException).message;
    }
    return 'Please try again.';
  }

  int _totalFor(TransactionType type) => _transactions
      .where((transaction) => transaction.type == type)
      .fold(0, (total, transaction) => total + transaction.amountPaise);

  String _money(int paise) =>
      '₹${(paise ~/ 100).toString()}.${(paise % 100).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final income = _totalFor(TransactionType.income);
    final expenses = _totalFor(TransactionType.expense);

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
      body: RefreshIndicator(
        onRefresh: _loadTransactions,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          children: [
            Center(
              child: Image.asset('assets/images/app_logo.png', width: 64, height: 64),
            ),
            const SizedBox(height: 12),
            Text(
              'Welcome${user != null ? ', ${user.email}' : ''}!',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text('Quick Stats', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatItem(label: 'Balance', value: _money(income - expenses), icon: Icons.account_balance),
                        _StatItem(label: 'Income', value: _money(income), icon: Icons.trending_up),
                        _StatItem(label: 'Expenses', value: _money(expenses), icon: Icons.trending_down),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Transactions', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                DropdownButton<_DateFilter>(
                  value: _dateFilter,
                  items: const [
                    DropdownMenuItem(value: _DateFilter.thisMonth, child: Text('This month')),
                    DropdownMenuItem(value: _DateFilter.allDates, child: Text('All dates')),
                    DropdownMenuItem(value: _DateFilter.customRange, child: Text('Custom range')),
                  ],
                  onChanged: _isMutating ? null : _selectDateFilter,
                ),
                DropdownButton<TransactionType?>(
                  value: _typeFilter,
                  hint: const Text('All types'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All types')),
                    DropdownMenuItem(value: TransactionType.expense, child: Text('Expense')),
                    DropdownMenuItem(value: TransactionType.income, child: Text('Income')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _typeFilter = value;
                      if (value != null &&
                          _categoryFilter != null &&
                          !TransactionCategories.forType(value).contains(_categoryFilter)) {
                        _categoryFilter = null;
                      }
                    });
                    _loadTransactions();
                  },
                ),
                DropdownButton<String?>(
                  value: _categoryFilter,
                  hint: const Text('All categories'),
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('All categories')),
                    ...(_typeFilter == null
                            ? TransactionCategories.all
                            : TransactionCategories.forType(_typeFilter!))
                        .map((category) => DropdownMenuItem(value: category, child: Text(category))),
                  ],
                  onChanged: (value) {
                    setState(() => _categoryFilter = value);
                    _loadTransactions();
                  },
                ),
              ],
            ),
            if (_loadError != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 36),
                child: Column(
                  children: [
                    const Icon(Icons.cloud_off, size: 40),
                    const SizedBox(height: 8),
                    Text('Could not load transactions. ${_errorText(_loadError!)}', textAlign: TextAlign.center),
                    TextButton.icon(onPressed: _loadTransactions, icon: const Icon(Icons.refresh), label: const Text('Retry')),
                  ],
                ),
              )
            else if (_isLoading && _transactions.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_transactions.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Text(
                  'No transactions for this view. Add a transaction to get started.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              )
            else ...[
              if (_isLoading) const LinearProgressIndicator(),
              ..._transactions.map(_transactionTile),
            ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isMutating ? null : _addTransaction,
        icon: const Icon(Icons.add),
        label: const Text('Add Transaction'),
      ),
    );
  }

  Widget _transactionTile(TransactionRecord transaction) {
    final theme = Theme.of(context);
    final isExpense = transaction.type == TransactionType.expense;
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isExpense ? theme.colorScheme.errorContainer : theme.colorScheme.secondaryContainer,
          child: Icon(isExpense ? Icons.south_west : Icons.north_east),
        ),
        title: Text(transaction.description),
        subtitle: Text('${transaction.category} · ${DateFormat('MMM d, y').format(transaction.date)}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${isExpense ? '−' : '+'}${_money(transaction.amountPaise)}',
              style: theme.textTheme.titleSmall?.copyWith(
                color: isExpense ? theme.colorScheme.error : theme.colorScheme.secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            PopupMenuButton<String>(
              enabled: !_isMutating,
              onSelected: (action) {
                if (action == 'edit') _editTransaction(transaction);
                if (action == 'delete') _deleteTransaction(transaction);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionFormSheet extends StatefulWidget {
  const _TransactionFormSheet({this.transaction});

  final TransactionRecord? transaction;

  @override
  State<_TransactionFormSheet> createState() => _TransactionFormSheetState();
}

class _TransactionFormSheetState extends State<_TransactionFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descriptionController;
  late final TextEditingController _amountController;
  late TransactionType _type;
  late String _category;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    final transaction = widget.transaction;
    _descriptionController = TextEditingController(text: transaction?.description ?? '');
    _amountController = TextEditingController(
      text: transaction == null
          ? ''
          : '${transaction.amountPaise ~/ 100}.${(transaction.amountPaise % 100).toString().padLeft(2, '0')}',
    );
    _type = transaction?.type ?? TransactionType.expense;
    _category = transaction?.category ?? TransactionCategories.forType(_type).first;
    _date = transaction?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  int? _parsePaise(String value) {
    final match = RegExp(r'^(\d+)(?:\.(\d{1,2}))?$').firstMatch(value.trim());
    if (match == null) return null;
    final whole = int.tryParse(match.group(1)!);
    final fraction = int.tryParse((match.group(2) ?? '').padRight(2, '0')) ?? 0;
    if (whole == null || whole > (1 << 62) ~/ 100) return null;
    final paise = whole * 100 + fraction;
    return paise > 0 ? paise : null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      TransactionDraft(
        description: _descriptionController.text.trim(),
        amountPaise: _parsePaise(_amountController.text.trim())!,
        type: _type,
        category: _category,
        date: _date,
      ),
    );
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (selected != null) setState(() => _date = selected);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final categories = TransactionCategories.forType(_type);
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + keyboardInset),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.transaction == null ? 'Add transaction' : 'Edit transaction', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 20),
              SegmentedButton<TransactionType>(
                segments: const [
                  ButtonSegment(value: TransactionType.expense, label: Text('Expense')),
                  ButtonSegment(value: TransactionType.income, label: Text('Income')),
                ],
                selected: {_type},
                onSelectionChanged: (selection) => setState(() {
                  _type = selection.first;
                  _category = TransactionCategories.forType(_type).first;
                }),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                validator: (value) => value == null || value.trim().isEmpty ? 'Enter a description' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Amount', prefixText: '₹ ', border: OutlineInputBorder()),
                validator: (value) => _parsePaise(value ?? '') == null ? 'Enter an amount greater than zero (up to 2 decimals)' : null,
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                items: categories.map((category) => DropdownMenuItem(value: category, child: Text(category))).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _category = value);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: const Text('Date'),
                subtitle: Text(DateFormat('EEEE, MMM d, y').format(_date)),
                trailing: const Icon(Icons.edit_calendar),
                onTap: _pickDate,
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.check),
                label: Text(widget.transaction == null ? 'Save transaction' : 'Save changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, size: 26, color: theme.colorScheme.primary),
        const SizedBox(height: 6),
        Text(value, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }
}
