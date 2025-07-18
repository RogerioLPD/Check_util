import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class FooterSection extends StatelessWidget {
  const FooterSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 800) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: _buildCompanyInfo(context)),
                    const SizedBox(width: 40),
                    Expanded(child: _buildQuickLinks(context)),
                    const SizedBox(width: 40),
                    Expanded(child: _buildContact(context)),
                  ],
                );
              } else {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCompanyInfo(context),
                    const SizedBox(height: 40),
                    Wrap(
                      spacing: 40,
                      runSpacing: 40,
                      children: [
                        _buildQuickLinks(context),
                        _buildContact(context),
                      ],
                    ),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 40),
          Container(height: 1, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;
              return Wrap(
                runSpacing: 12,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    '© 2024 Check Util. Todos os direitos reservados. Desenvolvido por ComCode',
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: Colors.white.withOpacity(0.8),
                        ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.facebook, color: Colors.white),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.alternate_email, color: Colors.white),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.phone, color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ).animate().slideY(begin: 1, duration: 800.ms, delay: 600.ms).fadeIn();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.qr_code_scanner,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Check Util',
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
            ),
          ],
        ).animate().slideX(begin: -1, duration: 800.ms).fadeIn(),
        const SizedBox(height: 16),
        Text(
          'Solução completa para gestão de facilities com tecnologia QR Code. '
          'Simplifique seus processos e aumente a eficiência da sua equipe.',
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: Colors.white.withOpacity(0.9),
                height: 1.5,
              ),
        ).animate().slideX(begin: -1, duration: 800.ms, delay: 100.ms).fadeIn(),
      ],
    );
  }

  Widget _buildQuickLinks(BuildContext context) {
    final links = [
      'Recursos',
      'Preços',
      'Documentação',
      'Suporte',
      'Blog',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Links Rápidos',
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
        ).animate().slideY(begin: -1, duration: 800.ms, delay: 200.ms).fadeIn(),
        const SizedBox(height: 16),
        ...links.asMap().entries.map((entry) {
          final index = entry.key;
          final link = entry.value;
          final delay = (300 + index * 50).ms;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                foregroundColor: Colors.white.withOpacity(0.8),
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
              ),
              child: Text(link),
            ),
          ).animate().slideX(begin: -1, duration: 800.ms, delay: delay).fadeIn();
        }).toList(),
      ],
    );
  }

  Widget _buildContact(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contato',
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
        ).animate().slideY(begin: -1, duration: 800.ms, delay: 300.ms).fadeIn(),
        const SizedBox(height: 16),
        _buildContactItem(context, Icons.email, 'contato@checkutil.com', 400.ms),
        _buildContactItem(context, Icons.phone, '+55 (42) 99834-3340', 450.ms),
        _buildContactItem(context, Icons.location_on, 'Ponta Grossa, PR', 500.ms),
      ],
    );
  }

  Widget _buildContactItem(
      BuildContext context, IconData icon, String text, Duration delay) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.white.withOpacity(0.8),
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: Colors.white.withOpacity(0.8),
                ),
          ),
        ],
      ),
    ).animate().slideX(begin: -1, duration: 800.ms, delay: delay).fadeIn();
  }
}
