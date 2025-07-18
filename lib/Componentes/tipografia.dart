
import 'package:checkutil/Componentes/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

// Simple
TextStyle headlineTextStyle = GoogleFonts.montserrat(
  textStyle: const TextStyle(
    fontSize: 26,
    color: textPrimary,
    letterSpacing: 1.5,
    fontWeight: FontWeight.w500,
  ),
);

TextStyle headTextStyle = GoogleFonts.montserrat(
  textStyle: const TextStyle(
    fontSize: 26,
    color: textSecondary,
    letterSpacing: 1.5,
    fontWeight: FontWeight.w500,
  ),
);

TextStyle headlineSecondaryTextStyle = GoogleFonts.montserrat(
  textStyle: const TextStyle(
    fontSize: 20,
    color: textSecondary,
    fontWeight: FontWeight.w500,
  ),
);

TextStyle secondaryTextStyle = GoogleFonts.montserrat(
  textStyle: const TextStyle(
    fontSize: 14,
    color: textSecondary,
    fontWeight: FontWeight.w600,
  ),
);

TextStyle mobileTextStyle = GoogleFonts.poppins(
  textStyle: const TextStyle(
    fontSize: 14,
    color: textPrimary,
    fontWeight: FontWeight.w500,
  ),
);

TextStyle mobiTextStyle = GoogleFonts.poppins(
  textStyle: const TextStyle(
    fontSize: 14,
    color: textSecondary,
    fontWeight: FontWeight.w500,
  ),
);

TextStyle mobileCardTextStyle = GoogleFonts.poppins(
  textStyle: const TextStyle(
    fontSize: 14,
    color: textSecondary,
    fontWeight: FontWeight.w500,
  ),
);

TextStyle headlineWhiteTextStyle = GoogleFonts.montserrat(
  textStyle: const TextStyle(
    fontSize: 20,
    color: textPrimary,
    fontWeight: FontWeight.w500,
  ),
);

TextStyle cardTitleTextStyle = GoogleFonts.montserrat(
  textStyle: const TextStyle(
    fontSize: 18,
    color: textSecondary,
    fontWeight: FontWeight.w500,
  ),
);

TextStyle cardBodyTextStyle = GoogleFonts.montserrat(
  textStyle: const TextStyle(
    fontSize: 18,
    color: textSecondary,
    fontWeight: FontWeight.normal,
  ),
);

TextStyle subtitleTextStyle = GoogleFonts.openSans(
  textStyle: const TextStyle(
    fontSize: 14,
    color: textSecondary,
    letterSpacing: 1,
  ),
);

TextStyle titleDrawerTextStyle = GoogleFonts.montserrat(
  textStyle: const TextStyle(
    fontSize: 16,
    color: textSecondary,
    fontWeight: FontWeight.w500,
  ),
);

TextStyle backgroundTextStyle = GoogleFonts.montserrat(
  textStyle: const TextStyle(
    fontSize: 16,
    color: backgroundColor,
    fontWeight: FontWeight.w500,
  ),
);

TextStyle drawerTextStyle = GoogleFonts.montserrat(
  textStyle: const TextStyle(
    fontSize: 16,
    color: textPrimary,
    fontWeight: FontWeight.w500,
  ),
);

TextStyle bodyTextStyle = GoogleFonts.openSans(
  textStyle: const TextStyle(fontSize: 14, color: textSecondary),
);

TextStyle formBodyTextStyle = GoogleFonts.openSans(
  textStyle: const TextStyle(
    fontSize: 14,
    color: textSecondary,
    fontWeight: FontWeight.bold,
  ),
);

TextStyle bodyDrawerTextStyle = GoogleFonts.openSans(
  textStyle: const TextStyle(fontSize: 14, color: textPrimary),
);

TextStyle drawerStyle = GoogleFonts.openSans(
  textStyle: const TextStyle(fontSize: 12, color: textPrimary),
);

TextStyle nameDrawerTextStyle = GoogleFonts.openSans(
  textStyle: const TextStyle(fontSize: 17, color: textPrimary),
);

TextStyle buttonTextStyle = GoogleFonts.montserrat(
  textStyle: const TextStyle(
    fontSize: 14,
    color: textSecondary,
    fontWeight: FontWeight.w600,
  ),
);

TextStyle buttonMobileTextStyle = GoogleFonts.poppins(
  textStyle: const TextStyle(
    fontSize: 14,
    color: backgroundAppBarMobile,
    fontWeight: FontWeight.w500,
  ),
);

TextStyle buttonLoginStyle = GoogleFonts.montserrat(
  textStyle: const TextStyle(
    fontSize: 14,
    color: textSecondary,
    fontWeight: FontWeight.w600,
  ),
);

TextStyle simpleText = const TextStyle(color: Colors.white, fontSize: 18);
TextStyle simpleTextM = const TextStyle(color: textSecondary, fontSize: 18);

TextStyle simpleSubText = const TextStyle(color: Colors.white, fontSize: 12);
TextStyle simpleSubTextM = const TextStyle(color: textSecondary, fontSize: 12);

TextStyle simpleTitleText = const TextStyle(color: Colors.white, fontSize: 14);
TextStyle simpleTitleTextM = const TextStyle(color: textSecondary, fontSize: 14);
// Advanced
// TODO: Add additional text styles.
InputDecoration buildInputDecoration(
  String labelText, {
  Widget? prefixIcon,
  Color prefixIconColor = textSecondary,
  TextEditingController? controller, // Cor padrão do ícone
}) {
  return InputDecoration(
    labelText: labelText,
    labelStyle: bodyTextStyle,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(5),
      borderSide: const BorderSide(color: Color.fromARGB(255, 216, 216, 216)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(5),
      borderSide: const BorderSide(color: Color.fromARGB(255, 216, 216, 216)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(5),
      borderSide: const BorderSide(color: textSecondary, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    prefixIcon:
        prefixIcon != null
            ? Icon(
              (prefixIcon as Icon).icon,
              color: prefixIconColor, // Definindo a cor do ícone
            )
            : null, // Se não passar um ícone, não exibe nada
  );
}

Widget customCard({
  required Widget child,
  double elevation = 5,
  Color borderColor = const Color(0xFFECEFF1),
  Color shadowColor = const Color.fromARGB(255, 15, 15, 15),
  double borderRadius = 10,
  double borderWidth = 2,
}) {
  return Card(
    color: const Color(0xFFECEFF1),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      side: BorderSide(color: borderColor, width: borderWidth),
    ),
    elevation: elevation,
    shadowColor: shadowColor.withOpacity(0.5),
    child: Padding(padding: const EdgeInsets.all(20), child: child),
  );
}

Widget customCardMobile({
  required Widget child,
  double elevation = 5,
  Color borderColor = Colors.white,
  Color shadowColor = const Color.fromARGB(255, 15, 15, 15),
  double borderRadius = 10,
  double borderWidth = 2,
}) {
  return Card(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      side: BorderSide(color: borderColor, width: borderWidth),
    ),
    elevation: elevation,
    shadowColor: shadowColor.withOpacity(0.5),
    child: Padding(padding: const EdgeInsets.all(20), child: child),
  );
}

Widget customCardF({
  required Widget child,
  Color borderColor = const Color.fromARGB(255, 216, 216, 216),
  double borderRadius = 0,
  double borderWidth = 1,
}) {
  return Card(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      side: BorderSide(color: borderColor, width: borderWidth),
    ),
    elevation: 0,
    shadowColor: Colors.transparent,
    child: Padding(padding: const EdgeInsets.all(30), child: child),
  );
}

Widget customCardForm({
  required Widget child,
  double elevation = 5,
  Color borderColor = textSecondary,
  Color shadowColor = const Color.fromARGB(255, 15, 15, 15),
  double borderRadius = 2,
  double borderWidth = 1,
}) {
  return Card(
    color: Colors.white,
    /*shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      side: BorderSide(
        color: borderColor,
        width: borderWidth,
      ),
    ),*/
    elevation: elevation,
    shadowColor: shadowColor.withOpacity(0.5),
    child: Padding(padding: const EdgeInsets.all(20), child: child),
  );
}

Widget customElevatedButton({
  required VoidCallback onPressed,
  required String label,
  required TextStyle labelStyle,
  required IconData icon,
  required Color iconColor,
  Color backgroundColor = Colors.orange,
  double borderRadius = 12,
  double elevation = 5,
  double? width, // Largura opcional
  double? height, // Altura opcional
  EdgeInsetsGeometry padding = const EdgeInsets.symmetric(
    vertical: 16,
    horizontal: 30,
  ),
}) {
  return ElevatedButton.icon(
    onPressed: onPressed,
    icon: Icon(icon, color: iconColor),
    label: Text(label, style: buttonTextStyle),
    style: ElevatedButton.styleFrom(
      backgroundColor: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      padding: padding,
      elevation: elevation,
    ),
  );
}

Widget customMobileElevatedButton({
  required VoidCallback onPressed,
  required String label,
  required TextStyle labelStyle,
  required IconData icon,
  required Color iconColor,
  double borderRadius = 10, // Alterado para 16 conforme o design
  double elevation = 4, // Sem sombra como no design
  double? width,
  double? height = 56, // Altura padrão conforme o design
  EdgeInsetsGeometry padding = const EdgeInsets.symmetric(
    vertical: 16,
    horizontal: 30,
  ),
}) {
  return Container(
    width: double.infinity,
    height: 56.h,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      color: backgroundButton,
    ),
    child: ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: iconColor),
      label: Text(
        label,
        style: labelStyle.copyWith(color: textPrimary), // Texto branco
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor:
            Colors.transparent, // Transparente para o gradient funcionar
        shadowColor: Colors.black.withOpacity(0.5), // Sem sombra
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        padding: padding,
        elevation: elevation,
      ),
    ),
  );
}

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: bodyTextStyle,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: textSecondary),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: textSecondary),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: textSecondary, width: 2),
            ),
          ),
          validator:
              validator ??
              (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, insira $label.';
                }
                return null;
              },
        ),
      ],
    );
  }
}
