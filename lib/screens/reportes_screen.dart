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

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  String _filtroFacturas = 'Todas';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  Uint8List? logoBytes;

  final List<String> _filtros = [
    'Todas',
    'Pagadas',
    'Pendientes / Entregadas',
  ];

  final List<String> _estadosPago = ['Pagado', 'Entrega'];
  final List<String> _metodosPago = [
    'Efectivo',
    'Transferencia',
    'Tarjeta',
    'Mercado Pago',
    'Otro',
  ];

  @override
  void initState() {
    super.initState();
    cargarLogo();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isLargeScreen = width > 1200;

    return Padding(
      padding: EdgeInsets.all(isLargeScreen ? 30 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reportes',
            style: GoogleFonts.poppins(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Listado de facturas guardadas en Firestore',
            style: TextStyle(
              color: Theme.of(context).hintColor,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 15),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('facturas')
                  .orderBy('fecha', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error al cargar facturas',
                      style: TextStyle(color: Theme.of(context).hintColor),
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                final facturasFiltradas = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>? ?? {};
                  final estado = data['estadoPago']?.toString().toLowerCase() ?? '';
                  if (_filtroFacturas == 'Todas') return true;
                  if (_filtroFacturas == 'Pagadas') {
                    return estado == 'pagado';
                  }
                  return estado != 'pagado';
                }).toList();

                // Agrupar por cliente y aplicar búsqueda
                Map<String, List<QueryDocumentSnapshot>> grouped = {};
                for (var doc in facturasFiltradas) {
                  final data = doc.data() as Map<String, dynamic>;
                  final cliente = _safeString(data['nombreCliente'] ?? data['cliente']);
                  final numero = data['numeroFactura']?.toString() ?? '';

                  if (_searchQuery.isNotEmpty) {
                    bool matchesClient = cliente.toLowerCase().contains(_searchQuery.toLowerCase());
                    bool matchesNumber = numero.contains(_searchQuery);
                    if (!matchesClient && !matchesNumber) continue;
                  }

                  if (!grouped.containsKey(cliente)) {
                    grouped[cliente] = [];
                  }
                  grouped[cliente]!.add(doc);
                }

                final clientNames = grouped.keys.toList()..sort();
                final isDark = Theme.of(context).brightness == Brightness.dark;
                final theme = Theme.of(context);

                return Column(
                  children: [
                    // 1. Total Facturas (Superior Derecha)
                    Align(
                      alignment: Alignment.topRight,
                      child: GlassmorphicContainer(
                        width: 150,
                        height: 35,
                        borderRadius: 10,
                        blur: 10,
                        alignment: Alignment.center,
                        border: 1,
                        linearGradient: LinearGradient(
                          colors: isDark 
                              ? [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)]
                              : [Colors.white, Colors.white.withOpacity(0.9)],
                        ),
                        borderGradient: LinearGradient(
                          colors: [Colors.blue.withOpacity(0.5), Colors.transparent],
                        ),
                        child: Text(
                          '${facturasFiltradas.length} Facturas',
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // 2. Buscador (Izquierda) y Filtros (Derecha) en la misma línea
                    if (isLargeScreen)
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: _buildSearchBar(),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 4,
                            child: _buildFilterBar(),
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          _buildSearchBar(),
                          const SizedBox(height: 10),
                          _buildFilterBar(),
                        ],
                      ),
                      
                    const SizedBox(height: 15),

                    Expanded(
                      child: grouped.isEmpty
                          ? Center(
                              child: Text(
                                'No se encontraron facturas.',
                                style: TextStyle(
                                  color: theme.hintColor,
                                  fontSize: 15,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            )
                          : ListView.builder(
                              itemCount: clientNames.length,
                              itemBuilder: (context, index) {
                                final clientName = clientNames[index];
                                final clientFacturas = grouped[clientName]!;

                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    dividerColor: Colors.transparent,
                                  ),
                                  child: ExpansionTile(
                                    title: Text(
                                      clientName,
                                      style: GoogleFonts.poppins(
                                        color: theme.colorScheme.onSurface,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${clientFacturas.length} facturas',
                                      style: TextStyle(color: theme.hintColor),
                                    ),
                                    leading: const CircleAvatar(
                                      backgroundColor: Color(0xFF3B82F6),
                                      child: Icon(Icons.person, color: Colors.white),
                                    ),
                                    children: clientFacturas.map((doc) {
                                      final data = doc.data() as Map<String, dynamic>? ?? {};
                                      final numero = data['numeroFactura'];
                                      final facturaNumero = numero != null
                                          ? '#${numero.toString().padLeft(6, '0')}'
                                          : '-';
                                      final total = _formatCurrency(data['total']);
                                      final estadoPago = _safeString(data['estadoPago']);
                                      final fecha = _formatFecha(data['fecha']);

                                      return Padding(
                                        padding: const EdgeInsets.only(left: 15, bottom: 10, right: 10),
                                        child: ListTile(
                                          onTap: () => _mostrarDetalleFactura(doc),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(15),
                                            side: BorderSide(
                                              color: theme.dividerColor.withOpacity(0.1),
                                            ),
                                          ),
                                          tileColor: theme.colorScheme.surface.withOpacity(0.03),
                                          title: Text(
                                            "Factura $facturaNumero",
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: theme.colorScheme.onSurface,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          subtitle: Text(
                                            fecha,
                                            style: TextStyle(
                                              color: theme.hintColor,
                                              fontSize: 11,
                                            ),
                                          ),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    "$total ",
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      color: Colors.green,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  Text(
                                                    estadoPago,
                                                    style: TextStyle(
                                                      color: estadoPago.toLowerCase() == 'pagado'
                                                          ? Colors.green
                                                          : Colors.orangeAccent,
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(width: 8),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.edit_outlined,
                                                  color: Colors.blueAccent,
                                                  size: 20,
                                                ),
                                                onPressed: () => _editarFactura(doc),
                                              ),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.delete_outline,
                                                  color: Colors.redAccent,
                                                  size: 20,
                                                ),
                                                onPressed: () => _confirmarEliminacionFactura(doc.id),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GlassmorphicContainer(
      width: double.infinity,
      height: 55,
      borderRadius: 20,
      blur: 20,
      alignment: Alignment.center,
      border: 1,
      linearGradient: LinearGradient(
        colors: isDark 
            ? [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)]
            : [Colors.white, Colors.white.withOpacity(0.9)],
      ),
      borderGradient: LinearGradient(
        colors: [
          isDark ? Colors.white.withOpacity(0.1) : Colors.black12,
          Colors.transparent,
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _filtros.map((filtro) {
              final selected = filtro == _filtroFacturas;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(
                    filtro,
                    style: TextStyle(
                      color: selected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                      fontSize: 11,
                    ),
                  ),
                  selected: selected,
                  backgroundColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                  selectedColor: const Color(0xFF3B82F6),
                  onSelected: (_) => setState(() => _filtroFacturas = filtro),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    return GlassmorphicContainer(
      width: double.infinity,
      height: 48,
      borderRadius: 15,
      blur: 15,
      alignment: Alignment.center,
      border: 1,
      linearGradient: LinearGradient(
        colors: isDark 
            ? [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)]
            : [Colors.white, Colors.white.withOpacity(0.9)],
      ),
      borderGradient: LinearGradient(
        colors: [
          isDark ? Colors.white.withOpacity(0.1) : Colors.black12,
          Colors.transparent,
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: TextField(
          controller: _searchController,
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
          style: TextStyle(color: theme.colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: "Buscar por cliente o nº de factura...",
            hintStyle: TextStyle(color: theme.hintColor),
            border: InputBorder.none,
            icon: const Icon(
              Icons.search,
              color: Color(0xFF3B82F6),
            ),
          ),
        ),
      ),
    );
  }

  String _safeString(dynamic value) {
    if (value == null) return '-';
    return value.toString();
  }

  String _formatCurrency(dynamic raw) {
    if (raw == null) return '\$0.00';
    double amount = 0;
    if (raw is num) {
      amount = raw.toDouble();
    } else {
      amount = double.tryParse(raw.toString()) ?? 0;
    }

    String str = amount.toStringAsFixed(0);
    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return '\$${str.replaceAllMapped(reg, (Match m) => '${m[1]}.')}';
  }

  String _formatFecha(dynamic raw) {
    if (raw == null) return '-';
    DateTime date;

    if (raw is Timestamp) {
      date = raw.toDate();
    } else if (raw is DateTime) {
      date = raw;
    } else {
      final parsed = DateTime.tryParse(raw.toString());
      if (parsed != null) {
        date = parsed;
      } else {
        return raw.toString();
      }
    }

    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
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
      debugPrint("Error cargando logo en reportes: $e");
    }
  }

  void _editarFactura(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final nomCtrl = TextEditingController(text: _safeString(data['nombreCliente'] ?? data['cliente']));
    final equCtrl = TextEditingController(text: _safeString(data['equipo']));
    final falCtrl = TextEditingController(text: _safeString(data['falla']));
    final solCtrl = TextEditingController(text: _safeString(data['reparacion']));
    final totCtrl = TextEditingController(text: data['total']?.toString() ?? '0');
    String estSel = _safeString(data['estadoPago']);
    String metSel = _safeString(data['metodoPago']);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Editar Factura"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _inputField("Cliente", nomCtrl, ctx),
              _inputField("Equipo", equCtrl, ctx),
              _inputField("Falla", falCtrl, ctx),
              _inputField("Solución / Reparación", solCtrl, ctx),
              _inputField("Total", totCtrl, ctx, isNumber: true),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                initialValue: _estadosPago.contains(estSel) ? estSel : _estadosPago.first,
                dropdownColor: Theme.of(ctx).canvasColor,
                style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: "Estado de Pago",
                  labelStyle: TextStyle(color: Theme.of(ctx).hintColor),
                ),
                items: _estadosPago.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => estSel = v!,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _metodosPago.contains(metSel) ? metSel : _metodosPago.first,
                dropdownColor: Theme.of(ctx).canvasColor,
                style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: "Método de Pago",
                  labelStyle: TextStyle(color: Theme.of(ctx).hintColor),
                ),
                items: _metodosPago.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => metSel = v!,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('facturas').doc(doc.id).update({
                'nombreCliente': nomCtrl.text,
                'equipo': equCtrl.text,
                'falla': falCtrl.text,
                'reparacion': solCtrl.text,
                'total': double.tryParse(totCtrl.text) ?? 0.0,
                'estadoPago': estSel,
                'metodoPago': metSel,
              });
              Navigator.pop(ctx);
            },
            child: const Text("GUARDAR"),
          )
        ],
      ),
    );
  }

  void _enviarWhatsAppDetalle(String cliente, String facturaNumero) async {
    await Future.delayed(const Duration(milliseconds: 100));
    
    final Uint8List? image = await _screenshotController.capture(
      pixelRatio: 2.0,
    );

    if (!mounted) return;

    if (image != null) {
      try {
        final directory = await getApplicationDocumentsDirectory();
        final String fileName =
            'Reenvio_Factura_${facturaNumero.replaceAll('#', '')}_${cliente.replaceAll(' ', '_')}.png';
        final File imageFile = File('${directory.path}/$fileName');
        await imageFile.writeAsBytes(image);

        const String ticketMessage = "Te reenvío el detalle de tu factura.";

        if (Platform.isWindows) {
          await Pasteboard.writeFiles([imageFile.path]);
          await Process.run(
            'explorer.exe',
            ['/select,', imageFile.path.replaceAll('/', '\\')],
          );

          final Uri whatsappUri = Uri.parse(
            "whatsapp://send?text=${Uri.encodeComponent(ticketMessage)}",
          );
          await launchUrl(whatsappUri);
        } else if (Platform.isAndroid || Platform.isIOS) {
          await Share.shareXFiles(
            [XFile(imageFile.path)],
            text: ticketMessage,
          );
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Platform.isWindows 
                  ? "¡Ticket copiado! Pegalo en WhatsApp (Ctrl+V)"
                  : "Compartiendo ticket..."
            ),
            backgroundColor: Colors.blueAccent,
          ),
        );
      } catch (e) {
        debugPrint("Error al reenviar: $e");
      }
    }
  }

  void _mostrarDetalleFactura(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final numero = data['numeroFactura'];
    final facturaNumero =
        numero != null ? '#${numero.toString().padLeft(6, '0')}' : '-';
    final cliente = _safeString(data['nombreCliente'] ?? data['cliente']);
    final equipo = _safeString(data['equipo'] ?? '-');
    final falla = _safeString(data['falla'] ?? '-');
    final reparacion = _safeString(data['reparacion'] ?? '-');
    final totalRaw = data['total'] ?? 0;
    final totalFormatted = _formatCurrency(totalRaw);
    final metodoPago = _safeString(data['metodoPago']);
    final estadoPago = _safeString(data['estadoPago']);
    final fecha = _formatFecha(data['fecha']);

    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final theme = Theme.of(ctx);
        return AlertDialog(
          title: Text(
            'Detalle $facturaNumero',
            style: TextStyle(color: theme.colorScheme.onSurface),
          ),
          content: Screenshot(
            controller: _screenshotController,
            child: Container(
              padding: const EdgeInsets.all(5),
              color: isDark ? Colors.black : Colors.white,
              child: GlassmorphicContainer(
                width: double.infinity,
                height: 550,
                borderRadius: 20,
                blur: 20,
                alignment: Alignment.topCenter,
                border: 1,
                linearGradient: LinearGradient(
                  colors: isDark 
                    ? [const Color(0x14FFFFFF), const Color(0x08FFFFFF)]
                    : [Colors.black.withOpacity(0.05), Colors.black.withOpacity(0.02)],
                ),
                borderGradient: const LinearGradient(
                  colors: [Color(0x4D2196F3), Colors.transparent],
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(25),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (logoBytes != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: Image.memory(logoBytes!, height: 80, fit: BoxFit.contain),
                          ),
                        
                        _ticketRow("Cliente:", cliente, ctx, isLarge: true),
                        _ticketRow("Método de pago:", metodoPago, ctx),
                        _ticketRow("Estado de pago:", estadoPago, ctx),
                        _ticketRow("Fecha:", fecha, ctx),
                        
                        const SizedBox(height: 25),

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
                              Text("Modelo: $equipo", style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 15)),
                              const SizedBox(height: 8),
                              Text("Falla: $falla", style: const TextStyle(color: Colors.red, fontSize: 15, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text("Reparación: $reparacion", style: const TextStyle(color: Colors.green, fontSize: 15, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),

                        Text("TOTAL A ABONAR", style: TextStyle(color: theme.hintColor, fontSize: 14, letterSpacing: 1.2)),
                        const SizedBox(height: 5),
                        Text(
                          totalFormatted,
                          style: TextStyle(
                            fontFamily: 'WhiskeyGirlsCondensedItalic',
                            color: theme.colorScheme.onSurface,
                            fontSize: 38,
                          ),
                        ),

                        const SizedBox(height: 20),
                        Text(
                          "¡Gracias por confiar en el servicio técnico de Conección One!",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: theme.hintColor, fontSize: 12, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cerrar',
                style: TextStyle(color: theme.hintColor),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _enviarWhatsAppDetalle(cliente, facturaNumero),
              icon: const Icon(Icons.send, size: 18),
              label: const Text("WhatsApp"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _ticketRow(String label, String value, BuildContext context, {bool isLarge = false}) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isLarge ? 6 : 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isLarge ? theme.colorScheme.onSurface : theme.hintColor,
              fontSize: isLarge ? 17 : 14,
              fontWeight: isLarge ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: isLarge ? 17 : 14,
              fontWeight: isLarge ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputField(String label, TextEditingController ctrl, BuildContext context, {bool isNumber = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: TextField(
        controller: ctrl,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Theme.of(context).hintColor),
          filled: true,
          fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.blueAccent),
          ),
        ),
      ),
    );
  }

  void _confirmarEliminacionFactura(String id) {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: Text(
            "Eliminar Factura",
            style: TextStyle(color: theme.colorScheme.onSurface),
          ),
          content: Text(
            "¿Estás seguro de que deseas eliminar esta factura? Esta acción borrará el registro de la base de datos permanentemente.",
            style: TextStyle(color: theme.hintColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CANCELAR"),
            ),
            TextButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('facturas')
                    .doc(id)
                    .delete();
                if (mounted) Navigator.pop(context);
              },
              child: Text(
                    "ELIMINAR",
                    style: TextStyle(color: Colors.redAccent),
                  ),
            ),
          ],
        );
      },
    );
  }
}