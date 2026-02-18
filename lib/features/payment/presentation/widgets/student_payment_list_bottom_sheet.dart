import 'package:flutter/material.dart';
import 'package:khoirunnasyien/core/utils/format_utils.dart';
import 'package:khoirunnasyien/core/utils/message_utils.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';
import 'package:khoirunnasyien/features/payment/presentation/widgets/payment_santri_card.dart';
import 'package:url_launcher/url_launcher.dart';

class StudentPaymentListBottomSheet extends StatefulWidget {
  final String title;
  final List<SantriEntity> students;
  final String monthYear;
  final bool showWhatsApp;

  const StudentPaymentListBottomSheet({
    super.key,
    required this.title,
    required this.students,
    required this.monthYear,
    this.showWhatsApp = true,
  });

  @override
  State<StudentPaymentListBottomSheet> createState() =>
      _StudentPaymentListBottomSheetState();
}

class _StudentPaymentListBottomSheetState
    extends State<StudentPaymentListBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<SantriEntity> _filteredStudents = [];

  @override
  void initState() {
    super.initState();
    _filteredStudents = widget.students;
  }

  void _filterStudents() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredStudents = widget.students.where((student) {
        return student.name.toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _launchWhatsApp(String? phone, String nis, String name) async {
    debugPrint('DEBUG: Launching WhatsApp for $name ($phone)');
    if (phone == null || phone.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Info'),
          content: const Text('Nomor telepon belum ada di data santri'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
    
    final formattedPhone = FormatUtils.formatPhoneNumber(phone);
    final message = Uri.encodeComponent(
      MessageUtils.getPaymentReminderMessage(name, nis, widget.monthYear),
    );
    
    final url = Uri.parse("https://wa.me/$formattedPhone?text=$message");
    
    // Launch directly since we are targeting a specific app scheme/url
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.only(top: 8),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_filteredStudents.length} Santri',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 8),
      
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => _filterStudents(),
                decoration: InputDecoration(
                  hintText: 'Cari santri...',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),
      
            // List
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _filteredStudents.length,
                separatorBuilder: (_,_) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final student = _filteredStudents[index];
                  return PaymentSantriCard(
                    student,
                    status: widget.showWhatsApp 
                        ? null 
                        : (student.isFree ? 'Gratis' : 'Sudah Bayar'),
                    trailing: widget.showWhatsApp
                        ? IconButton(
                            onPressed: () => _launchWhatsApp(
                              student.nomorWali,
                              student.nis,
                              student.name,
                            ),
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.chat_bubble_outline_rounded,
                                color: Colors.green,
                                size: 20,
                              ),
                            ),
                          )
                        : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
