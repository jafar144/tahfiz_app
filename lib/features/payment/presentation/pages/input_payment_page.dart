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
import 'package:khoirunnasyien/features/payment/presentation/widgets/santri_payment_history_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:khoirunnasyien/features/payment/presentation/widgets/payment_exists_bottom_sheet.dart';

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
      });
      if (context.mounted) {
        context.read<SantriPaymentHistoryCubit>().loadHistory(result.id);
      }
    }
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
    final years = List.generate(5, (index) => now.year - 1 + index);
    final months = List.generate(12, (index) => index + 1);

    int selectedYearIndex = years.indexOf(_selectedYear);
    if (selectedYearIndex == -1) selectedYearIndex = 1; // Default to current year index if found, simple fallback
    
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
                      child: CupertinoPicker(
                        scrollController: FixedExtentScrollController(
                          initialItem: selectedMonthIndex,
                        ),
                        itemExtent: 32,
                        onSelectedItemChanged: (index) {
                          selectedMonthIndex = index;
                        },
                        children: months.map((m) {
                          return Center(
                            child: Text(
                              DateFormat('MMMM', 'id_ID').format(DateTime(2024, m)),
                              style: const TextStyle(fontSize: 16),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    // Year Picker
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: FixedExtentScrollController(
                          initialItem: selectedYearIndex,
                        ),
                        itemExtent: 32,
                        onSelectedItemChanged: (index) {
                          selectedYearIndex = index;
                        },
                        children: years.map((y) {
                          return Center(
                            child: Text(
                              y.toString(),
                              style: const TextStyle(fontSize: 16),
                            ),
                          );
                        }).toList(),
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
                _buildSectionTitle('Data Santri'),
                const SizedBox(height: 8),
                AiwaClickableInput(
                  label: 'Pilih Santri',
                  value: _selectedSantri == null 
                      ? 'Cari Santri (Nama/ID)...' 
                      : '${_selectedSantri!.name} (${_selectedSantri!.nis})',
                  icon: Icons.person_search,
                  onTap: _pickSantri,
                ),
                
                const SizedBox(height: 24),
                
                const SantriPaymentHistoryWidget(),
                
                const SizedBox(height: 24),
                const Center(child: Text('DETAIL TRANSAKSI', style: TextStyle(color: Colors.grey, fontSize: 12, letterSpacing: 1.2))),
                const SizedBox(height: 24),

                _buildSectionTitle('Bulan & Tahun'),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _showMonthYearPicker,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                          style: const TextStyle(fontSize: 16, color: Colors.black87),
                        ),
                        const Icon(Icons.calendar_today, color: Colors.blue),
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
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        suffixIcon: const Icon(Icons.access_time, color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    hintText: 'Rp 0',
                  ),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black54),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Nominal datat harus diisi';
                    return null;
                  },
                ),

                const SizedBox(height: 32),
                BlocBuilder<InputPaymentCubit, InputPaymentState>(
                  builder: (context, state) {
                    final isLoading = state is InputPaymentLoading;
                    return SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: isLoading ? null : _submit,
                        icon: isLoading 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                            : const Icon(Icons.save),
                        label: Text(isLoading ? 'Menyimpan...' : 'Simpan Pembayaran'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.black87,
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
