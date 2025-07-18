import 'package:animations/animations.dart';
import 'package:flutter/widgets.dart';

class Routes {
  static const String home = "/";
  static const String cadastroAdmin = "cadastro_admin";
  static const String homepage = "homepage";
  static const String cadastroCliente = "cadastro_cliente";
  static const String homeAdmin = "home_admin";
  static const String addEquipamento = "add_equipamento";
  static const String addLocal = "add_local";
  static const String login = "login";
  static const String addPlano = "add_plano";
  static const String addUnidades = "add_unidades";
  static const String homeClientes = "home_clientes";
  static const String splashscreen = "splashscreen";
  static const String perguntaScreen = "perguntascreen";
  static const String addManutencao = "addmanutencao";
  static const String qrdisplay = "qrdisplay";
  static const String qrLocal = "qrLocal";
  static const String registerLocal = "registerlocal";
  static const String planoEquipamento = "planoequipamento";
  static const String addEmpresa = "addempresa";
  static const String perfil = "perfil";
  static const String addTask = "addtask";
  static const String addServices = "addservices";
  static const String homeQr = "homeqr";
  static const String homeWeb = "homeweb";
  static const String checklist = "checklist";
  static const String checklistVeiculos = "checklistveiculos";
  static const String auditorPage = "auditor";
  static const String auditorVeiculos = "veiculos";
  static const String empresaMobile = "empresamobile";

  static Route<T> fadeThrough<T>(RouteSettings settings, WidgetBuilder page,
      {int duration = 300}) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: Duration(milliseconds: duration),
      pageBuilder: (context, animation, secondaryAnimation) => page(context),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeScaleTransition(animation: animation, child: child);
      },
    );
  }
}
