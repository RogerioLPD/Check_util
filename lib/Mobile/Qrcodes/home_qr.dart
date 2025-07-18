import 'package:checkutil/Mobile/Checklist/checklist_itens.dart';
import 'package:checkutil/Services/agendamentos_provider.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class HomeQRScreen extends StatefulWidget {
  final String tag;
  final String unidade;
  const HomeQRScreen({super.key, required this.unidade, required this.tag});

  @override
  State<HomeQRScreen> createState() => _HomeQRScreenState();
}

class _HomeQRScreenState extends State<HomeQRScreen> {
  List<Map<String, dynamic>> atividades = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAtividades();
  }

  Future<void> _fetchAtividades() async {
    final agendamentosProvider =
        Provider.of<AgendamentosProvider>(context, listen: false);
    await agendamentosProvider.buscarAgendamentosPorTag(widget.tag);

    print(
        'Agendamentos carregados: ${agendamentosProvider.agendamentos.length}');

    setState(() {
      atividades = agendamentosProvider.agendamentos;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Atividades para: ${widget.tag}',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.teal,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : atividades.isEmpty
              ? Center(
                  child: Text('Nenhuma atividade encontrada.',
                      style: TextStyle(fontSize: 16)))
              : Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: ListView.builder(
                    itemCount: atividades.length,
                    itemBuilder: (context, index) {
                      final atividade = atividades[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                        elevation: 4,
                        child: ListTile(
                          contentPadding: EdgeInsets.all(16),
                          leading: Icon(Icons.assignment,
                              color: Colors.teal, size: 32),
                          title: Text(
                            atividade['checklistNome'] ??
                                'Inspeção Desconhecida',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Status: ${atividade['status']}',
                                style: TextStyle(
                                    fontSize: 14, color: Colors.grey[700]),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Data: ${DateFormat('dd/MM/yyyy HH:mm').format((atividade['dataAgendada'] as Timestamp).toDate())}',
                                style: TextStyle(
                                    fontSize: 14, color: Colors.grey[700]),
                              ),
                            ],
                          ),
                          trailing:
                              Icon(Icons.arrow_forward_ios, color: Colors.teal),
                          onTap: () {
                            final agendamentoIdSelecionado = atividade['id'];
                            final unidade = atividade[
                                'unidade']; // ou o nome correto do campo
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChecklistTagScreen(
                                  tag: atividade['tag'],
                                  agendamentoId: agendamentoIdSelecionado,
                                  unidade: unidade,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
