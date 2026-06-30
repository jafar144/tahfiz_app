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

  /// Bulan yang dipilih untuk santri tunggal (tanpa saudara),
  /// dikelompokkan per tahun (`{tahun: {bulan}}`).
  final Map<int, Set<int>> _selectedPeriods = {};

  /// Bulan yang dipilih per santri pada mode keluarga
  /// (`{santriId: {tahun: {bulan}}}`). Tiap saudara punya pilihan sendiri.
  final Map<String, Map<int, Set<int>>> _selectedByChild = {};

  /// Santri yang gridnya sedang ditampilkan pada switcher mode keluarga.
  String? _activeChildId;

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

  /// Bulan terpilih untuk [santriId] dalam bentuk `DateTime(tahun, bulan)`, terurut.
  List<DateTime> _periodsForChild(String santriId) {
    final byYear = _selectedByChild[santriId];
    if (byYear == null) return const [];
    final list = <DateTime>[];
    byYear.forEach((year, months) {
      for (final m in months) {
        list.add(DateTime(year, m));
      }
    });
    list.sort();
    return list;
  }

  /// Jumlah bulan yang sedang dipilih untuk [santriId].
  int _childPeriodsCount(String santriId) {
    final byYear = _selectedByChild[santriId];
    if (byYear == null) return 0;
    var n = 0;
    for (final months in byYear.values) {
      n += months.length;
    }
    return n;
  }

  /// Tambah/hapus satu bulan dari pilihan milik [santriId] (mode keluarga).
  void _toggleMonthForChild(String santriId, int year, int month) {
    setState(() {
      final byYear = _selectedByChild.putIfAbsent(santriId, () => {});
      final months = byYear.putIfAbsent(year, () => <int>{});
      if (!months.remove(month)) {
        months.add(month);
      }
      if (months.isEmpty) byYear.remove(year);
      if (byYear.isEmpty) _selectedByChild.remove(santriId);
    });
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
        _selectedByChild.clear();
        _activeChildId = null;
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

    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
    final famState = context.read<FamilyPaymentCubit>().state;

    // Mode keluarga: tiap santri membayar bulan & nominalnya sendiri.
    if (famState is FamilyPaymentLoaded && famState.isFamily) {
      final billed = famState.members
          .where((m) => _periodsForChild(m.santri.id).isNotEmpty)
          .toList();

      if (billed.isEmpty) {
        _showSnack('Pilih minimal satu bulan untuk salah satu santri');
        return;
      }
      for (final m in billed) {
        if (_childAmountValue(m.santri.id) <= 0) {
          _showSnack('Nominal untuk ${m.santri.name} belum diisi');
          return;
        }
      }

      context.read<InputPaymentCubit>().submitFamilyPayments(
            children: billed
                .map((m) => FamilyPaymentChild(
                      santriId: m.santri.id,
                      totalPerMonth: _childAmountValue(m.santri.id),
                      periods: _periodsForChild(m.santri.id),
                      startDate: _resolveStartDateFor(m.santri),
                    ))
                .toList(),
            createdBy: userId,
            date: _selectedDate,
          );
      return;
    }

    // Mode tunggal (santri tanpa saudara).
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
                  // Mulai dari grid santri yang dicari admin; saudara dipilih
                  // lewat switcher di atas grid, masing-masing bulannya sendiri.
                  _activeChildId = state.primary.santri.id;
                  _selectedByChild.clear();
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
                final hasPeriods = isFamily
                    ? members.any((m) => _childPeriodsCount(m.santri.id) > 0)
                    : periods.isNotEmpty;

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
                if (hasPeriods) ...[
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

  /// Bagian konteks santri: switcher per-santri (keluarga) atau grid tunggal.
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

    // Mode keluarga: tiap santri punya grid & pilihan bulannya sendiri.
    if (loaded.isFamily) {
      return _buildPerChildPayment(loaded.members);
    }

    // Mode tunggal: satu grid untuk santri yang dipilih.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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

  /// Mode keluarga: switcher chip per-santri + grid yang beranimasi saat ditukar.
  /// Tiap santri memilih bulan & nominalnya sendiri.
  Widget _buildPerChildPayment(List<FamilyMemberPayment> members) {
    final activeId = _activeChildId ?? members.first.santri.id;
    final active = members.firstWhere(
      (m) => m.santri.id == activeId,
      orElse: () => members.first,
    );
    final totalMonths = members.fold<int>(
      0,
      (sum, m) => sum + _childPeriodsCount(m.santri.id),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle('Pembayaran per Santri'),
            if (totalMonths > 0)
              Text(
                '$totalMonths bulan total',
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
          'Pilih bulan untuk tiap santri. Ketuk nama untuk berpindah kartu.',
          style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: members
                .map((m) => _buildChildChip(m, m.santri.id == activeId))
                .toList(),
          ),
        ),
        const SizedBox(height: 14),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            final slide = Tween<Offset>(
              begin: const Offset(0.06, 0),
              end: Offset.zero,
            ).animate(animation);
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(position: slide, child: child),
            );
          },
          child: _buildActiveChildCard(active),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  /// Chip switcher satu santri: avatar + nama depan + badge jumlah bulan.
  Widget _buildChildChip(FamilyMemberPayment member, bool active) {
    final s = member.santri;
    final count = _childPeriodsCount(s.id);

    final Color badgeBg;
    final Color badgeFg;
    if (active) {
      badgeBg = Colors.white;
      badgeFg = AppColors.primary;
    } else if (count > 0) {
      badgeBg = AppColors.primary;
      badgeFg = Colors.white;
    } else {
      badgeBg = AppColors.divider.withValues(alpha: 0.5);
      badgeFg = AppColors.textSecondary;
    }

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _activeChildId = s.id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: active ? AppColors.primary : AppColors.divider,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: active
                    ? Colors.white.withValues(alpha: 0.25)
                    : AppColors.primary.withValues(alpha: 0.12),
                child: Text(
                  UiUtils.getInitials(s.name),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: active ? Colors.white : AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                s.name.split(' ').first,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: active ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                constraints: const BoxConstraints(minWidth: 18),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: badgeFg,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Kartu santri aktif: identitas + nominal/bln + grid pilihannya + subtotal.
  Widget _buildActiveChildCard(FamilyMemberPayment member) {
    final s = member.santri;
    final periods = _periodsForChild(s.id);
    final amount = _childAmountValue(s.id);
    final subtotal = periods.length * amount;
    final firstName = s.name.split(' ').first;

    return Container(
      key: ValueKey(s.id),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: Text(
                  UiUtils.getInitials(s.name),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${s.kelas} • NIS ${s.nis}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: periods.isEmpty
                      ? AppColors.divider.withValues(alpha: 0.4)
                      : AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  periods.isEmpty ? 'Belum dipilih' : '${periods.length} bulan',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: periods.isEmpty
                        ? AppColors.textSecondary
                        : AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Text(
                'Nominal/bln',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(width: 12),
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
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 8),
          PaymentYearView(
            key: ValueKey('grid_${s.id}'),
            paidData: member.paid,
            startDate: _resolveStartDateFor(s),
            selectable: true,
            selectedData: _selectedByChild[s.id] ?? const <int, Set<int>>{},
            onToggleMonth: (y, m) => _toggleMonthForChild(s.id, y, m),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  periods.isEmpty
                      ? Icons.touch_app_outlined
                      : Icons.event_available,
                  color: AppColors.primary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    periods.isEmpty
                        ? 'Ketuk bulan untuk menagih $firstName'
                        : '${periods.length} bulan × ${_formatCurrency(amount)} = ${_formatCurrency(subtotal)}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Kartu total pembayaran. Mode tunggal: jumlah bulan × nominal. Mode
  /// keluarga: rincian tagihan tiap santri yang punya bulan terpilih.
  Widget _buildTotalCard(
    List<DateTime> periods, {
    required bool isFamily,
    required List<FamilyMemberPayment> members,
  }) {
    final int total;
    final String pillText;
    final Widget breakdown;

    if (isFamily) {
      int payCount = 0;
      int sum = 0;
      final lines = <Widget>[];
      for (final m in members) {
        final p = _periodsForChild(m.santri.id);
        if (p.isEmpty) continue;
        final amt = _childAmountValue(m.santri.id);
        payCount += p.length;
        sum += p.length * amt;
        lines.add(
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    m.santri.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${p.length} × ${_formatCurrency(amt)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      }
      total = sum;
      pillText = '$payCount pembayaran';
      breakdown = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lines,
      );
    } else {
      final count = periods.length;
      total = _amountValue * count;
      pillText = '$count bulan';
      breakdown = Text(
        '$count bulan × ${_formatCurrency(_amountValue)}',
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      );
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
          breakdown,
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
