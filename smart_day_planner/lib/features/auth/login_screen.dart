import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/db/app_database.dart';
import '../tasks/task_list_screen.dart';

final authProvider = StateProvider<bool>((ref) => false);
final currentUserFullNameProvider = StateProvider<String>((ref) => 'Kullanıcı');

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _isLoginView = true;
  bool _obscurePassword = true; // ✅ Şifre gizleme kontrolü
  String? _error;

  Future<void> _handleAuth() async {
    final db = await AppDatabase.instance.database;
    
    if (_isLoginView) {
      final results = await db.query(
        'users',
        where: 'username = ? AND password = ?',
        whereArgs: [_userCtrl.text, _passCtrl.text],
      );

      if (results.isNotEmpty) {
        final fullName = results.first['full_name'] as String? ?? 'Kullanıcı';
        ref.read(currentUserFullNameProvider.notifier).state = fullName;
        ref.read(authProvider.notifier).state = true;
      } else {
        setState(() => _error = 'Kullanıcı adı veya şifre hatalı!');
      }
    } else {
      if (_userCtrl.text.isEmpty || _passCtrl.text.isEmpty || _nameCtrl.text.isEmpty) {
        setState(() => _error = 'Lütfen tüm alanları doldurun!');
        return;
      }

      try {
        await db.insert('users', {
          'username': _userCtrl.text,
          'password': _passCtrl.text,
          'full_name': _nameCtrl.text,
        });
        setState(() {
          _isLoginView = true;
          _error = 'Kayıt başarılı! Şimdi giriş yapabilirsiniz.';
        });
      } catch (e) {
        setState(() => _error = 'Bu kullanıcı adı zaten alınmış!');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A4D8F),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            children: [
              const Icon(Icons.lock_person, size: 70, color: Colors.white),
              const SizedBox(height: 15),
              Text(
                _isLoginView ? 'Tekrar Hoş Geldin!' : 'Hesap Oluştur',
                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    if (!_isLoginView) ...[
                      TextField(
                        controller: _nameCtrl,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(labelText: 'Tam Adınız', prefixIcon: Icon(Icons.badge_outlined)),
                      ),
                      const SizedBox(height: 15),
                    ],
                    TextField(
                      controller: _userCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'Kullanıcı Adı', prefixIcon: Icon(Icons.person_outline)),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _passCtrl,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      // ✅ ENTER YAPINCA GİRİŞ YAPMAYI SAĞLAR
                      onSubmitted: (_) => _handleAuth(),
                      decoration: InputDecoration(
                        labelText: 'Şifre',
                        prefixIcon: const Icon(Icons.lock_outline),
                        // ✅ ŞİFREYİ GÖSTERME/GİZLEME BUTONU
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 15),
                      Text(_error!, style: TextStyle(color: _error!.contains('başarılı') ? Colors.green : Colors.red, fontSize: 13)),
                    ],
                    const SizedBox(height: 25),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _handleAuth,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(_isLoginView ? 'Giriş Yap' : 'Kayıt Ol', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextButton(
                      onPressed: () => setState(() {
                        _isLoginView = !_isLoginView;
                        _error = null;
                      }),
                      child: Text(_isLoginView ? 'Hesabınız yok mu? Kayıt Olun' : 'Zaten hesabınız var mı? Giriş Yapın'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
