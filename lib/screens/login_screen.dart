import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() { _loading = true; _error = null; });
    try {
      await context.read<AppState>().login(_emailCtrl.text, _passwordCtrl.text);
      if (mounted) {
        showToast(context, '登录成功 ✓');
        Navigator.pop(context);
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
                      child: Row(children: const [
                        Icon(Icons.arrow_back_ios_new, size: 14, color: AppColors.sub),
                        SizedBox(width: 4),
                        Text('返回', style: TextStyle(fontSize: 14, color: AppColors.sub)),
                      ]),
                    ),
                    const SizedBox(height: 32),
                    const Text('欢迎回来', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.text)),
                    const SizedBox(height: 6),
                    const Text('登录后数据将自动云端同步', style: TextStyle(fontSize: 13, color: AppColors.sub)),
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

                    const SectionLabel('邮箱'),
                    FormInput(controller: _emailCtrl, hintText: '请输入邮箱', keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 16),

                    const SectionLabel('密码'),
                    FormInput(controller: _passwordCtrl, hintText: '请输入密码', obscureText: true),
                    const SizedBox(height: 24),

                    AccentButton(
                      label: '登录',
                      onTap: _loading ? null : _login,
                      loading: _loading,
                    ),
                    const SizedBox(height: 24),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Text('还没有账号？', style: AppTextStyles.caption),
                        GestureDetector(
                          onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                          child: const Text(
                            '立即注册',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.accent),
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
