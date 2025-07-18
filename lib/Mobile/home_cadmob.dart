import 'package:checkutil/Componentes/colors.dart';
import 'package:checkutil/Componentes/tipografia.dart';
import 'package:checkutil/Mobile/Qrcodes/qrcode_screen.dart';
import 'package:checkutil/Mobile/dashboard_mobile.dart';
import 'package:checkutil/Mobile/dashboard_veiculos_mobile.dart';
import 'package:checkutil/Mobile/home_mobilecad.dart';
import 'package:checkutil/Login/login.dart';
import 'package:checkutil/Pages/dashboard.dart';
import 'package:checkutil/Pages/perfil.dart';
import 'package:checkutil/Services/equipamentos.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeEmpresaMobileScreen extends StatefulWidget {
  const HomeEmpresaMobileScreen({super.key});

  @override
  _HomeEmpresaMobileScreenState createState() =>
      _HomeEmpresaMobileScreenState();
}

class _HomeEmpresaMobileScreenState extends State<HomeEmpresaMobileScreen> {
  final User? _user = FirebaseAuth.instance.currentUser;
  List<String> unidades = [];
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    DashboardMobileScreen(),
    const DashboardVeiculosMobile(),
    const PerfilScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _carregarUnidades();
  }

  Future<void> _carregarUnidades() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('Unidades')
          .doc(_user?.uid)
          .collection('Unidade')
          .get();

      setState(() {
        unidades = snapshot.docs.map((doc) => doc['nome'].toString()).toList();
      });
    } catch (e) {
      print('Erro ao carregar unidades: $e');
    }
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginPage(
            placa: '',
            unidade: '',
            tipoVeiculo: '',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao fazer logout: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.teal,
          elevation: 0,
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          title: Consumer<UnidadeProvider>(
            builder: (context, unidadeProvider, child) {
              return Text(
                unidadeProvider.unidadeSelecionada ?? 'Selecione uma unidade',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600),
              );
            },
          ),
        ),
        drawer: Drawer(
          child: Consumer<UnidadeProvider>(
            builder: (context, unidadeProvider, child) {
              return Column(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.teal,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(color: Colors.black26, blurRadius: 4)
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.white,
                              radius: 30,
                              child: _user?.photoURL != null
                                  ? ClipOval(
                                      child: Image.network(
                                        _user!.photoURL!,
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : const Icon(Icons.person,
                                      size: 30, color: Colors.teal),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _user?.displayName ?? 'Usuário',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Online',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Seletor de Unidade
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (unidadeProvider.unidadeSelecionada == null)
                              Text('Selecione a Unidade', style: simpleSubText),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.filter_list,
                                    color: textPrimary, size: 18),
                                const SizedBox(width: 8),
                                DropdownButton<String>(
                                  dropdownColor: Colors.white,
                                  style: const TextStyle(
                                    color: textPrimary,
                                    fontSize: 14,
                                  ),
                                  value: unidadeProvider.unidadeSelecionada ??
                                      (unidades.isNotEmpty
                                          ? unidades.first
                                          : null),
                                  hint: Text(
                                    "Selecione a unidade",
                                    style: simpleTitleText,
                                  ),
                                  icon: const SizedBox.shrink(),
                                  underline: const SizedBox.shrink(),
                                  items: unidades.map((String unidade) {
                                    return DropdownMenuItem<String>(
                                      value: unidade,
                                      child: Text(
                                        unidade,
                                        style: bodyTextStyle.copyWith(
                                            fontSize: 14),
                                      ),
                                    );
                                  }).toList(),
                                  selectedItemBuilder: (BuildContext context) {
                                    return unidades.map((String unidade) {
                                      return Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(unidade,
                                            style: simpleTitleText),
                                      );
                                    }).toList();
                                  },
                                  onChanged: (String? novaUnidade) {
                                    if (novaUnidade != null) {
                                      unidadeProvider
                                          .setUnidadeSelecionada(novaUnidade);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // Informações da Unidade
                        if (unidadeProvider.unidadeSelecionada != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                unidadeProvider.unidadeSelecionada ?? "Unidade",
                                style: simpleTitleText,
                              ),
                              const Divider(color: textPrimary),
                            ],
                          ),
                      ],
                    ),
                  ),

                  // Menu abaixo da parte do cabeçalho com unidade
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      children: [
                        _buildDrawerItem(
                            icon: Icons.dashboard,
                            label: 'Dashboard',
                            onTap: () => _selectIndex(0)),
                        _buildDrawerItem(
                            icon: Icons.dashboard_customize_sharp,
                            label: 'Dashboard Veículos',
                            onTap: () => _selectIndex(1)),
                        _buildDrawerItem(
                            icon: Icons.person_outline,
                            label: 'Perfil',
                            onTap: () => _selectIndex(2)),
                        const Divider(thickness: 1),
                        _buildDrawerItem(
                          icon: Icons.logout,
                          label: 'Sair',
                          onTap: _logout,
                          color: Colors.redAccent,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        body: _screens[_selectedIndex],
        bottomNavigationBar: CustomBottomAppBar(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildBottomItem(
                    Icons.dashboard_customize_sharp, 'Dashboard Veículos', 1),
                const SizedBox(width: 50),
                _buildBottomItem(Icons.person, 'Perfil', 2),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          shape: const CircleBorder(),
          backgroundColor: Colors.teal,
          child: const Icon(Icons.home, color: Colors.white),
          onPressed: () => _selectIndex(0),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }

  Widget _buildBottomItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _selectIndex(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isSelected ? Colors.white : Colors.grey.shade300),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey.shade300,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.black87,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: TextStyle(fontSize: 16, color: color)),
      onTap: () {
        onTap();
        Navigator.pop(context);
      },
      horizontalTitleGap: 12,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }

  void _selectIndex(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}

// ---------- CustomClipper para recorte real do notch ----------
class NotchClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final notchRadius = 36.0; // raio do notch (altura do recorte)
    final notchWidth =
        60.0; // largura total do recorte (aproximadamente 2 * radius)
    final notchSmoothness = 25.0; // suavidade nos cantos superiores do recorte

    final notchCenterX = size.width / 2;

    final path = Path();

    // Começa no canto inferior esquerdo
    path.moveTo(0, size.height);

    // Sobe até o topo
    path.lineTo(0, 0);

    // Linha reta até o início do recorte
    path.lineTo(notchCenterX - notchWidth / 2 - notchSmoothness, 0);

    // Início do recorte com curva suave no canto superior esquerdo
    path.cubicTo(
      notchCenterX - notchWidth / 2,
      0,
      notchCenterX - notchWidth / 2,
      notchRadius,
      notchCenterX,
      notchRadius,
    );

    // Final do recorte com curva suave no canto superior direito
    path.cubicTo(
      notchCenterX + notchWidth / 2,
      notchRadius,
      notchCenterX + notchWidth / 2,
      0,
      notchCenterX + notchWidth / 2 + notchSmoothness,
      0,
    );

    // Continua linha até o canto superior direito
    path.lineTo(size.width, 0);

    // Desce até o rodapé
    path.lineTo(size.width, size.height);

    // Fecha o caminho
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

// ---------- Widget CustomBottomAppBar com recorte real ----------
class CustomBottomAppBar extends StatelessWidget {
  final Widget child;

  const CustomBottomAppBar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: NotchClipper(),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: Colors.teal,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 6,
              offset: const Offset(0, -3),
            ),
          ],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(0),
            topRight: Radius.circular(0),
          ),
        ),
        child: child,
      ),
    );
  }
}
