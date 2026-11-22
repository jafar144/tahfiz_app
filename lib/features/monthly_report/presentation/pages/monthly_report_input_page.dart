import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_app_bar.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_button.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';
import 'package:khoirunnasyien/features/monthly_report/domain/entities/monthly_report.dart';
import 'package:khoirunnasyien/features/monthly_report/presentation/constants/monthly_report_palette.dart';
import 'package:khoirunnasyien/features/monthly_report/presentation/constants/monthly_report_strings.dart';
import 'package:khoirunnasyien/features/monthly_report/presentation/cubit/monthly_report_input_cubit.dart';
import 'package:khoirunnasyien/features/monthly_report/presentation/cubit/monthly_report_input_state.dart';
import 'package:khoirunnasyien/features/monthly_report/presentation/widgets/monthly_report_card.dart';

/// Form tambah/edit penilaian bulanan.
///
/// Urutan bagian mengikuti alur kerja pembimbing: evaluasi target bulan ini,
/// penilaian bulan ini, lalu target bulan depan.
class MonthlyReportInputPage extends StatefulWidget {
  final SantriEntity santri;
  final String asatidzId;
  final String asatidzName;
  final int bulan;
  final int tahun;

  const MonthlyReportInputPage({
    super.key,
    required this.santri,
    required this.asatidzId,
    required this.asatidzName,
    required this.bulan,
    required this.tahun,
  });

  @override
  State<MonthlyReportInputPage> createState() => _MonthlyReportInputPageState();
}

class _MonthlyReportInputPageState extends State<MonthlyReportInputPage> {
  static const _ink = MonthlyReportPalette.ink;
  static const _muted = MonthlyReportPalette.muted;
  static const _field = MonthlyReportPalette.field;
  static const _line = MonthlyReportPalette.line;
  static const _danger = MonthlyReportPalette.penalized;

  final _formKey = GlobalKey<FormState>();
  final _hafalanController = TextEditingController();
  final _notesController = TextEditingController();
  final _targetMinimumController = TextEditingController();
  final _targetOptimumController = TextEditingController();
  final _excuseController = TextEditingController();

  final _evaluationKey = GlobalKey();
  final _hafalanKey = GlobalKey();
  final _perkembanganKey = GlobalKey();
  final _akhlaqKey = GlobalKey();
  final _nextTargetKey = GlobalKey();

  int _nilaiPerkembangan = 0;
  int _nilaiAkhlaq = 0;
  MonthlyTargetResult _targetResult = MonthlyTargetResult.notAssessed;
  MonthlyPenaltyDecision _penalty = MonthlyPenaltyDecision.undecided;
  MonthlyReportInputReady? _ready;
  bool _didHydrate = false;
  bool _showErrors = false;

  String get _periode =>
      '${MonthlyReport.getNamaBulan(widget.bulan)} ${widget.tahun}';

  String get _nextPeriode {
    final next = DateTime(widget.tahun, widget.bulan + 1);
    return '${MonthlyReport.getNamaBulan(next.month)} ${next.year}';
  }

  bool get _hasTargetToEvaluate => _ready?.targetToEvaluate?.target != null;

  @override
  void dispose() {
    _hafalanController.dispose();
    _notesController.dispose();
    _targetMinimumController.dispose();
    _targetOptimumController.dispose();
    _excuseController.dispose();
    super.dispose();
  }

  void _hydrate(MonthlyReportInputReady state) {
    _didHydrate = true;
    final existing = state.existingReport;
    if (existing != null) {
      _hafalanController.text = existing.hafalanTerakhir;
      _notesController.text = existing.notes;
      _targetMinimumController.text = existing.target?.minimum ?? '';
      _targetOptimumController.text = existing.target?.optimum ?? '';
    }

    final source = state.targetToEvaluate;
    final evaluation = existing?.targetEvaluation;
    setState(() {
      _nilaiPerkembangan = existing?.nilaiPerkembangan ?? 0;
      _nilaiAkhlaq = existing?.nilaiAkhlaq ?? 0;
      if (source?.target != null &&
          evaluation?.evaluates(source!.id, source.target!) == true) {
        _targetResult = evaluation!.result;
        _penalty = evaluation.penalty;
        _excuseController.text = evaluation.penaltyExcuse;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MonthlyReportInputCubit, MonthlyReportInputState>(
      listener: (context, state) {
        if (state is MonthlyReportInputReady && !_didHydrate) {
          _hydrate(state);
        }
        if (state is MonthlyReportInputSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: MonthlyReportPalette.optimum,
            ),
          );
          Navigator.pop(context);
        }
        if (state is MonthlyReportInputError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: _danger),
          );
        }
      },
      builder: (context, state) {
        if (state is MonthlyReportInputReady) _ready = state;
        final isLoading =
            state is MonthlyReportInputLoading ||
            (state is MonthlyReportInputInitial && _ready == null);

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AiwaAppBar(title: MonthlyReportStrings.inputTitle),
          bottomNavigationBar: isLoading ? null : _buildSaveBar(),
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildForm(),
        );
      },
    );
  }

  Widget _buildForm() {
    final target = _ready?.targetToEvaluate?.target;

    return Form(
      key: _formKey,
      autovalidateMode: _showErrors
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(_ready?.latestReport),
            _Section(
              key: _evaluationKey,
              title: MonthlyReportStrings.targetPeriode(_periode),
              child: target == null
                  ? const Text(
                      MonthlyReportStrings.tidakAdaTarget,
                      style: TextStyle(fontSize: 14, color: _muted),
                    )
                  : _buildEvaluation(target),
            ),
            _Section(
              title: MonthlyReportStrings.penilaianPeriode(_periode),
              child: _buildAssessment(),
            ),
            _Section(
              key: _nextTargetKey,
              title: MonthlyReportStrings.targetPeriode(_nextPeriode),
              child: _buildNextTarget(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Kepala halaman ────────────────────────────────────────────────────

  Widget _buildHeader(MonthlyReport? previous) {
    final nis = widget.santri.nis.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.santri.name,
          style: const TextStyle(
            fontSize: 18,
            height: 1.3,
            fontWeight: FontWeight.w700,
            color: _ink,
          ),
        ),
        if (nis.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text('NIS $nis', style: const TextStyle(fontSize: 13, color: _muted)),
        ],
        if (previous != null) ...[
          const SizedBox(height: 16),
          _buildPreviousReport(previous),
        ],
      ],
    );
  }

  Widget _buildPreviousReport(MonthlyReport previous) {
    final periode =
        '${MonthlyReport.getNamaBulan(previous.bulan)} ${previous.tahun}';
    return Material(
      color: _field,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        key: const Key('monthly_report_previous'),
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showPreviousReport(previous),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 11, 8, 11),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      MonthlyReportStrings.penilaianPeriode(periode),
                      style: const TextStyle(fontSize: 12, color: _muted),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      previous.hafalanTerakhir,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _ink,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: _muted),
            ],
          ),
        ),
      ),
    );
  }

  void _showPreviousReport(MonthlyReport previous) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: MonthlyReportCard(report: previous),
        ),
      ),
    );
  }

  // ── Target bulan ini ──────────────────────────────────────────────────

  Widget _buildEvaluation(MonthlyTarget target) {
    final missingResult =
        _showErrors && _targetResult == MonthlyTargetResult.notAssessed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.only(left: 14),
          decoration: const BoxDecoration(
            border: Border(left: BorderSide(color: _line, width: 3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TargetLine(MonthlyReportStrings.minimum, target.minimum),
              const SizedBox(height: 12),
              _TargetLine(MonthlyReportStrings.optimum, target.optimum),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _ResultSelector(
          value: _targetResult,
          hasError: missingResult,
          onChanged: (result) => setState(() => _targetResult = result),
        ),
        if (missingResult) _errorText(MonthlyReportStrings.hasilTargetWajib),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: _targetResult == MonthlyTargetResult.notAchieved
              ? _buildPenaltyDecision()
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }

  Widget _buildPenaltyDecision() {
    final missingDecision =
        _showErrors && _penalty == MonthlyPenaltyDecision.undecided;

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            MonthlyReportStrings.tanyaHukuman,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _ink,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ChoiceButton(
                  key: const Key('penalty_penalized'),
                  label: MonthlyReportStrings.ya,
                  color: MonthlyReportPalette.penalized,
                  selected: _penalty == MonthlyPenaltyDecision.penalized,
                  hasError: missingDecision,
                  onTap: () => setState(
                    () => _penalty = MonthlyPenaltyDecision.penalized,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ChoiceButton(
                  key: const Key('penalty_excused'),
                  label: MonthlyReportStrings.tidak,
                  color: _ink,
                  selected: _penalty == MonthlyPenaltyDecision.excused,
                  hasError: missingDecision,
                  onTap: () =>
                      setState(() => _penalty = MonthlyPenaltyDecision.excused),
                ),
              ),
            ],
          ),
          if (missingDecision) _errorText(MonthlyReportStrings.hukumanWajib),
          if (_penalty == MonthlyPenaltyDecision.excused) ...[
            const SizedBox(height: 16),
            _label(MonthlyReportStrings.alasanTidakDihukum),
            TextFormField(
              key: const Key('penalty_excuse_field'),
              controller: _excuseController,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: _decoration(
                hint: MonthlyReportStrings.alasanHint,
                helper: MonthlyReportStrings.alasanHelper,
              ),
              validator: (value) =>
                  _targetResult == MonthlyTargetResult.notAchieved &&
                      _penalty == MonthlyPenaltyDecision.excused &&
                      (value ?? '').trim().isEmpty
                  ? MonthlyReportStrings.alasanWajib
                  : null,
            ),
          ],
        ],
      ),
    );
  }

  // ── Penilaian bulan ini ───────────────────────────────────────────────

  Widget _buildAssessment() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KeyedSubtree(
          key: _hafalanKey,
          child: _textField(
            label: MonthlyReportStrings.hafalanTerakhir,
            controller: _hafalanController,
            hint: MonthlyReportStrings.hafalanHint,
            maxLines: 3,
            required: true,
          ),
        ),
        const SizedBox(height: 20),
        _ScoreField(
          key: _perkembanganKey,
          label: MonthlyReportStrings.perkembangan,
          value: _nilaiPerkembangan,
          showError: _showErrors,
          onChanged: (value) => setState(() => _nilaiPerkembangan = value),
        ),
        const SizedBox(height: 20),
        _ScoreField(
          key: _akhlaqKey,
          label: MonthlyReportStrings.akhlaq,
          value: _nilaiAkhlaq,
          showError: _showErrors,
          onChanged: (value) => setState(() => _nilaiAkhlaq = value),
        ),
        const SizedBox(height: 20),
        _textField(
          label: MonthlyReportStrings.catatanOpsional,
          controller: _notesController,
          hint: MonthlyReportStrings.catatanHint,
          minLines: 2,
          maxLines: 5,
        ),
      ],
    );
  }

  // ── Target bulan depan ────────────────────────────────────────────────

  Widget _buildNextTarget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _textField(
          label: MonthlyReportStrings.minimum,
          controller: _targetMinimumController,
          hint: MonthlyReportStrings.targetMinimumHint,
          maxLines: 3,
          required: true,
        ),
        const SizedBox(height: 16),
        _textField(
          label: MonthlyReportStrings.optimum,
          controller: _targetOptimumController,
          hint: MonthlyReportStrings.targetOptimumHint,
          maxLines: 3,
          required: true,
        ),
      ],
    );
  }

  // ── Komponen kecil ────────────────────────────────────────────────────

  Widget _buildSaveBar() {
    final isSaving = _ready?.isSaving ?? false;
    final isUpdate = _ready?.existingReport != null;
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: AiwaButton(
            key: const Key('monthly_report_save'),
            text: isUpdate
                ? MonthlyReportStrings.perbaruiPenilaian
                : MonthlyReportStrings.simpanPenilaian,
            isLoading: isSaving,
            onPressed: _submit,
          ),
        ),
      ),
    );
  }

  Widget _textField({
    required String label,
    required TextEditingController controller,
    required String hint,
    int minLines = 1,
    int maxLines = 1,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _label(label),
        TextFormField(
          controller: controller,
          minLines: minLines,
          maxLines: maxLines,
          keyboardType: TextInputType.multiline,
          textCapitalization: TextCapitalization.sentences,
          decoration: _decoration(hint: hint),
          validator: required
              ? (value) => (value ?? '').trim().isEmpty
                    ? MonthlyReportStrings.wajibDiisi
                    : null
              : null,
        ),
      ],
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: _muted,
        ),
      ),
    );
  }

  InputDecoration _decoration({required String hint, String? helper}) {
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: width == 0
          ? BorderSide.none
          : BorderSide(color: color, width: width),
    );
    final primary = Theme.of(context).colorScheme.primary;

    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
      helperText: helper,
      helperStyle: const TextStyle(fontSize: 12, color: _muted),
      errorStyle: const TextStyle(fontSize: 12, color: _danger),
      filled: true,
      fillColor: _field,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: border(_field, 0),
      enabledBorder: border(_field, 0),
      focusedBorder: border(primary, 1.5),
      errorBorder: border(_danger, 1),
      focusedErrorBorder: border(_danger, 1.5),
    );
  }

  Widget _errorText(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 2),
      child: Text(text, style: const TextStyle(fontSize: 12, color: _danger)),
    );
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    setState(() => _showErrors = true);
    final formValid = _formKey.currentState!.validate();

    final notAchieved = _targetResult == MonthlyTargetResult.notAchieved;
    final evaluationIncomplete =
        _hasTargetToEvaluate &&
        (_targetResult == MonthlyTargetResult.notAssessed ||
            (notAchieved &&
                (_penalty == MonthlyPenaltyDecision.undecided ||
                    (_penalty == MonthlyPenaltyDecision.excused &&
                        _excuseController.text.trim().isEmpty))));

    // Urutan mengikuti posisi di layar agar gulir ke kesalahan teratas.
    final invalidKeys = [
      if (evaluationIncomplete) _evaluationKey,
      if (_hafalanController.text.trim().isEmpty) _hafalanKey,
      if (_nilaiPerkembangan == 0) _perkembanganKey,
      if (_nilaiAkhlaq == 0) _akhlaqKey,
      if (_targetMinimumController.text.trim().isEmpty ||
          _targetOptimumController.text.trim().isEmpty)
        _nextTargetKey,
    ];
    if (!formValid || invalidKeys.isNotEmpty) {
      final target = invalidKeys.isEmpty
          ? null
          : invalidKeys.first.currentContext;
      if (target != null) {
        Scrollable.ensureVisible(
          target,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          alignment: 0.05,
        );
      }
      return;
    }

    context.read<MonthlyReportInputCubit>().saveReport(
      asatidzId: widget.asatidzId,
      asatidzName: widget.asatidzName,
      santriId: widget.santri.id,
      santriName: widget.santri.name,
      bulan: widget.bulan,
      tahun: widget.tahun,
      hafalanTerakhir: _hafalanController.text.trim(),
      nilaiPerkembangan: _nilaiPerkembangan,
      nilaiAkhlaq: _nilaiAkhlaq,
      targetMinimum: _targetMinimumController.text.trim(),
      targetOptimum: _targetOptimumController.text.trim(),
      targetResult: _targetResult,
      penalty: notAchieved ? _penalty : MonthlyPenaltyDecision.undecided,
      penaltyExcuse: _excuseController.text.trim(),
      notes: _notesController.text.trim(),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Divider(height: 1, color: MonthlyReportPalette.line),
          const SizedBox(height: 22),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              color: MonthlyReportPalette.ink,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _TargetLine extends StatelessWidget {
  final String label;
  final String value;

  const _TargetLine(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: MonthlyReportPalette.muted,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            height: 1.4,
            color: MonthlyReportPalette.ink,
          ),
        ),
      ],
    );
  }
}

/// Pemilih hasil target: tiga segmen dengan warna sesuai capaian.
class _ResultSelector extends StatelessWidget {
  final MonthlyTargetResult value;
  final bool hasError;
  final ValueChanged<MonthlyTargetResult> onChanged;

  const _ResultSelector({
    required this.value,
    required this.hasError,
    required this.onChanged,
  });

  static const _options = [
    (
      MonthlyTargetResult.notAchieved,
      MonthlyReportStrings.tidakCapai,
      MonthlyReportPalette.notAchieved,
    ),
    (
      MonthlyTargetResult.minimumAchieved,
      MonthlyReportStrings.minimum,
      MonthlyReportPalette.minimum,
    ),
    (
      MonthlyTargetResult.optimumAchieved,
      MonthlyReportStrings.optimum,
      MonthlyReportPalette.optimum,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: MonthlyReportPalette.field,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasError ? MonthlyReportPalette.penalized : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          for (final (result, label, color) in _options)
            Expanded(
              child: Semantics(
                button: true,
                selected: value == result,
                child: GestureDetector(
                  key: Key('target_result_${result.name}'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(result),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: value == result ? color : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: value == result
                              ? Colors.white
                              : MonthlyReportPalette.ink.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final bool hasError;
  final VoidCallback onTap;

  const _ChoiceButton({
    super.key,
    required this.label,
    required this.color,
    required this.selected,
    required this.hasError,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? color
        : hasError
        ? MonthlyReportPalette.penalized
        : MonthlyReportPalette.line;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? color.withValues(alpha: 0.07) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: borderColor, width: selected ? 1.5 : 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 46,
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: selected ? color : MonthlyReportPalette.ink,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Nilai 1–5 dengan label kualitatif di kanan judul.
class _ScoreField extends StatelessWidget {
  final String label;
  final int value;
  final bool showError;
  final ValueChanged<int> onChanged;

  const _ScoreField({
    super.key,
    required this.label,
    required this.value,
    required this.showError,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final missing = showError && value == 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: MonthlyReportPalette.muted,
                ),
              ),
              const Spacer(),
              if (value > 0)
                Text(
                  MonthlyReport.getNilaiLabel(value),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _scoreColor(value),
                  ),
                ),
            ],
          ),
        ),
        Row(
          children: [
            for (var score = 1; score <= 5; score++) ...[
              if (score > 1) const SizedBox(width: 8),
              Expanded(
                child: Semantics(
                  button: true,
                  selected: value == score,
                  label: '$label $score',
                  excludeSemantics: true,
                  child: Material(
                    color: value == score
                        ? primary
                        : MonthlyReportPalette.field,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      key: Key('score_${label.toLowerCase()}_$score'),
                      onTap: () => onChanged(score),
                      child: SizedBox(
                        height: 46,
                        child: Center(
                          child: Text(
                            '$score',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: value == score
                                  ? Colors.white
                                  : MonthlyReportPalette.ink.withValues(
                                      alpha: 0.7,
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        if (missing)
          const Padding(
            padding: EdgeInsets.only(top: 6, left: 2),
            child: Text(
              MonthlyReportStrings.pilihNilai,
              style: TextStyle(
                fontSize: 12,
                color: MonthlyReportPalette.penalized,
              ),
            ),
          ),
      ],
    );
  }

  static Color _scoreColor(int score) => switch (score) {
    5 => const Color(0xFF15803D),
    4 => const Color(0xFF16A34A),
    3 => const Color(0xFFA16207),
    2 => const Color(0xFFC2410C),
    _ => MonthlyReportPalette.penalized,
  };
}
