import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_app_bar.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_button.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';
import 'package:khoirunnasyien/features/monthly_report/domain/entities/monthly_report.dart';
import 'package:khoirunnasyien/features/monthly_report/presentation/cubit/monthly_report_input_cubit.dart';
import 'package:khoirunnasyien/features/monthly_report/presentation/cubit/monthly_report_input_state.dart';

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
  int _nilaiPerkembangan = 0;
  int _nilaiAkhlaq = 0;

  @override
  void dispose() {
    _hafalanController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AiwaAppBar(
        title: 'Penilaian Santri',
      ),
      body: BlocConsumer<MonthlyReportInputCubit, MonthlyReportInputState>(
        listener: (context, state) {
          if (state is MonthlyReportInputReady && state.existingReport != null && _hafalanController.text.isEmpty) {
            final r = state.existingReport!;
            _hafalanController.text = r.hafalanTerakhir;
            _notesController.text = r.notes;
            setState(() {
              _nilaiPerkembangan = r.nilaiPerkembangan;
              _nilaiAkhlaq = r.nilaiAkhlaq;
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
          final isUpdate = state is MonthlyReportInputReady && state.existingReport != null;

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
                  const SizedBox(height: 24),
                  _buildHafalanField(),
                  const SizedBox(height: 24),
                  _buildNilaiSection('Perkembangan', _nilaiPerkembangan, Icons.trending_up_rounded, (val) {
                    setState(() => _nilaiPerkembangan = val);
                  }),
                  const SizedBox(height: 24),
                  _buildNilaiSection('Akhlaq', _nilaiAkhlaq, Icons.favorite_rounded, (val) {
                    setState(() => _nilaiAkhlaq = val);
                  }),
                  const SizedBox(height: 24),
                  _buildNotesField(),
                  const SizedBox(height: 32),
                  AiwaButton(
                    text: isUpdate ? 'Perbarui Penilaian' : 'Simpan Penilaian',
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
            color: Colors.grey.withOpacity(0.06),
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
              color: color.withOpacity(0.1),
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
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
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
            'Periode: ${MonthlyReport.getNamaBulan(widget.bulan)} ${widget.tahun}',
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

  Widget _buildHafalanField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('Hafalan Terakhir', Icons.menu_book_rounded),
        const SizedBox(height: 8),
        TextFormField(
          controller: _hafalanController,
          keyboardType: TextInputType.multiline,
          minLines: 1,
          maxLines: null,
          textInputAction: TextInputAction.newline,
          decoration: InputDecoration(
            hintText: 'Contoh: Al-Baqarah ayat 1-20',
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
              borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          validator: (val) => (val == null || val.trim().isEmpty) ? 'Wajib diisi' : null,
        ),
      ],
    );
  }

  Widget _buildNilaiSection(String label, int currentValue, IconData icon, ValueChanged<int> onChanged) {
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
                          ? [BoxShadow(color: primary.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2))]
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
                'Pilih nilai',
                style: TextStyle(fontSize: 12, color: Colors.red.shade400, fontWeight: FontWeight.w500),
              )
            : Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: _getNilaiColor(currentValue), shape: BoxShape.circle),
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
        _buildSectionLabel('Catatan (Opsional)', Icons.notes_rounded),
        const SizedBox(height: 8),
        TextFormField(
          controller: _notesController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Tambahkan catatan...',
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
              borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
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
          content: Text('Harap pilih nilai Perkembangan dan Akhlaq'),
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
      notes: _notesController.text.trim(),
    );
  }

  Color _getNilaiColor(int nilai) {
    switch (nilai) {
      case 5: return const Color(0xFF16A34A);
      case 4: return const Color(0xFF22C55E);
      case 3: return const Color(0xFFEAB308);
      case 2: return const Color(0xFFF97316);
      case 1: return const Color(0xFFEF4444);
      default: return Colors.grey;
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
