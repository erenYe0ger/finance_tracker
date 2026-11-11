enum TransactionType {
  income,
  expense;

  String get label => this == income ? 'Income' : 'Expense';
}

class TransactionCategories {
  const TransactionCategories._();

  static const income = <String>[
    'Salary',
    'Freelance',
    'Investment',
    'Gift',
    'Other',
  ];

  static const expense = <String>[
    'Food',
    'Transport',
    'Bills',
    'Shopping',
    'Health',
    'Entertainment',
    'Other',
  ];

  static List<String> forType(TransactionType type) =>
      type == TransactionType.income ? income : expense;

  static List<String> get all => {...income, ...expense}.toList()..sort();
}

class TransactionRecord {
  const TransactionRecord({
    required this.id,
    required this.description,
    required this.amountPaise,
    required this.type,
    required this.category,
    required this.date,
  });

  final int id;
  final String description;
  final int amountPaise;
  final TransactionType type;
  final String category;
  final DateTime date;

  factory TransactionRecord.fromJson(Map<String, dynamic> json) {
    return TransactionRecord(
      id: json['id'] as int,
      description: json['description'] as String,
      amountPaise: (json['amount_paise'] as num).toInt(),
      type: TransactionType.values.byName(json['type'] as String),
      category: json['category'] as String,
      date: DateTime.parse(json['transaction_date'] as String),
    );
  }
}

class TransactionDraft {
  const TransactionDraft({
    required this.description,
    required this.amountPaise,
    required this.type,
    required this.category,
    required this.date,
  });

  final String description;
  final int amountPaise;
  final TransactionType type;
  final String category;
  final DateTime date;

  Map<String, dynamic> toJson() => {
        'description': description,
        'amount_paise': amountPaise,
        'type': type.name,
        'category': category,
        'transaction_date': _dateOnly(date),
      };
}

String transactionDateParameter(DateTime date) => _dateOnly(date);

String _dateOnly(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
