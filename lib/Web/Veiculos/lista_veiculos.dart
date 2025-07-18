import 'package:checkutil/Services/equipamentos.dart';
import 'package:checkutil/Services/veiculos_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dropdown_search/dropdown_search.dart';

class SelecionarVeiculoScreen extends StatefulWidget {
  @override
  _SelecionarVeiculoScreenState createState() =>
      _SelecionarVeiculoScreenState();
}

class _SelecionarVeiculoScreenState extends State<SelecionarVeiculoScreen> {
  String? _veiculoSelecionado;
  Map<String, dynamic>? _veiculoSelecionadoData;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final unidade = Provider.of<UnidadeProvider>(context, listen: false)
          .unidadeSelecionada;
      final veiculoProvider =
          Provider.of<VeiculoProvider>(context, listen: false);

      if (unidade != null) {
        veiculoProvider.listarVeiculos(unidade);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Selecionar Veículo')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Consumer2<VeiculoProvider, UnidadeProvider>(
          builder: (context, veiculoProvider, unidadeProvider, child) {
            if (unidadeProvider.unidadeSelecionada == null) {
              return const Center(child: Text('Nenhuma unidade selecionada.'));
            }

            if (veiculoProvider.veiculos.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownSearch<Map<String, dynamic>>(
                  asyncItems: (String? filter) async {
                    return veiculoProvider.veiculos;
                  },
                  itemAsString: (Map<String, dynamic> veiculo) {
                    return '${veiculo['marca']} - ${veiculo['modelo']} - ${veiculo['placa']}';
                  },
                  dropdownDecoratorProps: const DropDownDecoratorProps(
                    dropdownSearchDecoration: InputDecoration(
                      labelText: 'Selecione um veículo',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  onChanged: (Map<String, dynamic>? veiculo) {
                    setState(() {
                      _veiculoSelecionado = veiculo?['placa'];
                      _veiculoSelecionadoData = veiculo;
                    });
                  },
                  popupProps: const PopupProps.menu(
                    showSearchBox: true,
                    searchFieldProps: TextFieldProps(
                      decoration: InputDecoration(
                        labelText: 'Pesquisar veículo',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  selectedItem: _veiculoSelecionadoData,
                ),
                const SizedBox(height: 20),
                if (_veiculoSelecionadoData != null)
                  Column(
                    children: [
                      const Text(
                        'Imagem do veículo:',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          _veiculoSelecionadoData!['imageUrl'],
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.error),
                        ),
                      ),
                    ],
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
