

import 'package:checkutil/Componentes/colors.dart';
import 'package:checkutil/Componentes/gradient.dart';
import 'package:checkutil/Componentes/tipografia.dart';
import 'package:checkutil/Mobile/Cadastros/add_empresamobile.dart';
import 'package:checkutil/Mobile/Cadastros/add_equipmobile.dart';
import 'package:checkutil/Mobile/Cadastros/unidades_mobile.dart';
import 'package:checkutil/Mobile/User/user_cadastro.dart';
import 'package:checkutil/Services/equipamentos.dart';
import 'package:checkutil/Web/Addmanutencao/add_manutencao.dart';
import 'package:checkutil/Web/Addmanutencao/anual.dart';
import 'package:checkutil/Web/Addmanutencao/mensal.dart';
import 'package:checkutil/Web/Addmanutencao/semanal.dart';
import 'package:checkutil/Web/Addmanutencao/trimestral.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class HomeCadastrosMobileScreen extends StatelessWidget {
  final List<Widget> _screens = [
    const CadastrarEquipamentoMobileScreen(),
    const CadastrarUnidadeMobile(),
    const EmpresaMobile(),
    const CadastrarUsuarioPage(),
    const MaintenancePlanPage(), // cria um plano de manutenção
    const SemanalPage(),
    const MensalPage(),
    const TrimestralPage(),
    const AnualPage(),
    
  ];

  final List<String> titles = [
    "Cadastrar Equipamento",
    "Cadastrar Unidade",
    "Cadastrar Empresa",
    "Cadastrar Usuário",
    "Checklist Diário",
    "Checklist Semanal",
    "Checklist Mensal",
    "Checklist Trimestral",
    "Checklist Anual",
    
    
  ];

  final List<IconData> icons = [
    Icons.build,
    Icons.location_on,
    Icons.business,
    Icons.person_add_alt_1_outlined,
    Icons.assignment_add,
    Icons.assignment_add,
    Icons.assignment_add,
    Icons.assignment_add,
    Icons.assignment_add,
  ];

  HomeCadastrosMobileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    var unidadeProvider = Provider.of<UnidadeProvider>(context);
    return Scaffold(
      body: Container(
        color: textPrimary,
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        //decoration: BoxDecoration(gradient: primarySplitBillLightGradient()),
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.zero, // Sem margens
              width: double.infinity, // Largura total
              height: 80.h, // Altura fixa
              decoration: BoxDecoration(
                color: backgroundAppBarMobile,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(
                      0.6,
                    ), // Menos opacidade para suavizar a sombra
                    spreadRadius: 0,
                    blurRadius: 10, // Maior desfoque para uma sombra mais suave
                    offset: const Offset(
                      0,
                      8,
                    ), // Deslocamento menor para uma sombra mais sutil
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'Cadastros',
                  style: mobiTextStyle.copyWith(fontSize: 28.sp),
                ),
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  childAspectRatio: 1.2,
                ),
                itemCount: _screens.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => _screens[index],
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: backgroundAppBarMobile,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(icons[index], color: textSecondary, size: 30),
                          Text(
                            titles[index],
                            style: mobileTextStyle.copyWith(
                              fontSize: 12.sp,
                              color: textSecondary,
                              fontWeight: FontWeight.w200,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
