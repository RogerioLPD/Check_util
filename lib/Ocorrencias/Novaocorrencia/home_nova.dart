import 'package:checkutil/Ocorrencias/Novaocorrencia/nova_mobile.dart';
import 'package:checkutil/Web/home_empresa.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class HomeNovaOcorrencias extends StatelessWidget {
  const HomeNovaOcorrencias({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (kIsWeb) {
          return const HomeEmpresaPage();
        } else {
          return const NovaOcorrenciaMobile();
        }
      },
    );
  }
}
