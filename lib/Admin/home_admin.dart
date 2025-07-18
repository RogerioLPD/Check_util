import 'package:checkutil/Login/cadastro_cliente.dart';
import 'package:checkutil/Login/login.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';


class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final User? _user = FirebaseAuth.instance.currentUser;
  int _selectedIndex = 0;

  // Telas a serem exibidas no corpo
  final List<Widget> _screens = [
    const AdminPrincipalPage(),
    RelatorioClientesScreen(),
  ];

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage(placa: '', unidade: '', tipoVeiculo: '',)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao fazer logout: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Landing Page"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.green[700],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            _buildDrawerHeader(),
            const Divider(),
            _buildDrawerItem(
              icon: Icons.person_add,
              text: "Cadastrar Cliente",
              onTap: () {
                setState(() {
                  _selectedIndex = 0;
                });
                Navigator.pop(context); // Fecha o Drawer
              },
            ),
            _buildDrawerItem(
              icon: Icons.bar_chart,
              text: "Relatório de Clientes",
              onTap: () {
                setState(() {
                  _selectedIndex = 1;
                });
                Navigator.pop(context); // Fecha o Drawer
              },
            ),
            const Divider(),
            _buildDrawerItem(icon: Icons.logout, text: "Sair", onTap: _logout),
          ],
        ),
      ),
      body: _screens[_selectedIndex], // Exibe a tela selecionada
    );
  }

  Widget _buildDrawerHeader() {
    return UserAccountsDrawerHeader(
      decoration: BoxDecoration(color: Colors.green[700]),
      accountName: Text(
        _user?.displayName ?? "Usuário",
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      accountEmail: Text(_user?.email ?? "Email não disponível"),
      currentAccountPicture: CircleAvatar(
        backgroundColor: Colors.white,
        child: _user?.photoURL != null
            ? ClipOval(
                child: Image.network(
                  _user!.photoURL!,
                  fit: BoxFit.cover,
                  width: 90,
                  height: 90,
                ),
              )
            : const Icon(Icons.person, size: 40, color: Colors.green),
      ),
    );
  }

  Widget _buildDrawerItem(
      {required IconData icon,
      required String text,
      required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.green[700]),
      title: Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      onTap: onTap,
    );
  }
}

class RelatorioClientesScreen extends StatelessWidget {
  const RelatorioClientesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      print("Usuário não autenticado.");
      return Scaffold(
        appBar: AppBar(title: const Text("Usuários")),
        body: const Center(
          child: Text(
            "Usuário não autenticado.",
            style: TextStyle(color: Colors.red, fontSize: 18),
          ),
        ),
      );
    }

    print("Usuário autenticado: ${currentUser.uid}");

    return Scaffold(
      appBar: AppBar(title: const Text("Lista de Usuários")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            print("Conexão com o Firestore: aguardando dados...");
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            print("Erro ao carregar dados: ${snapshot.error}");
            return const Center(
              child: Text(
                "Erro ao carregar dados.",
                style: TextStyle(color: Colors.red, fontSize: 18),
              ),
            );
          }

          if (!snapshot.hasData) {
            print("Nenhum dado disponível na coleção.");
            return const Center(
              child: Text(
                "Nenhum usuário encontrado.",
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          final users = snapshot.data!.docs;

          if (users.isEmpty) {
            print("A coleção 'users' está vazia.");
            return const Center(
              child: Text(
                "Nenhum usuário encontrado.",
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          print("Usuários carregados: ${users.length}");
          for (var userDoc in users) {
            print("Usuário: ${userDoc.data()}");
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index].data() as Map<String, dynamic>;
              final name = user['name'] ?? 'Sem nome';
              final email = user['email'] ?? 'Sem email';
              final role = user['role'] ?? 'Sem função';

              print("Renderizando usuário: $name, $email, $role");

              return Card(
                margin: const EdgeInsets.fromLTRB(16, 5, 16, 5),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.green,
                    ),
                  ),
                  subtitle: Text(
                    "$email - $role",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
