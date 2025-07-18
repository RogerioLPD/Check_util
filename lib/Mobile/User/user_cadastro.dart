import 'package:checkutil/Admin/home_admin.dart';
import 'package:checkutil/Web/home_empresa.dart';
import 'package:checkutil/Componentes/colors.dart';
import 'package:checkutil/Componentes/tipografia.dart';
import 'package:checkutil/Login/login.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';

class CadastrarUsuarioPage extends StatefulWidget {
  const CadastrarUsuarioPage({super.key});

  @override
  _CadastrarUsuarioPageState createState() => _CadastrarUsuarioPageState();
}

class _CadastrarUsuarioPageState extends State<CadastrarUsuarioPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isLoading = false;
  final _formKey = GlobalKey<FormState>();

  String? userName;
  String? userEmail;

  // Novo: Role selecionado
  String _selectedRole = 'cliente'; // valor padrão: Inspeção

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
        setState(() {
          userName = userDoc['name'];
          userEmail = userDoc['email'];
        });
      }
    }
  }

  Future<void> _saveUserProfileOnLogin() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentReference userDocRef =
          _firestore.collection('users').doc(user.uid);
      DocumentSnapshot userDoc = await userDocRef.get();
      if (!userDoc.exists) {
        String userName = user.displayName ?? user.email ?? "Usuário";
        await userDocRef.set({
          'uid': user.uid,
          'name': userName,
          'email': user.email,
          'role': 'admin_primario',
        });
      }
    }
  }

  Future<void> _registerClient() async {
    if (!mounted) return;

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
          'role': _selectedRole, // Aqui define conforme o dropdown
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              duration: Duration(seconds: 3),
              content: Text('Usuário Cadastrado!'),
            ),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeEmpresaPage()),
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
            duration: const Duration(seconds: 3),
            content: Text(message),
          ),
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

  void _clearForm() {
    _nameController.clear();
    _emailController.clear();
    _passwordController.clear();
    setState(() {
      _selectedRole = 'cliente';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          '',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          customElevatedButton(
            onPressed: _clearForm,
            label: 'Cancelar',
            labelStyle: buttonTextStyle,
            icon: Icons.cancel,
            iconColor: const Color.fromARGB(255, 6, 41, 70),
            backgroundColor: const Color.fromARGB(193, 195, 204, 218),
          ),
          const SizedBox(width: 10),
          customElevatedButton(
            onPressed: _registerClient,
            label: 'Salvar',
            labelStyle: buttonTextStyle,
            icon: Icons.check,
            iconColor: const Color.fromARGB(255, 6, 41, 70),
            backgroundColor: backgroundButton,
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(0, 4, 0, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: EdgeInsets.zero,
                padding: EdgeInsets.zero,
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Color.fromARGB(255, 216, 216, 216)),
                    right:
                        BorderSide(color: Color.fromARGB(255, 216, 216, 216)),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(45, 20, 40, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text('Cadastrar Usuário', style: headTextStyle),
                      const SizedBox(height: 40),
                      Text('Nome', style: secondaryTextStyle),
                      _buildTextField(_nameController, 'Nome'),
                      const SizedBox(height: 16),
                      Text('E-mail', style: secondaryTextStyle),
                      _buildTextField(_emailController, 'E-mail'),
                      const SizedBox(height: 16),
                      Text('Senha', style: secondaryTextStyle),
                      _buildTextField(_passwordController, 'Senha',
                          obscureText: true),
                      const SizedBox(height: 16),
                      Text('Tipo de Usuário', style: secondaryTextStyle),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: _selectedRole,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5),
                            borderSide: const BorderSide(
                              color: Color.fromARGB(255, 216, 216, 216),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5),
                            borderSide: const BorderSide(
                              color: Color(0xFF37474F),
                              width: 2,
                            ),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'cliente',
                            child: Text('Inspeção'),
                          ),
                          DropdownMenuItem(
                            value: 'motorista',
                            child: Text('Motorista'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedRole = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildTextField(TextEditingController controller, String label,
    {bool obscureText = false}) {
  return Column(
    children: [
      const SizedBox(height: 10),
      TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: bodyTextStyle,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
            borderSide: const BorderSide(
                color: Color.fromARGB(255, 216, 216, 216)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
            borderSide:
                const BorderSide(color: Color(0xFF37474F), width: 2),
          ),
        ),
        obscureText: obscureText,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Por favor, insira $label.';
          }
          return null;
        },
      ),
    ],
  );
}
