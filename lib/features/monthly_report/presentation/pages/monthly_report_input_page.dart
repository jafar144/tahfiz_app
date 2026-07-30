import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_app_bar.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_button.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';
import 'package:khoirunnasyien/features/monthly_report/domain/entities/monthly_report.dart';
import 'package:khoirunnasyien/features/monthly_report/presentation/constants/monthly_report_strings.dart';
import 'package:khoirunnasyien/features/monthly_report/presentation/cubit/monthly_report_input_cubit.dart';
import 'package:khoirunnasyien/features/monthly_report/presentation/cubit/monthly_report_input_state.dart';
import 'package:khoirunnasyien/features/monthly_report/presentation/widgets/monthly_report_card.dart';

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
  final _formKey = GlobalKey<FormState>();
  final _hafalanController = TextEditingController();
  final _notesController = TextEditingController();
  final _targetMinimumController = TextEditingController();
  final _targetOptimumController = TextEditingController();
  int _nilaiPerkembangan = 0;
  int _nilaiAkhlaq = 0;
  MonthlyTargetResult _targetResult = MonthlyTargetResult.notAssessed;
  bool _didHydrate = false;

  @override
  void dispose() {
    _hafalanController.dispose();
    _notesController.dispose();
    _targetMinimumController.dispose();
    _targetOptimumController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AiwaAppBar(title: MonthlyReportStrings.inputTitle),
      body: BlocConsumer<MonthlyReportInputCubit, MonthlyReportInputState>(
        listener: (context, state) {
          if (state is MonthlyReportInputReady && !_didHydrate) {
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
              }
            });
          }
          if (state is MonthlyReportInputSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
          }
          if (state is MonthlyReportInputError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is MonthlyReportInputLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final isSaving = state is MonthlyReportInputReady && state.isSaving;
          final isUpdate =
              state is MonthlyReportInputReady && state.existingReport != null;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSantriHeader(),
                  const SizedBox(height: 8),
                  _buildPeriodInfo(),
                  if (state is MonthlyReportInputReady &&
                      state.latestReport != null) ...[
                    const SizedBox(height: 20),
                    _buildSectionLabel(
                      MonthlyReportStrings.penilaianTerakhir,
                      Icons.history_rounded,
                    ),
                    const SizedBox(height: 10),
                    MonthlyReportCard(report: state.latestReport!),
                  ],
                  if (state is MonthlyReportInputReady &&
                      state.targetToEvaluate?.target != null) ...[
                    const SizedBox(height: 24),
                    _buildTargetEvaluationSection(state.targetToEvaluate!),
                  ],
                  const SizedBox(height: 24),
                  _buildHafalanField(),
                  const SizedBox(height: 24),
                  _buildNilaiSection(
                    MonthlyReportStrings.perkembangan,
                    _nilaiPerkembangan,
                    Icons.trending_up_rounded,
                    (val) {
                      setState(() => _nilaiPerkembangan = val);
                    },
                  ),
                  const SizedBox(height: 24),
                  _buildNilaiSection(
                    MonthlyReportStrings.akhlaq,
                    _nilaiAkhlaq,
                    Icons.favorite_rounded,
                    (val) {
                      setState(() => _nilaiAkhlaq = val);
                    },
                  ),
                  const SizedBox(height: 24),
                  _buildNextTargetSection(),
                  const SizedBox(height: 24),
                  _buildNotesField(),
                  const SizedBox(height: 32),
                  AiwaButton(
                    text: isUpdate
                        ? MonthlyReportStrings.perbaruiPenilaian
                        : MonthlyReportStrings.simpanPenilaian,
                    isLoading: isSaving,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSantriHeader() {
    final isMale = widget.santri.jenisKelamin == 'L';
    final color = isMale ? Colors.blue : Colors.red;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              _getInitials(widget.santri.name),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.santri.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.santri.nis,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Icon(Icons.calendar_month, size: 14, color: Colors.grey.shade500),
          const SizedBox(width: 6),
          Text(
            MonthlyReportStrings.periode(
              MonthlyReport.getNamaBulan(widget.bulan),
              widget.tahun,
            ),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetEvaluationSection(MonthlyReport sourceReport) {
    final target = sourceReport.target!;
    const emerald = Color(0xFF0F766E);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(
          MonthlyReportStrings.evaluasiTarget,
          Icons.task_alt_rounded,
        ),
        const SizedBox(height: 6),
        Text(
          MonthlyReportStrings.evaluasiTargetHint,
          style: TextStyle(
            fontSize: 12,
            height: 1.4,
            color: Colors.grey.shade500,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDFA),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFCCFBF1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.flag_rounded,
                      size: 19,
                      color: emerald,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${MonthlyReport.getNamaBulan(target.bulan)} '
                      '${target.tahun}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF134E4A),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildTargetBrief(
                MonthlyReportStrings.targetMinimum,
                target.minimum,
                Icons.spa_outlined,
              ),
              const SizedBox(height: 10),
              _buildTargetBrief(
                MonthlyReportStrings.targetOptimum,
                target.optimum,
                Icons.auto_awesome_rounded,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildTargetResultOption(
          MonthlyTargetResult.notAchieved,
          'Belum tercapai',
          'Target minimum masih perlu dilanjutkan',
          Icons.refresh_rounded,
          const Color(0xFFB45309),
        ),
        const SizedBox(height: 8),
        _buildTargetResultOption(
          MonthlyTargetResult.minimumAchieved,
          'Minimum tercapai',
          'Batas minimum berhasil dituntaskan',
          Icons.check_circle_outline_rounded,
          const Color(0xFF059669),
        ),
        const SizedBox(height: 8),
        _buildTargetResultOption(
          MonthlyTargetResult.optimumAchieved,
          'Optimum tercapai',
          'Target terbaik berhasil dituntaskan',
          Icons.workspace_premium_outlined,
          const Color(0xFF0F766E),
        ),
      ],
    );
  }

  Widget _buildTargetBrief(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: const Color(0xFF0F766E)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: Color(0xFF5F8F89),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: Color(0xFF134E4A),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTargetResultOption(
    MonthlyTargetResult result,
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    final selected = _targetResult == result;
    return InkWell(
      onTap: () => setState(() => _targetResult = result),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.07) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : Colors.grey.shade200,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 21,
              color: selected ? color : Colors.grey.shade400,
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: selected ? color : Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 21,
              height: 21,
              decoration: BoxDecoration(
                color: selected ? color : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? color : Colors.grey.shade300,
                ),
              ),
              child: selected
                  ? const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextTargetSection() {
    final next = DateTime(widget.tahun, widget.bulan + 1);
    const emerald = Color(0xFF0F766E);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(
          '${MonthlyReportStrings.targetBulanDepan} · '
          '${MonthlyReport.getNamaBulan(next.month)} ${next.year}',
          Icons.flag_rounded,
        ),
        const SizedBox(height: 6),
        Text(
          MonthlyReportStrings.targetBulanDepanHint,
          style: TextStyle(
            fontSize: 12,
            height: 1.4,
            color: Colors.grey.shade500,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            children: [
              _buildTargetField(
                controller: _targetMinimumController,
                label: MonthlyReportStrings.targetMinimum,
                hint: MonthlyReportStrings.targetMinimumHint,
                icon: Icons.spa_outlined,
                color: const Color(0xFF059669),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Divider(height: 1, color: Color(0xFFF3F4F6)),
              ),
              _buildTargetField(
                controller: _targetOptimumController,
                label: MonthlyReportStrings.targetOptimum,
                hint: MonthlyReportStrings.targetOptimumHint,
                icon: Icons.auto_awesome_rounded,
                color: emerald,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTargetField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 17, color: color),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          minLines: 2,
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 12.5,
              height: 1.4,
            ),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: color, width: 1.5),
            ),
            contentPadding: const EdgeInsets.all(13),
          ),
          validator: (value) => value == null || value.trim().isEmpty
              ? MonthlyReportStrings.wajibDiisi
              : null,
        ),
      ],
    );
  }

  Widget _buildHafalanField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(
          MonthlyReportStrings.hafalanTerakhir,
          Icons.menu_book_rounded,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _hafalanController,
          keyboardType: TextInputType.multiline,
          minLines: 1,
          maxLines: null,
          textInputAction: TextInputAction.newline,
          decoration: InputDecoration(
            hintText: MonthlyReportStrings.hafalanHint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: Theme.of(context).primaryColor,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          validator: (val) => (val == null || val.trim().isEmpty)
              ? MonthlyReportStrings.wajibDiisi
              : null,
        ),
      ],
    );
  }

  Widget _buildNilaiSection(
    String label,
    int currentValue,
    IconData icon,
    ValueChanged<int> onChanged,
  ) {
    final primary = Theme.of(context).primaryColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(label, icon),
        const SizedBox(height: 10),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: List.generate(5, (index) {
              final nilai = index + 1;
              final isSelected = currentValue == nilai;

              return Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(nilai),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    margin: const EdgeInsets.all(4),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: primary.withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      '$nilai',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : Colors.grey.shade500,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 8),
        currentValue == 0
            ? Text(
                MonthlyReportStrings.pilihNilai,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red.shade400,
                  fontWeight: FontWeight.w500,
                ),
              )
            : Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _getNilaiColor(currentValue),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    MonthlyReport.getNilaiLabel(currentValue),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _getNilaiColor(currentValue),
                    ),
                  ),
                ],
              ),
      ],
    );
  }

  Widget _buildNotesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(
          MonthlyReportStrings.catatanOpsional,
          Icons.notes_rounded,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _notesController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: MonthlyReportStrings.catatanHint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: Theme.of(context).primaryColor,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade700),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_nilaiPerkembangan == 0 || _nilaiAkhlaq == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(MonthlyReportStrings.pilihNilaiPerkembanganAkhlaq),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final inputState = context.read<MonthlyReportInputCubit>().state;
    if (inputState is MonthlyReportInputReady &&
        inputState.targetToEvaluate != null &&
        _targetResult == MonthlyTargetResult.notAssessed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(MonthlyReportStrings.hasilTargetWajib),
          backgroundColor: Colors.orange,
        ),
      );
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
      notes: _notesController.text.trim(),
    );
  }

  Color _getNilaiColor(int nilai) {
    switch (nilai) {
      case 5:
        return const Color(0xFF16A34A);
      case 4:
        return const Color(0xFF22C55E);
      case 3:
        return const Color(0xFFEAB308);
      case 2:
        return const Color(0xFFF97316);
      case 1:
        return const Color(0xFFEF4444);
      default:
        return Colors.grey;
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '';
    final parts = name.split(' ');
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }
}
