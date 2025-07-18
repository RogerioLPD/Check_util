import 'package:checkutil/Componentes/colors.dart';
import 'package:checkutil/Componentes/tipografia.dart';
import 'package:checkutil/Services/equipamentos.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

class AnualPage extends StatefulWidget {
  const AnualPage({super.key});

  @override
  _AnualPageState createState() => _AnualPageState();
}

class _AnualPageState extends State<AnualPage> {
  final _formKey = GlobalKey<FormState>();
  String? unidadeSelecionada;
  String? selectedEquipment;
  List<Map<String, String>> equipmentList = [];

  @override
  void initState() {
    super.initState();
    unidadeSelecionada =
        Provider.of<UnidadeProvider>(context, listen: false).unidadeSelecionada;
    _fetchEquipmentList();
  }

 Future<void> _fetchEquipmentList() async {
    if (unidadeSelecionada == null || unidadeSelecionada!.isEmpty) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Equipamentos')
          .where('unidade', isEqualTo: unidadeSelecionada)
          .get();

      setState(() {
        equipmentList = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'tipoEquipamento':
                data['tipoEquipamento']?.toString() ?? 'Desconhecido',
            'tag': data['tag']?.toString() ?? 'Sem tag',
          };
        }).toList();
      });
    } catch (e) {
      _showSnackBar('Erro ao buscar equipamentos: $e');
    }
  }

  Future<void> _saveChecklist() async {
    try {
      // Itens do checklist diário
      final checklistItems = [
        'Manutenção completa do sistema de arrefecimento (troca de líquido de arrefecimento, limpeza do radiador).',
        'Revisão detalhada do sistema de alimentação de combustível.',
        'Inspeção dos rolamentos e acoplamentos mecânicos.',
        'Teste de carga máxima para avaliação do desempenho.',
        'Auditoria da documentação de manutenção e conformidade regulatória.',
      ];

      // Salva o checklist no Firestore
      for (var item in checklistItems) {
        await FirebaseFirestore.instance
            .collection('Checklist')
            .doc(unidadeSelecionada)
            .collection('Anual')
            .add({
          'item': item,
          'status': 'pendente',
          'createdAt': DateTime.now(),
          'unidade': unidadeSelecionada,
          'equipamento': selectedEquipment,
          'tag': selectedEquipment,
        });
      }

      // Feedback ao usuário
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Checklist diário salvo com sucesso!')),
      );
    } catch (e) {
      // Tratamento de erros
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar o checklist: $e')),
      );
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }


  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          '',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          const SizedBox(width: 10),
          customElevatedButton(
            onPressed: _saveChecklist,
            label: 'Salvar',
            labelStyle: buttonTextStyle,
            icon: Icons.check,
            iconColor: const Color.fromARGB(255, 6, 41, 70),
            backgroundColor: backgroundButton,
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(0, 4, 0, 0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: EdgeInsets.zero, // Garantindo que não há margem extra
                  padding: EdgeInsets.zero,
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(
                          color: Color.fromARGB(255, 216, 216, 216),
                          width: 1.0), // Borda no topo
                      right: BorderSide(
                          color: Color.fromARGB(255, 216, 216, 216),
                          width: 1.0), // Borda na direita
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(45, 20, 40, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Checklist Anual',
                          style: headTextStyle,
                        ),
                        const SizedBox(height: 40),
                DropdownButtonFormField<String>(
                  value: selectedEquipment,
                  hint: const Text('Selecione o Equipamento'),
                  items: equipmentList.map((Map<String, String> equipment) {
                    return DropdownMenuItem<String>(
                      value: equipment['tag'],
                      child: Text(
                          '${equipment['tag']} - ${equipment['tipoEquipamento']}'),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      selectedEquipment = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, selecione um equipamento.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                const Text(
                  'Itens do Checklist Anual:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text('• Manutenção completa do sistema de arrefecimento (troca de líquido de arrefecimento, limpeza do radiador).'),
                const Text(
                    '• Revisão detalhada do sistema de alimentação de combustível.'),
                const Text(
                    '• Inspeção dos rolamentos e acoplamentos mecânicos.'),
                const Text(
                    '• Teste de carga máxima para avaliação do desempenho.'),
                    const Text(
                    '• Auditoria da documentação de manutenção e conformidade regulatória.'),
              ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}