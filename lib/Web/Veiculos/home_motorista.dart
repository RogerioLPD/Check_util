import 'package:checkutil/Mobile/Qrcodes/qrcode_screen.dart';
import 'package:checkutil/Login/login.dart';
import 'package:checkutil/Ocorrencias/Novaocorrencia/nova_mobile.dart';
import 'package:checkutil/Pages/perfil_user.dart';
import 'package:checkutil/Web/Veiculos/checklist_veiculos.dart';
import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeMotoristaScreen extends StatefulWidget {
  final String placa;
  final String unidade;
  final String tipoVeiculo;
  const HomeMotoristaScreen({
    required this.placa,
    required this.unidade,
    required this.tipoVeiculo,
    super.key,
  });

  @override
  _HomeMotoristaScreenState createState() => _HomeMotoristaScreenState();
}

class _HomeMotoristaScreenState extends State<HomeMotoristaScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? userName;
  String? userEmail;
  String? photoUrl;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        setState(() {
          userName = userDoc['name'];
          userEmail = userDoc['email'];
          photoUrl = userDoc['logoUrl'];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Center(
          child: AnimatedTextKit(
            animatedTexts: [
              WavyAnimatedText(
                'Bem vindo!',
                textStyle: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'TitanOne',
                  letterSpacing: 2,
                ),
              ),
              WavyAnimatedText(
                'Check Util',
                textStyle: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'TitanOne',
                  letterSpacing: 2,
                ),
              ),
            ],
            isRepeatingAnimation: true,
          ),
        ),
        backgroundColor: Colors.teal,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(userName ?? 'Usuário'),
              accountEmail: Text(userEmail ?? 'Email não encontrado'),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                backgroundImage: _auth.currentUser?.photoURL != null
                    ? NetworkImage(_auth.currentUser!.photoURL!)
                    : null,
                child: _auth.currentUser?.photoURL == null
                    ? const Icon(Icons.person, color: Colors.white, size: 40)
                    : null,
              ),
              decoration: const BoxDecoration(color: Colors.teal),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Início'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.qr_code),
              title: const Text('Escanear QR Code'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const QRScannerScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_alert),
              title: const Text('Ocorrência'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const NovaOcorrenciaMobile()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Perfil'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PerfilUser()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                await _auth.signOut();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const LoginPage(
                            placa: '',
                            unidade: '',
                            tipoVeiculo: '',
                          )),
                  (Route<dynamic> route) => false,
                );
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildButton(
              context,
              'Iniciar Check List',
              Icons.checklist_rtl,
              Colors.teal,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChecklistPlacaScreen(
                      placa:
                          widget.placa, // passa a placa que veio para esta tela
                      tipoVeiculo: widget.tipoVeiculo,
                      unidade: widget.unidade,
                    ),
                  ),
                );
              },
            ),
            _buildButton(
              context,
              'Iniciar Jornada',
              Icons.play_circle_fill,
              Colors.green,
              () {
                // ação
              },
            ),
            _buildButton(
              context,
              'Finalizar Jornada',
              Icons.stop_circle,
              Colors.red,
              () {
                // ação
              },
            ),
            _buildButton(
              context,
              'Registrar Ocorrência',
              Icons.report,
              Colors.orange,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const NovaOcorrenciaMobile()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(BuildContext context, String label, IconData icon,
      Color color, VoidCallback onPressed) {
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(20),
      color: const Color(0xFFEFF1F5), // Cor de fundo mais visível
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onPressed,
        splashColor: color.withOpacity(0.2),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                child: Icon(
                  icon,
                  size: 64,
                  color: color,
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[900],
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
