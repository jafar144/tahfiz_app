import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:khoirunnasyien/core/di/injection.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';
import 'package:khoirunnasyien/features/management_santri/domain/repository/santri_repository.dart';
import 'package:khoirunnasyien/features/payment/presentation/cubit/input_payment_cubit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:khoirunnasyien/features/payment/presentation/widgets/payment_exists_bottom_sheet.dart';

class InputPaymentPage extends StatelessWidget {
  const InputPaymentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<InputPaymentCubit>(),
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

  List<SantriEntity> _allSantri = [];
  bool _isLoadingSantri = true;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null);
    _dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate);
    _loadSantri();
  }

  Future<void> _loadSantri() async {
    try {
      final santri = await getIt<SantriRepository>().getSantriList(isActive: true);
      if (mounted) {
        setState(() {
          _allSantri = santri.where((s) => !s.isFree).toList();
          _isLoadingSantri = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data santri: $e')),
        );
        setState(() {
          _isLoadingSantri = false;
        });
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
      appBar: AppBar(
        title: const Text(
          'Input Pembayaran',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
      ),
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
                _buildSantriAutocomplete(),
                
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

  Widget _buildSantriAutocomplete() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Autocomplete<SantriEntity>(
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (_isLoadingSantri) {
              return const Iterable<SantriEntity>.empty();
            }
            if (textEditingValue.text == '') {
              return const Iterable<SantriEntity>.empty();
            }
            return _allSantri.where((SantriEntity option) {
              return option.name.toLowerCase().contains(textEditingValue.text.toLowerCase()) || 
                     option.nis.toLowerCase().contains(textEditingValue.text.toLowerCase());
            });
          },
          displayStringForOption: (SantriEntity option) => '${option.name} (${option.nis})',
          onSelected: (SantriEntity selection) {
            setState(() {
              _selectedSantri = selection;
            });
          },
          fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
            return TextFormField(
              controller: textEditingController,
              focusNode: focusNode,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: 'Cari Santri (Nama/ID)...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              validator: (val) {
                if (_selectedSantri == null) return 'Wajib dipilih';
                return null;
              },
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4.0,
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
                child: SizedBox(
                  width: constraints.maxWidth,
                  height: 200, // Limit height
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: options.length,
                    itemBuilder: (BuildContext context, int index) {
                      final SantriEntity option = options.elementAt(index);
                      return ListTile(
                        title: Text(option.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('NIS: ${option.nis} • Kelas ${option.kelas}'),
                        onTap: () {
                          onSelected(option);
                        },
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      }
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
