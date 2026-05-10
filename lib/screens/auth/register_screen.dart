import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:g_route_app/theme/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Preencha os campos obrigatórios (Nome, Email e Senha)")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': name,
          'phone': phone.isEmpty ? null : phone,
        },
      );

      if (mounted) {
        if (response.user != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Cadastro realizado! Verifique seu email.")),
          );
          Navigator.pop(context);
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ocorreu um erro inesperado"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 35),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            RepaintBoundary(
              child: Hero(
                tag: 'app_logo',
                child: Image.asset(
                  'assets/Logo.png',
                  height: 100,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 25),
            const Text(
              "Criar Conta",
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1),
            ),
            const SizedBox(height: 10),
            const Text(
              "Junte-se à elite dos viajantes e planeje roteiros inesquecíveis.",
              style: TextStyle(color: AppTheme.textGrey, fontSize: 15, fontWeight: FontWeight.w500, height: 1.4),
            ),
            
            const SizedBox(height: 40),
            
            _buildTextField(
              controller: _nameController,
              label: "NOME COMPLETO",
              hint: "Seu nome",
              icon: Icons.person_outline_rounded,
            ),
            
            const SizedBox(height: 25),

            _buildTextField(
              controller: _phoneController,
              label: "TELEFONE (OPCIONAL)",
              hint: "+55 11 99999-9999",
              icon: Icons.phone_android_rounded,
            ),
            
            const SizedBox(height: 25),
            
            _buildTextField(
              controller: _emailController,
              label: "EMAIL",
              hint: "seu@email.com",
              icon: Icons.alternate_email_rounded,
            ),
            
            const SizedBox(height: 25),
            
            _buildTextField(
              controller: _passwordController,
              label: "SENHA",
              hint: "••••••••",
              icon: Icons.lock_outline_rounded,
              isPassword: true,
              obscureText: _obscurePassword,
              onTogglePassword: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
            ),
            
            const SizedBox(height: 40),
            
            // Botão de Cadastro
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryPurple,
                  foregroundColor: Colors.white,
                  elevation: 8,
                  shadowColor: AppTheme.primaryPurple.withOpacity(0.4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24, 
                        width: 24, 
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                      )
                    : const Text(
                        "FINALIZAR CADASTRO",
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 1),
                      ),
              ),
            ),
            
            const SizedBox(height: 35),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Já é um membro? ", style: TextStyle(color: AppTheme.textGrey, fontWeight: FontWeight.w500)),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Text(
                    "Fazer Login",
                    style: TextStyle(color: AppTheme.primaryPurple, fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onTogglePassword,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: AppTheme.primaryPurple, letterSpacing: 1),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15, fontWeight: FontWeight.normal),
              prefixIcon: Icon(icon, color: AppTheme.primaryPurple, size: 22),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        obscureText ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                        color: Colors.grey,
                        size: 20,
                      ),
                      onPressed: onTogglePassword,
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            ),
          ),
        ),
      ],
    );
  }
}
