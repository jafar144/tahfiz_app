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
import 'package:khoirunnasyien/features/payment/presentation/cubit/family_payment_cubit.dart';
import 'package:khoirunnasyien/features/payment/presentation/widgets/payment_year_view.dart';
import 'package:khoirunnasyien/core/utils/ui_utils.dart';
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
          create: (_) => getIt<FamilyPaymentCubit>(),
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
  /// Dipakai bersama untuk semua anggota keluarga.
  final Map<int, Set<int>> _selectedPeriods = {};

  /// Id santri (kakak-beradik) yang dicentang untuk ikut dibayar.
  final Set<String> _selectedChildIds = {};

  /// Controller nominal per anak (keyed by santriId) pada mode keluarga.
  final Map<String, TextEditingController> _childAmountControllers = {};

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null);
    _dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _dateController.dispose();
    for (final c in _childAmountControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// Controller nominal untuk seorang anak, dibuat dengan nilai default
  /// pertama kali diakses.
  TextEditingController _childController(SantriEntity santri) {
    return _childAmountControllers.putIfAbsent(
      santri.id,
      () => TextEditingController(text: _defaultAmountFor(santri)),
    );
  }

  int _childAmountValue(String santriId) {
    final text = _childAmountControllers[santriId]?.text ?? '';
    return int.tryParse(text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  }

  void _toggleChild(String santriId) {
    setState(() {
      if (!_selectedChildIds.remove(santriId)) {
        _selectedChildIds.add(santriId);
      }
    });
  }

  /// Bulan terpilih yang benar-benar akan ditagih untuk [member]: di luar bulan
  /// yang sudah lunas dan tidak sebelum tanggal mulai wajib bayarnya.
  List<DateTime> _newPeriodsFor(FamilyMemberPayment member, List<DateTime> periods) {
    final start = _resolveStartDateFor(member.santri);
    return periods.where((p) {
      if (start != null && p.isBefore(DateTime(start.year, start.month))) {
        return false;
      }
      return !member.isPaidPeriod(p);
    }).toList();
  }

  Future<void> _pickSantri() async {
    final result = await context.pushNamed(
      RouteNames.selectSantri,
      extra: const {'isFree': false},
    );
    if (result != null && result is SantriEntity) {
      // Bersihkan nominal anak & pilihan dari santri sebelumnya.
      for (final c in _childAmountControllers.values) {
        c.dispose();
      }
      _childAmountControllers.clear();
      setState(() {
        _selectedSantri = result;
        _amountController.text = _defaultAmountFor(result);
        _selectedPeriods.clear();
        _selectedChildIds.clear();
      });
      if (mounted) {
        context.read<FamilyPaymentCubit>().resolve(result);
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

    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
    final famState = context.read<FamilyPaymentCubit>().state;

    // Mode keluarga: bayar beberapa anak sekaligus dengan nominal masing-masing.
    if (famState is FamilyPaymentLoaded && famState.isFamily) {
      final selected = famState.members
          .where((m) => _selectedChildIds.contains(m.santri.id))
          .toList();

      if (selected.isEmpty) {
        _showSnack('Pilih minimal satu santri yang ingin dibayar');
        return;
      }
      for (final m in selected) {
        if (_childAmountValue(m.santri.id) <= 0) {
          _showSnack('Nominal untuk ${m.santri.name} belum diisi');
          return;
        }
      }

      context.read<InputPaymentCubit>().submitFamilyPayments(
            children: selected
                .map((m) => FamilyPaymentChild(
                      santriId: m.santri.id,
                      totalPerMonth: _childAmountValue(m.santri.id),
                      startDate: _resolveStartDateFor(m.santri),
                    ))
                .toList(),
            periods: periods,
            createdBy: userId,
            date: _selectedDate,
          );
      return;
    }

    // Mode tunggal (santri tanpa saudara).
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
      body: MultiBlocListener(
        listeners: [
          BlocListener<InputPaymentCubit, InputPaymentState>(
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
          ),
          BlocListener<FamilyPaymentCubit, FamilyPaymentState>(
            listener: (context, state) {
              if (state is FamilyPaymentLoaded) {
                setState(() {
                  // Default: hanya santri yang dipilih admin yang tercentang;
                  // saudara bersifat opt-in (centang untuk ikut dibayar).
                  _selectedChildIds
                    ..clear()
                    ..add(state.primary.santri.id);
                  for (final m in state.members) {
                    _childAmountControllers.putIfAbsent(
                      m.santri.id,
                      () =>
                          TextEditingController(text: _defaultAmountFor(m.santri)),
                    );
                  }
                });
              }
            },
          ),
        ],
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: BlocBuilder<FamilyPaymentCubit, FamilyPaymentState>(
              builder: (context, famState) {
                final isFamily =
                    famState is FamilyPaymentLoaded && famState.isFamily;
                final members = famState is FamilyPaymentLoaded
                    ? famState.members
                    : const <FamilyMemberPayment>[];

                return Column(
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
                  _buildSantriContext(famState, periods),

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

                // Nominal tunggal hanya untuk santri tanpa saudara. Pada mode
                // keluarga, nominal diatur per anak di kartu "Bayar Sekaligus".
                if (!isFamily) ...[
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
                ],

                const SizedBox(height: 24),
                if (periods.isNotEmpty) ...[
                  _buildTotalCard(periods, isFamily: isFamily, members: members),
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
                );
              },
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

  /// Bagian konteks santri: kartu saudara (jika ada) + grid periode.
  Widget _buildSantriContext(FamilyPaymentState famState, List<DateTime> periods) {
    if (famState is FamilyPaymentLoading || famState is FamilyPaymentInitial) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (famState is FamilyPaymentError) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Gagal memuat data: ${famState.message}',
          style: const TextStyle(color: Colors.red, fontSize: 12),
        ),
      );
    }

    final loaded = famState as FamilyPaymentLoaded;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (loaded.isFamily) ...[
          _buildFamilySection(loaded.members, periods),
          const SizedBox(height: 24),
        ],
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
        Text(
          loaded.isFamily
              ? 'Bulan ini berlaku untuk semua santri yang dicentang.'
              : 'Ketuk bulan untuk memilih. Boleh pilih lebih dari satu.',
          style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 16),
          child: PaymentYearView(
            paidData: loaded.primary.paid,
            startDate: _resolveStartDate(),
            selectable: true,
            selectedData: _selectedPeriods,
            onToggleMonth: _toggleMonth,
          ),
        ),
        if (periods.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildSelectionInfo(periods),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  /// Kartu "Bayar Sekaligus": daftar saudara satu keluarga + nominal per anak.
  Widget _buildFamilySection(
    List<FamilyMemberPayment> members,
    List<DateTime> periods,
  ) {
    final selectedCount =
        members.where((m) => _selectedChildIds.contains(m.santri.id)).length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.family_restroom,
                    color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bayar Sekaligus (Saudara)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Satu keluarga • $selectedCount dari ${members.length} dipilih',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...members.map((m) => _buildChildTile(m, periods)),
        ],
      ),
    );
  }

  /// Baris satu anak: centang ikut bayar + nominal per bulan + subtotal.
  Widget _buildChildTile(FamilyMemberPayment member, List<DateTime> periods) {
    final s = member.santri;
    final selected = _selectedChildIds.contains(s.id);
    final newPeriods = _newPeriodsFor(member, periods);
    final subtotal = newPeriods.length * _childAmountValue(s.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.primary.withValues(alpha: 0.04)
            : Colors.grey.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.4)
              : AppColors.divider,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Column(
        children: [
          InkWell(
            onTap: () => _toggleChild(s.id),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: selected,
                    onChanged: (_) => _toggleChild(s.id),
                    activeColor: AppColors.primary,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 10),
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  child: Text(
                    UiUtils.getInitials(s.name),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${s.kelas} • NIS ${s.nis}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (selected) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const SizedBox(width: 34),
                const Text(
                  'Nominal/bln',
                  style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _childController(s),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      CurrencyInputFormatter(),
                    ],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.teal,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: Colors.blue.withValues(alpha: 0.05),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: Colors.blue.withValues(alpha: 0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: Colors.blue.withValues(alpha: 0.3)),
                      ),
                      hintText: 'Rp 0',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 34),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  periods.isEmpty
                      ? 'Pilih bulan terlebih dahulu'
                      : newPeriods.isEmpty
                          ? 'Semua bulan terpilih sudah lunas'
                          : '${newPeriods.length} bulan × ${_formatCurrency(_childAmountValue(s.id))} = ${_formatCurrency(subtotal)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: (newPeriods.isEmpty && periods.isNotEmpty)
                        ? AppColors.error
                        : AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Kartu total pembayaran. Mode tunggal: jumlah bulan × nominal. Mode
  /// keluarga: jumlah semua tagihan tiap anak yang dicentang.
  Widget _buildTotalCard(
    List<DateTime> periods, {
    required bool isFamily,
    required List<FamilyMemberPayment> members,
  }) {
    int total;
    String pillText;
    String breakdown;

    if (isFamily) {
      int payCount = 0;
      int sum = 0;
      int selectedCount = 0;
      for (final m in members) {
        if (!_selectedChildIds.contains(m.santri.id)) continue;
        selectedCount++;
        final n = _newPeriodsFor(m, periods).length;
        payCount += n;
        sum += n * _childAmountValue(m.santri.id);
      }
      total = sum;
      pillText = '$payCount pembayaran';
      breakdown = '$selectedCount santri dipilih • $payCount bulan ditagih';
    } else {
      final count = periods.length;
      total = _amountValue * count;
      pillText = '$count bulan';
      breakdown = '$count bulan × ${_formatCurrency(_amountValue)}';
    }

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
                  pillText,
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
            breakdown,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  /// Bulan pertama wajib bayar untuk santri primary (dipakai grid).
  DateTime? _resolveStartDate() {
    final santri = _selectedSantri;
    if (santri == null) return null;
    return _resolveStartDateFor(santri);
  }

  /// Menghitung bulan pertama [santri] wajib membayar.
  /// - free_until null → mulai dari tanggal_masuk
  /// - free_until ada dan sudah lewat → mulai dari bulan setelah free_until
  DateTime? _resolveStartDateFor(SantriEntity santri) {
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
