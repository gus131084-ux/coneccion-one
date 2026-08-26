import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glassmorphism/glassmorphism.dart';

import 'firebase_options.dart';
import 'screens/clientes_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/reparaciones_screen.dart';
import 'screens/inventario_screen.dart';
import 'screens/facturacion_screen.dart';
import 'screens/reportes_screen.dart';
import 'screens/configuracion_screen.dart';

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

String _getMonthName(int month) {
  const monthNames = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
  ];
  return monthNames[month - 1];
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Aquí se podría cargar la preferencia guardada de SharedPreferences antes de iniciar
  runApp(const ConeccionOneApp());
}

// Notificador global para el cambio de tema en tiempo real
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

class ConeccionOneApp extends StatefulWidget {
  const ConeccionOneApp({super.key});

  @override
  State<ConeccionOneApp> createState() => _ConeccionOneAppState();
}

class _ConeccionOneAppState extends State<ConeccionOneApp> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, mode, __) {
        return MaterialApp(
          title: 'Conección One',
          debugShowCheckedModeBanner: false,
          themeMode: mode,
          locale: const Locale('es', 'ES'),
          supportedLocales: const [
            Locale('es', 'ES'),
          ],
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: ThemeData(
            brightness: Brightness.light,
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFFF8FAFC),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF3B82F6),
              brightness: Brightness.light,
            ),
            textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFF080808),
            dialogTheme: const DialogThemeData(
              backgroundColor: Color(0xFF1E1E1E),
            ),
            textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
          ),
          home: const MainLayout(),
        );
      },
    );
  }
}

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;
  Map<String, dynamic>? _selectedClientData;

  String filtroFinanciero = "Este Mes";

  int totalReparaciones = 0;
  int totalInventario = 0;
  int totalClientes = 0;
  double totalVentas = 0;
  double totalGastos = 0;

  String nombreNegocio = "Conección One";
  String nombreAdmin = "Admin";
  Uint8List? logoBytes;

  Map<String, int> repairRanking = {};
  Map<int, double> monthlyIngresos = {};
  Map<int, double> monthlyGastos = {};
  List<QueryDocumentSnapshot> productosBajoStock = [];

  final List<String> _menuLabels = [
    "Dashboard",
    "Clientes",
    "Reparaciones",
    "Inventario",
    "Facturación",
    "Reportes",
    "Configuración",
  ];

  final List<IconData> _menuIcons = [
    Icons.grid_view_rounded,
    Icons.people_outline,
    Icons.smartphone_outlined,
    Icons.inventory_2_outlined,
    Icons.receipt_long_outlined,
    Icons.bar_chart_outlined,
    Icons.settings_outlined,
  ];

  // Listas para el formulario de reparación rápido
  final List<String> marcas = ["Samsung", "Motorola", "Xiaomi", "iPhone", "Huawei", "Otro"];
  final List<String> fallas = ["Cambio de módulo", "No carga", "Pin de carga", "Batería", "Software", "Otro"];
  final Map<String, List<String>> modelosPorMarca = {
    "Samsung": ["A10", "A20", "S21", "S22", "Otro"],
    "Motorola": ["G8", "G9", "E7", "Edge 30", "Otro"],
    "Xiaomi": ["Redmi 9", "Note 10", "Note 11", "Otro"],
    "iPhone": ["11", "12", "13", "14", "Otro"],
    "Huawei": ["P30", "P40", "Otro"],
    "Otro": ["Genérico"],
  };

  @override
  void initState() {
    super.initState();
    cargarDashboard();
    cargarConfiguracionGeneral();
  }

  Future<void> cargarConfiguracionGeneral() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('configuracion')
          .doc('general')
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;

        setState(() {
          nombreNegocio =
              data['nombreNegocio'] ?? "Conección One";
          nombreAdmin = 
              data['nombreAdmin'] ?? "Admin";

          if (data['logoBase64'] != null && data['logoBase64'].toString().isNotEmpty) {
            logoBytes = base64Decode(data['logoBase64']);
          } else {
            logoBytes = null;
          }
        });
      }
    } catch (e) {
      debugPrint("Error cargando configuración: $e");
    }
  }

  Future<void> cargarDashboard() async {
    final clientes =
        await FirebaseFirestore.instance
            .collection('clientes')
            .get();

    final reparaciones =
        await FirebaseFirestore.instance
            .collection('reparaciones')
            .get();

    final inventario =
        await FirebaseFirestore.instance
            .collection('inventario')
            .get();

    final ventas =
        await FirebaseFirestore.instance
            .collection('facturas')
            .get();

    monthlyIngresos = { for (var i = 1; i <= 12; i++) i: 0.0 };
    monthlyGastos = { for (var i = 1; i <= 12; i++) i: 0.0 };

    double sumaVentas = 0;
    double sumaGastos = 0;

    for (var venta in ventas.docs) {
      final data = venta.data();
      final total = (data['total'] as num?)?.toDouble() ?? 0.0;
      final repuesto = double.tryParse(data['repuesto']?.toString() ?? '0') ?? 0.0;
      final envio = double.tryParse(data['envio']?.toString() ?? '0') ?? 0.0;
      final gastosVenta = repuesto + envio;

      sumaVentas += total;
      sumaGastos += gastosVenta;

      final fecha = data['fecha'] as Timestamp?;
      if (fecha != null) {
        final month = fecha.toDate().month;
        monthlyIngresos[month] = (monthlyIngresos[month] ?? 0.0) + total;
        monthlyGastos[month] = (monthlyGastos[month] ?? 0.0) + gastosVenta;
      }
    }

    repairRanking = {};
    for (var doc in reparaciones.docs) {
      final data = doc.data();
      final falla = data['falla'] as String? ?? 'Desconocida';
      repairRanking[falla] = (repairRanking[falla] ?? 0) + 1;
    }
    var sortedRanking = repairRanking.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    repairRanking = Map.fromEntries(sortedRanking);

    final bajoStock = inventario.docs.where((doc) {
      final data = doc.data();
      return (data['stock'] ?? 0) < 5;
    }).toList();

    setState(() {
      totalClientes = clientes.docs.length;
      totalReparaciones = reparaciones.docs.length;
      totalInventario = inventario.docs.length;
      totalVentas = sumaVentas;
      totalGastos = sumaGastos;
      productosBajoStock = bajoStock;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      endDrawer: _buildClientDetailsDrawer(),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark 
                ? [const Color(0xFF080808), const Color(0xFF000000)]
                : [const Color(0xFFF1F5F9), const Color(0xFFE2E8F0)],
          ),
        ),
        child: Column(
          children: [
            _buildTopNavigation(),
            Expanded(child: _buildCurrentScreen()),
          ],
        ),
      ),
    );
  }

  Widget _buildTopNavigation() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.colorScheme.onSurface;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111111) : const Color(0xFFF8FAFC),
        border: Border(bottom: BorderSide(color: isDark ? Colors.white10 : Colors.black12)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 150,
                height: 54,
                child: logoBytes != null
                    ? Image.memory(logoBytes!, fit: BoxFit.contain, alignment: Alignment.centerLeft)
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.flash_on, color: Color(0xFF3B82F6), size: 28),
                          const SizedBox(width: 8),
                          Text(nombreNegocio, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                        ],
                      ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Text(
                  '¡Bienvenido, $nombreAdmin!',
                  style: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                tooltip: isDark ? 'Cambiar a tema claro' : 'Cambiar a tema oscuro',
                onPressed: () => themeNotifier.value = isDark ? ThemeMode.light : ThemeMode.dark,
                icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined, color: textColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_menuLabels.length, (index) {
                final active = _selectedIndex == index;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: TextButton.icon(
                    onPressed: () async {
                      setState(() => _selectedIndex = index);
                      await cargarDashboard();
                      await cargarConfiguracionGeneral();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: active ? Colors.white : textColor,
                      backgroundColor: active ? const Color(0xFF3B82F6) : Colors.transparent,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    icon: Icon(_menuIcons[index], size: 19),
                    label: Text(_menuLabels[index]),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 250,
      decoration: BoxDecoration(
        // Color sólido para separar claramente la barra lateral del contenido principal
        color: isDark ? const Color(0xFF111111) : const Color(0xFFEDF2F7),
        border: Border(
          right: BorderSide(
            color: isDark ? Colors.white10 : Colors.black12,
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.only(
        top: 10,
        bottom: 30,
        left: 15,
        right: 15,
      ),
      child: Column(
        children: [
          Center(
            child: SizedBox(
              width: 220,
              height: 110,
              child: logoBytes != null
                  ? Image.memory(
                      logoBytes!,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    )
                  : const SizedBox.shrink(),
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Divider(height: 40), 
          ),

          Expanded(
            child: ListView.builder(
              itemCount: _menuLabels.length,
              itemBuilder: (context, index) {
                bool isActive =
                    _selectedIndex == index;

                return GestureDetector(
                  onTap: () async {
                    setState(() {
                      _selectedIndex = index;
                    });

                    await cargarDashboard();
                    await cargarConfiguracionGeneral();
                  },
                  child: Container(
                    margin:
                        const EdgeInsets.only(
                      bottom: 8,
                    ),
                    padding:
                        const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 15,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(
                              0xFF3B82F6)
                          : Colors.transparent,
                      borderRadius:
                          BorderRadius.circular(
                              12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _menuIcons[index],
                          color: isActive
                              ? Colors.white
                              : Colors.white54,
                          size: 22,
                        ),

                        const SizedBox(width: 15),

                        Expanded(
                          child: Text(
                            _menuLabels[index],
                            overflow:
                                TextOverflow
                                    .ellipsis,
                            style: TextStyle(
                              color: isActive
                                  ? Colors.white
                                  : isDark ? Colors.white70 : Colors.black87,
                              fontWeight:
                                  isActive
                                      ? FontWeight
                                          .bold
                                      : FontWeight
                                          .normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          _buildThemeToggle(true),
        ],
      ),
    );
  }

  Widget _buildThemeToggle(bool isLarge) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isLarge ? 15 : 20, vertical: 10),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        dense: true,
        leading: Icon(
          isDark ? Icons.dark_mode : Icons.light_mode,
          color: isDark ? Colors.blueAccent : Colors.orangeAccent,
          size: 20,
        ),
        title: Text(
          isDark ? "Oscuro" : "Claro",
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.black87,
            fontSize: 13,
          ),
        ),
        trailing: Switch(
          value: isDark,
          activeThumbColor: Colors.blueAccent,
          onChanged: (val) {
            themeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
          },
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          // Mantenemos el mismo color que el sidebar para consistencia visual
          color: isDark ? const Color(0xFF111111) : const Color(0xFFEDF2F7),
        ),
        child: Column(
          children: [
            DrawerHeader(
              child: Center(
                child: SizedBox(
                  width: 200,
                  height: 80,
                  child: logoBytes != null
                      ? Image.memory(
                          logoBytes!,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) =>
                              const SizedBox.shrink(),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: _menuLabels.length,
                itemBuilder: (context, index) {
                  bool isActive =
                      _selectedIndex == index;

                  return ListTile(
                    leading: Icon(
                      _menuIcons[index],
                      color: isActive
                          ? Colors.white
                          : isDark ? Colors.white54 : Colors.black54,
                    ),
                    title: Text(
                      _menuLabels[index],
                      style: TextStyle(
                        color: isActive
                            ? Colors.white
                            : isDark ? Colors.white70 : Colors.black87,
                        fontWeight: isActive
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    selected: isActive,
                    onTap: () async {
                      final navigator = Navigator.of(context);

                      setState(() {
                        _selectedIndex = index;
                      });

                      await cargarDashboard();
                      await cargarConfiguracionGeneral();
                      if (!mounted) return;
                      navigator.pop();
                    },
                  );
                },
              ),
            ),
            const Divider(height: 1),
            _buildThemeToggle(false),
          ],
        ),
      ),
    );
  }

  Widget _buildClientDetailsDrawer() {
    if (_selectedClientData == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Drawer(
      backgroundColor: theme.colorScheme.surface,
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : theme.colorScheme.primary.withAlpha((0.1 * 255).round()),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircleAvatar(radius: 30, backgroundColor: Colors.blue, child: Icon(Icons.person, color: Colors.white, size: 30)),
                  const SizedBox(height: 10),
                  Text("Ficha de Cliente", style: GoogleFonts.poppins(color: theme.colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline, color: Colors.blue),
            title: Text("Nombre Completo", style: TextStyle(color: theme.hintColor, fontSize: 12)),
            subtitle: Text(_selectedClientData!['nombre'] ?? 'Sin nombre', style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 16)),
          ),
          ListTile(
            leading: const Icon(Icons.phone_android, color: Colors.green),
            title: Text("Teléfono / WhatsApp", style: TextStyle(color: theme.hintColor, fontSize: 12)),
            subtitle: Text(_selectedClientData!['telefono'] ?? 'Sin teléfono', style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 16)),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text("Conección One v1.0", style: TextStyle(color: theme.hintColor.withAlpha((0.2 * 255).round()), fontSize: 12)),
          )
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppBar(
      backgroundColor: isDark ? const Color(0xE6000000) : const Color.fromRGBO(255, 255, 255, 0.9),
      elevation: 0,
      title: Text(
        _menuLabels[_selectedIndex],
        style: GoogleFonts.poppins(
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.bold,
        ),
      ),
      leading: Builder(
        builder: (context) => IconButton(
          icon: Icon(
            Icons.menu,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
        ),
      ),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_selectedIndex) {
      case 0:
        return const DashboardScreen();

      case 1:
        return const ClientesScreen();

      case 2:
        return const ReparacionesScreen();

      case 3:
        return const InventarioScreen();

      case 4:
        return const FacturacionScreen();

      case 5:
        return const ReportesScreen();

      case 6:
        return const ConfiguracionScreen();

      default:
        return const Center(
          child: Text(
            "Pantalla no encontrada",
            style: TextStyle(
              color: Colors.white24,
            ),
          ),
        );
    }
  }

  Widget _buildDashboardContent() {
    double ganancias = totalVentas - totalGastos;
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 1200;
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              "¡Bienvenido, $nombreAdmin!",
              style: TextStyle(
                fontFamily: 'WhiskeyGirlsCondensedItalic',
                fontSize: isLargeScreen ? 32 : 24,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              "Resumen general de tu taller",
              style: textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).hintColor,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 30),

            // STAT CARDS - RESPONSIVE
            isLargeScreen
                ? Row(
                    children: [
                      Expanded(
                        child: _statCard(
                          "Clientes",
                          totalClientes.toString(),
                          Icons.people_outline,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: _statCard(
                          "Reparaciones",
                          totalReparaciones.toString(),
                          Icons.build_outlined,
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: _statCard(
                          "Ventas",
                          "\$${totalVentas.toStringAsFixed(0)}",
                          Icons.payments_outlined,
                          Colors.purple,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: _statCard(
                          "Inventario",
                          totalInventario.toString(),
                          Icons.inventory_2_outlined,
                          Colors.orange,
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _statCard(
                              "Clientes",
                              totalClientes.toString(),
                              Icons.people_outline,
                              Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: _statCard(
                              "Reparaciones",
                              totalReparaciones.toString(),
                              Icons.build_outlined,
                              Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(
                            child: _statCard(
                              "Ventas",
                              "\$${totalVentas.toStringAsFixed(0)}",
                              Icons.payments_outlined,
                              Colors.purple,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: _statCard(
                              "Inventario",
                              totalInventario.toString(),
                              Icons.inventory_2_outlined,
                              Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

            const SizedBox(height: 25),

            // BOTTOM SECTIONS - RESPONSIVE
            isLargeScreen
                ? SizedBox(
                    height: 450,
                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: _clientesBox(),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          flex: 1,
                          child: _finanzasBox(
                            totalVentas,
                            totalGastos,
                            ganancias,
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      SizedBox(
                        height: 300,
                        child: _finanzasBox(
                          totalVentas,
                          totalGastos,
                          ganancias,
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 450,
                        child: _clientesBox(),
                      ),
                    ],
                  ),

            const SizedBox(height: 30),
            SizedBox(
              height: 350,
              child: _rankingReparacionesBox(),
            ),
          ],
        ),
      ),
    );
  }

  void _showMonthlyBreakdownDialog(String type) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).dialogBackgroundColor,
          title: Text(
            'Desglose Mensual: ${type.capitalize()}',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
          content: SizedBox(
            width: 300,
            height: 400,
            child: ListView.builder(
              itemCount: 12,
              itemBuilder: (context, index) {
                int month = index + 1;
                double value = 0;
                if (type == 'ingresos') {
                  value = monthlyIngresos[month] ?? 0;
                } else if (type == 'gastos') {
                  value = monthlyGastos[month] ?? 0;
                } else if (type == 'ganancia') {
                  value = (monthlyIngresos[month] ?? 0) - (monthlyGastos[month] ?? 0);
                }

                Color textColor = Theme.of(context).colorScheme.onSurface;
                if (type == 'ingresos' || (type == 'ganancia' && value >= 0)) textColor = Colors.greenAccent;
                if (type == 'gastos' || (type == 'ganancia' && value < 0)) textColor = Colors.redAccent;

                return ListTile(
                  title: Text(_getMonthName(month), style: TextStyle(color: Theme.of(context).hintColor)),
                  trailing: Text("\$${value.toStringAsFixed(2)}", 
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold
                    )),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cerrar', style: TextStyle(color: Theme.of(context).hintColor)),
            ),
          ],
        );
      }
    );
  }

  TextStyle _numberStyle({
    double fontSize = 15,
    required Color color,
    FontWeight fontWeight = FontWeight.normal,
  }) {
    return TextStyle(
      fontFamily: 'WhiskeyGirlsCondensedItalic',
      letterSpacing: 0.0,
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
    );
  }

  Widget _financeItem(
    String title,
    String value,
    Color color,
    IconData icon, {
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: iconColor ?? color,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: Theme.of(context).hintColor,
                fontSize: 10,
                letterSpacing: 1,
              ),
            ),
            if (onTap != null)
              GestureDetector(
                onTap: onTap,
                child: const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Icon(Icons.arrow_drop_down, size: 18),
                ),
              ),
          ],
        ),

        const SizedBox(height: 4),

        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            "$value ",
            style: _numberStyle(
              fontSize: 18,
              color: color,
              fontWeight: FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _statCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GlassmorphicContainer(
      width: double.infinity,
      height: 120,
      borderRadius: 20,
      blur: 20,
      alignment: Alignment.center,
      border: 1,
      linearGradient: LinearGradient(
        colors: isDark 
            ? [const Color(0x1AFFFFFF), const Color(0x0DFFFFFF)]
            : [Colors.white.withOpacity(0.8), Colors.white.withOpacity(0.6)],
      ),
      borderGradient: LinearGradient(
        colors: [
          color.withAlpha(128),
          Colors.transparent,
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      "$value ",
                      style: _numberStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.normal,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                ],
              ),
            ),

            Icon(
              icon,
              color: color,
              size: 34,
            ),
          ],
        ),
      ),
    );
  }

  Widget _clientesBox() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GlassmorphicContainer(
      width: double.infinity,
      height: double.infinity,
      borderRadius: 25,
      blur: 15,
      alignment: Alignment.topLeft,
      border: 1,
      linearGradient: LinearGradient(colors: isDark ? [Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.02)] : [Colors.white, Colors.white.withOpacity(0.8)]),
      borderGradient: LinearGradient(colors: [isDark ? Colors.white.withOpacity(0.1) : Colors.black12, Colors.transparent]),
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Mis Clientes", style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface, fontSize: 20, fontWeight: FontWeight.bold)),
                const Icon(Icons.people_alt_outlined, color: Colors.blueAccent, size: 24),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('clientes').orderBy('nombre').limit(10).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) return Center(child: Text("No hay clientes registrados", style: TextStyle(color: Theme.of(context).hintColor.withOpacity(0.5))));

                  return ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (context, index) => Divider(color: Theme.of(context).dividerColor.withOpacity(0.1)),
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.blue.withOpacity(0.1),
                              child: Text(data['nombre'][0].toUpperCase(), style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(data['nombre'], style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
                                  Text(data['telefono'] ?? 'Sin tel.', style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12)),
                                ],
                              ),
                            ),
                            IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                            onPressed: () => _confirmarEliminacionCliente(docs[index].id),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, color: Colors.green, size: 20),
                              onPressed: () => _mostrarReparacionRapida(data['nombre']),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: Colors.orange, size: 20),
                              onPressed: () => _editarClienteDashboard(docs[index].id, data),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmarEliminacionCliente(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Eliminar Cliente", style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        content: const Text("¿Estás seguro de que deseas eliminar este cliente?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('clientes').doc(id).delete();
              if (mounted) Navigator.pop(context);
            },
            child: const Text("Eliminar", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _editarClienteDashboard(String id, Map<String, dynamic> data) {
    final nomCtrl = TextEditingController(text: data['nombre']);
    final telCtrl = TextEditingController(text: data['telefono']);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Editar Cliente", style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _inputField("Nombre", nomCtrl),
            const SizedBox(height: 15),
            _inputField("Teléfono", telCtrl),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('clientes').doc(id).update({'nombre': nomCtrl.text, 'telefono': telCtrl.text});
              Navigator.pop(context);
            },
            child: const Text("GUARDAR"),
          ),
        ],
      ),
    );
  }

  void _mostrarReparacionRapida(String nombreCliente) {
    final imeiCtrl = TextEditingController();
    final obsCtrl = TextEditingController();
    final marcaCustomCtrl = TextEditingController();
    final modeloCustomCtrl = TextEditingController();
    final preCtrl = TextEditingController();
    final entCtrl = TextEditingController();
    String marcaSel = "Samsung";
    String modeloSel = "A10";
    String fallaSel = "Cambio de módulo";

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text("Nueva Orden: $nombreCliente", style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 18)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: marcaSel,
                  dropdownColor: Theme.of(context).canvasColor,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  decoration: InputDecoration(labelText: "Marca", labelStyle: TextStyle(color: Theme.of(context).hintColor)),
                  items: marcas.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                  onChanged: (v) => setStateDialog(() {
                    marcaSel = v!;
                    modeloSel = modelosPorMarca[marcaSel]!.first;
                  }),
                ),
                if (marcaSel == "Otro") ...[
                  const SizedBox(height: 10),
                  _inputField("Marca (especificar)", marcaCustomCtrl),
                ],
                DropdownButtonFormField<String>(
                  initialValue: modeloSel,
                  dropdownColor: Theme.of(context).canvasColor,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  decoration: InputDecoration(labelText: "Modelo", labelStyle: TextStyle(color: Theme.of(context).hintColor)),
                  items: modelosPorMarca[marcaSel]!.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                  onChanged: (v) => setStateDialog(() => modeloSel = v!),
                ),
                if (modeloSel == "Otro" || modeloSel == "Genérico") ...[
                  const SizedBox(height: 10),
                  _inputField("Modelo (especificar)", modeloCustomCtrl),
                ],
                DropdownButtonFormField<String>(
                  initialValue: fallaSel,
                  dropdownColor: Theme.of(context).canvasColor,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  decoration: InputDecoration(labelText: "Falla", labelStyle: TextStyle(color: Theme.of(context).hintColor)),
                  items: fallas.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                  onChanged: (v) => setStateDialog(() => fallaSel = v!),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _inputField("Presupuesto", preCtrl, isNumber: true),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _inputField("Entrega", entCtrl, isNumber: true),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _inputField("IMEI", imeiCtrl),
                _inputField("Observaciones", obsCtrl),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
            ElevatedButton(
              onPressed: () async {
                final marcaFinal = marcaSel == "Otro"
                    ? (marcaCustomCtrl.text.trim().isNotEmpty ? marcaCustomCtrl.text.trim() : "Otro")
                    : marcaSel;

                final modeloFinal = (modeloSel == "Otro" || modeloSel == "Genérico")
                    ? (modeloCustomCtrl.text.trim().isNotEmpty ? modeloCustomCtrl.text.trim() : modeloSel)
                    : modeloSel;

                await FirebaseFirestore.instance.collection('reparaciones').add({
                  'equipo': "$marcaFinal $modeloFinal",
                  'marca': marcaFinal,
                  'modelo': modeloFinal,
                  'cliente': nombreCliente,
                  'falla': fallaSel,
                  'estado': 'Pendiente',
                  'fecha_ingreso': DateTime.now(),
                  'imei': imeiCtrl.text,
                  'presupuesto': double.tryParse(preCtrl.text) ?? 0.0,
                  'entrega': double.tryParse(entCtrl.text) ?? 0.0,
                  'observaciones': obsCtrl.text,
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Orden registrada correctamente")));
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text("REGISTRAR"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputField(String label, TextEditingController ctrl, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: TextField(
        controller: ctrl,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Theme.of(context).hintColor),
          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Theme.of(context).dividerColor)),
        ),
      ),
    );
  }

  Widget _rankingReparacionesBox() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GlassmorphicContainer(
      width: double.infinity,
      height: double.infinity,
      borderRadius: 25,
      blur: 15,
      alignment: Alignment.topLeft,
      border: 1,
      linearGradient: LinearGradient(
        colors: isDark 
          ? [const Color(0x0DFFFFFF), const Color(0x05FFFFFF)]
          : [Colors.white, Colors.white.withOpacity(0.7)],
      ),
      borderGradient: LinearGradient(
        colors: [
          isDark ? const Color(0x1AFFFFFF) : Colors.black12,
          Colors.transparent,
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              "Ranking de Reparaciones",
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.normal,
                fontSize: 18,
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child:
                  repairRanking.isEmpty
                      ? Center(
                          child: Text(
                            "No hay reparaciones",
                            style: TextStyle(
                              color:
                                  Theme.of(context).hintColor,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount:
                              repairRanking.length > 5 ? 5 : repairRanking.length,
                          itemBuilder:
                              (context, index) {
                            final entry = repairRanking.entries.elementAt(index);

                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading:
                                  Text("${index + 1}", style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.normal)),
                              title: Text(
                                entry.key,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                              trailing: Text("${entry.value} veces", style: TextStyle(color: Theme.of(context).hintColor)),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _finanzasBox(double totalVentas, double gastos, double ganancias) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GlassmorphicContainer(
      width: double.infinity,
      height: double.infinity,
      borderRadius: 20,
      blur: 20,
      alignment: Alignment.center,
      border: 1,
      linearGradient: LinearGradient(
        colors: isDark 
          ? [const Color(0x14FFFFFF), const Color(0x08FFFFFF)]
          : [Colors.white, Colors.white.withOpacity(0.9)],
      ),
      borderGradient: LinearGradient(
        colors: [
          isDark ? Colors.transparent : Colors.black12,
          Colors.transparent,
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Resumen Financiero",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    setState(() {
                      filtroFinanciero = value;
                    });
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: "Esta Semana",
                      child: Text("Esta Semana"),
                    ),
                    const PopupMenuItem(
                      value: "Este Mes",
                      child: Text("Este Mes"),
                    ),
                    const PopupMenuItem(
                      value: "Este Año",
                      child: Text("Este Año"),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0x0DFFFFFF) : Colors.black.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          filtroFinanciero,
                          style: const TextStyle(
                            color: Colors.blueAccent,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.blueAccent,
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _financeItem(
              "INGRESOS",
              "\$${totalVentas.toStringAsFixed(0)}",
              Theme.of(context).colorScheme.onSurface,
              Icons.payments,
              iconColor: Colors.blue,
              onTap: () => _showMonthlyBreakdownDialog('ingresos'),
            ),
            const SizedBox(height: 20),
            _financeItem(
              "GASTOS",
              "\$${gastos.toStringAsFixed(0)}",
              Colors.red,
              Icons.trending_down,
              onTap: () => _showMonthlyBreakdownDialog('gastos'),
            ),
            const SizedBox(height: 20),
            _financeItem(
              "GANANCIA",
              "\$${ganancias.toStringAsFixed(0)}",
              Colors.green,
              Icons.trending_up,
              onTap: () => _showMonthlyBreakdownDialog('ganancia'),
            ),
          ],
        ),
      ),
    );
  }
}
