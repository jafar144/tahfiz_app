import 'package:flutter/material.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';
import 'package:khoirunnasyien/features/management_santri/presentation/widgets/gender_dot.dart';

class SantriCard extends StatelessWidget {
  final SantriEntity santri;

  const SantriCard(this.santri, {super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: ListTile(
        leading: GenderDot(santri.jenisKelamin),
        title: Text(
          santri.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('NIS: ${santri.nis}'),
            Text('Kelas: ${santri.kelas}'),
            Text(
              'Pembimbing: ${santri.pembimbing ?? '-'}',
            ),
          ],
        ),
        trailing: const Icon(Icons.more_vert),
      ),
    );
  }
}
