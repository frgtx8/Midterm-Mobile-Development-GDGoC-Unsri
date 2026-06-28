import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/transaction.dart';
import '../cubit/transaction_cubit.dart';
import '../cubit/transaction_state.dart';
import '../../../../injection_container.dart';

class AddTransactionPage extends StatefulWidget {
  final Transaction? transaction; // null = create, non-null = edit

  const AddTransactionPage({super.key, this.transaction});

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _type = 'expense';
  String? _selectedCategoryId;
  DateTime _selectedDate = DateTime.now();
  late TransactionFormCubit _formCubit;
  List<Category> _categories = [];

  bool get isEditing => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    _formCubit = sl<TransactionFormCubit>();

    if (isEditing) {
      final tx = widget.transaction!;
      _amountController.text = AppFormatters.currency(tx.amount).replaceAll('Rp ', '').trim();
      _descriptionController.text = tx.description;
      _type = tx.type;
      _selectedCategoryId = tx.categoryId;
      _selectedDate = tx.date;
    }

    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final state = context.read<TransactionCubit>().state;
    if (state is TransactionLoaded) {
      setState(() => _categories = state.categories);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _formCubit.close();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(_amountController.text.replaceAll(RegExp(r'[^0-9]'), ''));

    if (isEditing) {
      _formCubit.updateTransaction(
        id: widget.transaction!.id,
        type: _type,
        amount: amount,
        description: _descriptionController.text.trim(),
        date: _selectedDate.toIso8601String(),
        categoryId: _selectedCategoryId,
      );
    } else {
      _formCubit.createTransaction(
        type: _type,
        amount: amount,
        description: _descriptionController.text.trim(),
        date: _selectedDate.toIso8601String(),
        categoryId: _selectedCategoryId,
      );
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _formCubit,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEditing ? 'Edit Transaksi' : 'Tambah Transaksi'),
        ),
        body: BlocListener<TransactionFormCubit, TransactionFormState>(
          listener: (context, state) {
            if (state is TransactionFormSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white),
                      const SizedBox(width: 12),
                      Text(state.message),
                    ],
                  ),
                  backgroundColor: AppColors.income,
                ),
              );
              Navigator.of(context).pop(true);
            }
            if (state is TransactionFormError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(child: Text(state.message)),
                    ],
                  ),
                  backgroundColor: AppColors.expense,
                ),
              );
            }
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Type selector
                  _buildTypeSelector(),
                  const SizedBox(height: 24),

                  // Amount
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    validator: AppValidators.amount,
                    inputFormatters: [RupiahInputFormatter()],
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: 'Jumlah',
                      prefixText: 'Rp ',
                      prefixStyle: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _type == 'income' ? AppColors.income : AppColors.expense,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Category
                  _buildCategorySelector(),
                  const SizedBox(height: 16),

                  // Description
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 2,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'Deskripsi (opsional)',
                      hintText: 'Contoh: Makan siang',
                      prefixIcon: Icon(Icons.notes),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Date
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Tanggal',
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(AppFormatters.date(_selectedDate)),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Submit button
                  BlocBuilder<TransactionFormCubit, TransactionFormState>(
                    builder: (context, state) {
                      final isLoading = state is TransactionFormLoading;
                      return SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _submit,
                          child: isLoading
                              ? const SizedBox(
                                  height: 24, width: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                )
                              : Text(isEditing ? 'Simpan Perubahan' : 'Simpan Transaksi'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(child: _typeTab('expense', 'Pengeluaran', Icons.arrow_upward, AppColors.expense)),
          Expanded(child: _typeTab('income', 'Pemasukan', Icons.arrow_downward, AppColors.income)),
        ],
      ),
    );
  }

  Widget _typeTab(String type, String label, IconData icon, Color color) {
    final isSelected = _type == type;
    return GestureDetector(
      onTap: () => setState(() {
        _type = type;
        _selectedCategoryId = null;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isSelected ? Border.all(color: color, width: 1.5) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? color : Theme.of(context).textTheme.bodySmall?.color, size: 20),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? color : Theme.of(context).textTheme.bodySmall?.color,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    final filtered = _categories.where((c) => c.type == _type).toList();
    return DropdownButtonFormField<String>(
      initialValue: _selectedCategoryId,
      decoration: const InputDecoration(
        labelText: 'Kategori',
        prefixIcon: Icon(Icons.category),
      ),
      items: filtered.map((cat) {
        return DropdownMenuItem(
          value: cat.id,
          child: Text(cat.name),
        );
      }).toList(),
      onChanged: (value) => setState(() => _selectedCategoryId = value),
      validator: (value) => value == null ? 'Pilih kategori' : null,
    );
  }
}
