import 'package:checkutil/Login/login.dart';
import 'package:checkutil/Mobile/User/home_user.dart';
import 'package:checkutil/Web/Veiculos/auditor_veiculos.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

class AnimatedScreen extends StatefulWidget {
  const AnimatedScreen({super.key});

  @override
  _AnimatedScreenState createState() => _AnimatedScreenState();
}

class _AnimatedScreenState extends State<AnimatedScreen> {
  bool hasNavigated =
      false; // Adicionando uma variável para controlar a navegação

  @override
  Widget build(BuildContext context) {
    // Obtém a altura e a largura da tela
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.teal,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          SizedBox(
              height: screenHeight * 0.1), // Espaçamento no topo responsivo
          SizedBox(
            height: screenHeight * 0.4, // Altura da animação responsiva
            width: screenWidth * 0.8, // Largura da animação ajustada
            child: Center(
              child: Lottie.asset(
                'assets/animations/HandUp.json', // Caminho para o arquivo Lottie
                fit: BoxFit
                    .contain, // Ajusta o Lottie para conter a animação dentro da área
              ),
            ),
          ),
          SizedBox(
              height: screenHeight *
                  0.05), // Espaçamento entre a animação e o texto
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
            child: Column(
              children: [
                Center(
                  child: AnimatedTextKit(
                    animatedTexts: [
                      ColorizeAnimatedText(
                        'Parabéns!!!',
                        textStyle: TextStyle(
                          fontSize: screenHeight *
                              0.04, // Tamanho da fonte responsivo
                          fontWeight: FontWeight.bold,
                        ),
                        colors: [
                          Colors.white,
                          Colors.yellow,
                          Colors.red,
                          Colors.blue,
                        ],
                        speed: const Duration(milliseconds: 500),
                      ),
                    ],
                    isRepeatingAnimation: false,
                    onFinished: () => _navigateToHome(),
                  ),
                ),
                Center(
                  child: AnimatedTextKit(
                    animatedTexts: [
                      ColorizeAnimatedText(
                        'Inspeção concluída',
                        textStyle: TextStyle(
                          fontSize: screenHeight *
                              0.035, // Tamanho da fonte responsivo
                          fontWeight: FontWeight.bold,
                        ),
                        colors: [
                          Colors.white,
                          Colors.yellow,
                          Colors.red,
                          Colors.blue,
                        ],
                        speed: const Duration(milliseconds: 500),
                      ),
                    ],
                    isRepeatingAnimation: false,
                    onFinished: () => _navigateToHome(),
                  ),
                ),
                Center(
                  child: AnimatedTextKit(
                    animatedTexts: [
                      ColorizeAnimatedText(
                        'com sucesso!',
                        textStyle: TextStyle(
                          fontSize: screenHeight *
                              0.035, // Tamanho da fonte responsivo
                          fontWeight: FontWeight.bold,
                        ),
                        colors: [
                          Colors.white,
                          Colors.yellow,
                          Colors.red,
                          Colors.blue,
                        ],
                        speed: const Duration(milliseconds: 500),
                      ),
                    ],
                    isRepeatingAnimation: false,
                    onFinished: () => _navigateToHome(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

 void _navigateToHome() {
  if (!hasNavigated) {
    hasNavigated = true;

    if (kIsWeb) {
      // Navegar para a tela web
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AuditorVeiculosPage(),
        ),
      );
    } else {
      // Navegar para a tela mobile
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MobileHomeScreen(key: UniqueKey()),
        ),
      );
    }
  }
}

}
