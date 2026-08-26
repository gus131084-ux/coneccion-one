import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:google_fonts/google_fonts.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  final TextEditingController _searchController = TextEditingController();

  Color _textColor(BuildContext context) => Theme.of(context).colorScheme.onSurface;
  Color _mutedTextColor(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? Colors.white54 : const Color(0xFF64748B);
  bool _isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;

  String _searchQuery = "";

  // Listas para el formulario
  final List<String> marcas = [
    "Samsung", "Motorola", "Xiaomi", "iPhone", "Huawei", "LG", "Nokia",
    "Realme", "Oppo", "Vivo", "Sony", "ZTE", "Alcatel", "Tecno", "Infinix", "Otro"
  ];

  final Map<String, List<String>> modelosPorMarca = {
    "Samsung": ["A10", "A20", "A30", "A50", "S21", "S22", "S23", "S24", "Otro"],
    "Motorola": ["G8", "G9", "G10", "G20", "G30", "G54", "E13", "E20", "Edge 30", "Otro"],
    "Xiaomi": ["Redmi 9", "Redmi 10", "Note 10", "Note 11", "Note 12", "Poco X3", "Poco X5", "Otro"],
    "iPhone": ["6", "7", "8", "X", "11", "12", "13", "14", "15", "Otro"],
    "Huawei": ["P20 Lite", "P30 Lite", "P40", "Mate 20", "Otro"],
    "LG": ["K40", "K50", "G7", "Otro"],
    "Nokia": ["G20", "C30", "Otro"],
    "Realme": ["C11", "C25", "Otro"],
    "Oppo": ["A15", "A54", "Otro"],
    "Vivo": ["Y20", "V21", "Otro"],
    "Sony": ["Xperia 1", "Otro"],
    "ZTE": ["Blade A51", "V40", "Otro"],
    "Alcatel": ["1V", "3X", "Otro"],
    "Tecno": ["Spark 10", "Otro"],
    "Infinix": ["Hot 30", "Otro"],
    "Otro": ["Genérico"],
  };

  final List<String> fallasTipicas = [
    "Cambio de módulo", "Cambio de pin de carga", "Cambio de batería",
    "No enciende", "No carga", "Pantalla negra", "Se moja / Humedad",
    "Software / Cuenta Google", "Cambio de vidrio / Glass", "Cámaras",
    "Auricular / Micrófono", "Señal / Sin servicio", "Otro"
  ];

  final List<String> estados = ["Pendiente", "En reparación", "Entregado"];

  void _editarReparacion(String id, Map<String, dynamic> rep) {
    final preCtrl = TextEditingController(text: rep['presupuesto'].toString());
    final entCtrl = TextEditingController(text: rep['entrega'].toString());
    final falCtrl = TextEditingController(text: rep['falla']);
    final modCtrl = TextEditingController(text: rep['equipo']);
    String estadoSel = rep['estado'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text("Editar Reparación", style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _input("Equipo", modCtrl),
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
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  initialValue: estadoSel,
                  dropdownColor: const Color(0xFF2D2D2D),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: "Estado", labelStyle: TextStyle(color: Colors.white54)),
                  items: estados.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => setStateDialog(() => estadoSel = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance.collection('reparaciones').doc(id).update({
                  'equipo': modCtrl.text,
                  'falla': falCtrl.text,
                  'presupuesto': double.tryParse(preCtrl.text) ?? 0.0,
                  'entrega': double.tryParse(entCtrl.text) ?? 0.0,
                  'estado': estadoSel,
                });
                Navigator.pop(context);
                Navigator.pop(context); // Cerrar lista de equipos para refrescar
              },
              child: const Text("ACTUALIZAR"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textColor = _textColor(context);
    final mutedTextColor = _mutedTextColor(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 1200;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
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
                            "Gestión de Clientes",
                            style: GoogleFonts.poppins(
                              color: textColor,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "Listado completo de clientes",
                            style: TextStyle(
                              color: mutedTextColor,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _mostrarFormularioCliente(context),
                        icon: const Icon(
                          Icons.person_add_alt_1,
                          color: Colors.white,
                        ),
                        label: const Text(
                          "NUEVO CLIENTE",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 15,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Gestión de Clientes",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Listado completo de clientes",
                        style: TextStyle(
                          color: mutedTextColor,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _mostrarFormularioCliente(context),
                          icon: const Icon(
                            Icons.person_add_alt_1,
                            color: Colors.white,
                          ),
                          label: const Text(
                            "NUEVO CLIENTE",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B82F6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 15,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
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
                    .collection('clientes')
                    .orderBy('nombre')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF3B82F6),
                      ),
                    );
                  }

                  var docs = snapshot.data!.docs.where(
                    (doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return data['nombre']
                          .toString()
                          .toLowerCase()
                          .contains(_searchQuery.toLowerCase());
                    },
                  ).toList();

                  if (docs.isEmpty) {
                    return Center(
                      child: Text(
                        "No se encontraron clientes",
                        style: TextStyle(
                          color: mutedTextColor,
                        ),
                      ),
                    );
                  }

                  return GridView.builder(
                    padding: EdgeInsets.zero,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isLargeScreen ? 3 : 1,
                      crossAxisSpacing: isLargeScreen ? 20 : 10,
                      mainAxisSpacing: isLargeScreen ? 20 : 10,
                      childAspectRatio: isLargeScreen ? 2.5 : 3.0,
                    ),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      var cliente = docs[index].data() as Map<String, dynamic>;

                      return _buildClienteCard(
                        cliente,
                        docs[index].id,
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

  Widget _buildSearchBar() {
    final isDark = _isDark(context);
    return GlassmorphicContainer(
      width: double.infinity,
      height: 60,
      borderRadius: 15,
      blur: 15,
      alignment: Alignment.center,
      border: 1,
      linearGradient: LinearGradient(
        colors: [
          isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFFFFFFF),
          isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF8FAFC),
        ],
      ),
      borderGradient: LinearGradient(
        colors: [
          isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFD7E0EC),
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
            color: _textColor(context),
          ),
          decoration: InputDecoration(
            hintText: "Buscar cliente...",
            hintStyle: TextStyle(
              color: _mutedTextColor(context),
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

  Widget _buildClienteCard(
    Map<String, dynamic> cliente,
    String id,
  ) {
    final isDark = _isDark(context);
    return GestureDetector(
      onTap: () {
        _verEquiposCliente(
          cliente['nombre'],
        );
      },
      child: GlassmorphicContainer(
        width: double.infinity,
        height: 120,
        borderRadius: 20,
        blur: 20,
        alignment: Alignment.center,
        border: 1,
        linearGradient: LinearGradient(
          colors: [
            isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFFFFFFF),
            isDark ? Colors.white.withOpacity(0.02) : const Color(0xFFF8FAFC),
          ],
        ),
        borderGradient: LinearGradient(
          colors: [
            const Color(0xFF3B82F6).withOpacity(0.3),
            Colors.transparent,
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFF1E293B),
                radius: 25,
                child: Icon(
                  Icons.person,
                  color: Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      cliente['nombre'] ?? 'Sin Nombre',
                      style: TextStyle(
                        color: _textColor(context),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      cliente['telefono'] ?? 'Sin Teléfono',
                      style: TextStyle(
                        color: _mutedTextColor(context),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.edit_outlined,
                  color: _isDark(context) ? Colors.white70 : const Color(0xFF475569),
                ),
                onPressed: () {
                  _editarCliente(
                    id,
                    cliente,
                  );
                },
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.redAccent,
                ),
                onPressed: () {
                  _eliminarCliente(id);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarFormularioCliente(BuildContext context) {
    final nomCtrl = TextEditingController();
    final telCtrl = TextEditingController();
    final marCustomCtrl = TextEditingController();
    final modCustomCtrl = TextEditingController();
    final falCustomCtrl = TextEditingController();
    final preCtrl = TextEditingController();
    final entCtrl = TextEditingController();

    String? marSel = "Samsung";
    String? modSel = "A10";
    String? falSel = "Cambio de módulo";

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text(
            "Nuevo Cliente e Ingreso",
            style: TextStyle(
              color: Colors.white,
            ),
          ),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _input("Nombre del Cliente", nomCtrl),
                  const SizedBox(height: 15),
                  _input("Teléfono de Contacto", telCtrl),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(color: Colors.white24),
                  ),
                  
                  // Selector de Marca
                  DropdownButtonFormField<String>(
                    initialValue: marSel,
                    dropdownColor: const Color(0xFF2D2D2D),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: "Marca", labelStyle: TextStyle(color: Colors.white54)),
                    items: marcas.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                    onChanged: (v) => setStateDialog(() {
                      marSel = v;
                      modSel = (modelosPorMarca[v] ?? ["Otro"]).first;
                    }),
                  ),
                  if (marSel == "Otro") Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: _input("Especificar Marca", marCustomCtrl),
                  ),
                  const SizedBox(height: 15),

                  // Selector de Modelo
                  DropdownButtonFormField<String>(
                    initialValue: modSel,
                    dropdownColor: const Color(0xFF2D2D2D),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: "Modelo", labelStyle: TextStyle(color: Colors.white54)),
                    items: (modelosPorMarca[marSel] ?? ["Otro"]).map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                    onChanged: (v) => setStateDialog(() => modSel = v),
                  ),
                  if (modSel == "Otro") Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: _input("Especificar Modelo", modCustomCtrl),
                  ),
                  const SizedBox(height: 15),

                  // Selector de Falla
                  DropdownButtonFormField<String>(
                    initialValue: falSel,
                    dropdownColor: const Color(0xFF2D2D2D),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: "Falla típica", labelStyle: TextStyle(color: Colors.white54)),
                    items: fallasTipicas.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                    onChanged: (v) => setStateDialog(() => falSel = v),
                  ),
                  if (falSel == "Otro") Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: _input("Describir Falla", falCustomCtrl),
                  ),
                  const SizedBox(height: 15),

                  Row(
                    children: [
                      Expanded(
                        child: _input("Presupuesto", preCtrl, isNumber: true),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _input("Entrega", entCtrl, isNumber: true),
                      ),
                    ],
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
                // Guardar información del cliente
                await FirebaseFirestore.instance.collection('clientes').add({
                  'nombre': nomCtrl.text,
                  'telefono': telCtrl.text,
                  'fecha_registro': DateTime.now(),
                });

                // Determinar Marca, Modelo y Falla finales
                final marcaFinal = marSel == "Otro" ? marCustomCtrl.text : marSel;
                final modeloFinal = modSel == "Otro" ? modCustomCtrl.text : modSel;
                final fallaFinal = falSel == "Otro" ? falCustomCtrl.text : falSel;
                final equipoCompleto = "$marcaFinal $modeloFinal".trim();

                // Crear automáticamente la orden de reparación vinculada
                if (equipoCompleto.isNotEmpty || fallaFinal != null) {
                  await FirebaseFirestore.instance.collection('reparaciones').add({
                    'cliente': nomCtrl.text,
                    'equipo': equipoCompleto,
                    'falla': fallaFinal,
                    'presupuesto': double.tryParse(preCtrl.text) ?? 0.0,
                    'entrega': double.tryParse(entCtrl.text) ?? 0.0,
                    'estado': 'Pendiente',
                    'fecha_ingreso': DateTime.now(),
                  });
                }

                Navigator.pop(context);
              },
              child: const Text("GUARDAR"),
            ),
          ],
        ),
      ),
    );
  }

  void _editarCliente(
    String id,
    Map<String, dynamic> cliente,
  ) {
    final nomCtrl = TextEditingController(
      text: cliente['nombre'],
    );

    final telCtrl = TextEditingController(
      text: cliente['telefono'],
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          "Editar Cliente",
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _input(
              "Nombre",
              nomCtrl,
            ),
            const SizedBox(height: 15),
            _input(
              "Teléfono",
              telCtrl,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('clientes')
                  .doc(id)
                  .update({
                'nombre': nomCtrl.text,
                'telefono': telCtrl.text,
              });

              // Actualizar también el nombre del cliente en todas sus reparaciones
              final reps = await FirebaseFirestore.instance
                  .collection('reparaciones')
                  .where('cliente', isEqualTo: cliente['nombre'])
                  .get();
              
              for (var doc in reps.docs) {
                await doc.reference.update({'cliente': nomCtrl.text});
              }

              Navigator.pop(context);
            },
            child: const Text("GUARDAR"),
          ),
        ],
      ),
    );
  }

  void _eliminarCliente(String id) async {
    await FirebaseFirestore.instance.collection('clientes').doc(id).delete();
  }

  void _verEquiposCliente(
    String nombreCliente,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: Text(
            "Equipos de $nombreCliente",
            style: const TextStyle(
              color: Colors.white,
            ),
          ),
          content: SizedBox(
            width: 500,
            height: 400,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('reparaciones')
                  .where(
                    'cliente',
                    isEqualTo: nombreCliente,
                  )
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                var docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "No hay equipos",
                      style: TextStyle(
                        color: Colors.white54,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var rep = docs[index].data() as Map<String, dynamic>;

                    return ListTile(
                      leading: const Icon(
                        Icons.smartphone,
                        color: Color(0xFF3B82F6),
                      ),
                      title: Text(
                        rep['equipo'],
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blueAccent, size: 20),
                        onPressed: () => _editarReparacion(docs[index].id, rep),
                      ),
                      subtitle: Text(
                        "${rep['falla']} - ${rep['estado']}",
                        style: const TextStyle(
                          color: Colors.white54,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cerrar"),
            ),
          ],
        );
      },
    );
  }

  Widget _input(
    String label,
    TextEditingController controller, {
    bool isNumber = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(
        color: Colors.white,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Colors.white54,
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xFF3B82F6),
          ),
        ),
      ),
    );
  }
}
