import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:screenshot/screenshot.dart';

class InvoiceView extends StatelessWidget {
  final Uint8List? logoBytes;
  final String nombreCliente;
  final String metodoPago;
  final String estadoPago;
  final DateTime fechaFactura;
  final Map<String, dynamic>? datosReparacion;
  final String reparacionRealizada;
  final double total;
  final ScreenshotController? screenshotController;
  final double height;

  const InvoiceView({
    super.key,
    this.logoBytes,
    required this.nombreCliente,
    required this.metodoPago,
    required this.estadoPago,
    required this.fechaFactura,
    this.datosReparacion,
    required this.reparacionRealizada,
    required this.total,
    this.screenshotController,
    this.height = 600,
  });

  String _formatConPuntos(double amount) {
    String str = amount.toStringAsFixed(0);
    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return str.replaceAllMapped(reg, (Match m) => '${m[1]}.');
  }

  String _formatFecha(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Widget _ticketRow(BuildContext context, String label, String value, {bool isLarge = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Theme.of(context).hintColor, fontSize: isLarge ? 16 : 13)),
        Text(value, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: isLarge ? 16 : 13)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final content = ColoredBox(
      color: isDark ? Colors.black : Colors.white,
      child: GlassmorphicContainer(
        width: double.infinity,
        height: height,
        borderRadius: 20,
        blur: 15,
        alignment: Alignment.topCenter,
        border: 1,
        linearGradient: LinearGradient(
          colors: isDark
              ? [const Color(0x14FFFFFF), const Color(0x08FFFFFF)]
              : [const Color.fromRGBO(0, 0, 0, 0.05), const Color.fromRGBO(0, 0, 0, 0.02)],
        ),
        borderGradient: const LinearGradient(
          colors: [Color(0x4D2196F3), Colors.transparent],
        ),
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (logoBytes != null) Padding(padding: const EdgeInsets.only(bottom: 20), child: Image.memory(logoBytes!, height: 80, fit: BoxFit.contain)),
              _ticketRow(context, 'Cliente:', nombreCliente, isLarge: true),
              _ticketRow(context, 'Método de pago:', metodoPago),
              _ticketRow(context, 'Estado de pago:', estadoPago),
              _ticketRow(context, 'Fecha:', _formatFecha(fechaFactura)),
              const SizedBox(height: 25),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: isDark ? const Color.fromRGBO(255, 255, 255, 0.05) : const Color.fromRGBO(0, 0, 0, 0.05),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('DETALLES DEL TRABAJO', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.1)),
                    Divider(color: isDark ? Colors.white10 : Colors.black12, height: 20),
                    Text('Modelo: ${datosReparacion?['equipo'] ?? '-'}', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 15)),
                    const SizedBox(height: 8),
                    Text('Falla: ${datosReparacion?['falla'] ?? '-'}', style: const TextStyle(color: Colors.red, fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Reparación: ${reparacionRealizada.isNotEmpty ? reparacionRealizada : '-'}', style: const TextStyle(color: Colors.green, fontSize: 15, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const Spacer(),
              Text('TOTAL A ABONAR', style: TextStyle(color: Theme.of(context).hintColor, fontSize: 14, letterSpacing: 1.2)),
              const SizedBox(height: 5),
              Text('\$${_formatConPuntos(total)}', style: TextStyle(fontFamily: 'WhiskeyGirlsCondensedItalic', color: Theme.of(context).colorScheme.onSurface, fontSize: 38)),
              const SizedBox(height: 20),
              Text('¡Gracias por confiar en el servicio técnico de Conección One!', textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12, fontStyle: FontStyle.italic)),
            ],
          ),
        ),
      ),
    );

    if (screenshotController != null) {
      return Screenshot(controller: screenshotController!, child: content);
    }

    return content;
  }
}
