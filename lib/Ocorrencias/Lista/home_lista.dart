import 'package:checkutil/Ocorrencias/Lista/lista_mobile.dart';
import 'package:checkutil/Web/home_empresa.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class HomeLista extends StatelessWidget {
  const HomeLista({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (kIsWeb) {
          return const HomeEmpresaPage();
        } else {
          return ListaOcorrenciasMobile();
        }
      },
    );
  }
}
