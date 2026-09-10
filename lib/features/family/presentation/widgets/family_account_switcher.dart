import 'package:flutter/material.dart';
import 'package:khoirunnasyien/features/family/domain/entities/family_account.dart';

typedef SwitchFamilyAccount = Future<String?> Function(String santriId);

class FamilyAccountSwitcher extends StatelessWidget {
  final List<FamilyAccount> accounts;
  final SwitchFamilyAccount onSwitch;

  const FamilyAccountSwitcher({
    required this.accounts,
    required this.onSwitch,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (accounts.isEmpty) return const SizedBox.shrink();

    final primary = Theme.of(context).primaryColor;
    return Tooltip(
      message: 'Ganti akun keluarga',
      child: Material(
        key: const ValueKey('family-account-switcher'),
        color: primary.withValues(alpha: 0.1),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _showAccounts(context),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(Icons.swap_horiz_rounded, color: primary, size: 22),
          ),
        ),
      ),
    );
  }

  Future<void> _showAccounts(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Ganti Akun',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
              const Divider(height: 1),
              ...accounts.map(
                (account) => _FamilyAccountTile(
                  account: account,
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    final error = await onSwitch(account.id);
                    if (!context.mounted || error == null) return;
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(error)));
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FamilyAccountTile extends StatelessWidget {
  final FamilyAccount account;
  final VoidCallback onTap;

  const _FamilyAccountTile({required this.account, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isMale = account.jenisKelamin == 'L';
    final backgroundColor = isMale ? Colors.blue.shade50 : Colors.pink.shade50;
    final foregroundColor = isMale
        ? Colors.blue.shade700
        : Colors.pink.shade700;

    return ListTile(
      key: ValueKey('family-account-${account.id}'),
      leading: CircleAvatar(
        backgroundColor: backgroundColor,
        backgroundImage: account.photoUrl == null
            ? null
            : NetworkImage(account.photoUrl!),
        child: account.photoUrl == null
            ? Text(
                account.name.isEmpty ? '?' : account.name[0].toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: foregroundColor,
                ),
              )
            : null,
      ),
      title: Text(
        account.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        'NIS: ${account.nis} • ${account.kelas}',
        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
      onTap: onTap,
    );
  }
}
