import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:khoirunnasyien/core/theme/app_colors.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_app_bar.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_button.dart';
import 'package:khoirunnasyien/features/monthly_report/domain/entities/pembimbing_assessment.dart';
import 'package:khoirunnasyien/features/monthly_report/presentation/cubit/admin_assessment_cubit.dart';
import 'package:khoirunnasyien/features/monthly_report/presentation/cubit/admin_assessment_state.dart';
import 'package:khoirunnasyien/features/monthly_report/presentation/widgets/pembimbing_assessment_card.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminAssessmentPage extends StatefulWidget {
  const AdminAssessmentPage({super.key});

  @override
  State<AdminAssessmentPage> createState() => _AdminAssessmentPageState();
}

class _AdminAssessmentPageState extends State<AdminAssessmentPage> {
  String _gender = 'L'; // 'L' = Putra, 'P' = Putri
  late final DateTime _currentPeriod;
  late final DateTime _previousPeriod;
  late DateTime _selectedPeriod;

  static final _skeletonData = List.generate(
    4,
    (i) => PembimbingAssessment(
      asatidzId: 'skeleton_$i',
      asatidzName: 'Nama Pembimbing',
      gender: 'L',
      totalSantri: 10,
      unassessedSantri: const [
        UnassessedSantri(id: '1', name: 'Santri', nis: '0000'),
      ],
    ),
  );

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null);
    final cubit = context.read<AdminAssessmentCubit>();
    _currentPeriod = cubit.currentPeriod;
    _previousPeriod = DateTime(_currentPeriod.year, _currentPeriod.month - 1);
    _selectedPeriod = _currentPeriod;
    // Sekali muat untuk putra & putri; pindah tab tidak request ulang.
    cubit.load();
  }

  void _onGenderChanged(String gender) {
    if (gender == _gender) return;
    setState(() => _gender = gender);
  }

  Future<void> _changePeriod(DateTime period) async {
    if (_isSamePeriod(period, _selectedPeriod)) return;
    setState(() => _selectedPeriod = period);
    await _loadSelectedPeriod();
  }

  Future<void> _loadSelectedPeriod() {
    return context.read<AdminAssessmentCubit>().load(period: _selectedPeriod);
  }

  Future<void> _remind(PembimbingAssessment data) async {
    final messenger = ScaffoldMessenger.of(context);
    final cubit = context.read<AdminAssessmentCubit>();

    final rawPhone = await cubit.getPembimbingPhone(data.asatidzId);
    if (!mounted) return;

    if (rawPhone == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Nomor WhatsApp pembimbing belum tersedia'),
        ),
      );
      return;
    }

    var phone = rawPhone.replaceAll(RegExp(r'\D'), '');
    if (phone.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Nomor WhatsApp pembimbing tidak valid')),
      );
      return;
    }
    if (phone.startsWith('0')) {
      phone = '62${phone.substring(1)}';
    } else if (!phone.startsWith('62')) {
      phone = '62$phone';
    }

    final message = _buildReminderMessage(data);
    final url = Uri.parse(
      'https://wa.me/$phone?text=${Uri.encodeComponent(message)}',
    );

    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Gagal membuka WhatsApp')),
      );
    }
  }

  String _buildReminderMessage(PembimbingAssessment data) {
    final periode = _monthYearLabel(_selectedPeriod);
    final namaBergelar = _nameWithGelar(data.asatidzName, data.gender);
    final buffer = StringBuffer()
      ..writeln(
        'Assalamu\'alaikum, $namaBergelar. Sekedar mengingatkan '
        'berikut santri-santri yang belum diberikan penilaian di bulan $periode :',
      )
      ..writeln();
    for (var i = 0; i < data.unassessedSantri.length; i++) {
      final s = data.unassessedSantri[i];
      buffer.writeln('${i + 1}. ${s.name} (${s.nis})');
    }
    return buffer.toString().trimRight();
  }

  /// Menambahkan gelar (Ustadz/Ustadzah) di depan nama, sambil membuang
  /// awalan honorifik yang mungkin sudah ada agar tidak dobel.
  String _nameWithGelar(String name, String gender) {
    final gelar = gender.toUpperCase() == 'P' ? 'Ustadzah' : 'Ustadz';
    final cleaned = name
        .replaceFirst(
          RegExp(
            r'^\s*(ustadzah|ustadz|ustad|ustz|ust)\.?\s+',
            caseSensitive: false,
          ),
          '',
        )
        .trim();
    return '$gelar ${cleaned.isEmpty ? name : cleaned}';
  }

  bool _isSamePeriod(DateTime first, DateTime second) {
    return first.year == second.year && first.month == second.month;
  }

  String _monthYearLabel(DateTime period) {
    return '${DateFormat('MMMM', 'id_ID').format(period)} ${period.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AiwaAppBar(title: 'Penilaian Bulanan'),
      body: SafeArea(
        child: BlocBuilder<AdminAssessmentCubit, AdminAssessmentState>(
          builder: (context, state) {
            if (state is AdminAssessmentError) {
              return _buildError(state.message);
            }

            final isLoading =
                state is AdminAssessmentLoading ||
                state is AdminAssessmentInitial;
            final pembimbingList = state is AdminAssessmentLoaded
                ? state.byGender(_gender)
                : const <PembimbingAssessment>[];
            final previousMonthHasIncompleteAssessment =
                state is AdminAssessmentLoaded &&
                state.previousMonthHasIncompleteAssessment;

            return Column(
              children: [
                _buildHeader(
                  isLoading,
                  pembimbingList,
                  previousMonthHasIncompleteAssessment:
                      previousMonthHasIncompleteAssessment,
                ),
                _buildGenderToggle(),
                Expanded(
                  child: isLoading
                      ? _buildSkeleton()
                      : _buildList(pembimbingList),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(
    bool isLoading,
    List<PembimbingAssessment> list, {
    required bool previousMonthHasIncompleteAssessment,
  }) {
    final completed = list.where((p) => p.isComplete).length;
    final isCurrentPeriod = _isSamePeriod(_selectedPeriod, _currentPeriod);
    final isPreviousPeriod = _isSamePeriod(_selectedPeriod, _previousPeriod);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SizedBox.square(
                dimension: 48,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: IconButton(
                        key: const Key('admin_assessment_previous_month'),
                        tooltip: 'Lihat ${_monthYearLabel(_previousPeriod)}',
                        onPressed: !isLoading && isCurrentPeriod
                            ? () => _changePeriod(_previousPeriod)
                            : null,
                        icon: const Icon(Icons.chevron_left_rounded),
                      ),
                    ),
                    if (!isLoading &&
                        isCurrentPeriod &&
                        previousMonthHasIncompleteAssessment)
                      const Positioned(
                        right: 4,
                        top: 4,
                        child: _PreviousMonthIncompleteIndicator(),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Text(
                  _monthYearLabel(_selectedPeriod),
                  key: const Key('admin_assessment_period_label'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              SizedBox.square(
                dimension: 48,
                child: IconButton(
                  key: const Key('admin_assessment_next_month'),
                  tooltip: 'Lihat ${_monthYearLabel(_currentPeriod)}',
                  onPressed: !isLoading && isPreviousPeriod
                      ? () => _changePeriod(_currentPeriod)
                      : null,
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            isLoading
                ? 'Memuat data penilaian…'
                : '$completed dari ${list.length} pembimbing sudah menilai',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderToggle() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [_genderTab('Putra', 'L'), _genderTab('Putri', 'P')],
      ),
    );
  }

  Widget _genderTab(String label, String value) {
    final isSelected = _gender == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onGenderChanged(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return Skeletonizer(
      enabled: true,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _skeletonData.length,
        separatorBuilder: (_, _) => const SizedBox(height: 14),
        itemBuilder: (_, i) =>
            PembimbingAssessmentCard(data: _skeletonData[i], onRemind: () {}),
      ),
    );
  }

  Widget _buildList(List<PembimbingAssessment> list) {
    return RefreshIndicator(
      onRefresh: _loadSelectedPeriod,
      child: list.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [_buildEmpty()],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(height: 14),
              itemBuilder: (_, i) => PembimbingAssessmentCard(
                data: list[i],
                onRemind: () => _remind(list[i]),
              ),
            ),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Column(
        children: [
          Icon(Icons.groups_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Belum ada pembimbing dengan santri binaan\nuntuk kategori ini.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 56, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              'Gagal memuat data:\n$message',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, height: 1.5),
            ),
            const SizedBox(height: 20),
            AiwaButton(text: 'Coba Lagi', onPressed: _loadSelectedPeriod),
          ],
        ),
      ),
    );
  }
}

class _PreviousMonthIncompleteIndicator extends StatefulWidget {
  const _PreviousMonthIncompleteIndicator();

  @override
  State<_PreviousMonthIncompleteIndicator> createState() =>
      _PreviousMonthIncompleteIndicatorState();
}

class _PreviousMonthIncompleteIndicatorState
    extends State<_PreviousMonthIncompleteIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(count: 3);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Penilaian bulan sebelumnya belum lengkap',
      child: SizedBox.square(
        key: const Key('admin_assessment_previous_incomplete_indicator'),
        dimension: 14,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Opacity(
                  opacity: 1 - _controller.value,
                  child: Transform.scale(
                    scale: 0.7 + (_controller.value * 1.15),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red.withValues(alpha: 0.35),
                      ),
                    ),
                  ),
                ),
                child!,
              ],
            );
          },
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.red,
            ),
          ),
        ),
      ),
    );
  }
}
