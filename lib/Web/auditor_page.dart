import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Para formatar as datas

class AuditorPage extends StatelessWidget {
  final String? tag;

  AuditorPage({this.tag});

  static String extractRoomNumberFromUrl(BuildContext context) {
    final uri = Uri.base;
    return uri.queryParameters['tag'] ?? 'N/A';
  }

  Future<Map<String, dynamic>?> fetchLastChecklist(String tag) async {
    try {
      print('Buscando checklists para o equipamento: $tag');

      var querySnapshot = await FirebaseFirestore.instance
          .collection('Checklist_finalizados')
          .where('tag', isEqualTo: tag)
          .get();

      print('Documentos encontrados: ${querySnapshot.docs.length}');

      if (querySnapshot.docs.isEmpty) {
        print('Nenhum checklist encontrado para o equipamento $tag');
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
    final String tag = checklistData['tag'] ?? 'N/A';
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
              _buildInfoRow('Equipamento (TAG):', tag, Icons.qr_code),
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

  void handleViewReport(BuildContext context, String realTag) async {
    final checklistData = await fetchLastChecklist(realTag);

    if (checklistData != null) {
      showChecklistDialog(context, checklistData);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Nenhum checklist encontrado para este equipamento.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String realTag = tag ?? 'Desconhecido';

    if (realTag.isEmpty || realTag == 'Desconhecido') {
      final uri = Uri.base;
      if (uri.queryParameters['tag'] != null) {
        realTag = uri.queryParameters['tag']!;
      } else if (uri.fragment.contains('?')) {
        final fragmentParams =
            Uri.splitQueryString(uri.fragment.split('?').last);
        realTag = fragmentParams['tag'] ?? 'Desconhecido';
      }
    }

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  height: MediaQuery.of(context).size.height * 0.6,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF00BFAE),
                        Color(0xFF008080)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 80.0),
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
                      const SizedBox(height: 10),
                      Container(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.4,
                        ),
                        child: const SingleChildScrollView(
                          child: Text(
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
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: [
                  TextButton(
                    onPressed: () => handleViewReport(context, realTag),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.all(16.0),
                      backgroundColor: const Color(0xFF00BFAE),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "Ver Detalhes do Local",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 50),
            Container(
              color: Colors.grey[200],
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: const Column(
                children: [
                  Text(
                    "© 2025 ComCode Fábrica de Softwares",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Seu parceiro em inovação tecnológica.",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
