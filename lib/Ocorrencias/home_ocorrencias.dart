
import 'package:checkutil/Ocorrencias/home_ocorrenciasmobile.dart';
import 'package:checkutil/Web/home_empresa.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';


class HomeOcorrencias extends StatelessWidget {
  const HomeOcorrencias({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (kIsWeb) {
          return const HomeEmpresaPage();
        } else {
          return  HomeOcorrenciasMobile();
        
        }
      },
    );
  }
}