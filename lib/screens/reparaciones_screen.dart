import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:google_fonts/google_fonts.dart';

class ReparacionesScreen extends StatefulWidget {
  const ReparacionesScreen({super.key});

  @override
  State<ReparacionesScreen> createState() => _ReparacionesScreenState();
}

class _ReparacionesScreenState extends State<ReparacionesScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = "";

  // =========================
  // MARCAS
  // =========================

  final List<String> marcas = [
    "Samsung",
    "Motorola",
    "Xiaomi",
    "iPhone",
    "Huawei",
    "LG",
    "Nokia",
    "Realme",
    "Oppo",
    "Vivo",
    "Sony",
    "ZTE",
    "Alcatel",
    "Tecno",
    "Infinix",
  ];

  // =========================
  // MODELOS
  // =========================

  final Map<String, List<String>> modelosPorMarca = {
    "Samsung": [
      "Galaxy S20",
      "Galaxy S20 FE",
      "Galaxy S21",
      "Galaxy S21 FE",
      "Galaxy S22",
      "Galaxy S22 Ultra",
      "Galaxy S23",
      "Galaxy S23 Ultra",
      "Galaxy S24",
      "Galaxy S24 Ultra",
      "Galaxy A04",
      "Galaxy A04e",
      "Galaxy A05",
      "Galaxy A05s",
      "Galaxy A10",
      "Galaxy A10s",
      "Galaxy A11",
      "Galaxy A12",
      "Galaxy A13",
      "Galaxy A14",
      "Galaxy A15",
      "Galaxy A20",
      "Galaxy A20s",
      "Galaxy A21",
      "Galaxy A22",
      "Galaxy A23",
      "Galaxy A24",
      "Galaxy A30",
      "Galaxy A30s",
      "Galaxy A31",
      "Galaxy A32",
      "Galaxy A33",
      "Galaxy A34",
      "Galaxy A40",
      "Galaxy A41",
      "Galaxy A50",
      "Galaxy A51",
      "Galaxy A52",
      "Galaxy A53",
      "Galaxy A54",
      "Galaxy A70",
      "Galaxy A71",
      "Galaxy A72",
      "Galaxy A73",
      "Galaxy M12",
      "Galaxy M13",
      "Galaxy M14",
      "Galaxy M21",
      "Galaxy M31",
      "Galaxy M32",
      "Galaxy M33",
      "Galaxy M53",
      "Galaxy Z Flip",
      "Galaxy Z Flip 3",
      "Galaxy Z Flip 4",
      "Galaxy Z Fold",
      "Galaxy Z Fold 2",
      "Otro",
    ],
    "Motorola": [
      "Moto G5",
      "Moto G6",
      "Moto G7",
      "Moto G8",
      "Moto G9",
      "Moto G10",
      "Moto G10 Power",
      "Moto G20",
      "Moto G22",
      "Moto G23",
      "Moto G24",
      "Moto G30",
      "Moto G31",
      "Moto G32",
      "Moto G41",
      "Moto G42",
      "Moto G52",
      "Moto G54",
      "Moto G60",
      "Moto G71",
      "Moto G72",
      "Moto G82",
      "Moto E6",
      "Moto E7",
      "Moto E13",
      "Moto E20",
      "Moto E22",
      "Moto Edge 20",
      "Moto Edge 30",
      "Moto Edge 40",
      "Moto Edge 50",
      "Moto One",
      "Moto One Fusion",
      "Moto One Hyper",
      "Moto One Action",
      "Moto Razr",
      "Otro",
    ],
    "Xiaomi": [
      "Redmi 8",
      "Redmi 8A",
      "Redmi 9",
      "Redmi 10",
      "Redmi 12",
      "Redmi 12C",
      "Redmi Note 7",
      "Redmi Note 8",
      "Redmi Note 8 Pro",
      "Redmi Note 9",
      "Redmi Note 10",
      "Redmi Note 10 Pro",
      "Redmi Note 11",
      "Redmi Note 11 Pro",
      "Redmi Note 12",
      "Redmi Note 12 Pro",
      "Redmi Note 13",
      "Poco X2",
      "Poco X3",
      "Poco X4",
      "Poco X5",
      "Poco X6",
      "Poco X6 Pro",
      "Poco M5",
      "Poco M6",
      "Poco F3",
      "Poco F4",
      "Mi 10",
      "Mi 11",
      "Mi 12",
      "Mi 13",
      "Otro",
    ],
    "iPhone": [
      "iPhone 6",
      "iPhone 6S",
      "iPhone 7",
      "iPhone 7 Plus",
      "iPhone 8",
      "iPhone 8 Plus",
      "iPhone X",
      "iPhone XR",
      "iPhone XS",
      "iPhone 11",
      "iPhone 11 Pro",
      "iPhone 12",
      "iPhone 12 mini",
      "iPhone 12 Pro",
      "iPhone 13",
      "iPhone 13 mini",
      "iPhone 13 Pro",
      "iPhone 14",
      "iPhone 14 Plus",
      "iPhone 14 Pro",
      "iPhone 15",
      "iPhone 15 Plus",
      "iPhone 15 Pro",
      "iPhone 15 Pro Max",
      "iPhone SE",
      "iPhone SE 2",
      "iPhone SE 3",
      "Otro",
    ],
    "Huawei": [
      "P10",
      "P20",
      "P20 Lite",
      "P30",
      "P30 Lite",
      "P40",
      "P40 Lite",
      "P50",
      "Mate 10",
      "Mate 10 Pro",
      "Mate 20",
      "Mate 30",
      "Mate 40",
      "Nova 8",
      "Nova 9",
      "Nova 10",
      "Otro",
    ],
    "LG": [
      "K10",
      "K40",
      "K50",
      "K61",
      "G6",
      "G7 ThinQ",
      "G8",
      "V30",
      "Otro",
    ],
    "Nokia": [
      "Nokia 5.3",
      "Nokia 6.1",
      "Nokia 6.2",
      "Nokia 7.2",
      "Nokia 8.3",
      "Nokia G20",
      "Nokia G21",
      "Nokia C20",
      "Nokia C30",
      "Otro",
    ],
    "Realme": [
      "Realme C11",
      "Realme C25",
      "Realme C55",
      "Realme 8 Pro",
      "Realme 9",
      "Realme 10",
      "Realme GT 2",
      "Realme 11",
      "Otro",
    ],
    "Oppo": [
      "Oppo A15",
      "Oppo A57",
      "Oppo Reno 7",
      "Oppo A54",
      "Oppo Reno 8",
      "Oppo Reno 9",
      "Oppo Find X2",
    ],
    "Vivo": [
      "Vivo Y20",
      "Vivo Y22",
      "Vivo Y35",
      "Vivo Y33s",
      "Vivo Y55",
      "Vivo V15",
      "Vivo V21",
    ],
    "Sony": [
      "Xperia 1",
      "Xperia 5",
      "Xperia XA",
    ],
    "ZTE": [
      "Axon 20",
      "Blade A31",
      "Blade A72",
      "Blade V40",
      "Otro",
    ],
    "Alcatel": [
      "1B",
      "1S",
      "1V",
      "3X",
      "Otro",
    ],
    "Tecno": [
      "Spark 9",
      "Spark 10",
      "Camon 19",
      "Camon 20",
      "Otro",
    ],
    "Infinix": [
      "Hot 30",
      "Hot 30i",
      "Note 11",
      "Note 12",
      "Note 12 Pro",
      "Otro",
    ],
  };

  // =========================
  // FALLAS
  // =========================

  final List<String> fallas = [
    "Cambio de módulo",
    "Cambio de batería",
    "No carga",
    "Pin de carga roto",
    "No enciende",
    "Reinicio constante",
    "Pantalla negra",
    "Se moja",
    "Cambio de tapa",
    "Cambio de cámara",
    "Cambio de auricular",
    "Cambio de micrófono",
    "Sin señal",
    "Problema de software",
    "Cuenta Google",
    "FRP",
    "Liberación",
    "Actualización",
    "Placa dañada",
    "Cambio de flex",
    "Face ID",
    "Huella digital",
    "Problema de audio",
    "No reconoce SIM",
    "Sobrecalentamiento",
    "Cambio de vidrio",
    "Cambio de táctil",
    "Wifi no funciona",
    "Bluetooth no funciona",
    "No vibra",
    "No da imagen",
    "Equipo doblado",
    "Batería hinchada",
  ];

  final List<String> estados = [
    "Pendiente",
    "En reparación",
    "Entregado",
  ];

  void _editarReparacionCompleta(String id, Map<String, dynamic> rep) {
    final cliCtrl = TextEditingController(text: rep['cliente']);
    final equCtrl = TextEditingController(text: rep['equipo']);
    final falCtrl = TextEditingController(text: rep['falla']);
    final preCtrl = TextEditingController(text: rep['presupuesto'].toString());
    final entCtrl = TextEditingController(text: rep['entrega'].toString());
    final imeCtrl = TextEditingController(text: rep['imei'] ?? '');
    final obsCtrl = TextEditingController(text: rep['observaciones'] ?? '');
    String estSel = rep['estado'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text("Editar Reparación Completa"),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 450,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _input("Cliente", cliCtrl),
                  const SizedBox(height: 10),
                  _input("Equipo", equCtrl),
                  const SizedBox(height: 10),
                  _input("Falla", falCtrl),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _input("Presupuesto", preCtrl, isNumber: true)),
                      const SizedBox(width: 10),
                      Expanded(child: _input("Entrega", entCtrl, isNumber: true)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _input("IMEI", imeCtrl),
                  const SizedBox(height: 10),
                  _input("Observaciones", obsCtrl),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    initialValue: estSel,
                    dropdownColor: Theme.of(context).canvasColor,
                    decoration: const InputDecoration(labelText: "Estado"),
                    items: estados.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => setStateDialog(() => estSel = v!),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance.collection('reparaciones').doc(id).update({
                  'cliente': cliCtrl.text,
                  'equipo': equCtrl.text,
                  'falla': falCtrl.text,
                  'presupuesto': double.tryParse(preCtrl.text) ?? 0.0,
                  'entrega': double.tryParse(entCtrl.text) ?? 0.0,
                  'imei': imeCtrl.text,
                  'observaciones': obsCtrl.text,
                  'estado': estSel,
                });
                Navigator.pop(context);
              },
              child: const Text("GUARDAR CAMBIOS"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 1200;

    return Padding(
      padding: EdgeInsets.all(isLargeScreen ? 30.0 : 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          isLargeScreen
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Órdenes de Reparación",
                          style: GoogleFonts.poppins(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Seguimiento de equipos",
                          style: TextStyle(
                            color: Theme.of(context).hintColor,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _mostrarFormularioReparacion(context),
                      icon: const Icon(
                        Icons.add,
                        color: Colors.white,
                      ),
                      label: const Text(
                        "NUEVO INGRESO",
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Órdenes de Reparación",
                      style: GoogleFonts.poppins(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Seguimiento de equipos",
                      style: TextStyle(
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _mostrarFormularioReparacion(context),
                        icon: const Icon(
                          Icons.add,
                          color: Colors.white,
                        ),
                        label: const Text(
                          "NUEVO INGRESO",
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                        ),
                      ),
                    ),
                  ],
                ),
          SizedBox(height: isLargeScreen ? 30 : 20),
          _buildSearchBar(),
          SizedBox(height: isLargeScreen ? 25 : 20),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('reparaciones')
                  .orderBy(
                    'fecha_ingreso',
                    descending: true,
                  )
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                var docs = snapshot.data!.docs.where(
                  (doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return data['equipo']
                            .toString()
                            .toLowerCase()
                            .contains(_searchQuery.toLowerCase()) ||
                        data['cliente']
                            .toString()
                            .toLowerCase()
                            .contains(_searchQuery.toLowerCase());
                  },
                ).toList();

                if (docs.isEmpty) {
                  return Center(
                    child: Text(
                      "No se encontraron reparaciones",
                      style: TextStyle(
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var rep = docs[index].data() as Map<String, dynamic>;

                    return _buildReparacionCard(
                      rep,
                      docs[index].id,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GlassmorphicContainer(
      width: double.infinity,
      height: 60,
      borderRadius: 15,
      blur: 15,
      alignment: Alignment.center,
      border: 1,
      linearGradient: LinearGradient(
        colors: isDark 
          ? [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)]
          : [Colors.white, Colors.white.withOpacity(0.8)],
      ),
      borderGradient: LinearGradient(
        colors: [
          isDark ? Colors.white.withOpacity(0.1) : Colors.black12,
          Colors.transparent,
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            hintText: "Buscar equipo o cliente...",
            hintStyle: TextStyle(
              color: Theme.of(context).hintColor.withOpacity(0.5),
            ),
            border: InputBorder.none,
            icon: Icon(
              Icons.search,
              color: Color(0xFF3B82F6),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReparacionCard(
    Map<String, dynamic> rep,
    String id,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 1200;

    Color estadoColor = Colors.orange;

    if (rep['estado'] == 'En reparación') {
      estadoColor = Colors.blue;
    }

    if (rep['estado'] == 'Entregado') {
      estadoColor = Colors.green;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: GlassmorphicContainer(
        width: double.infinity,
        height: isLargeScreen ? 120 : 140,
        borderRadius: 20,
        blur: 20,
        alignment: Alignment.center,
        border: 1,
        linearGradient: LinearGradient(
          colors: Theme.of(context).brightness == Brightness.dark
            ? [Colors.white.withOpacity(0.08), Colors.white.withOpacity(0.03)]
            : [Colors.white, Colors.white.withOpacity(0.9)],
        ),
        borderGradient: LinearGradient(
          colors: [
            estadoColor.withOpacity(0.3),
            Colors.transparent,
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 15,
          ),
          child: isLargeScreen
              ? Row(
                  children: [
                    Icon(
                      Icons.smartphone,
                      color: estadoColor,
                      size: 30,
                    ),
                    const SizedBox(width: 20),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            rep['equipo'],
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            "Cliente: ${rep['cliente']}",
                            style: TextStyle(
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                          Text(
                            rep['falla'],
                            style: TextStyle(
                              color: Theme.of(context).hintColor.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 15),
                    IconButton(
                      icon: const Icon(
                        Icons.edit_note,
                        color: Colors.blueAccent,
                      ),
                      onPressed: () => _editarReparacionCompleta(id, rep),
                    ),
                    const SizedBox(width: 5),
                    DropdownButton<String>(
                      value: rep['estado'],
                      dropdownColor: Theme.of(context).canvasColor,
                      style: TextStyle(
                        color: estadoColor,
                        fontWeight: FontWeight.bold,
                      ),
                      underline: Container(),
                      items: estados.map(
                        (estado) {
                          return DropdownMenuItem(
                            value: estado,
                            child: Text(estado),
                          );
                        },
                      ).toList(),
                      onChanged: (value) async {
                        await FirebaseFirestore.instance
                            .collection('reparaciones')
                            .doc(id)
                            .update({
                          'estado': value,
                        });
                      },
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                      ),
                      onPressed: () => _confirmarEliminacion(id),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.smartphone,
                          color: estadoColor,
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            rep['equipo'],
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton(
                          icon: const Icon(
                            Icons.edit_note,
                            color: Colors.blueAccent,
                            size: 20,
                          ),
                          onPressed: () => _editarReparacionCompleta(id, rep),
                        ),
                        DropdownButton<String>(
                          value: rep['estado'],
                          dropdownColor: Theme.of(context).canvasColor,
                          style: TextStyle(
                            color: estadoColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          underline: Container(),
                          items: estados.map(
                            (estado) {
                              return DropdownMenuItem(
                                value: estado,
                                child: Text(estado),
                              );
                            },
                          ).toList(),
                          onChanged: (value) async {
                            await FirebaseFirestore.instance
                                .collection('reparaciones')
                                .doc(id)
                                .update({
                              'estado': value,
                            });
                          },
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                            size: 20,
                          ),
                          onPressed: () => _confirmarEliminacion(id),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Cliente: ${rep['cliente']}",
                      style: TextStyle(
                        color: Theme.of(context).hintColor,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "Falla: ${rep['falla']}",
                      style: TextStyle(
                        color: Theme.of(context).hintColor.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  void _confirmarEliminacion(String id) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            "Eliminar Reparación",
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
          content: Text(
            "¿Estás seguro de que deseas eliminar esta reparación?",
            style: TextStyle(color: Theme.of(context).hintColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CANCELAR"),
            ),
            TextButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('reparaciones')
                    .doc(id)
                    .delete();
                if (mounted) Navigator.pop(context);
              },
              child: const Text(
                "ELIMINAR",
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );
  }

  void _mostrarFormularioReparacion(BuildContext context) {
    final clienteCtrl = TextEditingController();
    final imeiCtrl = TextEditingController();
    final observacionesCtrl = TextEditingController();
    final modeloCustomCtrl = TextEditingController();
    final marcaCustomCtrl = TextEditingController();
    final preCtrl = TextEditingController();
    final entCtrl = TextEditingController();

    String marcaSeleccionada = "Samsung";

    String modeloSeleccionado = "Galaxy S23";

    String fallaSeleccionada = "Cambio de módulo";

    String estadoSeleccionado = "Pendiente";

    String? clienteSeleccionado;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(
                "Registrar Ingreso",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 450,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: marcaSeleccionada,
                        dropdownColor: Theme.of(context).canvasColor,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        decoration: InputDecoration(
                          labelText: "Marca",
                          labelStyle: TextStyle(color: Theme.of(context).hintColor),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Theme.of(context).dividerColor),
                          ),
                        ),
                        items: marcas.map(
                          (marca) {
                            return DropdownMenuItem(
                              value: marca,
                              child: Text(marca),
                            );
                          },
                        ).toList(),
                        onChanged: (value) {
                          setStateDialog(() {
                            marcaSeleccionada = value!;

                            modeloSeleccionado =
                                modelosPorMarca[marcaSeleccionada]!.first;
                          });
                        },
                      ),
                      if (marcaSeleccionada == 'Otro') ...[
                        const SizedBox(height: 15),
                        _input(
                          "Marca (especificar)",
                          marcaCustomCtrl,
                        ),
                      ],
                      const SizedBox(height: 15),
                      DropdownButtonFormField<String>(
                        initialValue: modeloSeleccionado,
                        dropdownColor: Theme.of(context).canvasColor,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        decoration: InputDecoration(
                          labelText: "Modelo",
                          labelStyle: TextStyle(color: Theme.of(context).hintColor),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Theme.of(context).dividerColor),
                          ),
                        ),
                        items: modelosPorMarca[marcaSeleccionada]!.map(
                          (modelo) {
                            return DropdownMenuItem(
                              value: modelo,
                              child: Text(modelo),
                            );
                          },
                        ).toList(),
                        onChanged: (value) {
                          setStateDialog(() {
                            modeloSeleccionado = value!;
                          });
                        },
                      ),
                      if (modeloSeleccionado == 'Otro' || modeloSeleccionado == 'Genérico') ...[
                        const SizedBox(height: 15),
                        _input(
                          "Modelo (otro)",
                          modeloCustomCtrl,
                        ),
                      ],
                      const SizedBox(height: 15),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('clientes')
                            .orderBy('nombre')
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const SizedBox.shrink();
                          }

                          final clientes = snapshot.data!.docs;
                          final nombresClientes = clientes
                              .map((doc) {
                                final d = doc.data() as Map<String, dynamic>;
                                return d['nombre'].toString();
                              })
                              .toList();

                          return DropdownButtonFormField<String>(
                            initialValue: clienteSeleccionado,
                            dropdownColor: Theme.of(context).canvasColor,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            decoration: InputDecoration(
                              labelText: "Cliente existente",
                              hintText: "Seleccionar cliente guardado",
                              labelStyle: TextStyle(color: Theme.of(context).hintColor),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Theme.of(context).dividerColor),
                              ),
                            ),
                            items: nombresClientes.map((nombre) {
                              return DropdownMenuItem(
                                value: nombre,
                                child: Text(nombre),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setStateDialog(() {
                                clienteSeleccionado = value;
                                if (value != null) {
                                  clienteCtrl.text = value;
                                }
                              });
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 15),
                      _input(
                        "Cliente",
                        clienteCtrl,
                      ),
                      const SizedBox(height: 15),
                      DropdownButtonFormField<String>(
                        initialValue: fallaSeleccionada,
                        dropdownColor: Theme.of(context).canvasColor,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        decoration: InputDecoration(
                          labelText: "Falla",
                          labelStyle: TextStyle(color: Theme.of(context).hintColor),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Theme.of(context).dividerColor),
                          ),
                        ),
                        items: fallas.map(
                          (falla) {
                            return DropdownMenuItem(
                              value: falla,
                              child: Text(falla),
                            );
                          },
                        ).toList(),
                        onChanged: (value) {
                          setStateDialog(() {
                            fallaSeleccionada = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(
                            child: _input(
                              "Presupuesto",
                              preCtrl,
                              isNumber: true,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _input(
                              "Entrega",
                              entCtrl,
                              isNumber: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      _input(
                        "IMEI",
                        imeiCtrl,
                      ),
                      const SizedBox(height: 15),
                      _input(
                        "Observaciones",
                        observacionesCtrl,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancelar"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final clienteExiste = await FirebaseFirestore.instance
                        .collection('clientes')
                        .where(
                          'nombre',
                          isEqualTo: clienteCtrl.text,
                        )
                        .get();

                    if (clienteExiste.docs.isEmpty) {
                      await FirebaseFirestore.instance
                          .collection('clientes')
                          .add({
                        'nombre': clienteCtrl.text,
                        'telefono': '',
                        'fecha_registro': DateTime.now(),
                      });
                    }

                    final marcaFinal = marcaSeleccionada == 'Otro'
                        ? marcaCustomCtrl.text.trim().isNotEmpty
                            ? marcaCustomCtrl.text.trim()
                            : 'Otro'
                        : marcaSeleccionada;

                    final modeloFinal = (modeloSeleccionado == 'Otro' || modeloSeleccionado == 'Genérico')
                        ? modeloCustomCtrl.text.trim().isNotEmpty
                            ? modeloCustomCtrl.text.trim()
                            : modeloSeleccionado
                        : modeloSeleccionado;

                    await FirebaseFirestore.instance
                        .collection('reparaciones')
                        .add({
                      'equipo': "$marcaFinal $modeloFinal",
                      'marca': marcaFinal,
                      'modelo': modeloFinal,
                      'cliente': clienteCtrl.text,
                      'falla': fallaSeleccionada,
                      'estado': estadoSeleccionado,
                      'imei': imeiCtrl.text,
                      'observaciones': observacionesCtrl.text,
                      'presupuesto': double.tryParse(preCtrl.text) ?? 0.0,
                      'entrega': double.tryParse(entCtrl.text) ?? 0.0,
                      'fecha_ingreso': DateTime.now(),
                    });

                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                  ),
                  child: const Text(
                    "REGISTRAR",
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _input(
    String label,
    TextEditingController controller, {
    bool isNumber = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Theme.of(context).hintColor,
        ),
        filled: true,
        fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Colors.blueAccent,
          ),
        ),
      ),
    );
  }
}
