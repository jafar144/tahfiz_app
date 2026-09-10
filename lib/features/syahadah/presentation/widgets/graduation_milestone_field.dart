import 'package:flutter/material.dart';
import 'package:khoirunnasyien/core/institution/domain/institution_curriculum.dart';

class GraduationMilestoneField extends StatelessWidget {
  final String className;
  final List<GraduationMilestone> milestones;
  final GraduationMilestone? selected;
  final bool enabled;
  final Future<bool> Function(GraduationMilestone milestone) onSelected;
  final GraduationPromotion? Function(GraduationMilestone milestone)
  promotionFor;

  const GraduationMilestoneField({
    super.key,
    required this.className,
    required this.milestones,
    required this.selected,
    required this.enabled,
    required this.onSelected,
    required this.promotionFor,
  });

  Future<void> _openPicker(
    BuildContext context,
    FormFieldState<GraduationMilestone> field,
  ) async {
    if (!enabled) return;
    final result = await showModalBottomSheet<GraduationMilestone>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _MilestonePickerSheet(
        className: className,
        milestones: milestones,
        selected: selected,
        promotionFor: promotionFor,
      ),
    );
    if (result == null) return;
    if (await onSelected(result)) {
      field.didChange(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormField<GraduationMilestone>(
      key: ValueKey('graduation-milestone-${selected?.number ?? 'empty'}'),
      initialValue: selected,
      validator: (value) =>
          value == null ? 'Capaian kelulusan wajib dipilih' : null,
      builder: (field) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Capaian Kelulusan',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            key: const ValueKey('graduation-milestone-field'),
            onTap: enabled ? () => _openPicker(context, field) : null,
            borderRadius: BorderRadius.circular(10),
            child: InputDecorator(
              decoration: InputDecoration(
                prefixIcon: const Icon(
                  Icons.menu_book_outlined,
                  color: Colors.grey,
                  size: 18,
                ),
                suffixIcon: const Icon(Icons.arrow_drop_down_rounded),
                errorText: field.errorText,
                enabled: enabled,
              ),
              child: Text(
                selected?.displayLabel ??
                    (enabled
                        ? 'Pilih capaian untuk kelas $className'
                        : 'Pilih santri terlebih dahulu'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: selected == null ? Colors.black38 : Colors.black87,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MilestonePickerSheet extends StatelessWidget {
  final String className;
  final List<GraduationMilestone> milestones;
  final GraduationMilestone? selected;
  final GraduationPromotion? Function(GraduationMilestone milestone)
  promotionFor;

  const _MilestonePickerSheet({
    required this.className,
    required this.milestones,
    required this.selected,
    required this.promotionFor,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.78,
      ),
      padding: EdgeInsets.fromLTRB(16, 16, 16, 12 + bottomPadding),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pilih Capaian Kelulusan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$className • ${milestones.length} pilihan',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Tutup',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: milestones.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final milestone = milestones[index];
                final promotion = promotionFor(milestone);
                final isSelected = selected?.number == milestone.number;
                return Material(
                  color: Colors.transparent,
                  child: ListTile(
                    key: ValueKey('graduation-milestone-${milestone.number}'),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    leading: CircleAvatar(
                      radius: 17,
                      backgroundColor: isSelected
                          ? Colors.blue
                          : Colors.blue.shade50,
                      child: Text(
                        '${milestone.number}',
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : Colors.blue.shade700,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    title: Text(milestone.label),
                    subtitle: promotion == null
                        ? null
                        : Text(
                            'Menuntaskan kelas • naik ke ${promotion.toClass}',
                          ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: Colors.blue)
                        : null,
                    onTap: () => Navigator.pop(context, milestone),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
