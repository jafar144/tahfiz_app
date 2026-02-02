import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khoirunnasyien/features/management_santri/presentation/cubit/santri_cubit.dart';
import 'package:khoirunnasyien/features/management_santri/presentation/cubit/santri_state.dart';
import 'package:khoirunnasyien/features/management_santri/presentation/widgets/santri_card.dart';

class AdminSantriPage extends StatefulWidget {
  const AdminSantriPage({super.key});

  @override
  State<AdminSantriPage> createState() => _AdminSantriPageState();
}

class _AdminSantriPageState extends State<AdminSantriPage> {
  @override
  void initState() {
    super.initState();
    context.read<SantriCubit>().loadSantri();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Data')),
      body: Column(
        children: [
          // Search & Filter nanti
          Expanded(
            child: BlocBuilder<SantriCubit, SantriState>(
              builder: (context, state) {
                if (state is SantriLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (state is SantriLoaded) {
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.santri.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      return SantriCard(state.santri[index]);
                    },
                  );
                }

                if (state is SantriError) {
                  return Center(child: Text(state.message));
                }

                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
  }
}
