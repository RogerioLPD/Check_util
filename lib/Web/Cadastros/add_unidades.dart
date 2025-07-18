import 'dart:convert'; // Para base64
import 'dart:io';
import 'package:checkutil/Componentes/colors.dart';
import 'package:checkutil/Componentes/tipografia.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart'; // Para kIsWeb
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class CadastrarUnidadeScreen extends StatefulWidget {
  const CadastrarUnidadeScreen({super.key});

  @override
  _CadastrarUnidadeScreenState createState() => _CadastrarUnidadeScreenState();
}

class _CadastrarUnidadeScreenState extends State<CadastrarUnidadeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();

  List estados = [];
  List cidades = [];
  String? estadoSelecionado;
  String? cidadeSelecionada;
  File? _imagem; // Para Mobile
  String? _imagemBase64; // Para Web

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchEstados();
  }

  Future<void> _fetchEstados() async {
    final response = await http.get(Uri.parse(
        'https://servicodados.ibge.gov.br/api/v1/localidades/estados'));
    if (response.statusCode == 200) {
      setState(() {
        estados = json.decode(response.body);
      });
    }
  }

  Future<void> _fetchCidades(String uf) async {
    final response = await http.get(Uri.parse(
        'https://servicodados.ibge.gov.br/api/v1/localidades/estados/$uf/municipios'));
    if (response.statusCode == 200) {
      setState(() {
        cidades = json.decode(response.body);
      });
    }
  }

  Future<void> _selecionarImagem() async {
    final XFile? imagemSelecionada =
        await _picker.pickImage(source: ImageSource.gallery);
    if (imagemSelecionada != null) {
      if (kIsWeb) {
        // Para Web: Converter a imagem para base64
        final bytes = await imagemSelecionada.readAsBytes();
        setState(() {
          _imagemBase64 = base64Encode(bytes); // Salvar a imagem em base64
        });
      } else {
        // Para Mobile: Usar o File
        setState(() {
          _imagem = File(imagemSelecionada.path);
        });
      }
    }
  }

  Future<void> _salvarUnidade() async {
    if (_formKey.currentState!.validate()) {
      try {
        final userId = FirebaseAuth.instance.currentUser?.uid;

        if (userId == null) {
          throw Exception('Usuário não autenticado.');
        }


        

        // Salvar os dados no Firestore
        await FirebaseFirestore.instance
            .collection('Unidades')
            .doc(userId)
            .collection('Unidade')
            .add({
          'nome': _nomeController.text,
          
          'estado': estadoSelecionado,
          'cidade': cidadeSelecionada,
          
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unidade cadastrada com sucesso!')),
        );

        _nomeController.clear();
       
        setState(() {
          estadoSelecionado = null;
          cidadeSelecionada = null;
          cidades = [];
         
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao cadastrar unidade: $e')),
        );
      }
    }
  }

  void _clearForm() {
    _nomeController.clear();
   

    setState(() {
      estadoSelecionado = null;
      cidadeSelecionada = null;
      cidades = [];
     
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Formulário limpo com sucesso.')),
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
          customElevatedButton(
            onPressed: _clearForm,
            label: 'Cancelar',
            labelStyle: buttonTextStyle,
            icon: Icons.cancel,
            iconColor: const Color.fromARGB(255, 6, 41, 70),
            backgroundColor: const Color.fromARGB(193, 195, 204, 218),
          ),
          const SizedBox(width: 10),
          customElevatedButton(
            onPressed: _salvarUnidade,
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
                        const SizedBox(height: 8),
                        Text(
                          'Cadastrar Unidades',
                          style: headTextStyle,
                        ),
                        const SizedBox(height: 40),
                        Text(
                          'Nome da Unidade',
                          style: secondaryTextStyle,
                          textAlign: TextAlign.start,
                        ),
                        _buildTextField(_nomeController, 'Nome da Unidade'),
                        const SizedBox(height: 16),
                        
                        Text(
                          'Estado',
                          style: secondaryTextStyle,
                          textAlign: TextAlign.start,
                        ),
                        DropdownButtonFormField<String>(
                          dropdownColor: Colors.white,
                          style: const TextStyle(color: Color(0xFF37474F)),
                          decoration: buildInputDecoration('Estado'),
                          value: estadoSelecionado,
                          items:
                              estados.map<DropdownMenuItem<String>>((estado) {
                            return DropdownMenuItem<String>(
                              value: estado['sigla'],
                              child: Text(estado['nome']),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              estadoSelecionado = value;
                              cidadeSelecionada = null;
                              cidades = [];
                            });
                            if (value != null) {
                              _fetchCidades(value);
                            }
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Por favor, selecione um estado.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Cidade',
                          style: secondaryTextStyle,
                          textAlign: TextAlign.start,
                        ),
                        DropdownButtonFormField<String>(
                          dropdownColor: Colors.white,
                          style: const TextStyle(color: Color(0xFF37474F)),
                          decoration: buildInputDecoration('Cidade'),
                          value: cidadeSelecionada,
                          items:
                              cidades.map<DropdownMenuItem<String>>((cidade) {
                            return DropdownMenuItem<String>(
                              value: cidade['nome'],
                              child: Text(cidade['nome']),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              cidadeSelecionada = value;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Por favor, selecione uma cidade.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: customElevatedButton(
                            onPressed: _selecionarImagem,
                            icon: Icons.check,
                            iconColor: const Color.fromARGB(255, 6, 41, 70),
                            backgroundColor: backgroundButton,
                            labelStyle: buttonTextStyle,
                            label: "Inserir Logo",
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (kIsWeb && _imagemBase64 != null)
                          Image.memory(
                            base64Decode(_imagemBase64!),
                            width: 100,
                            height: 100,
                          )
                        else if (_imagem != null)
                          Image.file(
                            _imagem!,
                            width: 100,
                            height: 100,
                          ),
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

Widget _buildTextField(TextEditingController controller, String label) {
  return Column(
    children: [
      const SizedBox(height: 10),
      TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: bodyTextStyle,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
            borderSide: const BorderSide(color: Color(0xFF37474F)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
            borderSide:
                const BorderSide(color: Color.fromARGB(255, 216, 216, 216)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
            borderSide: const BorderSide(color: Color(0xFF37474F), width: 2),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Por favor, insira $label.';
          }
          return null;
        },
      ),
    ],
  );
}
