import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:signature/signature.dart';
import 'package:checkutil/Mobile/Checklist/finalizado.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:checkutil/Services/agendamentos_provider.dart';

class ChecklistPlacaScreen extends StatefulWidget {
  final String placa;
  final String tipoVeiculo;
  final String unidade;

  const ChecklistPlacaScreen(
      {required this.placa,
      required this.unidade,
      required this.tipoVeiculo,
      super.key});

  @override
  State<ChecklistPlacaScreen> createState() => _ChecklistPlacaScreenState();
}

class _ChecklistPlacaScreenState extends State<ChecklistPlacaScreen> {
  bool showChecklist = false;
  bool showFinalizarButton = false;
  List<dynamic> checklistItems = [];
  List<Map<String, dynamic>> checklists = [];
  bool _isLoading = false;


  @override
  void initState() {
    super.initState();
    print('Placa recebida: ${widget.placa}');
    _loadChecklistItems(widget.placa);
  }

  Future<void> _loadChecklistItems(String placa) async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('Veiculos')
          .where('placa', isEqualTo: placa)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        var data = querySnapshot.docs.first.data() as Map<String, dynamic>;
        if (data.containsKey('checklist') && data['checklist'] is List) {
          List<dynamic> rawList = data['checklist'];

          setState(() {
            checklists = rawList
                .map((e) => {
                      'item': e.toString(),
                      'descricao': '',
                      'status': '',
                      'comment': '',
                      'imageUrl': '',
                    })
                .toList();
            showChecklist = true;
          });
          return;
        }
      }
      setState(() {
        checklists = [];
        showChecklist = false;
      });
    } catch (e) {
      print('Erro ao buscar checklist: $e');
      setState(() {
        checklists = [];
        showChecklist = false;
      });
    }
  }

  double getCompletionPercentage(List<Map<String, dynamic>> items) {
    if (items.isEmpty) return 0.0;
    int completed = items
        .where((item) =>
            item['status'] == 'conforme' ||
            item['status'] == 'naoConforme' ||
            item['status'] == 'inexistente')
        .length;
    return (completed / items.length) * 100;
  }

  bool allItemsCompleted(List<Map<String, dynamic>> items) {
    return items.every((item) =>
        item['status'] == 'conforme' ||
        item['status'] == 'naoConforme' ||
        item['status'] == 'inexistente');
  }

  Future<void> _finalizeChecklist(Uint8List? signatureData) async {
    final user = FirebaseAuth.instance.currentUser;

    if (checklists.isEmpty || user == null) return;

    setState(() {
      _isLoading = true; // ← Ativa o loading
    });

    String? assinaturaUrl;
    if (signatureData != null) {
      final ref = FirebaseStorage.instance
          .ref('assinaturas/${DateTime.now().millisecondsSinceEpoch}.png');
      await ref.putData(
          signatureData, SettableMetadata(contentType: 'image/png'));
      assinaturaUrl = await ref.getDownloadURL();
    }

    final firestore = FirebaseFirestore.instance;
    final checklistFinalizado = {
      'unidade': widget.unidade,
      'placa': widget.placa,
      'tipoVeiculo': widget.tipoVeiculo,
      'itens': checklists
          .map((item) => {
                'item': item['item'],
                'descricao': item['descricao'] ?? '',
                'status': item['status'] == 'naoConforme'
                    ? 'Não Conforme'
                    : item['status'],
                'comentario': item['comment'] ?? '',
                'imagem': item['imageUrl'] ?? '',
              })
          .toList(),
      'dataFinalizacao': Timestamp.now(),
      'usuario': {
        'nome': user.displayName ?? '',
        'email': user.email ?? '',
      },
      'assinaturaUrl': assinaturaUrl,
    };

    try {
      await firestore
          .collection('Veiculos_finalizados')
          .add(checklistFinalizado);

      setState(() {
        showChecklist = false;
        showFinalizarButton = false;
        _isLoading = false; // ← Desativa loading antes de navegar
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AnimatedScreen()),
      );
    } catch (e) {
      setState(() => _isLoading = false); // ← Desativa em caso de erro

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao finalizar checklist: $e')),
      );
    }
  }

  Future<void> _showSignaturePad() async {
    final SignatureController signatureController = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
    );

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Assinatura"),
          content: SizedBox(
            width: MediaQuery.of(context).size.width *
                0.9, // Define largura proporcional
            height: 300, // Altura fixa para o widget Signature
            child: Signature(
              controller: signatureController,
              backgroundColor: Colors.grey[200]!,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                signatureController.clear();
              },
              child: const Text("Limpar"),
            ),
            TextButton(
              onPressed: () async {
                if (signatureController.isNotEmpty) {
                  Navigator.of(context).pop(signatureController);
                }
              },
              child: const Text("Confirmar"),
            ),
          ],
        );
      },
    ).then((result) async {
      if (result is SignatureController) {
        final Uint8List? data = await result.toPngBytes();
        if (data != null) {
          await _finalizeChecklist(data);
        }
      }
    });
  }

  Future<void> _showCommentDialog(
      BuildContext context, Map<String, dynamic> item) async {
    TextEditingController commentController = TextEditingController();
    File? image;
    bool isLoading = false;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Comentários'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: commentController,
                    decoration: const InputDecoration(
                      labelText: 'Insira um comentário',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const Icon(Icons.camera_alt),
                      const SizedBox(width: 8),
                      TextButton(
                        child: const Text('Tirar Foto'),
                        onPressed: () async {
                          final pickedImage = await _pickImage();
                          if (pickedImage != null) {
                            setState(() {
                              image = pickedImage;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  if (image != null)
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      child: kIsWeb
                          ? Image.memory(image as Uint8List,
                              height: 150, fit: BoxFit.cover)
                          : Image.file(image as File,
                              height: 150, fit: BoxFit.cover),
                    ),
                  if (isLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: CircularProgressIndicator(),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text('Cancelar'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('Salvar'),
                  onPressed: () async {
                    setState(() {
                      isLoading = true;
                    });

                    String? imageUrl;
                    if (image != null) {
                      imageUrl = await _uploadImage(image!,
                          'checklist_image_${DateTime.now().millisecondsSinceEpoch}');
                    }

                    setState(() {
                      item['comment'] = commentController.text;
                      item['imageUrl'] = imageUrl;
                    });

                    await Future.delayed(const Duration(seconds: 2));
                    setState(() {
                      isLoading = false;
                    });
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<String?> _uploadImage(dynamic image, String imageName) async {
    try {
      final ref =
          FirebaseStorage.instance.ref('checklist_images/$imageName.jpg');

      if (kIsWeb) {
        // Web: usa Uint8List
        final metadata = SettableMetadata(contentType: 'image/jpeg');
        await ref.putData(image as Uint8List, metadata);
      } else {
        // Mobile: usa File
        await ref.putFile(image as File);
      }

      return await ref.getDownloadURL();
    } catch (e) {
      print('Erro ao fazer upload da imagem: $e');
      return null;
    }
  }

  Future<dynamic> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      if (kIsWeb) {
        return await pickedFile.readAsBytes(); // retorna Uint8List
      } else {
        return File(pickedFile.path); // retorna File
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    double progress = getCompletionPercentage(checklists);

    return Stack(
      children: [
        Scaffold(
        backgroundColor: const Color.fromARGB(255, 191, 233, 229),
        appBar: AppBar(
          title: Text(
            'Veículo placa: ${widget.placa}',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.teal,
          elevation: 0,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // 🔹 LinearProgressIndicator FORA da rolagem
              LinearProgressIndicator(
                value: progress / 100,
                backgroundColor: Colors.grey[300],
                color: Colors.green,
                minHeight: 8,
              ),
              const SizedBox(height: 16),
              Text(
                'Progresso: ${progress.toStringAsFixed(1)}%',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      if (checklists.isEmpty)
                        const Center(
                            child:
                                Text("Nenhum item encontrado para esta placa.")),
                      const SizedBox(height: 16),
                      if (showChecklist && checklists.isNotEmpty)
                        ListView.builder(
                          itemCount: checklists.length,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            final item = checklists[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8.0),
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15.0),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  children: [
                                    Align(
                                      alignment: Alignment.topLeft,
                                      child: Text(
                                        '${index + 1}/${checklists.length}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.teal,
                                        ),
                                      ),
                                    ),
                                    ListTile(
                                      title: Text(
                                        item['item'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                      subtitle: Text(item['descricao'] ?? ''),
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              item['status'] = 'conforme';
                                              showFinalizarButton = true;
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(8.0),
                                            decoration: BoxDecoration(
                                              color: item['status'] == 'conforme'
                                                  ? Colors.green
                                                  : Colors.grey[300],
                                              borderRadius:
                                                  BorderRadius.circular(10.0),
                                            ),
                                            child: const Text('Conforme'),
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              item['status'] = 'naoConforme';
                                              _showCommentDialog(context, item);
                                              showFinalizarButton = true;
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(8.0),
                                            decoration: BoxDecoration(
                                              color:
                                                  item['status'] == 'naoConforme'
                                                      ? Colors.red
                                                      : Colors.grey[300],
                                              borderRadius:
                                                  BorderRadius.circular(10.0),
                                            ),
                                            child: const Text('Não Conforme'),
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              item['status'] = 'inexistente';
                                              showFinalizarButton = true;
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(8.0),
                                            decoration: BoxDecoration(
                                              color:
                                                  item['status'] == 'inexistente'
                                                      ? Colors.grey
                                                      : Colors.grey[300],
                                              borderRadius:
                                                  BorderRadius.circular(10.0),
                                            ),
                                            child: const Text('Inexistente'),
                                          ),
                                        ),
                                      ],
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
              ),
            ],
          ),
        ),
        floatingActionButton: progress == 100.0
            ? FloatingActionButton.large(
                onPressed: () {
                  if (allItemsCompleted(checklists)) {
                    _showSignaturePad();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Finalize todos os itens do checklist.'),
                      ),
                    );
                  }
                },
                backgroundColor: Colors.teal,
                child: const Text(
                  'Finalizar',
                  style: TextStyle(color: Colors.white),
                ),
              )
            : null,
      ),
      if (_isLoading)
        Container(
          color: Colors.white,
          child: const Center(
            child: CircularProgressIndicator(color: Colors.teal),
          ),
        ),
      ],
    );
  }
}
