import 'package:checkutil/Componentes/colors.dart';
import 'package:checkutil/Componentes/tipografia.dart';
import 'package:checkutil/Services/equipamentos.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

class MicroCheckPage extends StatefulWidget {
  const MicroCheckPage({super.key});

  @override
  _MicroCheckPageState createState() => _MicroCheckPageState();
}

class _MicroCheckPageState extends State<MicroCheckPage> {
  final _formKey = GlobalKey<FormState>();
  String? unidadeSelecionada;

  @override
  void initState() {
    super.initState();
    unidadeSelecionada =
        Provider.of<UnidadeProvider>(context, listen: false).unidadeSelecionada;
  }

  Future<void> _saveChecklist() async {
    try {
      // Itens do checklist diário
      final checklistItems = [
        'Lataria: Verificar integridade de toda a lataria.',
        'Faróis/Lâmpadas/Piscas: Verificar condições e funcionamento.',
        'Pneus: Verificar se estão calibrados e se existe alguma avaria.',
        'Para-brisa e limpadores: Verificar condições e funcionamento.',
        'Portas e fechaduras: Verificar condições e funcionamento.',
        'Parachoques e para-barros: Verificar condições e fixação.',
        'Retrovisores: Verificar condições e funcionamento.',
        'Rodas e parafusos: Verificar condição e aperto dos parafusos.',
        'Placas de sinalização e de identificação: Legibilidade e fixação adequada.',
        'Assentos e estofados: Verificar condições e funcionamento.',
        'Sistema de iluminação interna: Verificar condições e funcionamento.',
        'Vidros e janelas: Condição dos vidros, funcionamento das janelas e cortinas.',
        'Instrumentos e indicadores: Verificar no painel os indicadores.',
        'Tacógrafo: Condição e funcionamento (inclusive de discos e fitas).',
            'Ar-condicionado: Verificar condições e funcionamento.',
        'Cintos de segurança: Verificar condições e funcionamento.',
        'Óleo do motor: Verificar o nível.',
        'Fluido de freio: Verificar o nível.',
        'Líquido de arrefecimento: Verificar o nível.',
        'Fluido de direção hidráulica: Verificar o nível.',
        'Fluido de embreagem: Verificar o nível.',
        'Bateria: Verificar carga e corrosões nos terminais.',
        'Freios: Verificar condições e funcionamento.',
        'Correias e mangueiras: Verificar condições e funcionamento.',
        'Documentação: Verificar se os documentos estão em ordem.',
        'Itens de segurança: Chave de roda/ Triangulo/ Macaco.',
        'Limpeza: Verificar se o veículo está limpo.',
      ];

      for (int i = 0; i < checklistItems.length; i++) {
        await FirebaseFirestore.instance
            .collection('Checklist_veiculos')
            .doc(unidadeSelecionada)
            .collection('MicroÔnibus')
            .add({
          'item': checklistItems[i],
          'ordem': i, // <-- isso aqui garante a ordem!
          'status': 'pendente',
          'createdAt': DateTime.now(),
          'unidade': unidadeSelecionada,
        });
      }
      

      // Feedback ao usuário
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Checklist Micro Ônibus salvo com sucesso!')),
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
                          'Checklist Micro Ônibus',
                          style: headTextStyle,
                        ),
                        const SizedBox(height: 40),
                        const Text(
                          'Itens do Checklist de Micro Ônibus:',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                            '•Lataria: Verificar integridade de toda a lataria.'),
                        const Text(
                            '•Faróis/Lâmpadas/Piscas: Verificar condições e funcionamento.'),
                        const Text(
                            '•Pneus: Verificar se estão calibrados e se existe alguma avaria.'),
                        const Text(
                            '•Parachoques e para-barros: Verificar condições e fixação.'),
                        const Text(
                            '•Para-brisa e limpadores: Verificar condições e funcionamento.'),
                        const Text(
                            '•Portas e fechaduras: Verificar condições e funcionamento.'),
                        const Text(
                            '•Rodas e parafusos: Verificar condição e aperto dos parafusos.'),
                        const Text(
                            '•Placas de sinalização e de identificação: Verificar legibilidade e fixação adequada.'),
                        const Text(
                            '•Assentos e estofados: Verificar condições e funcionamento.'),
                        const Text(
                            '•Sistema de iluminação interna: Verificar condições e funcionamento.'),
                        const Text(
                            '•Vidros e janelas: Verificar condição dos vidros, funcionamento das janelas e cortinas.'),
                        const Text(
                            '•Retrovisores: Verificar condições e funcionamento.'),
                        const Text(
                            '•Instrumentos e indicadores: Verificar no painel os indicadores.'),
                        const Text(
                            '•Tacógrafo: Condição e funcionamento (inclusive de discos e fitas).'),
                        const Text(
                            '•Ar-condicionado: Verificar condições e funcionamento.'),
                        const Text(
                            '•Cintos de segurança: Verificar condições e funcionamento.'),
                        const Text('•Óleo do motor: Verificar o nível.'),
                        const Text('•Fluido de freio: Verificar o nível.'),
                        const Text(
                            '•Líquido de arrefecimento: Verificar o nível.'),
                        const Text(
                            '•Fluido de direção hidráulica: Verificar o nível.'),
                        const Text('•Fluido de embreagem: Verificar o nível.'),
                        const Text(
                            '•Bateria: Verificar carga e corrosões nos terminais.'),
                        const Text(
                            '•Freios: Verificar condições e funcionamento.'),
                        const Text(
                            '•Correias e mangueiras: Verificar condições e funcionamento.'),
                        const Text(
                            '•Documentação: Verificar se os documentos estão em ordem.'),
                        const Text(
                            '•Itens de segurança: Chave de roda/ Triangulo/ Macaco.'),
                        const Text(
                            '•Limpeza: Verificar se o veículo está limpo.'),
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
