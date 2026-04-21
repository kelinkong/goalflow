import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_i18n.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nicknameCtrl = TextEditingController();
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nicknameCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    setState(() { _loading = true; _error = null; });
    try {
      await context.read<AppState>().register(
        _emailCtrl.text,
        _passwordCtrl.text,
        _nicknameCtrl.text,
      );
      if (mounted) {
        showToast(context, context.tr('注册成功，请登录', 'Account created. Please sign in.'));
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      }
    } catch (e) {
      setState(() {
        _error = userErrorMessage(e);
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                     GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Row(children: [
                        const Icon(Icons.arrow_back_ios_new, size: 14, color: AppColors.sub),
                        SizedBox(width: 4),
                        Text(
                          context.tr('返回', 'Back'),
                          style: const TextStyle(fontSize: 14, color: AppColors.sub),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      context.tr('创建新账号', 'Create account'),
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.text),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.tr('开启你的目标之旅', 'Start your goal journey.'),
                      style: const TextStyle(fontSize: 13, color: AppColors.sub),
                    ),
                    const SizedBox(height: 32),

                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF0F0),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFFDEAEA)),
                        ),
                        child: Text(_error!, style: const TextStyle(fontSize: 13, color: AppColors.danger)),
                      ),
                    ],

                    SectionLabel(context.tr('昵称', 'Nickname')),
                    FormInput(controller: _nicknameCtrl, hintText: context.tr('请输入昵称', 'Enter your nickname')),
                    const SizedBox(height: 16),

                    SectionLabel(context.tr('邮箱', 'Email')),
                    FormInput(controller: _emailCtrl, hintText: context.tr('请输入邮箱', 'Enter your email'), keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 16),

                    SectionLabel(context.tr('密码', 'Password')),
                    FormInput(controller: _passwordCtrl, hintText: context.tr('请输入密码', 'Enter your password'), obscureText: true),
                    const SizedBox(height: 24),

                    AccentButton(
                      label: context.tr('注册', 'Sign up'),
                      onTap: _loading ? null : _register,
                      loading: _loading,
                    ),
                     const SizedBox(height: 24),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text(context.tr('已有账号？', 'Already have an account?'), style: AppTextStyles.caption),
                        GestureDetector(
                          onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                          child: Text(
                            context.tr('立即登录', 'Sign in'),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.accent),
                          ),
                        ),
                      ]),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
