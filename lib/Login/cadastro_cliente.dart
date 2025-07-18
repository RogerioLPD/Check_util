

import 'package:checkutil/Admin/home_admin.dart';
import 'package:checkutil/Componentes/colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class AdminPrincipalPage extends StatefulWidget {
  const AdminPrincipalPage({super.key});

  @override
  _AdminPrincipalPageState createState() => _AdminPrincipalPageState();
}

class _AdminPrincipalPageState extends State<AdminPrincipalPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  bool isLoading = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? userName;
  String? userEmail;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _saveUserProfileOnLogin();
  }

  Future<void> _fetchUserData() async {
    User? user = _auth.currentUser;

    if (user != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();

      if (userDoc.exists && mounted) {
        // Verifica se o widget ainda está montado
        setState(() {
          userName = userDoc['name'];
          userEmail = userDoc['email'];
        });
      }
    }
  }

  // Salva o perfil do usuário no Firestore após o login, se ele ainda não existir
  Future<void> _saveUserProfileOnLogin() async {
    User? user = _auth.currentUser;

    if (user != null) {
      DocumentReference userDocRef =
          _firestore.collection('users').doc(user.uid);

      // Verifica se o perfil já existe
      DocumentSnapshot userDoc = await userDocRef.get();
      if (!userDoc.exists) {
        // Usa displayName ou email como fallback para o nome, se não estiver definido
        String userName = user.displayName ?? user.email ?? "Usuário";

        // Salva o perfil no Firestore
        await userDocRef.set({
          'uid': user.uid,
          'name': userName,
          'email': user.email,
          'role': 'admin_primario', // ou outro papel padrão desejado
        });
      }
    }
  }

  // Função para cadastrar o ADM Secundário
  Future<void> _registerAdminSecundario() async {
    if (!mounted) return; // Verifica antes de mudar o estado

    setState(() {
      isLoading = true;
    });
    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      User? user = userCredential.user;

      if (user != null) {
        await user.updateDisplayName(_nameController.text);
        await user.reload();

        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email,
          'name': _nameController.text,
          'role': 'admin_secundario',
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                duration: Duration(seconds: 3),
                content: Text('Administrador Secundário Cadastrado!')),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) =>  AdminPage()),
          );
        }
      } else {
        throw Exception("Erro ao criar usuário.");
      }
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'weak-password') {
        message = 'A senha fornecida é muito fraca.';
      } else if (e.code == 'email-already-in-use') {
        message = 'O e-mail já está em uso por outra conta.';
      } else {
        message = 'Erro: ${e.message}';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              duration: const Duration(seconds: 3), content: Text(message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao cadastrar administrador.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 820) {
            return Row(
              children: [
                Expanded(
                  flex: 6,
                  child: Container(
                    color: backgroundColor,
                    child: Center(
                      child: Image.asset(
                        "assets/images/contaverde.png",
                        height: 400,
                      ),
                    ),
                  ),
                ),
                const VerticalDivider(
                  thickness: 1,
                  color: Colors.white,
                  width: 60,
                ),
                Expanded(
                  flex: 4,
                  child: _buildRegisterForm(),
                ),
              ],
            );
          } else {
            return _buildRegisterForm();
          }
        },
      ),
    );
  }

  Widget _buildRegisterForm() {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.fromLTRB(36, 5, 36, 36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.1),
            Image.asset(
              "assets/images/logo.png",
              height: 150,
            ),
            Text(
              'Cadastrar Cliente',
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
                fontSize: 32,
              ),
            ),
            const SizedBox(height: 60),
            _textInput(
              controller: _nameController,
              hint: "Digite o Nome",
              icon: Icons.person,
            ),
            const SizedBox(height: 16),
            _textInput(
              controller: _emailController,
              hint: "Digite o Email",
              icon: Icons.email,
            ),
            const SizedBox(height: 16),
            _textInput(
              controller: _passwordController,
              hint: "Crie uma senha para o seu cliente",
              icon: Icons.lock,
              obscureText: true,
            ),
            const SizedBox(height: 20),
            isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: backgroundColor,
                      minimumSize: const Size(200, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _registerAdminSecundario,
                    child: const Text(
                      "Cadastrar Cliente",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _textInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          prefixIcon: Icon(icon, color: textButton),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
