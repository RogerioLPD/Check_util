import 'package:checkutil/Admin/home_admin.dart';
import 'package:checkutil/Componentes/theme.dart';
import 'package:checkutil/Mobile/Checklist/checklist_itens.dart';
import 'package:checkutil/Mobile/Qrcodes/home_qr.dart';
import 'package:checkutil/Login/login.dart';
import 'package:checkutil/Mobile/home_cadmob.dart';
import 'package:checkutil/Pages/splash_screen.dart';
import 'package:checkutil/Services/agendamentos_provider.dart';
import 'package:checkutil/Services/equipamentos.dart';
import 'package:checkutil/Services/lista_equiprovider.dart';
import 'package:checkutil/Services/local_provider.dart';
import 'package:checkutil/Services/naoconforme_provider.dart';
import 'package:checkutil/Services/naoconforme_veiculos.dart';
import 'package:checkutil/Services/ocorrencia_estado.dart';
import 'package:checkutil/Services/relatorios_veiculos_provider.dart';
import 'package:checkutil/Services/routes.dart';
import 'package:checkutil/Services/veiculo_finalizado_provider.dart';
import 'package:checkutil/Services/veiculos_provider.dart';
import 'package:checkutil/Services/venda_estado.dart';
import 'package:checkutil/Web/Veiculos/auditor_veiculos.dart';
import 'package:checkutil/Web/Veiculos/checklist_veiculos.dart';
import 'package:checkutil/Web/auditor_page.dart';
import 'package:checkutil/firebase_options.dart';
import 'package:checkutil/home_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializando o Firebase com as opções corretas para Web/Android/iOS
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => VendaState()),
        ChangeNotifierProvider(create: (_) => UnidadeProvider()),
        ChangeNotifierProvider(create: (_) => OcorrenciaEstado()),
        ChangeNotifierProvider(create: (context) => LocalProvider()),
        ChangeNotifierProvider(create: (_) => AgendamentosProvider()),
        ChangeNotifierProvider(create: (_) => EquipamentoProvider()),
        ChangeNotifierProvider(create: (_) => VeiculoProvider()),
        ChangeNotifierProvider(create: (_) => RelatoriosVeiculosProvider()),
        ChangeNotifierProvider(
            create: (_) => VeiculoFinalizadoProvider()..carregarVeiculos()),
        ChangeNotifierProvider(
          create: (_) => ItensNaoConformesVeiculos(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 820), // Tamanho base para dimensionamento
      minTextAdapt: true, // Ajusta automaticamente os textos
      builder: (context, child) {
        final bool isSmallScreen = MediaQuery.of(context).size.width < 600;
        return MaterialApp(
          title: 'Flutter Demo',
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: ThemeMode.system,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('pt', 'BR'), // Português do Brasil
            Locale('en', 'US'), // Inglês (opcional)
            // Adicione outros idiomas se necessário
          ],
          home: kIsWeb && !isSmallScreen
              ? const HomePage()
              : SplashScreen(),
          onGenerateRoute: (RouteSettings settings) {
            return Routes.fadeThrough(settings, (context) {
              final uri = Uri.parse(
                  settings.name ?? ''); // Parse da URL para capturar parâmetros

              switch (uri.path) {
                case Routes.login:
                  return const LoginPage(
                    placa: '',
                    unidade: '',
                    tipoVeiculo: '',
                  );
                case Routes.cadastroAdmin:
                  return const AdminPage();
                case Routes.empresaMobile:
                  return const HomeEmpresaMobileScreen();
                case Routes.splashscreen:
                  return SplashScreen();
                case Routes.auditorPage:
                  return AuditorPage(
                    tag: '',
                  );
                case Routes.auditorVeiculos:
                  return AuditorVeiculosPage(
                    placa: '',
                  );
                case Routes.checklistVeiculos:
                  return const ChecklistPlacaScreen(
                    placa: '',
                    unidade: '',
                    tipoVeiculo: '',
                  );
                case Routes.checklist:
                  return const ChecklistTagScreen(
                    tag: '',
                    agendamentoId: '',
                    unidade: '',
                  );
                case Routes.homeQr:
                  return const HomeQRScreen(
                    tag: '',
                    unidade: '',
                  );

                default:
                  return const SizedBox.shrink();
              }
            });
          },
          debugShowCheckedModeBanner: false, // Removendo a faixa de debug
        );
      },
    );
  }
}
