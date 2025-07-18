



import 'package:checkutil/Componentes/colors.dart';
import 'package:checkutil/Componentes/tipografia.dart';
import 'package:checkutil/Mobile/Qrcodes/qrcode_equipmobile.dart';
import 'package:checkutil/Mobile/Qrcodes/qrcode_screen.dart';
import 'package:checkutil/Services/equipamentos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class HomeQrMobile extends StatelessWidget {
  final List<Widget> _screens = [
   
     QRCodeEquipamentoMobile(), 
     QRScannerScreen(),
  ];

  final List<String> titles = [
    
    "QrCodes Equipamentos",
    "Escanear QRcode",
  ];

  final List<IconData> icons = [
   
    Icons.qr_code_2,
    Icons.qr_code_scanner_outlined,
  ];

  HomeQrMobile({super.key});

  @override
  Widget build(BuildContext context) {
    print("Telas: ${_screens.length}"); // Deve imprimir 2
    var unidadeProvider = Provider.of<UnidadeProvider>(context);
    return Scaffold(
      backgroundColor: textPrimary,
      body: Padding(
        padding: const EdgeInsets.all(0),
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.zero, // Sem margens
              width: double.infinity, // Largura total
              height: 80.h, // Altura fixa
              decoration: BoxDecoration(
                color: backgroundAppBarMobile,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(
                        0.6), // Menos opacidade para suavizar a sombra
                    spreadRadius: 0,
                    blurRadius: 10, // Maior desfoque para uma sombra mais suave
                    offset: const Offset(
                        0, 8), // Deslocamento menor para uma sombra mais sutil
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'QR Codes',
                  style: mobiTextStyle.copyWith(
                      fontSize: 28.sp, ),
                ),
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  childAspectRatio: 1.2,
                ),
                itemCount: _screens.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => _screens[index]),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: backgroundAppBarMobile,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            icons[index],
                            color: textSecondary,
                            size: 30,
                          ),
                          Text(
                            titles[index],
                            style: mobileTextStyle.copyWith(
                                fontSize: 14.sp,
                                color: textSecondary,
                                fontWeight: FontWeight.w200),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

