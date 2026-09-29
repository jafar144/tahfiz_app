import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:khoirunnasyien/core/theme/app_colors.dart';
import 'package:khoirunnasyien/core/utils/whatsapp_utils.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_app_bar.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_button.dart';
import 'package:khoirunnasyien/features/monthly_report/domain/entities/pembimbing_assessment.dart';
import 'package:khoirunnasyien/features/monthly_report/domain/entities/target_achievement_recap.dart';
import 'package:khoirunnasyien/features/monthly_report/presentation/cubit/admin_assessment_cubit.dart';
import 'package:khoirunnasyien/features/monthly_report/presentation/cubit/admin_assessment_state.dart';
import 'package:khoirunnasyien/features/monthly_report/presentation/widgets/pembimbing_assessment_card.dart';
import 'package:khoirunnasyien/features/monthly_report/presentation/widgets/target_achievement_recap_panel.dart';
import 'package:skeletonizer/skeletonizer.dart';

class AdminAssessmentPage extends StatefulWidget {
  const AdminAssessmentPage({super.key});

  @override
  State<AdminAssessmentPage> createState() => _AdminAssessmentPageState();
}

class _AdminAssessmentPageState extends State<AdminAssessmentPage> {
  String _gender = 'L'; // 'L' = Putra, 'P' = Putri
  bool _showRecap = false;
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
    // Sekali muat untuk putra & putri; pindah menu tidak request ulang.
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

  Future<void> _refreshSelectedPeriod() {
    return context.read<AdminAssessmentCubit>().load(
      period: _selectedPeriod,
      forceRefresh: true,
    );
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

    final message = _buildReminderMessage(data);
    final result = await WhatsAppUtils.launch(rawPhone, message: message);
    if (!mounted || result == WhatsAppLaunchResult.opened) return;

    final errorMessage = switch (result) {
      WhatsAppLaunchResult.invalidPhone =>
        'Nomor WhatsApp pembimbing tidak valid',
      WhatsAppLaunchResult.unavailable =>
        'WhatsApp tidak dapat dibuka. Pastikan WhatsApp atau browser tersedia.',
      WhatsAppLaunchResult.opened => '',
    };
    messenger.showSnackBar(SnackBar(content: Text(errorMessage)));
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
      bottomNavigationBar: _buildBottomNavigation(),
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<AdminAssessmentCubit, AdminAssessmentState>(
          builder: (context, state) {
            final isLoading =
                state is AdminAssessmentLoading ||
                state is AdminAssessmentInitial;
            final loadedState = state is AdminAssessmentLoaded ? state : null;
            final pembimbingList = loadedState != null
                ? loadedState.byGender(_gender)
                : const <PembimbingAssessment>[];
            final previousMonthHasIncompleteAssessment =
                loadedState?.previousMonthHasIncompleteAssessment ?? false;

            return Column(
              children: [
                _buildHeader(
                  isLoading,
                  previousMonthHasIncompleteAssessment:
                      previousMonthHasIncompleteAssessment,
                ),
                Expanded(
                  child: state is AdminAssessmentError
                      ? _buildError(state.message)
                      : _showRecap
                      ? _buildRecap(loadedState?.targetAchievementRecap)
                      : _buildAssessment(pembimbingList, isLoading: isLoading),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: BottomNavigationBar(
        key: const Key('admin_assessment_bottom_navigation'),
        currentIndex: _showRecap ? 1 : 0,
        onTap: (index) {
          final showRecap = index == 1;
          if (showRecap == _showRecap) return;
          setState(() => _showRecap = showRecap);
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 0,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        selectedLabelStyle: const TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w500,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.fact_check_outlined),
            activeIcon: Icon(Icons.fact_check_rounded),
            label: 'Penilaian',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart_rounded),
            label: 'Rekap Bulanan',
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    bool isLoading, {
    required bool previousMonthHasIncompleteAssessment,
  }) {
    final isCurrentPeriod = _isSamePeriod(_selectedPeriod, _currentPeriod);
    final isPreviousPeriod = _isSamePeriod(_selectedPeriod, _previousPeriod);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
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
      child: Semantics(
        selected: isSelected,
        child: TextButton(
          onPressed: () => _onGenderChanged(value),
          style: TextButton.styleFrom(
            backgroundColor: isSelected
                ? AppColors.primary.withValues(alpha: 0.08)
                : Colors.transparent,
            foregroundColor: isSelected
                ? AppColors.primary
                : AppColors.textSecondary,
            minimumSize: const Size(0, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  Widget _buildAssessment(
    List<PembimbingAssessment> list, {
    required bool isLoading,
  }) {
    final completed = list.where((p) => p.isComplete).length;
    final visibleList = isLoading ? _skeletonData : list;
    return RefreshIndicator(
      onRefresh: _refreshSelectedPeriod,
      child: CustomScrollView(
        key: const PageStorageKey('admin_assessment_list'),
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Status penilaian',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isLoading
                            ? 'Memuat data penilaian…'
                            : '$completed dari ${list.length} pembimbing sudah menilai',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildGenderToggle(),
              ],
            ),
          ),
          if (visibleList.isEmpty)
            SliverToBoxAdapter(child: _buildEmpty())
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              sliver: SliverList.separated(
                itemCount: visibleList.length,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (_, i) => Skeletonizer(
                  enabled: isLoading,
                  child: PembimbingAssessmentCard(
                    data: visibleList[i],
                    onRemind: () => _remind(visibleList[i]),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecap(TargetAchievementRecap? recap) {
    if (recap == null) {
      return const Center(
        child: CircularProgressIndicator(
          semanticsLabel: 'Memuat rekap bulanan',
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _refreshSelectedPeriod,
      child: ListView(
        key: const PageStorageKey('admin_target_recap'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          TargetAchievementRecapPanel(
            recap: recap,
            periodLabel: _monthYearLabel(_selectedPeriod),
          ),
        ],
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
      child: SingleChildScrollView(
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
