import 'package:flutter/material.dart';

class Footer extends StatelessWidget {
  const Footer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0B0D1B),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10), // Altura reduzida
      child: const Column(
        children: [
          Text(
            "© 2024 Conforbras Tech ",
            style: TextStyle(fontSize: 12, color: Colors.grey), // Fonte menor
          ),
          SizedBox(height: 5), // Espaçamento reduzido
          Text(
            "Seu parceiro em inovação tecnológica.",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
