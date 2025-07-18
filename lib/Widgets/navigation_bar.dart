import 'package:checkutil/Login/login.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CustomNavigationBar extends StatefulWidget {
  final void Function(String section) onNavItemTap;

  const CustomNavigationBar({super.key, required this.onNavItemTap});

  @override
  State<CustomNavigationBar> createState() => _CustomNavigationBarState();
}

class _CustomNavigationBarState extends State<CustomNavigationBar> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 800;

    // Define o tamanho da logo com base na largura da tela
    final logoSize = screenWidth * 0.06; // 6% da largura da tela

    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo + título
          Row(
            children: [
              Image.asset(
                "assets/images/SUBMARCA.png",
                width: logoSize.clamp(40.0, 80.0),
                height: logoSize.clamp(40.0, 80.0),
                fit: BoxFit.contain,
              ).animate().slideX(begin: -1, duration: 600.ms).fadeIn(),
              const SizedBox(width: 16),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Check Util',
                    style: Theme.of(context).textTheme.titleLarge!.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  )
                      .animate()
                      .slideX(begin: -1, duration: 600.ms, delay: 100.ms)
                      .fadeIn(),
                  Text(
                    'Gestão de Facilities',
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: Colors.grey[600],
                        ),
                  )
                      .animate()
                      .slideX(begin: -1, duration: 600.ms, delay: 200.ms)
                      .fadeIn(),
                ],
              ),
            ],
          ),

          // Menu ou botão mobile
          if (isWide)
            Flexible(
              child: Wrap(
                spacing: 16,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _buildNavItem(context, 'Recursos',
                      () => widget.onNavItemTap('Recursos')),
                  _buildNavItem(context, 'Benefícios',
                      () => widget.onNavItemTap('Benefícios')),
                  _buildNavItem(
                      context, 'Contato', () => widget.onNavItemTap('Contato')),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const LoginPage(
                                  placa: '',
                                  unidade: '',
                                  tipoVeiculo: '',
                                )),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Começar Agora'),
                  )
                      .animate()
                      .slideX(begin: 1, duration: 600.ms, delay: 300.ms)
                      .fadeIn(),
                ],
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                // TODO: implementar menu mobile
              },
            ).animate().slideX(begin: 1, duration: 600.ms).fadeIn(),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, String title, VoidCallback onTap) {
    return TextButton(
      onPressed: onTap,
      child: Text(
        title,
        style: Theme.of(context).textTheme.bodyLarge!.copyWith(
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
      ),
    ).animate().slideY(begin: -1, duration: 600.ms, delay: 400.ms).fadeIn();
  }
}
