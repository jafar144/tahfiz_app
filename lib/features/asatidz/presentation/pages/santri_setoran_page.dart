import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:khoirunnasyien/features/asatidz/domain/entities/active_halaqah.dart';
import 'package:khoirunnasyien/features/asatidz/presentation/cubit/santri_setoran_cubit.dart';
import 'package:khoirunnasyien/features/asatidz/presentation/cubit/santri_setoran_state.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/entities/halaqah_santri.dart';


class SantriSetoranPage extends StatefulWidget {
  final ActiveHalaqah activeHalaqah;
  final HalaqahSantri santri;

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
  final _hafalanController = TextEditingController(); // Replaces surah
  final _catatanController = TextEditingController();
  


  @override
  void dispose() {
    _hafalanController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: BlocBuilder<SantriSetoranCubit, SantriSetoranState>(
          builder: (context, state) {
            String title = 'Input Setoran';
            if (state is SantriSetoranDataLoaded && state.todaySetoran != null) {
              title = 'Edit Setoran';
            }
            return Text(title);
          },
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
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
          // Initial data loaded listener to populate fields for editing
          if (state is SantriSetoranDataLoaded && state.todaySetoran != null && !_hafalanController.text.isNotEmpty) {
             _hafalanController.text = state.todaySetoran!.surah;
             _catatanController.text = state.todaySetoran!.catatan;
          }
        },
        builder: (context, state) {
          if (state is SantriSetoranLoading) {
            return const Center(child: CircularProgressIndicator());
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
                        _buildHeader(), // Simplified header
                        const SizedBox(height: 20),
                        
                        _buildSectionLabel('Tanggal'),
                        const SizedBox(height: 8),
                        _buildDateInput(),
                        
                        const SizedBox(height: 20),
                        _buildSectionLabel('Hafalan'),
                        const SizedBox(height: 8),
                        _buildHafalanInput(),
                        
                        const SizedBox(height: 20),
                        _buildSectionLabel('Catatan Ustadz'),
                        const SizedBox(height: 8),
                        _buildCatatanInput(),
                        
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
              _buildSubmitButton(context, state is SantriSetoranDataLoaded ? state.isSubmitting : false, isEditing),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    final initial = widget.santri.name.isNotEmpty ? widget.santri.name[0].toUpperCase() : '?';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white,
            child: Text(
              initial,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.santri.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'NIS: ${widget.santri.nis}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildDateInput() {
    final now = DateTime.now();
    // Improved date format: DD/MM/YYYY
    final dateStr = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              dateStr,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ),
          const Icon(Icons.calendar_today, color: Colors.blue, size: 20),
        ],
      ),
    );
  }

  Widget _buildHafalanInput() {
    return TextFormField(
      controller: _hafalanController,
      decoration: InputDecoration(
        hintText: 'Contoh: Juz 30 Full, atau Al-Mulk 1-10',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Wajib diisi';
        }
        return null;
      },
    );
  }

  Widget _buildCatatanInput() {
    return TextFormField(
      controller: _catatanController,
      maxLines: 4,
      decoration: InputDecoration(
        hintText: 'Tulis catatan perbaikan makhroj atau tajwid...',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext context, bool isSubmitting, bool isEditing) {
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
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: isSubmitting ? null : _handleSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: isEditing ? Colors.orange : Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            icon: isSubmitting 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Icon(isEditing ? Icons.edit : Icons.save),
            label: Text(
              isSubmitting ? 'Menyimpan...' : (isEditing ? 'Perbarui Setoran' : 'Simpan Setoran'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    context.read<SantriSetoranCubit>().submitSetoran(
          surah: _hafalanController.text,
          catatan: _catatanController.text,
        );
  }
}
