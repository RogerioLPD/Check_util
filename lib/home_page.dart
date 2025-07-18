import 'package:checkutil/Widgets/navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:checkutil/widgets/hero_section.dart';
import 'package:checkutil/widgets/features_section.dart';
import 'package:checkutil/widgets/benefits_section.dart';
import 'package:checkutil/widgets/cta_section.dart';
import 'package:checkutil/widgets/footer_section.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey heroKey = GlobalKey();
  final GlobalKey featuresKey = GlobalKey();
  final GlobalKey benefitsKey = GlobalKey();
  final GlobalKey ctaKey = GlobalKey();
  final GlobalKey footerKey = GlobalKey();

  bool _showScrollToTop = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.offset > 500) {
        if (!_showScrollToTop) setState(() => _showScrollToTop = true);
      } else {
        if (_showScrollToTop) setState(() => _showScrollToTop = false);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToPosition(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                CustomNavigationBar(
                  onNavItemTap: (section) {
                    switch (section) {
                      case 'Recursos':
                        _scrollToPosition(featuresKey);
                        break;
                      case 'Benefícios':
                        _scrollToPosition(benefitsKey);
                        break;
                      case 'Contato':
                        _scrollToPosition(footerKey);
                        break;
                      case 'Começar':
                        _scrollToTop();
                        break;
                      default:
                        break;
                    }
                  },
                ),
                HeroSection(key: heroKey),
                FeaturesSection(key: featuresKey),
                BenefitsSection(key: benefitsKey),
                CTASection(key: ctaKey),
                FooterSection(key: footerKey),
              ],
            ),
          ),
          if (_showScrollToTop)
            Positioned(
              right: 20,
              bottom: 20,
              child: FloatingActionButton(
                onPressed: _scrollToTop,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: const Icon(Icons.keyboard_arrow_up, color: Colors.white),
              ).animate().fadeIn().scale(),
            ),
        ],
      ),
    );
  }
}
