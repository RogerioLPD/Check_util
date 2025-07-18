import 'package:checkutil/Services/equipamentos.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';


class MaintenanceMobile extends StatefulWidget {
  const MaintenanceMobile({super.key});

  @override
  _MaintenanceMobileState createState() => _MaintenanceMobileState();
}

class _MaintenanceMobileState extends State<MaintenanceMobile> {
  final _formKey = GlobalKey<FormState>();
  String? unidadeSelecionada;
  String? selectedEquipment;
  List<String> equipmentList = [];

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
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('Usuário não autenticado.');

      final snapshot = await FirebaseFirestore.instance
          .collection('Equipamentos')
          .doc(userId)
          .collection('Equipamento')
          .where('unidade', isEqualTo: unidadeSelecionada)
          .get();

      setState(() {
        equipmentList = snapshot.docs
            .map((doc) => doc.data()['tipoEquipamento']?.toString() ?? 'Desconhecido')
            .toList();
      });
    } catch (e) {
      _showSnackBar('Erro ao buscar equipamentos: $e');
    }
  }

  Future<void> _saveChecklist() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;

      if (userId == null) {
        throw Exception('Usuário não autenticado.');
      }

      // Itens do checklist diário
      final checklistItems = [
        'Verificação do nível de óleo lubrificante.',
        'Inspeção visual de vazamentos de óleo, combustível e líquido de arrefecimento.',
        'Conferência do painel de controle quanto a alertas e mensagens de erro.',
        'Avaliação da tensão e frequência da bateria de partida.',
      ];

      // Salva o checklist no Firestore
      for (var item in checklistItems) {
        await FirebaseFirestore.instance
            .collection('Checklist')
            .doc(userId)
            .collection('Diario')
            .add({
          'item': item,
          'status': 'pendente',
          'createdAt': DateTime.now(),
          'unidade': unidadeSelecionada,
          'equipamento': selectedEquipment,
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
          'Checklist Diário',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          ElevatedButton(
            onPressed: _saveChecklist,
            child: const Text('Salvar'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedEquipment,
                  hint: const Text('Selecione o Equipamento'),
                  items: equipmentList.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
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
                  'Itens do Checklist Diário:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text('• Verificação do nível de óleo lubrificante.'),
                const Text(
                    '• Inspeção visual de vazamentos de óleo, combustível e líquido de arrefecimento.'),
                const Text(
                    '• Conferência do painel de controle quanto a alertas e mensagens de erro.'),
                const Text(
                    '• Avaliação da tensão e frequência da bateria de partida.'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}