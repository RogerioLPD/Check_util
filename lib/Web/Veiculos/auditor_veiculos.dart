import 'package:checkutil/Login/login.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Para formatar as datas

class AuditorVeiculosPage extends StatelessWidget {
  final String? placa;
  final String? tipoVeiculo;
  final String? unidade;

  AuditorVeiculosPage({this.placa, this.unidade, this.tipoVeiculo});

  factory AuditorVeiculosPage.fromUrl() {
    final uri = Uri.base;
    return AuditorVeiculosPage(
      placa: uri.queryParameters['placa'] ?? '',
      unidade: uri.queryParameters['unidade'] ?? '',
      tipoVeiculo: uri.queryParameters['tipoVeiculo'] ?? '',
    );
  }
  Future<Map<String, dynamic>?> fetchLastChecklist(String placa) async {
    try {
      print('Buscando checklists para o equipamento: $placa');

      var querySnapshot = await FirebaseFirestore.instance
          .collection('Veiculos_finalizados')
          .where('placa', isEqualTo: placa)
          .get();

      print('Documentos encontrados: ${querySnapshot.docs.length}');

      if (querySnapshot.docs.isEmpty) {
        print('Nenhum checklist encontrado para o equipamento $placa');
        return null;
      }

      var sortedDocs = querySnapshot.docs
          .where((doc) => doc.data().containsKey('dataFinalizacao'))
          .toList();

      if (sortedDocs.isEmpty) {
        print('Nenhum documento com dataFinalizacao encontrado.');
        return null;
      }

      sortedDocs.sort((a, b) {
        Timestamp tA = a['dataFinalizacao'] as Timestamp;
        Timestamp tB = b['dataFinalizacao'] as Timestamp;
        return tB.compareTo(tA);
      });

      print('Último checklist encontrado: ${sortedDocs.first.data()}');
      return sortedDocs.first.data();
    } catch (e) {
      print('Erro ao buscar checklist: $e');
    }
    return null;
  }

  void showChecklistDialog(
      BuildContext context, Map<String, dynamic> checklistData) {
    final String placa = checklistData['placa'] ?? 'N/A';
    final Timestamp? dataFinalizacao = checklistData['dataFinalizacao'];
    final Map<String, dynamic> usuario =
        Map<String, dynamic>.from(checklistData['usuario'] ?? {});
    final String nomeUsuario = usuario['nome'] ?? 'N/A';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            'Detalhes da Última Inspeção',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00BFAE),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('Veículo (Placa):', placa, Icons.qr_code),
              _buildInfoRow(
                'Data de Finalização:',
                dataFinalizacao != null
                    ? formatTimestampWithTime(dataFinalizacao)
                    : 'N/A',
                Icons.event,
              ),
              _buildInfoRow('Funcionário:', nomeUsuario, Icons.person),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Fechar',
                style: TextStyle(
                  color: Color(0xFF00BFAE),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF00BFAE), size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black54),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String formatTimestampWithTime(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return DateFormat('dd/MM/yy - HH:mm').format(timestamp.toDate());
    }
    return 'N/A';
  }

  void handleViewReport(BuildContext context, String realPlaca) async {
    final checklistData = await fetchLastChecklist(realPlaca);

    if (checklistData != null) {
      showChecklistDialog(context, checklistData);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Nenhum checklist encontrado para este equipamento.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    String realPlaca = placa ?? '';
    String realUnidade = unidade ?? '';
    String realTipoVeiculo = tipoVeiculo ?? '';

    final uri = Uri.base;

    // Trata caso venha por URL
    if (realPlaca.isEmpty) {
      if (uri.queryParameters['placa'] != null) {
        realPlaca = uri.queryParameters['placa']!;
      } else if (uri.fragment.contains('?')) {
        final fragmentParams =
            Uri.splitQueryString(uri.fragment.split('?').last);
        realPlaca = fragmentParams['placa'] ?? '';
      }
    }

    if (realUnidade.isEmpty) {
      if (uri.queryParameters['unidade'] != null) {
        realUnidade = uri.queryParameters['unidade']!;
      } else if (uri.fragment.contains('?')) {
        final fragmentParams =
            Uri.splitQueryString(uri.fragment.split('?').last);
        realUnidade = fragmentParams['unidade'] ?? '';
      }
    }

    if (realTipoVeiculo.isEmpty) {
      if (uri.queryParameters['tipoVeiculo'] != null) {
        realTipoVeiculo = uri.queryParameters['tipoVeiculo']!;
      } else if (uri.fragment.contains('?')) {
        final fragmentParams =
            Uri.splitQueryString(uri.fragment.split('?').last);
        realTipoVeiculo = fragmentParams['tipoVeiculo'] ?? '';
      }
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(''),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LoginPage(
                    placa: realPlaca,
                    unidade: realUnidade,
                    tipoVeiculo: realTipoVeiculo,
                  ),
                ),
              );
            },
            child: const Text(
              'Login',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Imagem de fundo com sobreposição
          Container(
            height: size.height,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                    'assets/images/Principal1.png'), // coloque sua imagem aqui
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF008080), Color(0xFF008080)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 80),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const Text(
                          "Check Util",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "Otimize seus processos com o Check Util — um sistema completo de gestão de facilities e checklists, desenvolvido para atender às mais diversas demandas operacionais, em qualquer setor.\n\n"
                          "Destaques que fazem o Check Util indispensável:\n"
                          "- Monitoramento em tempo real de todas as operações e tarefas\n"
                          "- Automação de checklists e rotinas, reduzindo falhas humanas\n"
                          "- Relatórios inteligentes que apoiam a tomada de decisão\n"
                          "- Gestão eficiente de equipes com registros precisos de cada execução\n"
                          "- Mais conformidade e segurança em ambientes críticos ou altamente regulados",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 30),
                        ElevatedButton(
                          onPressed: () => handleViewReport(context, realPlaca),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 14),
                            backgroundColor: Colors.tealAccent[700],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 5,
                          ),
                          child: const Text(
                            "Ver Detalhes do Local",
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 60),
                  Container(
                    width: double.infinity,
                    color: Colors.grey[200],
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: const Column(
                      children: [
                        Text(
                          "© 2025 ComCode Fábrica de Softwares",
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Seu parceiro em inovação tecnológica.",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
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
    );
  }
}
