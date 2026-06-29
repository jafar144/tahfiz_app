import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:khoirunnasyien/core/di/injection.dart';
import 'package:khoirunnasyien/core/theme/app_colors.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_app_bar.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_form_widgets.dart';
import 'package:khoirunnasyien/core/router/route_names.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';
import 'package:khoirunnasyien/features/payment/presentation/cubit/input_payment_cubit.dart';
import 'package:khoirunnasyien/features/payment/presentation/cubit/santri_payment_history_cubit.dart';
import 'package:khoirunnasyien/features/payment/presentation/cubit/santri_payment_history_state.dart';
import 'package:khoirunnasyien/features/payment/presentation/widgets/payment_year_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:khoirunnasyien/features/payment/presentation/widgets/payment_exists_bottom_sheet.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_button.dart';

class InputPaymentPage extends StatelessWidget {
  const InputPaymentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => getIt<InputPaymentCubit>(),
        ),
        BlocProvider(
          create: (_) => getIt<SantriPaymentHistoryCubit>(),
        ),
      ],
      child: const InputPaymentView(),
    );
  }
}

class InputPaymentView extends StatefulWidget {
  const InputPaymentView({super.key});

  @override
  State<InputPaymentView> createState() => _InputPaymentViewState();
}

class _InputPaymentViewState extends State<InputPaymentView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController(text: 'Rp 200.000');
  final TextEditingController _dateController = TextEditingController();

  SantriEntity? _selectedSantri;
  DateTime _selectedDate = DateTime.now();

  /// Bulan yang dipilih untuk dibayar, dikelompokkan per tahun (`{tahun: {bulan}}`).
  final Map<int, Set<int>> _selectedPeriods = {};

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null);
    _dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate);
  }

  Future<void> _pickSantri() async {
    final result = await context.pushNamed(
      RouteNames.selectSantri,
      extra: const {'isFree': false},
    );
    if (result != null && result is SantriEntity) {
      setState(() {
        _selectedSantri = result;
        _amountController.text = _defaultAmountFor(result);
        _selectedPeriods.clear();
      });
      if (context.mounted) {
        context.read<SantriPaymentHistoryCubit>().loadHistory(result.id);
      }
    }
  }

  /// Nominal default berdasarkan santri.
  /// Putri Pagi (jenis_kelamin "P" & tipe_kelas "Pagi") → 100.000,
  /// selain itu → 200.000.
  String _defaultAmountFor(SantriEntity santri) {
    final isPutriPagi = santri.jenisKelamin.toUpperCase() == 'P' &&
        (santri.tipeKelas?.toLowerCase() == 'pagi');
    final amount = isPutriPagi ? 100000 : 200000;
    return _formatCurrency(amount);
  }

  String _formatCurrency(int value) => NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp ',
        decimalDigits: 0,
      ).format(value);

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  /// Tambah/hapus satu bulan dari daftar pilihan.
  void _toggleMonth(int year, int month) {
    setState(() {
      final months = _selectedPeriods.putIfAbsent(year, () => <int>{});
      if (!months.remove(month)) {
        months.add(month);
      }
      if (months.isEmpty) {
        _selectedPeriods.remove(year);
      }
    });
  }

  /// Daftar bulan terpilih dalam bentuk `DateTime(tahun, bulan)`, terurut.
  List<DateTime> get _flatPeriods {
    final list = <DateTime>[];
    _selectedPeriods.forEach((year, months) {
      for (final m in months) {
        list.add(DateTime(year, m));
      }
    });
    list.sort();
    return list;
  }

  /// Nominal yang diketik (per bulan) sebagai int.
  int get _amountValue =>
      int.tryParse(_amountController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  /// Label ringkas bulan terpilih, mis. "Mar, Apr 2026 · Jan 2027".
  String _periodLabel(List<DateTime> periods) {
    final byYear = <int, List<int>>{};
    for (final p in periods) {
      byYear.putIfAbsent(p.year, () => <int>[]).add(p.month);
    }
    final years = byYear.keys.toList()..sort();
    return years.map((y) {
      final names = (byYear[y]!..sort())
          .map((m) => DateFormat('MMM', 'id_ID').format(DateTime(2024, m)))
          .join(', ');
      return '$names $y';
    }).join(' · ');
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSantri == null) {
      _showSnack('Silakan pilih data santri terlebih dahulu');
      return;
    }

    final periods = _flatPeriods;
    if (periods.isEmpty) {
      _showSnack('Pilih minimal satu bulan yang ingin dibayar');
      return;
    }

    final santri = _selectedSantri!;

    // Validasi user gratis: blokir bulan yang masih dalam masa gratis.
    // (Bulan sebelum tanggal masuk sudah otomatis tidak bisa dipilih di grid.)
    if (santri.isFree && santri.freeUntil != null) {
      final freeUntil = santri.freeUntil!;
      final freeUntilMonth = DateTime(freeUntil.year, freeUntil.month);
      final hasBlocked = periods.any((p) => !p.isAfter(freeUntilMonth));
      if (hasBlocked) {
        _showSnack(
          'Santri ini gratis pembayaran hingga ${DateFormat('MMMM yyyy', 'id_ID').format(freeUntil)}',
        );
        return;
      }
    }

    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';

    context.read<InputPaymentCubit>().submitMultiplePayments(
          santriId: santri.id,
          periods: periods,
          totalPerMonth: _amountValue,
          createdBy: userId,
          date: _selectedDate,
        );
  }

  @override
  Widget build(BuildContext context) {
    final periods = _flatPeriods;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AiwaAppBar(title: 'Input Pembayaran'),
      body: BlocListener<InputPaymentCubit, InputPaymentState>(
        listener: (context, state) {
          if (state is InputPaymentSuccess) {
            final message = state.count > 1
                ? '${state.count} pembayaran berhasil disimpan'
                : 'Pembayaran berhasil disimpan';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message)),
            );
            context.pop();
          } else if (state is InputPaymentFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${state.message}')),
            );
          } else if (state is InputPaymentAlreadyExists) {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              builder: (_) => PaymentExistsBottomSheet(
                payment: state.payment,
                santriName: _selectedSantri?.name ?? '-',
                onClose: () {
                  context.pop();
                  context.read<InputPaymentCubit>().reset();
                },
              ),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _buildSectionTitle('Data Santri'),
                const SizedBox(height: 8),
                AiwaClickableInput(
                  label: 'Pilih Santri',
                  value: _selectedSantri == null
                      ? 'Cari Santri'
                      : '${_selectedSantri!.name} (${_selectedSantri!.nis})',
                  icon: Icons.person_search,
                  onTap: _pickSantri,
                ),

                const SizedBox(height: 24),

                if (_selectedSantri != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionTitle('Periode Pembayaran'),
                      if (periods.isNotEmpty)
                        Text(
                          '${periods.length} bulan dipilih',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Ketuk bulan untuk memilih. Boleh pilih lebih dari satu.',
                    style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  BlocBuilder<SantriPaymentHistoryCubit, SantriPaymentHistoryState>(
                    builder: (context, state) {
                      if (state is SantriPaymentHistoryLoading) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      if (state is SantriPaymentHistoryError) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'Gagal memuat riwayat: ${state.message}',
                            style: const TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        );
                      }

                      if (state is SantriPaymentHistoryLoaded) {
                        final paidData = <int, Set<int>>{};
                        for (final p in state.payments) {
                          final year = int.tryParse(p.tahun);
                          final month = int.tryParse(p.bulan);
                          if (year != null && month != null) {
                            paidData.putIfAbsent(year, () => {}).add(month);
                          }
                        }

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.fromLTRB(8, 12, 8, 16),
                          child: PaymentYearView(
                            paidData: paidData,
                            startDate: _resolveStartDate(),
                            selectable: true,
                            selectedData: _selectedPeriods,
                            onToggleMonth: _toggleMonth,
                          ),
                        );
                      }

                      return const SizedBox.shrink();
                    },
                  ),
                  if (periods.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildSelectionInfo(periods),
                  ],
                  const SizedBox(height: 24),
                ],

                const Center(child: Text('DETAIL PEMBAYARAN', style: TextStyle(color: Colors.grey, fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.w600))),
                const SizedBox(height: 16),

                _buildSectionTitle('Tanggal Bayar'),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _selectDate(context),
                  child: IgnorePointer(
                    child: TextFormField(
                      controller: _dateController,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        suffixIcon: const Icon(Icons.access_time, color: Colors.grey, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                _buildSectionTitle('Nominal per Bulan'),
                const SizedBox(height: 4),
                const Text(
                  'Berlaku untuk setiap bulan yang dipilih.',
                  style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    CurrencyInputFormatter(),
                  ],
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.blue.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.blue, width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.blue.withValues(alpha: 0.3)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    hintText: 'Rp 0',
                  ),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.teal),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Nominal harus diisi';
                    return null;
                  },
                ),

                const SizedBox(height: 24),
                if (periods.isNotEmpty) ...[
                  _buildTotalCard(periods),
                  const SizedBox(height: 16),
                ],
                BlocBuilder<InputPaymentCubit, InputPaymentState>(
                  builder: (context, state) {
                    final isLoading = state is InputPaymentLoading;
                    return AiwaButton(
                      text: 'Simpan Pembayaran',
                      onPressed: _submit,
                      isLoading: isLoading,
                    );
                  },
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Ringkasan bulan yang sedang dipilih (di bawah grid).
  Widget _buildSelectionInfo(List<DateTime> periods) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.event_available, color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _periodLabel(periods),
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Kartu total pembayaran (jumlah bulan × nominal).
  Widget _buildTotalCard(List<DateTime> periods) {
    final count = periods.length;
    final total = _amountValue * count;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Pembayaran',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count bulan',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _formatCurrency(total),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$count bulan × ${_formatCurrency(_amountValue)}',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  /// Menghitung bulan pertama santri wajib membayar.
  /// - free_until null → mulai dari tanggal_masuk
  /// - free_until ada dan sudah lewat → mulai dari bulan setelah free_until
  DateTime? _resolveStartDate() {
    final santri = _selectedSantri;
    if (santri == null) return null;

    final freeUntil = santri.freeUntil;
    final tanggalMasuk = santri.tanggalMasuk;

    if (freeUntil != null && !freeUntil.isAfter(DateTime.now())) {
      // Masa gratis sudah selesai → mulai bayar dari bulan setelah free_until
      final afterFree = DateTime(freeUntil.year, freeUntil.month + 1);
      return DateTime(afterFree.year, afterFree.month);
    }

    // Reguler → mulai dari tanggal_masuk
    if (tanggalMasuk != null) {
      return DateTime(tanggalMasuk.year, tanggalMasuk.month);
    }

    return null;
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.black87,
        fontSize: 13,
      ),
    );
  }
}

class CurrencyInputFormatter extends TextInputFormatter {

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    int value = int.parse(newValue.text);
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    String newText = formatter.format(value);

    return newValue.copyWith(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length));
  }
}
