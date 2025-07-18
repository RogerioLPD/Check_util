import 'package:checkutil/Services/equipamentos.dart';
import 'package:checkutil/Services/naoconforme_veiculos.dart';
import 'package:checkutil/Services/veiculo_finalizado_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class DashboardVeiculos extends StatefulWidget {
  const DashboardVeiculos({super.key});

  @override
  State<DashboardVeiculos> createState() => _DashboardVeiculosState();
}

class _DashboardVeiculosState extends State<DashboardVeiculos> {
  bool _dadosCarregados = false;

 @override
void didChangeDependencies() {
  super.didChangeDependencies();

  final unidade = Provider.of<UnidadeProvider>(context).unidadeSelecionada;

  if (!_dadosCarregados && unidade != null && unidade.isNotEmpty) {
    _dadosCarregados = true;
    Provider.of<VeiculoFinalizadoProvider>(context, listen: false)
        .carregarVeiculosDoDia(unidade);
    Provider.of<ItensNaoConformesVeiculos>(context, listen: false)
        .setUnidadeSelecionada(unidade);
  }
}


  @override
  Widget build(BuildContext context) {
    final veiculoProvider = Provider.of<VeiculoFinalizadoProvider>(context);
    final unidadeProvider = Provider.of<UnidadeProvider>(context);
    final naoConformesProvider =
    Provider.of<ItensNaoConformesVeiculos>(context);
final listaNaoConformes = naoConformesProvider.itensNaoConformes;


    if (unidadeProvider.unidadeSelecionada == null) {
      return const Scaffold(
        body: Center(child: Text("Carregando unidade...")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard Veículos"),
        backgroundColor: Colors.teal,
      ),
      body: veiculoProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 800;

                if (isMobile) {
                  // Layout para mobile (coluna única)
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Veículos Finalizados',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        ...veiculoProvider.veiculos.map((veiculo) {
                          final dataFormatada = DateFormat('dd/MM/yyyy – HH:mm')
                              .format(veiculo.dataFinalizacao);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            elevation: 6,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Placa: ${veiculo.placa}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold, fontSize: 18)),
                                  const SizedBox(height: 8),
                                  Text('Usuário: ${veiculo.usuarioNome} (${veiculo.usuarioEmail})'),
                                  Text('Finalizado em: $dataFormatada'),
                                ],
                              ),
                            ),
                          );
                        }).toList(),

                        const SizedBox(height: 24),
                        const Text('Itens Não Conformes',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        if (listaNaoConformes.isEmpty)
                          const Text('Nenhum item não conforme encontrado.'),
                        ...listaNaoConformes.map((item) {
                          final dataFormatada = item['dataFinalizacao'] != null
                              ? DateFormat('dd/MM/yyyy – HH:mm')
                                  .format((item['dataFinalizacao'] as Timestamp).toDate())
                              : '';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            color: Colors.red[50],
                            elevation: 4,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: const [
                                      Icon(Icons.warning, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Item Não Conforme',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold, fontSize: 16)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text('Item: ${item['item']}'),
                                  Text('Comentário: ${item['comentario']}'),
                                  Text('Placa: ${item['placa']}'),
                                  Text('Data: $dataFormatada'),
                                  Text('Usuário: ${item['usuario']['nome']}'),
                                  const SizedBox(height: 8),
                                  if (item['imagem'] != null && (item['imagem'] as String).isNotEmpty)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        item['imagem'],
                                        height: 150,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  );
                } else {
                  // Layout para Web (duas colunas lado a lado com scroll)
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Coluna Veículos
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Veículos Finalizados',
                                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 12),
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: veiculoProvider.veiculos.length,
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: 1.5,
                                ),
                                itemBuilder: (context, index) {
                                  final veiculo = veiculoProvider.veiculos[index];
                                  final dataFormatada = DateFormat('dd/MM/yyyy – HH:mm')
                                      .format(veiculo.dataFinalizacao);

                                  return Card(
                                    elevation: 6,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16)),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Placa: ${veiculo.placa}',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold, fontSize: 18)),
                                          const SizedBox(height: 6),
                                          Text(
                                              'Usuário: ${veiculo.usuarioNome} '),
                                          Text(dataFormatada),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 24),

                        // Coluna Itens Não Conformes
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Itens Não Conformes',
                                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 12),
                              if (listaNaoConformes.isEmpty)
                                const Text('Nenhum item não conforme encontrado.'),
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: listaNaoConformes.length,
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 1,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: 1.4,
                                ),
                                itemBuilder: (context, index) {
                                  final item = listaNaoConformes[index];
                                  final dataFormatada = item['dataFinalizacao'] != null
                                      ? DateFormat('dd/MM/yyyy – HH:mm')
                                          .format((item['dataFinalizacao'] as Timestamp).toDate())
                                      : '';

                                  return Card(
                                    color: Colors.red[50],
                                    elevation: 4,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12)),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: const [
                                              Icon(Icons.warning, color: Colors.red),
                                              SizedBox(width: 8),
                                              Text('Item Não Conforme',
                                                  style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 16)),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text('Item: ${item['item']}'),
                                          Text('Comentário: ${item['comentario']}'),
                                          Text('Placa: ${item['placa']}'),
                                          Text('Data: $dataFormatada'),
                                          Text('Usuário: ${item['usuario']['nome']}'),
                                          const SizedBox(height: 8),
                                          if (item['imagem'] != null &&
                                              (item['imagem'] as String).isNotEmpty)
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: Image.network(
                                                item['imagem'],
                                                height: 100,
                                                width: double.infinity,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
    );
  }
}