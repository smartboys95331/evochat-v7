import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';
import 'home_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
    _checkExistingUser();
  }

  Future<void> _checkExistingUser() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('userId');
    final name = prefs.getString('userName');
    if (id != null && name != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(userId: id, userName: name),
        ),
      );
    }
  }

  Future<void> _startMessaging() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final id = const Uuid().v4();
    final name = _nameController.text.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', id);
    await prefs.setString('userName', name);
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(userId: id, userName: name),
        ),
      );
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.bgDark, Color(0xFF1A0533)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppTheme.primary, AppTheme.accent],
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withOpacity(0.4),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.chat_bubble_rounded,
                              size: 48, color: Colors.white),
                        ),
                        const SizedBox(height: 28),
                        const Text(
                          'EvoChat',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Secure · Offline · P2P',
                          style: TextStyle(
                            color: AppTheme.accent,
                            fontSize: 14,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 48),
                        // Features row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _featureChip(Icons.lock_outline, 'Encrypted'),
                            const SizedBox(width: 12),
                            _featureChip(Icons.wifi_off, 'No Internet'),
                            const SizedBox(width: 12),
                            _featureChip(Icons.people_outline, 'P2P'),
                          ],
                        ),
                        const SizedBox(height: 40),
                        // Name field
                        TextFormField(
                          controller: _nameController,
                          style: const TextStyle(color: AppTheme.textPrimary),
                          decoration: const InputDecoration(
                            labelText: 'Your Display Name',
                            prefixIcon: Icon(Icons.person_outline,
                                color: AppTheme.primary),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Please enter your name';
                            }
                            if (v.trim().length < 2) {
                              return 'Name must be at least 2 characters';
                            }
                            return null;
                          },
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _startMessaging(),
                        ),
                        const SizedBox(height: 28),
                        // Start button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _startMessaging,
                            child: _loading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text('Start Messaging',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'No account needed. No servers. Just you and your peers.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: AppTheme.textSecondary.withOpacity(0.7),
                              fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _featureChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.accent),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}
