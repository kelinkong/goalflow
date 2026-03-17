import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'dart:async';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // mode: login | register | verify
  String _mode = 'login';
  final _phoneCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _codeFocus = FocusNode();
  int _countdown = 0;
  Timer? _timer;

  bool get _validPhone => RegExp(r'^1[3-9]\d{9}$').hasMatch(_phoneCtrl.text);

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _codeCtrl.dispose();
    _codeFocus.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    setState(() => _countdown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdown <= 1) { t.cancel(); setState(() => _countdown = 0); }
      else setState(() => _countdown--);
    });
  }

  void _sendCode() {
    if (!_validPhone) return;
    setState(() => _mode = 'verify');
    _startCountdown();
    Future.delayed(const Duration(milliseconds: 300), () {
      _codeFocus.requestFocus();
    });
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

                    // Logo
                    Row(children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(color: AppColors.pill, borderRadius: BorderRadius.circular(16)),
                        child: const Center(child: Text('🎯', style: TextStyle(fontSize: 24))),
                      ),
                      const SizedBox(width: 14),
                      const Text('GoalFlow',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900,
                              color: AppColors.text, letterSpacing: -0.5)),
                    ]),
                    const SizedBox(height: 28),

                    Text(
                      _mode == 'verify' ? '输入验证码' : _mode == 'login' ? '手机号登录' : '注册账号',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.text),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _mode == 'verify'
                          ? '验证码已发送至 ${_phoneCtrl.text}'
                          : '登录后数据将自动云端同步',
                      style: const TextStyle(fontSize: 13, color: AppColors.sub),
                    ),
                    const SizedBox(height: 32),

                    if (_mode != 'verify') ...[
                      // Phone input
                      const SectionLabel('手机号'),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
                        ),
                        child: Row(children: [
                          const Padding(
                            padding: EdgeInsets.only(left: 18),
                            child: Text('+86', style: TextStyle(fontSize: 15, color: AppColors.sub, fontWeight: FontWeight.w500)),
                          ),
                          Container(width: 1, height: 20, color: AppColors.border, margin: const EdgeInsets.symmetric(horizontal: 12)),
                          Expanded(
                            child: TextField(
                              controller: _phoneCtrl,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(11),
                              ],
                              onChanged: (_) => setState(() {}),
                              decoration: const InputDecoration(
                                hintText: '请输入手机号',
                                hintStyle: TextStyle(color: AppColors.sub),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(vertical: 15),
                              ),
                              style: const TextStyle(fontSize: 15, color: AppColors.text, letterSpacing: 1),
                            ),
                          ),
                          if (_phoneCtrl.text.isNotEmpty)
                            GestureDetector(
                              onTap: () { _phoneCtrl.clear(); setState(() {}); },
                              child: const Padding(
                                padding: EdgeInsets.only(right: 16),
                                child: Icon(Icons.cancel, size: 18, color: AppColors.sub),
                              ),
                            ),
                        ]),
                      ),
                      if (_phoneCtrl.text.length == 11 && !_validPhone)
                        const Padding(
                          padding: EdgeInsets.only(top: 6, left: 4),
                          child: Text('请输入正确的手机号', style: TextStyle(fontSize: 12, color: AppColors.danger)),
                        ),
                      const SizedBox(height: 24),

                      AccentButton(
                        label: '发送验证码',
                        onTap: _validPhone ? _sendCode : null,
                      ),

                      const SizedBox(height: 28),
                      Row(children: [
                        Expanded(child: Divider(color: AppColors.border)),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text('或者', style: TextStyle(fontSize: 13, color: AppColors.sub)),
                        ),
                        Expanded(child: Divider(color: AppColors.border)),
                      ]),
                      const SizedBox(height: 20),

                      // Third-party
                      _ThirdPartyBtn(emoji: '🍎', label: '通过 Apple 登录', onTap: () {}),
                      const SizedBox(height: 10),
                      _ThirdPartyBtn(emoji: '💬', label: '通过微信登录', onTap: () {}),

                      const SizedBox(height: 24),
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text(_mode == 'login' ? '还没有账号？' : '已有账号？',
                            style: AppTextStyles.caption),
                        GestureDetector(
                          onTap: () => setState(() => _mode = _mode == 'login' ? 'register' : 'login'),
                          child: Text(
                            _mode == 'login' ? '立即注册' : '去登录',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.accent),
                          ),
                        ),
                      ]),
                    ] else ...[
                      // 6-digit code input
                      const SectionLabel('验证码'),
                      GestureDetector(
                        onTap: () => _codeFocus.requestFocus(),
                        child: Stack(children: [
                          Row(
                            children: List.generate(6, (i) => Expanded(
                              child: Container(
                                margin: EdgeInsets.only(right: i < 5 ? 8 : 0),
                                height: 52,
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: _codeCtrl.text.length == i ? AppColors.accent : AppColors.border,
                                    width: _codeCtrl.text.length == i ? 1.5 : 1,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    i < _codeCtrl.text.length ? _codeCtrl.text[i] : '',
                                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.text),
                                  ),
                                ),
                              ),
                            )),
                          ),
                          // Hidden real input
                          SizedBox(
                            height: 52,
                            child: TextField(
                              controller: _codeCtrl,
                              focusNode: _codeFocus,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(6),
                              ],
                              onChanged: (_) => setState(() {}),
                              style: const TextStyle(color: Colors.transparent, fontSize: 1),
                              cursorColor: Colors.transparent,
                              decoration: const InputDecoration(border: InputBorder.none),
                            ),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 28),

                      AccentButton(
                        label: _mode == 'register' ? '注册并登录' : '登录',
                        onTap: _codeCtrl.text.length == 6 ? () {
                          showToast(context, '登录成功 ✓');
                          Navigator.pop(context);
                        } : null,
                      ),
                      const SizedBox(height: 16),

                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        GestureDetector(
                          onTap: () => setState(() { _mode = 'login'; _codeCtrl.clear(); }),
                          child: const Text('← 修改手机号',
                              style: TextStyle(fontSize: 13, color: AppColors.sub)),
                        ),
                        GestureDetector(
                          onTap: _countdown == 0 ? () { _startCountdown(); } : null,
                          child: Text(
                            _countdown > 0 ? '${_countdown}s 后重发' : '重新发送',
                            style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600,
                              color: _countdown == 0 ? AppColors.accent : AppColors.sub,
                            ),
                          ),
                        ),
                      ]),
                    ],

                    const SizedBox(height: 40),
                    Center(
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: const TextStyle(fontSize: 12, color: AppColors.sub, height: 1.6),
                          children: const [
                            TextSpan(text: '登录即代表同意 '),
                            TextSpan(text: '服务条款', style: TextStyle(color: AppColors.accent)),
                            TextSpan(text: ' 和 '),
                            TextSpan(text: '隐私政策', style: TextStyle(color: AppColors.accent)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
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

class _ThirdPartyBtn extends StatelessWidget {
  final String emoji, label;
  final VoidCallback onTap;
  const _ThirdPartyBtn({required this.emoji, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.text)),
      ]),
    ),
  );
}
