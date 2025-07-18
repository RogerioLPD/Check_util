import 'dart:convert';
import 'dart:io';
import 'package:checkutil/Componentes/colors.dart';
import 'package:checkutil/Login/login.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class PerfilUser extends StatefulWidget {
  const PerfilUser({super.key});

  @override
  _PerfilUserState createState() => _PerfilUserState();
}

class _PerfilUserState extends State<PerfilUser> {
  final User? _user = FirebaseAuth.instance.currentUser;
  final ImagePicker _picker = ImagePicker();
  File? _imagem;
  String? _imagemBase64;

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage(placa: '', unidade: '', tipoVeiculo: '',)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao fazer logout: $e')),
      );
    }
  }

  Future<void> _selecionarImagem() async {
    final XFile? imagemSelecionada =
        await _picker.pickImage(source: ImageSource.camera);
    if (imagemSelecionada != null) {
      try {
        if (kIsWeb) {
          final bytes = await imagemSelecionada.readAsBytes();
          setState(() {
            _imagemBase64 = base64Encode(bytes);
            _imagem = null;
          });
          final url = await _uploadImageWeb(imagemSelecionada);
          if (url != null) {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(_user!.uid)
                .update({'logoUrl': url});
            setState(() {
              _user!.updatePhotoURL(url);
            });
            _showMessage('Imagem atualizada com sucesso!');
          }
        } else {
          setState(() {
            _imagem = File(imagemSelecionada.path);
            _imagemBase64 = null;
          });
          final url = await _uploadImage(_imagem!);
          if (url != null) {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(_user!.uid)
                .update({'logoUrl': url});
            setState(() {
              _user!.updatePhotoURL(url);
            });
            _showMessage('Imagem atualizada com sucesso!');
          }
        }
      } catch (e) {
        _showMessage('Erro ao selecionar imagem: $e');
      }
    }
  }

  Future<String?> _uploadImage(File image) async {
    try {
      String imageName = DateTime.now().millisecondsSinceEpoch.toString();
      final ref =
          FirebaseStorage.instance.ref().child('logos_usuarios/$imageName');
      final upload = await ref.putFile(image);
      return await upload.ref.getDownloadURL();
    } catch (_) {
      return null;
    }
  }

  Future<String?> _uploadImageWeb(XFile imagem) async {
    try {
      String imageName = DateTime.now().millisecondsSinceEpoch.toString();
      final ref =
          FirebaseStorage.instance.ref().child('logos_usuarios/$imageName');
      final upload = await ref.putData(await imagem.readAsBytes());
      return await upload.ref.getDownloadURL();
    } catch (_) {
      return null;
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final alturaTela = MediaQuery.of(context).size.height;
    return Scaffold(
      body: Stack(
        children: [
          // Imagem de capa
          Container(
            height: alturaTela * 0.4,
            width: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: _user?.photoURL != null
                    ? NetworkImage(_user!.photoURL!)
                    : const AssetImage('assets/images/default_cover.jpg')
                        as ImageProvider,
                fit: BoxFit.cover,
              ),
            ),
          ),
          
          // Conteúdo
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                SizedBox(height: alturaTela * 0.32), // Espaço da imagem de capa
                _buildProfileCard(context),
                const SizedBox(height: 24),
                _buildLogoutButton(),
              ],
            ),
          ),
          Positioned(
            top: 40,
            left: 16,
            child: CircleAvatar(
              backgroundColor: Colors.black54,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: _user?.photoURL != null
                    ? NetworkImage(_user!.photoURL!)
                    : null,
                backgroundColor: const Color.fromARGB(255, 6, 41, 70),
                child: _user?.photoURL == null
                    ? const Icon(Icons.person, color: Colors.white, size: 50)
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: InkWell(
                  onTap: _selecionarImagem,
                  child: const CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.edit,
                        color: Color.fromARGB(255, 6, 41, 70), size: 18),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _user?.displayName ?? "Usuário",
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _user?.email ?? "Email não disponível",
            style: const TextStyle(color: Colors.black54, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return ElevatedButton.icon(
      onPressed: _logout,
      icon: const Icon(Icons.logout, color: Colors.white),
      label: const Text(
        "Sair",
        style: TextStyle(color: Colors.white, fontSize: 16),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
