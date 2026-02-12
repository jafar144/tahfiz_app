import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:khoirunnasyien/core/router/route_names.dart';
import 'package:khoirunnasyien/core/theme/app_text_styles.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_form_widgets.dart'; // Added
import 'package:khoirunnasyien/core/widgets/aiwa_button.dart';
import 'package:khoirunnasyien/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:khoirunnasyien/features/auth/presentation/cubit/auth_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final nisController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // Prevent keyboard from pushing UI up
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            context.goNamed(RouteNames.home);
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.8, // Take up most height to allow centering but bias
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center, // Center vertically in the SizedBox
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Spacer(), // Push down a bit
                    // Center content but biased up
                    const Center(
                    child: Image(
                      image: AssetImage('assets/images/logo.png'),
                      width: 120,
                      height: 120,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Khoirunnasyien',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.titleBlack,
                  ),
                  const SizedBox(height: 32),
                  AiwaTextField(
                    label: 'NIS',
                    hint: 'Masukkan NIS',
                    icon: Icons.person_outline,
                    controller: nisController,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  AiwaTextField(
                    label: 'Password',
                    hint: 'Masukkan Password',
                    icon: Icons.lock_outline,
                    controller: passwordController,
                    obscureText: true,
                    textCapitalization: TextCapitalization.none,
                  ),
                  const SizedBox(height: 32),
                  AiwaButton(
                    text: 'Login',
                    onPressed: () {
                      context.read<AuthCubit>().login(
                        nisController.text,
                        passwordController.text,
                      );
                    },
                    isLoading: isLoading,
                  ),
                  const Spacer(flex: 2), // Push up more from bottom
                ],
              ),
            ),
          ),
        );
      },
    ),
   );
  }
}
