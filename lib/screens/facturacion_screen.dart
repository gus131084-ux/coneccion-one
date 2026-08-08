import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:share_plus/share_plus.dart';

class FacturacionScreen extends StatefulWidget {
  const FacturacionScreen({super.key});

  @override
  State<FacturacionScreen> createState() => _FacturacionScreenState();
}

class _FacturacionScreenState extends State<FacturacionScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();

  final TextEditingController _costoEnvioCtrl =
      TextEditingController(text: "0");

  final TextEditingController _costoRepuestoCtrl =
      TextEditingController(text: "0");

  final TextEditingController _manoObraCtrl = TextEditingController(text: "0");

  final TextEditingController _montoEntregaCtrl =
      TextEditingController(text: "0");
  final TextEditingController _reparacionRealizadaCtrl = TextEditingController();
  final TextEditingController _fechaFacturaCtrl = TextEditingController();

  DateTime _fechaFactura = DateTime.now();
  String _nombreClienteDisplay = "No seleccionado";
  String _estadoPago = "Pagado";
  String _metodoPago = "Efectivo";
  int _numeroFactura = 0;

  final List<String> _estadosPago = [
    'Pagado',
    'Entrega',
  ];

  final List<String> _metodosPago = [
    'Efectivo',
    'Transferencia',
    'Tarjeta',
    'Mercado Pago',
    'Otro',
  ];

  String? _clienteSeleccionadoId;

  Map<String, dynamic>? _datosReparacion;

  Uint8List? logoBytes;

  @override
  void initState() {
    super.initState();

    _costoEnvioCtrl.addListener(() => setState(() {}));
    _costoRepuestoCtrl.addListener(() => setState(() {}));
    _manoObraCtrl.addListener(() => setState(() {}));
    _montoEntregaCtrl.addListener(() => setState(() {}));
    _reparacionRealizadaCtrl.addListener(() => setState(() {}));

    _fechaFacturaCtrl.text = _formatFecha(_fechaFactura);
    cargarLogo();
    _cargarSiguienteNumeroFactura();
  }

  Future<void> _cargarSiguienteNumeroFactura() async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('facturas')
          .orderBy('numeroFactura', descending: true)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final data = query.docs.first.data();
        if (data['numeroFactura'] != null) {
          setState(() {
            _numeroFactura = (data['numeroFactura'] as num).toInt() + 1;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('Error al cargar número de factura: $e');
    }

    setState(() {
      _numeroFactura = 1;
    });
  }

  Future<void> cargarLogo() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('configuracion')
          .doc('general')
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['logoBase64'] != null &&
            data['logoBase64'].toString().isNotEmpty) {
          setState(() {
            logoBytes = base64Decode(data['logoBase64']);
          });
        } else {
          setState(() {
            logoBytes = null;
          });
        }
      }
    } catch (e) {
      debugPrint("Error cargando logo: $e");
    }
  }

  double get _totalCalculado {
    return double.tryParse(_manoObraCtrl.text) ?? 0;
  }

  double get _saldoRestante {
    double entrega = double.tryParse(_montoEntregaCtrl.text) ?? 0;
    return _totalCalculado - entrega;
  }

  String _formatConPuntos(double amount) {
    String str = amount.toStringAsFixed(0);
    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return str.replaceAllMapped(reg, (Match m) => '${m[1]}.');
  }

  String _formatFecha(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _seleccionarFechaFactura() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaFactura,
      firstDate: DateTime(2000),
      lastDate: DateTime(DateTime.now().year + 5),
      locale: const Locale('es', 'ES'),
    );

    if (picked != null) {
      setState(() {
        _fechaFactura = picked;
        _fechaFacturaCtrl.text = _formatFecha(_fechaFactura);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 1200;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(isLargeScreen ? 30.0 : 20.0),
          child: isLargeScreen
              ? Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: _buildFormulario(),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 1,
                      child: _buildPreviewTicket(),
                    ),
                  ],
                )
              : Column(
                  children: [
                    _buildFormulario(),
                    const SizedBox(height: 30),
                    _buildPreviewTicket(),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildFormulario() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Facturación",
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Factura Nº ${_numeroFactura > 0 ? _numeroFactura.toString().padLeft(6, '0') : '-'}",
            style: TextStyle(
              color: Theme.of(context).hintColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 15),
          _label("Fecha de factura"),
          TextField(
            controller: _fechaFacturaCtrl,
            readOnly: true,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
            ),
            decoration: _inputDeco("Seleccionar fecha"),
            onTap: _seleccionarFechaFactura,
          ),
          const SizedBox(height: 20),
          _label("Cliente"),
          StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance.collection('clientes').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const LinearProgressIndicator();
              }

              return DropdownButtonFormField<String>(
                dropdownColor: Theme.of(context).canvasColor,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                decoration: _inputDeco(
                  "Seleccionar cliente",
                ),
                onChanged: (val) {
                  var doc = snapshot.data!.docs.firstWhere((d) => d.id == val);
                  final data = doc.data() as Map<String, dynamic>;

                  setState(() {
                    _clienteSeleccionadoId = val;

                    _nombreClienteDisplay = data['nombre'] ?? 'Sin nombre';
                  });
                },
                items: snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return DropdownMenuItem(
                    value: doc.id,
                    child: Text(data['nombre'] ?? 'Sin nombre'),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 20),
          _label("Reparación Vinculada"),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('reparaciones')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const LinearProgressIndicator();
              }

              return DropdownButtonFormField<String>(
                dropdownColor: Theme.of(context).canvasColor,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                decoration: _inputDeco(
                  "Seleccionar equipo",
                ),
                onChanged: (val) {
                  var doc = snapshot.data!.docs.firstWhere((d) => d.id == val);
                  final data = doc.data() as Map<String, dynamic>;
                  setState(() {
                    _datosReparacion = data;
                    // Si la reparación ya tiene una solución cargada en su ficha, 
                    // la pre-llenamos en el cuadro de texto.
                    if (data['reparacion'] != null) {
                      _reparacionRealizadaCtrl.text = data['reparacion'].toString();
                    }
                  });
                },
                items: snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return DropdownMenuItem(
                    value: doc.id,
                    child: Text(
                      "${data['equipo'] ?? 'Sin equipo'} - ${data['falla'] ?? 'Sin falla'}",
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 20),
          _label("Solución / Reparación Realizada"),
          TextField(
            controller: _reparacionRealizadaCtrl,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            decoration: _inputDeco("Ej: Se cambió el pin de carga"),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label("Presupuesto Total"),
                    _campoPrecio(_manoObraCtrl),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label("Repuesto"),
                    _campoPrecio(_costoRepuestoCtrl),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _label("Envío (Uso interno)"),
          _campoPrecio(_costoEnvioCtrl),
          const SizedBox(height: 20),
          _label("Estado de pago"),
          DropdownButtonFormField<String>(
            dropdownColor: Theme.of(context).canvasColor,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
            ),
            decoration: _inputDeco("Seleccionar estado"),
            initialValue: _estadoPago,
            onChanged: (val) {
              if (val == null) return;
              setState(() {
                _estadoPago = val;
              });
            },
            items: _estadosPago.map((estado) {
              return DropdownMenuItem(
                value: estado,
                child: Text(estado),
              );
            }).toList(),
          ),
          if (_estadoPago == 'Entrega') ...[
            const SizedBox(height: 20),
            _label('Monto de entrega (A cuenta)'),
            _campoPrecio(_montoEntregaCtrl),
            const SizedBox(height: 10),
            Text(
              "Saldo restante: \$${_saldoRestante.toStringAsFixed(2)}",
              style: const TextStyle(
                color: Colors.orangeAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
          const SizedBox(height: 20),
          _label('Método de pago'),
          DropdownButtonFormField<String>(
            dropdownColor: Theme.of(context).canvasColor,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
            ),
            decoration: _inputDeco("Seleccionar método de pago"),
            initialValue: _metodoPago,
            onChanged: (val) {
              if (val == null) return;
              setState(() {
                _metodoPago = val;
              });
            },
            items: _metodosPago.map((metodo) {
              return DropdownMenuItem(
                value: metodo,
                child: Text(metodo),
              );
            }).toList(),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _guardarFactura,
              icon: const Icon(
                Icons.check_circle_outline,
              ),
              label: const Text(
                "GUARDAR FACTURA",
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
              ),
            ),
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _enviarWhatsAppDirecto,
              icon: const Icon(
                Icons.send_to_mobile,
              ),
              label: const Text(
                "ENVIAR TICKET (BYPASS)",
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _campoPrecio(TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
      ),
      decoration: _inputDeco("\$"),
      onTap: () {
        if (controller.text == "0") {
          controller.clear();
        }
      },
    );
  }

  Widget _buildPreviewTicket() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Screenshot(
      controller: _screenshotController,
      child: ColoredBox(
        // Forzar fondo sólido para capturas correctas
        color: isDark ? Colors.black : Colors.white,
        child: GlassmorphicContainer(
          width: double.infinity,
          height: 600,
          borderRadius: 20,
          blur: 15,
          alignment: Alignment.topCenter,
          border: 1,
          linearGradient: LinearGradient(
            colors: isDark 
                ? [const Color(0x14FFFFFF), const Color(0x08FFFFFF)]
                : [Colors.black.withOpacity(0.05), Colors.black.withOpacity(0.02)],
          ),
          borderGradient: const LinearGradient(
            colors: [
              Color(0x4D2196F3),
              Colors.transparent,
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(25.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. Logo arriba de todo
                if (logoBytes != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Image.memory(logoBytes!, height: 80, fit: BoxFit.contain),
                  ),

                // 2. Cliente (item destacado) y otros datos
                _ticketRow("Cliente:", _nombreClienteDisplay, isLarge: true),
                _ticketRow("Método de pago:", _metodoPago),
                
                // 3. Estado de pago
                _ticketRow("Estado de pago:", _estadoPago),

                // 4. Fecha formato 03/03/2026
                _ticketRow("Fecha:", _formatFecha(_fechaFactura)),
                
                const SizedBox(height: 25),

                // 5. Cuadro Detalles del Trabajo
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "DETALLES DEL TRABAJO",
                        style: TextStyle(
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 1.1,
                        ),
                      ),
                      Divider(color: isDark ? Colors.white10 : Colors.black12, height: 20),
                      Text(
                        "Modelo: ${_datosReparacion?['equipo'] ?? '-'}",
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 15),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Falla: ${_datosReparacion?['falla'] ?? '-'}",
                        style: const TextStyle(color: Colors.red, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Reparación: ${_reparacionRealizadaCtrl.text.isNotEmpty ? _reparacionRealizadaCtrl.text : '-'}",
                        style: const TextStyle(color: Colors.green, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // 6. Total a abonar
                Text(
                  "TOTAL A ABONAR",
                  style: TextStyle(color: Theme.of(context).hintColor, fontSize: 14, letterSpacing: 1.2),
                ),
                const SizedBox(height: 5),
                
                // 7. Precio total
                Text(
                  "\$${_formatConPuntos(_totalCalculado)}",
                  style: TextStyle(
                    fontFamily: 'WhiskeyGirlsCondensedItalic',
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 38, // Tamaño reducido según lo pedido
                  ),
                ),

                const SizedBox(height: 20),

                // 8. Mensaje final
                Text(
                  "¡Gracias por confiar en el servicio técnico de Conección One!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).hintColor,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _guardarFactura() async {
    if (_clienteSeleccionadoId == null) {
      return;
    }

    final int numeroFacturaGuardar = _numeroFactura > 0 ? _numeroFactura : 1;

    final messenger = ScaffoldMessenger.of(context);

    await FirebaseFirestore.instance.collection('facturas').add({
      'nombreCliente': _nombreClienteDisplay,
      'clienteId': _clienteSeleccionadoId,
      'equipo': _datosReparacion?['equipo'] ?? "No registrado",
      'falla': _datosReparacion?['falla'] ?? "No registrada",
      'reparacion': _reparacionRealizadaCtrl.text.isNotEmpty ? _reparacionRealizadaCtrl.text : "No registrada",
      'numeroFactura': numeroFacturaGuardar,
      'estadoPago': _estadoPago,
      'metodoPago': _metodoPago,
      'montoEntrega': _estadoPago == 'Entrega'
          ? double.tryParse(_montoEntregaCtrl.text) ?? 0
          : 0,
      'saldoRestante': _estadoPago == 'Entrega' ? _saldoRestante : 0,
      'total': _totalCalculado,
      'fechaFactura': _fechaFactura,
      'manoObra': _manoObraCtrl.text,
      'repuesto': _costoRepuestoCtrl.text,
      'envio': _costoEnvioCtrl.text,
      'fecha': DateTime.now(),
    });

    await _cargarSiguienteNumeroFactura();

    if (!mounted) return;
    messenger.showSnackBar(
      const SnackBar(
        content: Text(
          "Factura registrada",
        ),
      ),
    );
  }

  void _enviarWhatsAppDirecto() async {
    // Damos un margen de tiempo para que el motor gráfico de Windows
    // termine de renderizar los filtros de desenfoque (blur).
    await Future.delayed(const Duration(milliseconds: 100));
    
    final Uint8List? image = await _screenshotController.capture(
      pixelRatio: 2.0,
    );

    if (image != null) {
      try {
        final directory = await getApplicationDocumentsDirectory();

        final String invoiceNumberPart = _numeroFactura > 0
            ? '_${_numeroFactura.toString().padLeft(6, '0')}'
            : '';

        final String fileName =
            'Ticket${invoiceNumberPart}_${_nombreClienteDisplay.replaceAll(' ', '_')}.png';

        final File imageFile = File(
          '${directory.path}/$fileName',
        );

        await imageFile.writeAsBytes(image);

        const String ticketMessage = "Te adjunto el ticket de tu servicio.";

        if (Platform.isAndroid) {
          // En Android compartimos el archivo directamente
          await Share.shareXFiles(
            [XFile(imageFile.path)],
            text: ticketMessage,
          );
        } else if (Platform.isWindows) {
          // En Windows usamos el método de portapapeles y explorer
          await Pasteboard.writeFiles([
            imageFile.path,
          ]);

          final String pathWindows = imageFile.path.replaceAll(
            '/',
            '\\',
          );

          await Process.run(
            'explorer.exe',
            [
              '/select,',
              pathWindows,
            ],
          );

          final Uri whatsappUri = Uri.parse(
            "whatsapp://send?text=$ticketMessage",
          );

          await launchUrl(
            whatsappUri,
          );

          if (!mounted) return;
          final messenger = ScaffoldMessenger.of(context);
          messenger.showSnackBar(
            const SnackBar(
              content: Text(
                "¡Ticket listo! Entrá al chat y presioná Ctrl + V",
              ),
              backgroundColor: Colors.blueAccent,
              duration: Duration(seconds: 5),
            ),
          );
        }
      } catch (e) {
        debugPrint("Error: $e");
      }
    }
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Text(
          text,
          style: TextStyle(
            color: Theme.of(context).hintColor,
            fontSize: 12,
          ),
        ),
      );

  InputDecoration _inputDeco(String hint) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Theme.of(context).hintColor.withOpacity(0.3),
        ),
        filled: true,
        fillColor: isDark ? const Color(0x0DFFFFFF) : Colors.black.withOpacity(0.05),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: isDark ? const Color(0x1AFFFFFF) : Colors.black12,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Colors.blueAccent,
          ),
        ),
      );
  }

  Widget _ticketRow(
    String label,
    String value,
    {bool isLarge = false}
  ) =>
      Padding(
        padding: EdgeInsets.symmetric(
          vertical: isLarge ? 6 : 4,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isLarge ? Theme.of(context).colorScheme.onSurface : Theme.of(context).hintColor,
                fontSize: isLarge ? 17 : 14,
                fontWeight: isLarge ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: isLarge ? 17 : 14,
                fontWeight: isLarge ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      );
}
