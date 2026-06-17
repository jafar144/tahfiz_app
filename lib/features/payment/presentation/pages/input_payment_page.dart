import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:khoirunnasyien/core/di/injection.dart';
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
import 'package:khoirunnasyien/core/widgets/aiwa_wheel_picker.dart';

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
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null);
    _dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate);
  }

  Future<void> _pickSantri() async {
    final result = await context.pushNamed(RouteNames.selectSantri);
    if (result != null && result is SantriEntity) {
      setState(() {
        _selectedSantri = result;
        _amountController.text = _defaultAmountFor(result);
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
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

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

  void _showMonthYearPicker() {
    final now = DateTime.now();
    final years = List.generate(3, (index) => now.year - 1 + index);
    final months = List.generate(12, (index) => index + 1);

    int selectedYearIndex = years.indexOf(_selectedYear);
    if (selectedYearIndex == -1) selectedYearIndex = 1;
    
    int selectedMonthIndex = _selectedMonth - 1;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SizedBox(
          height: 300,
          child: Column(
            children: [
              // Toolbar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => ctx.pop(),
                      child: const Text('Batal',
                          style: TextStyle(color: Colors.red)),
                    ),
                    const Text('Pilih Bulan & Tahun',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedYear = years[selectedYearIndex];
                          _selectedMonth = months[selectedMonthIndex];
                        });
                        ctx.pop();
                      },
                      child: const Text('Pilih',
                          style: TextStyle(color: Colors.blue)),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Pickers
              Expanded(
                child: Row(
                  children: [
                    // Month Picker
                    Expanded(
                      flex: 3,
                      child: AiwaWheelPicker<int>(
                        initialItem: selectedMonthIndex,
                        items: months,
                        itemExtent: 40,
                        onSelectedItemChanged: (index) => selectedMonthIndex = index,
                        itemBuilder: (m) => Text(
                          DateFormat('MMMM', 'id_ID').format(DateTime(2024, m)),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Year Picker
                    Expanded(
                      flex: 2,
                      child: AiwaWheelPicker<int>(
                        initialItem: selectedYearIndex,
                        items: years,
                        itemExtent: 40,
                        onSelectedItemChanged: (index) => selectedYearIndex = index,
                        itemBuilder: (y) => Text(
                          y.toString(),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (_selectedSantri == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Silakan pilih data santri terlebih dahulu')),
        );
        return;
      }

      // 1. Validation: Payment for duplicate month/year is handled in Cubit (InputPaymentAlreadyExists)
      // but we can also double check here if we had the history locally, but Cubit is safer.

      // 2. Validation: Payment Date cannot be before entry date
       if (_selectedSantri!.tanggalMasuk != null) {
          final tanggalMasuk = _selectedSantri!.tanggalMasuk!;
          final paymentMonthDate = DateTime(_selectedYear, _selectedMonth);
          final entryMonthDate = DateTime(tanggalMasuk.year, tanggalMasuk.month);

          if (paymentMonthDate.isBefore(entryMonthDate)) {
             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(content: Text('Pembayaran tidak bisa sebelum tanggal masuk santri (${DateFormat('dd MMMM yyyy', 'id_ID').format(tanggalMasuk)})')),
             );
             return;
          }
       }

      // 3. Validation: Free User
      if (_selectedSantri!.isFree && _selectedSantri!.freeUntil != null) {
         final freeUntil = _selectedSantri!.freeUntil!;
         final paymentMonthDate = DateTime(_selectedYear, _selectedMonth);
         // If payment month is BEFORE or EQUAL to freeUntil, block it? 
         // "jika bulan yang dipilih itu kurang dari free_until"
         // If freeUntil is March 2024. Payment for Feb 2024 should be blocked? Yes.
         // If payment for April 2024? Allowed.
         
         // We need to compare Month and Year.
         final freeUntilMonthYear = DateTime(freeUntil.year, freeUntil.month);
         
         if (paymentMonthDate.isBefore(freeUntilMonthYear) || paymentMonthDate.isAtSameMomentAs(freeUntilMonthYear)) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Santri ini gratis pembayaran hingga ${DateFormat('MMMM yyyy', 'id_ID').format(freeUntil)}')),
            );
            return;
         }
      }

      // Remove Rp, dot, space to get int
      final rawAmount = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
      final amount = int.tryParse(rawAmount) ?? 0;
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';

      context.read<InputPaymentCubit>().validateAndSubmitPayment(
        santriId: _selectedSantri!.id,
        month: _selectedMonth.toString(),
        year: _selectedYear.toString(),
        total: amount,
        createdBy: userId,
        date: _selectedDate,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayMonthYear = DateFormat('MMMM yyyy', 'id_ID').format(DateTime(_selectedYear, _selectedMonth));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AiwaAppBar(title: 'Input Pembayaran'),
      body: BlocListener<InputPaymentCubit, InputPaymentState>(
        listener: (context, state) {
          if (state is InputPaymentSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Pembayaran berhasil disimpan')),
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
                
                if (_selectedSantri != null)
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
                          ),
                        );
                      }

                      return const SizedBox.shrink();
                    },
                  ),
                
                const SizedBox(height: 24),
                const Center(child: Text('DETAIL PEMBAYARAN', style: TextStyle(color: Colors.grey, fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.w600))),
                const SizedBox(height: 16),

                _buildSectionTitle('Periode Pembayaran'),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _showMonthYearPicker,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          displayMonthYear,
                          style: const TextStyle(fontSize: 14, color: Colors.black87),
                        ),
                        const Icon(Icons.calendar_today, color: Colors.blue, size: 20),
                      ],
                    ),
                  ),
                ),

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
                _buildSectionTitle('Nominal (Rp)'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
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

                const SizedBox(height: 32),
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
