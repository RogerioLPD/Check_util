import 'package:checkutil/Mobile/Qrcodes/qrcode_screen.dart';
import 'package:checkutil/Login/login.dart';
import 'package:checkutil/Ocorrencias/Novaocorrencia/nova_mobile.dart';
import 'package:checkutil/Pages/perfil_user.dart';
import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

class MobileHomeScreen extends StatefulWidget {
  const MobileHomeScreen({super.key});

  @override
  _MobileHomeScreenState createState() => _MobileHomeScreenState();
}

class _MobileHomeScreenState extends State<MobileHomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? userName;
  String? userEmail;
  String? photoUrl;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _checkForUrgentActivities();
    Timer.periodic(const Duration(minutes: 30), (timer) {
      _checkForUrgentActivities(); // Verifica a cada 30 minutos
    });
  }

  Future<void> _fetchUserData() async {
    User? user = _auth.currentUser;
    print("Usuário atual: ${user?.uid}");
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

 Future<void> _checkForUrgentActivities() async {
  DateTime now = DateTime.now();
  DateTime startOfDay = DateTime(now.year, now.month, now.day, 0, 0, 0);
  DateTime endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

  QuerySnapshot snapshot = await _firestore
      .collection('Agendamentos')
      .where('dataAgendada', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
      .where('dataAgendada', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
      .where('status', isEqualTo: 'pendente')
      .get();

  print('🔍 Buscando atividades pendentes entre $startOfDay e $endOfDay');
  print('📋 Atividades encontradas: ${snapshot.docs.length}');
  for (var doc in snapshot.docs) {
    print('📄 Documento: ${doc.data()}');
  }

  if (snapshot.docs.isNotEmpty) {
    List<String> atividades = [];

    for (var doc in snapshot.docs) {
  final data = doc.data() as Map<String, dynamic>;
  String nomeAtividade = data['checklistNome'] ?? 'Atividade sem nome';
  String nomeEquipamento = data['equipamento'] ?? 'Equipamento desconhecido';
  String tipoEquipamento = data['tipoEquipamento'] ?? 'Tipo não informado';
  atividades.add('• $nomeAtividade ($tipoEquipamento | $nomeEquipamento)');

}


    _showGroupedUrgentActivityDialog(atividades);
  }
}


  void _showGroupedUrgentActivityDialog(List<String> atividades) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.red.shade100,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red, size: 32),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Atividades Urgentes!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Text(
                'A Inspeção a seguir está pendente:\n\n${atividades.join('\n')}',
                style: const TextStyle(fontSize: 16),
              ),
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'Fechar',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      );
    });
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
                _checkForUrgentActivities();
              },
            ),
            ListTile(
              leading: const Icon(Icons.qr_code),
              title: const Text('Escanear QR Code'),
              onTap: () {
                _checkForUrgentActivities();
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
                _checkForUrgentActivities();
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
                _checkForUrgentActivities();
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
                _checkForUrgentActivities();
                await _auth.signOut();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage(placa: '', unidade: '', tipoVeiculo: '')),
                  (Route<dynamic> route) => false,
                );
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(46.0),
        child: GridView.count(
          crossAxisCount: 1,
          crossAxisSpacing: 56,
          mainAxisSpacing: 56,
          children: [
            _buildButton(
              context,
              'Escanear QR Code',
              Icons.qr_code_scanner_sharp,
              Colors.teal,
              const QRScannerScreen(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(BuildContext context, String label, IconData icon,
      Color color, Widget screen) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
      ),
      onPressed: () {
        _checkForUrgentActivities();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => screen),
        );
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 100, color: Colors.white),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
