import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_app_bar.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_button.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_form_widgets.dart';
import 'package:khoirunnasyien/features/asatidz/domain/entities/active_halaqah.dart';
import 'package:khoirunnasyien/features/asatidz/presentation/cubit/santri_setoran_cubit.dart';
import 'package:khoirunnasyien/features/asatidz/presentation/cubit/santri_setoran_state.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';
import 'package:skeletonizer/skeletonizer.dart';

class SantriSetoranPage extends StatefulWidget {
  final ActiveHalaqah activeHalaqah;
  final SantriEntity santri;

  const SantriSetoranPage({
    super.key,
    required this.activeHalaqah,
    required this.santri,
  });

  @override
  State<SantriSetoranPage> createState() => _SantriSetoranPageState();
}

class _SantriSetoranPageState extends State<SantriSetoranPage> {
  final _formKey = GlobalKey<FormState>();
  final _hafalanController = TextEditingController();
  final _catatanController = TextEditingController();

  @override
  void dispose() {
    _hafalanController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SantriSetoranCubit, SantriSetoranState>(
      buildWhen: (prev, curr) {
        final wasEditing = prev is SantriSetoranDataLoaded && prev.todaySetoran != null;
        final isEditing = curr is SantriSetoranDataLoaded && curr.todaySetoran != null;
        return wasEditing != isEditing;
      },
      builder: (context, titleState) {
        final appBarTitle = (titleState is SantriSetoranDataLoaded && titleState.todaySetoran != null)
            ? 'Edit Setoran'
            : 'Input Setoran';

        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: AiwaAppBar(title: appBarTitle),
          body: BlocConsumer<SantriSetoranCubit, SantriSetoranState>(
            listener: (context, state) {
              if (state is SantriSetoranSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pop(context);
              }
              if (state is SantriSetoranError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                  ),
                );
              }
              if (state is SantriSetoranDataLoaded && state.todaySetoran != null && !_hafalanController.text.isNotEmpty) {
                _hafalanController.text = state.todaySetoran!.surah;
                _catatanController.text = state.todaySetoran!.catatan;
              }
            },
            builder: (context, state) {
              if (state is SantriSetoranLoading) {
                return _buildSkeleton();
              }

              bool isEditing = false;
              if (state is SantriSetoranDataLoaded && state.todaySetoran != null) {
                isEditing = true;
              }

              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(),
                            const SizedBox(height: 24),
                            AiwaClickableInput(
                              label: 'Tanggal',
                              value: _formattedDate(),
                              icon: Icons.calendar_today_rounded,
                              onTap: () {},
                            ),
                            const SizedBox(height: 20),
                            AiwaTextField(
                              label: 'Hafalan',
                              hint: 'Contoh: Juz 30, Al-Mulk 1-10',
                              icon: Icons.menu_book_rounded,
                              controller: _hafalanController,
                            ),
                            const SizedBox(height: 20),
                            AiwaTextField(
                              label: 'Catatan Ustadz',
                              hint: 'Tulis catatan perbaikan makhroj atau tajwid...',
                              icon: Icons.edit_note_rounded,
                              controller: _catatanController,
                              maxLines: 4,
                              isOptional: true,
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _buildSubmitSection(
                    isSubmitting: state is SantriSetoranDataLoaded ? state.isSubmitting : false,
                    isEditing: isEditing,
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  String _formattedDate() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
  }

  Widget _buildHeader() {
    final initial = widget.santri.name.isNotEmpty ? widget.santri.name[0].toUpperCase() : '?';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.blue.shade100.withOpacity(0.4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Text(
                initial,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
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
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'NIS: ${widget.santri.nis}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.menu_book_rounded, color: Colors.blue.shade400, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitSection({required bool isSubmitting, required bool isEditing}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: AiwaButton(
          text: isEditing ? 'Perbarui Setoran' : 'Simpan Setoran',
          isLoading: isSubmitting,
          onPressed: _handleSubmit,
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return Skeletonizer(
      enabled: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: 140, height: 16, color: Colors.grey.shade300),
                      const SizedBox(height: 6),
                      Container(width: 80, height: 12, color: Colors.grey.shade200),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(width: 60, height: 13, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 20),
            Container(width: 60, height: 13, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 20),
            Container(width: 100, height: 13, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;

    context.read<SantriSetoranCubit>().submitSetoran(
          surah: _hafalanController.text,
          catatan: _catatanController.text,
        );
  }
}
