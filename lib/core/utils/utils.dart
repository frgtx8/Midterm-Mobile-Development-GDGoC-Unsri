import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Currency and date formatting utilities.
class AppFormatters {
  AppFormatters._();

  static final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static final _compactCurrencyFormat = NumberFormat.compactCurrency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static final _dateFormat = DateFormat('dd MMM yyyy', 'id_ID');
  static final _dateTimeFormat = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');
  static final _monthYearFormat = DateFormat('MMMM yyyy', 'id_ID');
  static final _dayFormat = DateFormat('EEEE', 'id_ID');

  /// Format amount as Indonesian Rupiah: Rp 1.000.000
  static String currency(double amount) {
    return _currencyFormat.format(amount);
  }

  /// Format amount in compact form: Rp 1jt
  static String compactCurrency(double amount) {
    return _compactCurrencyFormat.format(amount);
  }

  /// Format date: 27 Jun 2024
  static String date(DateTime date) {
    return _dateFormat.format(date);
  }

  /// Format datetime: 27 Jun 2024, 14:30
  static String dateTime(DateTime date) {
    return _dateTimeFormat.format(date);
  }

  /// Format month year: Juni 2024
  static String monthYear(DateTime date) {
    return _monthYearFormat.format(date);
  }

  /// Format day name: Senin
  static String dayName(DateTime date) {
    return _dayFormat.format(date);
  }

  /// Relative time: "Hari ini", "Kemarin", "3 hari lalu"
  static String relativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    final diff = today.difference(dateOnly).inDays;

    if (diff == 0) return 'Hari ini';
    if (diff == 1) return 'Kemarin';
    if (diff < 7) return '$diff hari lalu';
    return AppFormatters.date(date);
  }
}

/// Input validators.
class AppValidators {
  AppValidators._();

  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'Email wajib diisi';
    final regex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!regex.hasMatch(value)) return 'Format email tidak valid';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password wajib diisi';
    if (value.length < 6) return 'Password minimal 6 karakter';
    return null;
  }

  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) return 'Nama wajib diisi';
    return null;
  }

  static String? amount(String? value) {
    if (value == null || value.isEmpty) return 'Jumlah wajib diisi';
    final num = double.tryParse(value.replaceAll(RegExp(r'[^0-9]'), ''));
    if (num == null || num <= 0) return 'Jumlah harus lebih dari 0';
    return null;
  }

  static String? required(String? value, [String fieldName = 'Field']) {
    if (value == null || value.trim().isEmpty) return '$fieldName wajib diisi';
    return null;
  }
}

/// Formatter to dynamically insert dots as thousands separators.
class RupiahInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    // Strip everything except numbers
    final cleanText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanText.isEmpty) {
      return const TextEditingValue();
    }

    final double value = double.parse(cleanText);
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: '',
      decimalDigits: 0,
    );

    final String newText = formatter.format(value).trim();

    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
