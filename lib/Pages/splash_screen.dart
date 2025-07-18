import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:checkutil/Mobile/Addmanutencao/add_manutencaomobile.dart';
import 'package:checkutil/Web/home_empresa.dart';
import 'package:checkutil/Login/login.dart';
import 'package:checkutil/home_page.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _zoomController;
  late Animation<double> _zoomAnimation;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  bool showText = false;

  @override
  void initState() {
    super.initState();

    // Animação de Zoom In (mais lenta e começa cobrindo a tela)
    _zoomController = AnimationController(
        vsync: this, duration: const Duration(seconds: 2, milliseconds: 500));
    _zoomAnimation = Tween<double>(begin: 5.0, end: 1.0).animate(
      CurvedAnimation(parent: _zoomController, curve: Curves.easeOut),
    );

    // Animação de Fade In para o texto (mais lenta)
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(seconds: 1, milliseconds: 500));
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    // Inicia animação de zoom
    Future.delayed(const Duration(milliseconds: 500), () {
      _zoomController.forward();
    });
  }

  @override
  void dispose() {
    _zoomController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal, // Fundo azul claro
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _zoomAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _zoomAnimation.value,
                  child: child,
                );
              },
              child: Lottie.asset(
                'assets/animations/checklist.json', // Substitua pelo nome correto do arquivo
                width: 300,
                height: 300,
                onLoaded: (composition) {
                  Future.delayed(composition.duration, () {
                    setState(() {
                      showText = true;
                    });

                    // Inicia animação do texto
                    _fadeController.forward();

                    // Redireciona para outra tela após um tempo
                    Future.delayed(const Duration(seconds: 4), () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const HomePage(),), // Substitua por sua tela de Login
                      );
                    });
                  });
                },
              ),
            ),
            if (showText)
              FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: AnimatedTextKit(
                    animatedTexts: [
                      WavyAnimatedText(
                        'CHECK UTIL',
                        textStyle: const TextStyle(
                          fontSize: 38, // Tamanho maior para destaque
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'TitanOne', // Fonte Titan One
                          letterSpacing:
                              2, // Dá um efeito mais espaçado e estilizado
                        ),
                      ),
                     
                    ],
                    isRepeatingAnimation: true,
                    onTap: () {
                      print("Tap Event");
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
