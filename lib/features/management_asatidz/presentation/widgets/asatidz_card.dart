import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:khoirunnasyien/core/router/route_names.dart';
import 'package:khoirunnasyien/features/management_asatidz/domain/entities/asatidz_entity.dart';

class AsatidzCard extends StatelessWidget {
  final AsatidzEntity asatidz;
  final VoidCallback? onReturn;

  const AsatidzCard(this.asatidz, {super.key, this.onReturn});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: ListTile(
        onTap: () async {
          await context.pushNamed(
            RouteNames.detailAsatidz,
            pathParameters: {'id': asatidz.id},
          );
          onReturn?.call();
        },
        leading: CircleAvatar(
          backgroundColor: asatidz.jenisKelamin == 'L'
              ? Colors.blue.withValues(alpha: 0.1)
              : Colors.pink.withValues(alpha: 0.1),
          child: Icon(
            asatidz.jenisKelamin == 'L' ? Icons.face : Icons.face_3,
            color: asatidz.jenisKelamin == 'L' ? Colors.blue : Colors.pink,
          ),
        ),
        title: Text(
          asatidz.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('NIS: ${asatidz.nis}'),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: asatidz.isActive ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                asatidz.isActive ? 'Active' : 'Inactive',
                style: TextStyle(
                  color: asatidz.isActive ? Colors.green : Colors.red,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
