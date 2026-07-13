import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:khoirunnasyien/core/config/app_config.dart';
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
      resizeToAvoidBottomInset: false,
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
                height: MediaQuery.of(context).size.height * 0.8,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Spacer(),
                    Center(
                      child: Image(
                        image: AssetImage(AppConfig.current.logoAsset),
                        width: 120,
                        height: 120,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      AppConfig.current.appName,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.titleBlack,
                    ),
                  const SizedBox(height: 32),
                  AiwaTextField(
                    label: 'NIS',
                    hint: 'Masukkan NIS',
                    icon: Icons.person_outline,
                    controller: nisController,
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
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                              height: 1.4,
                            ),
                            children: [
                              TextSpan(
                                text:
                                    'Password = Tanggal Lahir, mis. ',
                              ),
                              TextSpan(
                                text: '12 April 2015, maka',
                                
                              ),
                              TextSpan(text: ' 20150412',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black54,
                                ),),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
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
                  const Spacer(flex: 2),
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
