import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:khoirunnasyien/core/router/route_names.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';


class SantriCard extends StatelessWidget {
  final SantriEntity santri;
  final VoidCallback? onReturn;

  const SantriCard(this.santri, {super.key, this.onReturn});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: ListTile(
        onTap: () async {
          await context.pushNamed(
            RouteNames.detailSantri,
            pathParameters: {'id': santri.id},
          );
          onReturn?.call();
        },
        leading: CircleAvatar(
          backgroundColor: santri.jenisKelamin == 'L'
              ? Colors.blue.withValues(alpha: 0.1)
              : Colors.pink.withValues(alpha: 0.1),
          child: Icon(
            santri.jenisKelamin == 'L' ? Icons.face : Icons.face_3,
            color: santri.jenisKelamin == 'L' ? Colors.blue : Colors.pink,
          ),
        ),
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
