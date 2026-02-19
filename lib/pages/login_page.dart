import 'package:flutter/material.dart';
import '../widgets/logo_widget.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final usernameCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  bool showPassword = false;
  bool loading = false;

  Future<void> _onSignIn() async {
	setState(() => loading = true);
	await Future.delayed(const Duration(milliseconds: 600)); // static demo
	if (!mounted) return;
	setState(() => loading = false);
	Navigator.pushReplacementNamed(context, '/dashboard');
  }

  @override
  void dispose() {
	usernameCtrl.dispose();
	passwordCtrl.dispose();
	super.dispose();
  }

  @override
  Widget build(BuildContext context) {
	const primaryBlue = Color(0xFF3B47FF);

	InputDecoration deco(String hint, IconData icon, {Widget? suffix}) {
  	return InputDecoration(
    	hintText: hint,
    	filled: true,
    	fillColor: Colors.white,
    	prefixIcon: Icon(icon, color: Colors.grey.shade500),
    	suffixIcon: suffix,
    	contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    	enabledBorder: OutlineInputBorder(
      	borderRadius: BorderRadius.circular(10),
      	borderSide: BorderSide(color: Colors.grey.shade300),
    	),
    	focusedBorder: OutlineInputBorder(
      	borderRadius: BorderRadius.circular(10),
      	borderSide: const BorderSide(color: primaryBlue, width: 1.2),
    	),
  	);
	}

	return Scaffold(
  	body: SafeArea(
    	child: SingleChildScrollView(
      	padding: const EdgeInsets.symmetric(horizontal: 20),
      	child: Column(
        	children: [
          	const SizedBox(height: 40),
          	const LogoWidget(),
          	const SizedBox(height: 20),
          	const Text("InventoryPro",
              	style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          	const SizedBox(height: 6),
          	const Text("Inventory Management System",
              	style: TextStyle(fontSize: 13, color: Color(0xFF7A7A7A))),
          	const SizedBox(height: 28),

          	Align(
            	alignment: Alignment.centerLeft,
            	child: Text("Username",
                	style: TextStyle(color: Colors.grey.shade700, fontSize: 12.5)),
          	),
          	const SizedBox(height: 8),
          	TextField(
            	controller: usernameCtrl,
            	decoration: deco("Enter username", Icons.person_outline),
          	),
          	const SizedBox(height: 18),

          	Align(
            	alignment: Alignment.centerLeft,
            	child: Text("Password",
                	style: TextStyle(color: Colors.grey.shade700, fontSize: 12.5)),
          	),
          	const SizedBox(height: 8),
          	TextField(
            	controller: passwordCtrl,
            	obscureText: !showPassword,
            	decoration: deco(
              	"Enter password",
              	Icons.lock_outline,
              	suffix: IconButton(
                	icon: Icon(
                  	showPassword ? Icons.visibility : Icons.visibility_off,
                  	color: Colors.grey,
                	),
                	onPressed: () => setState(() => showPassword = !showPassword),
              	),
            	),
            	onSubmitted: (_) => _onSignIn(),
          	),
          	const SizedBox(height: 24),

          	SizedBox(
            	width: double.infinity,
            	height: 46,
            	child: ElevatedButton(
              	style: ElevatedButton.styleFrom(
                	backgroundColor: primaryBlue,
                	foregroundColor: Colors.white,
                	shape: RoundedRectangleBorder(
                  	borderRadius: BorderRadius.circular(8),
                	),
              	),
              	onPressed: loading ? null : _onSignIn,
              	child: loading
                  	? const SizedBox(
                      	height: 20, width: 20,
                      	child: CircularProgressIndicator(
                        	strokeWidth: 2, color: Colors.white))
                  	: const Text("Sign In"),
            	),
          	),
          	const SizedBox(height: 40),
          	const Text(
            	"© 2026 InventoryPro. All rights reserved.",
            	style: TextStyle(fontSize: 12, color: Colors.grey),
          	),
          	const SizedBox(height: 16),
        	],
      	),
    	),
  	),
	);
  }
}


