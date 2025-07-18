import 'package:checkutil/Ocorrencias/Lista/lista_ocorrencias.dart';
import 'package:checkutil/Ocorrencias/Novaocorrencia/nova_ocorrencia.dart';
import 'package:checkutil/Web/Addmanutencao/anual.dart';
import 'package:checkutil/Web/Addmanutencao/add_manutencao.dart';
import 'package:checkutil/Web/Addmanutencao/mensal.dart';
import 'package:checkutil/Web/Addmanutencao/semanal.dart';
import 'package:checkutil/Web/Addmanutencao/trimestral.dart';
import 'package:checkutil/Web/Cadastros/add_empresaprincipal.dart';
import 'package:checkutil/Web/Cadastros/add_equipamento.dart';
import 'package:checkutil/Web/Qrcodes/qrcode_display.dart';
import 'package:checkutil/Mobile/Qrcodes/home_qr.dart';
import 'package:checkutil/Task/task.dart';
import 'package:checkutil/Task/task_display.dart';
import 'package:checkutil/Web/Cadastros/add_unidades.dart';
import 'package:checkutil/Mobile/User/user_cadastro.dart';
import 'package:checkutil/Componentes/colors.dart';
import 'package:checkutil/Componentes/tipografia.dart';
import 'package:checkutil/Login/login.dart';
import 'package:checkutil/Pages/dashboard.dart';
import 'package:checkutil/Pages/perfil.dart';
import 'package:checkutil/Services/equipamentos.dart';
import 'package:checkutil/Web/Relatorios/relatorio_equipamento.dart';
import 'package:checkutil/Web/Veiculos/add_veiculos.dart';
import 'package:checkutil/Web/Veiculos/caminhao.dart';
import 'package:checkutil/Web/Veiculos/carros.dart';
import 'package:checkutil/Web/Veiculos/dashboard_veiculos.dart';
import 'package:checkutil/Web/Veiculos/lista_veiculos.dart';
import 'package:checkutil/Web/Veiculos/micro.dart';
import 'package:checkutil/Web/Veiculos/onibus.dart';
import 'package:checkutil/Web/Veiculos/qr_display_new.dart';
import 'package:checkutil/Web/Veiculos/qr_veiculos.dart';
import 'package:checkutil/Web/Veiculos/relatorios_veiculos.dart';
import 'package:checkutil/Web/Veiculos/van.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class HomeEmpresaPage extends StatefulWidget {
  const HomeEmpresaPage({super.key});

  @override
  _HomeEmpresaPageState createState() => _HomeEmpresaPageState();
}

class _HomeEmpresaPageState extends State<HomeEmpresaPage> {
  final User? _user = FirebaseAuth.instance.currentUser;
  int _selectedIndex = 0;
  Map<String, dynamic>? unidadePrincipal;
  String? _imagemBase64;
  List<String> unidades = [];
  String? unidadeSelecionada;
  String? hoveredItem;
  String selectedItem = "Select an item";
  bool isSecondDrawerOpen = false;
  String selectedSubItem = "";

  // Telas a serem exibidas no corpo
  final List<Widget> _screens = [
    DashboardScreen(),
    const CadastrarEquipamentoScreen(), //faz o cadastro dos equipamentos
    //const LocalScreen(), //faz o cadastro dos locais
    const CadastrarUnidadeScreen(), // faz o cadastro das unidades
    //CadastrarAtividadesScreen(), // faz ocadastro das atividades
    //const RegistrationLocalScreen(), // faz o cadastro da inpeção no local
    //const PlanoEquipamentoScreen(), // faz o cadastro da manutenção no equipamento
    const EmpresaPrincipalScreen(), // faz o cadastro da empresa
    const CadastrarUsuarioPage(),
    const MaintenancePlanPage(), // cria um plano de manutenção
    const SemanalPage(),
    const MensalPage(),
    const TrimestralPage(),
    const AnualPage(),

    //const CriarPlanoInspecaoScreen(), // cria um plano de inspeção
    //const PerguntaScreen(), // adiciona perguntas
    //NovoServicoScreen(), // adiciona serviços
    //const QRDisplayLocalScreen(), // lista os qrcodes dos locais
    const QRCodeDisplayScreen(), // lista os qrcodes dos equipamentos
    //const HomeQRScreen(tag: '',),
    AgendamentoScreen(),
    CalendarioAgendamentosScreen(),
    const CadastrarOcorrenciaScreen(), //cadastra uma nova ocorrencia
    const ListaOcorrenciasScreen(), // lista as ocorrencias
    const ListaEquipamentosScreen(),
    const DashboardVeiculos(),
    const CadastrarVeiculoScreen(),
    SelecionarVeiculoScreen(),
    const CarsCheckPage(),
    const VansCheckPage(),
    const MicroCheckPage(),
    const OnibusCheckPage(),
    const CaminhaoCheckPage(),
    //const QRCodeVeiculos(),
   const CheckUtilScreen(),
    const RelatoriosVeiculos(),
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
          .doc(_user!.uid)
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
            unidade: '', // Provide appropriate value here
            tipoVeiculo: '', // Provide appropriate value here
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao fazer logout: $e')));
    }
  }

  void openSecondDrawer(String item) {
    setState(() {
      selectedItem = item;
      isSecondDrawerOpen = true;
    });
  }

  void closeSecondDrawer() {
    setState(() {
      isSecondDrawerOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    var unidadeProvider = Provider.of<UnidadeProvider>(context);

    // Definição dos itens da segunda drawer para cada categoria
    Map<String, List<Map<String, dynamic>>> secondDrawerItems = {
      'Cadastros': [
        {
          'icon': Icons.precision_manufacturing,
          'text': "Cadastrar Equipamento",
          'index': 1,
        },
        /* {
          'icon': Icons.add_location_alt,
          'text': "Cadastrar Locais",
          'index': 1,
        },*/
        {'icon': Icons.add_business, 'text': "Cadastrar Unidades", 'index': 2},
        // {'icon': Icons.add_task, 'text': "Cadastrar Atividades", 'index': 3},
        /* {
          'icon': Icons.app_registration,
          'text': "Cadastrar Inspeção no Local",
          'index': 4,
        },
        {'icon': Icons.build, 'text': "Cadastrar Manutenção", 'index': 5},*/
        {'icon': Icons.add_home_work, 'text': "Cadastrar Empresa", 'index': 3},
        {
          'icon': Icons.person_add_alt_1_outlined,
          'text': "Cadastrar Usuário",
          'index': 4
        },

        {
          'icon': Icons.assignment_add,
          'text': "Checklist Diário",
          'index': 5,
        },
        {
          'icon': Icons.assignment_add,
          'text': "Checklist Semanal",
          'index': 6,
        },
        {
          'icon': Icons.assignment_add,
          'text': "Checklist Mensal",
          'index': 7,
        },
        {
          'icon': Icons.assignment_add,
          'text': "Checklist Trimestral",
          'index': 8,
        },
        {
          'icon': Icons.assignment_add,
          'text': "Checklist Anual",
          'index': 9,
        },
      ],
      /*{
          'icon': Icons.add_chart,
          'text': "Criar plano de inspeção",
          'index': 8,
        },
        {'icon': Icons.comment_bank, 'text': "Adicionar perguntas", 'index': 9},
        {
          'icon': Icons.miscellaneous_services,
          'text': "Adicionar Serviços",
          'index': 10,
        },*/

      'Qr': [
        //{'icon': Icons.qr_code, 'text': "QrCodes Locais", 'index': 11},
        {'icon': Icons.qr_code_2, 'text': "QrCodes Equipamentos", 'index': 10},
      ],
      'Ocorrencias': [
        {'icon': Icons.add_alert, 'text': "Nova ocorrência", 'index': 13},
        {'icon': Icons.list, 'text': "Listar ocorrências", 'index': 14},
      ],
      'Atividades': [
        {
          'icon': FontAwesomeIcons.calendarCheck,
          'text': "Atividades",
          'index': 11,
        },
        {
          'icon': FontAwesomeIcons.calendarCheck,
          'text': "Calendário",
          'index': 12,
        },
      ],
      'Relatorio': [
        {'icon': Icons.file_open_outlined, 'text': "Relatórios", 'index': 15},
      ],
      'Veiculos': [
        {'icon': Icons.dashboard_outlined, 'text': "Dashboard", 'index': 16},
        {'icon': Icons.car_rental, 'text': "Adicionar Veículos", 'index': 17},
        {'icon': Icons.car_repair, 'text': "Listar Veículos", 'index': 18},
        {'icon': Icons.checklist, 'text': "Checklist Carros", 'index': 19},
        {'icon': Icons.checklist, 'text': "Checklist Vans", 'index': 20},
        {'icon': Icons.checklist, 'text': "Checklist Micro Ônibus", 'index': 21},
        {'icon': Icons.checklist, 'text': "Checklist Ônibus", 'index': 22},
        {'icon': Icons.checklist, 'text': "Checklist Caminhão", 'index': 23},
        {'icon': Icons.qr_code, 'text': "QR Codes", 'index': 24},
         {'icon': Icons.file_open_outlined, 'text': "Relatórios", 'index': 25},
        
        
      ],
      'Perfil': [
        {'icon': Icons.person, 'text': "Perfil", 'index': 26},
      ],
      'Dashboard': [
        {'icon': Icons.dashboard_outlined, 'text': "Dashboard", 'index': 0},
      ],
    };

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                // Primeira Drawer
                Container(
                  width: 240,
                  color: backColorMobile,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDrawerHeader(unidadeProvider),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              ListTile(
                                leading: const Icon(
                                  Icons.dashboard_outlined,
                                  color: Colors.white70,
                                ),
                                title: Text(
                                  'Dashboard',
                                  style: simpleText,
                                ),
                                onTap: () {
                                  setState(() {
                                    _selectedIndex =
                                        0; // Índice correto da tela de perfil na lista _screens
                                    isSecondDrawerOpen =
                                        false; // Fecha a segunda drawer caso esteja aberta
                                  });
                                },
                              ),
                              ListTile(
                                leading: const Icon(
                                  FeatherIcons.fileText,
                                  color: Colors.white70,
                                ),
                                title: Text('Cadastros', style: simpleText),
                                onTap: () {
                                  final submenu =
                                      secondDrawerItems['Cadastros'];
                                  if (submenu != null && submenu.isNotEmpty) {
                                    setState(() {
                                      selectedItem = 'Cadastros';
                                      isSecondDrawerOpen = true;
                                      _selectedIndex = submenu.first[
                                          'index']; // Atualiza para a primeira tela do submenu
                                    });
                                  }
                                },
                              ),
                              ListTile(
                                leading: const Icon(
                                  Icons.qr_code_scanner,
                                  color: Colors.white70,
                                ),
                                title: Text('Qr Codes', style: simpleText),
                                onTap: () {
                                  final submenu = secondDrawerItems['Qr'];
                                  if (submenu != null && submenu.isNotEmpty) {
                                    setState(() {
                                      selectedItem = 'Qr';
                                      isSecondDrawerOpen = true;
                                      _selectedIndex = submenu.first[
                                          'index']; // Atualiza para a primeira tela do submenu
                                    });
                                  }
                                },
                              ),
                              ListTile(
                                leading: const Icon(
                                  FeatherIcons.alertCircle,
                                  color: Colors.white70,
                                ),
                                title: Text('Ocorrências', style: simpleText),
                                onTap: () {
                                  final submenu =
                                      secondDrawerItems['Ocorrencias'];
                                  if (submenu != null && submenu.isNotEmpty) {
                                    setState(() {
                                      selectedItem = 'Ocorrencias';
                                      isSecondDrawerOpen = true;
                                      _selectedIndex = submenu.first[
                                          'index']; // Atualiza para a primeira tela do submenu
                                    });
                                  }
                                },
                              ),
                              ListTile(
                                leading: const Icon(
                                  Icons.add_task,
                                  color: Colors.white70,
                                ),
                                title: Text('Atividades', style: simpleText),
                                onTap: () {
                                  final submenu =
                                      secondDrawerItems['Atividades'];
                                  if (submenu != null && submenu.isNotEmpty) {
                                    setState(() {
                                      selectedItem = 'Atividades';
                                      isSecondDrawerOpen = true;
                                      _selectedIndex = submenu.first[
                                          'index']; // Atualiza para a primeira tela do submenu
                                    });
                                  }
                                },
                              ),
                              ListTile(
                                leading: const Icon(
                                  Icons.file_open_outlined,
                                  color: Colors.white70,
                                ),
                                title: Text('Relatórios', style: simpleText),
                                onTap: () {
                                  setState(() {
                                    _selectedIndex =
                                        15; // Índice correto da tela de perfil na lista _screens
                                    isSecondDrawerOpen =
                                        false; // Fecha a segunda drawer caso esteja aberta
                                  });
                                },
                              ),
                              ListTile(
                                leading: const Icon(
                                  Icons.car_rental,
                                  color: Colors.white70,
                                ),
                                title: Text('Veículos', style: simpleText),
                                onTap: () {
                                  final submenu = secondDrawerItems['Veiculos'];
                                  if (submenu != null && submenu.isNotEmpty) {
                                    setState(() {
                                      selectedItem = 'Veiculos';
                                      isSecondDrawerOpen = true;
                                      _selectedIndex = submenu.first[
                                          'index']; // Atualiza para a primeira tela do submenu
                                    });
                                  }
                                },
                              ),
                              Divider(color: drawerTextColor),
                              ListTile(
                                leading: const Icon(
                                  Icons.person,
                                  color: Colors.white70,
                                ),
                                title: Text('Perfil', style: simpleText),
                                onTap: () {
                                  setState(() {
                                    _selectedIndex =
                                        26; // Índice correto da tela de perfil na lista _screens
                                    isSecondDrawerOpen =
                                        false; // Fecha a segunda drawer caso esteja aberta
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

                // Área do conteúdo principal
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            // Segunda Drawer dinâmica
                            if (isSecondDrawerOpen)
                              Container(
                                width: MediaQuery.of(context).size.width * 0.2,
                                color: const Color(
                                  0xFFECEFF1,
                                ), // Fundo da parte superior sem borda
                                child: Column(
                                  children: [
                                    // Parte superior SEM borda
                                    Container(height: 60, color: Colors.white),

                                    // Parte COM borda (a partir do Align e até o final)
                                    Expanded(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFFECEFF1,
                                          ), // Mantém a cor de fundo
                                          border: Border.all(
                                            color: const Color.fromARGB(
                                              255,
                                              216,
                                              216,
                                              216,
                                            ), // Cor da borda
                                            width: 1.0, // Espessura da borda
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            Align(
                                              alignment: Alignment.topRight,
                                              child: IconButton(
                                                icon: const Icon(
                                                  Icons.close,
                                                  color: Colors.black54,
                                                ),
                                                onPressed: closeSecondDrawer,
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            // Gerando dinamicamente os itens da segunda drawer usando _buildDrawerItem
                                            Expanded(
                                              child: ListView(
                                                children: [
                                                  ...?secondDrawerItems[
                                                          selectedItem]
                                                      ?.map(
                                                    (
                                                      item,
                                                    ) =>
                                                        _buildDrawerItem(
                                                      icon: item['icon'],
                                                      text: item['text'],
                                                      index: item['index'],
                                                      onTap: () {
                                                        setState(() {
                                                          _selectedIndex =
                                                              item['index'];
                                                        });
                                                      },
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // Conteúdo principal
                            Expanded(
                              child: Column(
                                children: [
                                  Expanded(
                                    child: Container(
                                      child: _screens[_selectedIndex],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(UnidadeProvider unidadeProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(color: backColorMobile),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar e informações do usuário
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: textPrimary,
                radius: 32,
                child: _user?.photoURL != null
                    ? ClipOval(
                        child: Image.network(
                          _user!.photoURL!,
                          fit: BoxFit.cover,
                          width: 60,
                          height: 60,
                          loadingBuilder: (context, child, progress) {
                            return progress == null
                                ? child
                                : const CircularProgressIndicator();
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.person,
                              size: 36,
                              color: Colors.white,
                            );
                          },
                        ),
                      )
                    : const Icon(
                        Icons.person,
                        size: 36,
                        color: Colors.white,
                      ),
              ),
              const SizedBox(height: 12),
              Text("Usuário logado", style: simpleSubText),
              const SizedBox(height: 4),
              Text(_user?.displayName ?? "Usuário", style: simpleText),
            ],
          ),

          const SizedBox(height: 10),
          Divider(color: drawerTextColor),

          // Seletor de Unidade
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (unidadeProvider.unidadeSelecionada == null)
                Text('Selecione a Unidade', style: simpleSubText),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.filter_list, color: textPrimary, size: 18),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    dropdownColor: Colors.white,
                    style: const TextStyle(
                      color: Color(0xFF37474F),
                      fontSize: 14,
                    ),
                    value: unidadeProvider.unidadeSelecionada ??
                        (unidades.isNotEmpty ? unidades.first : null),
                    hint: Text("Selecione a unidade", style: simpleTitleText),
                    icon: const SizedBox.shrink(),
                    underline: const SizedBox.shrink(),
                    items: unidades.map((String unidade) {
                      return DropdownMenuItem<String>(
                        value: unidade,
                        child: Text(
                          unidade,
                          style: bodyTextStyle.copyWith(fontSize: 14),
                        ),
                      );
                    }).toList(),
                    selectedItemBuilder: (BuildContext context) {
                      return unidades.map((String unidade) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Text("Unidade", style: simpleTitleText),
                        );
                      }).toList();
                    },
                    onChanged: (String? novaUnidade) {
                      if (novaUnidade != null) {
                        unidadeProvider.setUnidadeSelecionada(novaUnidade);
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
              children: [
                Text(
                  unidadeProvider.unidadeSelecionada!,
                  style: simpleTitleText,
                ),
                Divider(color: drawerTextColor),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String text,
    required int index,
    required VoidCallback onTap,
  }) {
    final isHovered = hoveredItem == text; // Verifica se está sendo "hovered"
    final isSelected = _selectedIndex == index; // Verifica se está selecionado

    return MouseRegion(
      onEnter: (_) {
        setState(() {
          hoveredItem = text; // Atualiza o item "hovered"
        });
      },
      onExit: (_) {
        setState(() {
          hoveredItem = null; // Remove o "hover"
        });
      },
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedIndex = index; // Altera a tela ao clicar
          });
          onTap();
        },
        child: Container(
          color: isSelected
              ? textPrimary // Cor de fundo para o item selecionado
              : isHovered
                  ? textPrimary // Cor ao passar o mouse
                  : Colors.transparent, // Fundo padrão
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? const Color.fromARGB(255, 6, 41, 70)
                    : isHovered
                        ? const Color.fromARGB(255, 6, 41, 70)
                        : const Color.fromARGB(255, 6, 41, 70),
              ),
              const SizedBox(width: 16.0),
              Text(
                text,
                style: bodyTextStyle.copyWith(
                  color: isSelected
                      ? const Color.fromARGB(255, 6, 41, 70)
                      : isHovered
                          ? const Color.fromARGB(255, 6, 41, 70)
                          : const Color.fromARGB(
                              255,
                              6,
                              41,
                              70,
                            ), // Cor não selecionada
                  fontWeight:
                      isSelected ? FontWeight.normal : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
