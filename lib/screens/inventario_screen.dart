import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:google_fonts/google_fonts.dart';

class InventarioScreen extends StatefulWidget {
  const InventarioScreen({super.key});

  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen> {
  final CollectionReference inventarioRef =
      FirebaseFirestore.instance.collection('inventario');

  void _mostrarDialogoProducto({DocumentSnapshot? producto}) {
    final dataMap = producto?.data() as Map<String, dynamic>?;
    final nombreCtrl = TextEditingController(
      text: dataMap?['nombre'] ?? '',
    );

    final stockCtrl = TextEditingController(
      text: dataMap?['stock']?.toString() ?? '',
    );

    final precioCtrl = TextEditingController(
      text: dataMap?['precio']?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (_) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: Theme.of(context).dialogBackgroundColor,
          title: Text(
            producto == null
                ? "Agregar Producto"
                : "Editar Producto",
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
          content: SizedBox(
            width: 350,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombreCtrl,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  decoration: _inputDeco("Nombre"),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: stockCtrl,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  decoration: _inputDeco("Stock"),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: precioCtrl,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  decoration: _inputDeco("Precio"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () async {
                final data = {
                  'nombre': nombreCtrl.text,
                  'stock': int.tryParse(stockCtrl.text) ?? 0,
                  'precio': double.tryParse(precioCtrl.text) ?? 0,
                };

                if (producto == null) {
                  await inventarioRef.add(data);
                } else {
                  await inventarioRef
                      .doc(producto.id)
                      .update(data);
                }

                Navigator.pop(context);
              },
              child: const Text("Guardar"),
            ),
          ],
        );
      },
    );
  }

  void _eliminarProducto(String id) async {
    await inventarioRef.doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 1200;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(isLargeScreen ? 30.0 : 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Inventario",
              style: GoogleFonts.poppins(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: isLargeScreen ? 28 : 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "Gestión de repuestos y stock",
              style: TextStyle(
                color: Theme.of(context).hintColor,
              ),
            ),
            SizedBox(height: isLargeScreen ? 25 : 20),

            SizedBox(
              width: isLargeScreen ? 200 : double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _mostrarDialogoProducto(),
                icon: const Icon(Icons.add),
                label: const Text("Agregar Producto"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                ),
              ),
            ),

            SizedBox(height: isLargeScreen ? 25 : 20),

            StreamBuilder<QuerySnapshot>(
              stream: inventarioRef.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      "Error al cargar inventario",
                      style: TextStyle(color: Colors.red),
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final productos = snapshot.data!.docs;

                if (productos.isEmpty) {
                  return const Center(
                    child: Text(
                      "No hay productos cargados",
                      style: TextStyle(color: Colors.white24),
                    ),
                  );
                }

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: productos.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isLargeScreen ? 3 : 1,
                    crossAxisSpacing: isLargeScreen ? 20 : 10,
                    mainAxisSpacing: isLargeScreen ? 20 : 10,
                    childAspectRatio: isLargeScreen ? 1.5 : 2.0,
                  ),
                  itemBuilder: (context, index) {
                    final producto = productos[index];
                    final data = producto.data() as Map<String, dynamic>;

                    return GlassmorphicContainer(
                      width: double.infinity,
                      height: 200.0,
                      borderRadius: 20,
                      blur: 15,
                      alignment: Alignment.center,
                      border: 1,
                      linearGradient: LinearGradient(
                        colors: [
                          isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
                          isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
                        ],
                      ),
                      borderGradient: LinearGradient(
                        colors: [
                          isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
                          Colors.transparent,
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['nombre'] ?? 'Sin nombre',
                              style: GoogleFonts.poppins(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const Spacer(),

                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "Stock: ${data['stock'] ?? 0} ",
                                style: TextStyle(
                                  fontFamily: 'WhiskeyGirlsCondensedItalic',
                                  letterSpacing: 0.0,
                                  color: Theme.of(context).hintColor,
                                ),
                              ),
                            ),

                            const SizedBox(height: 5),

                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "Precio: \$${data['precio'] ?? 0.0} ",
                                style: const TextStyle(
                                  fontFamily: 'WhiskeyGirlsCondensedItalic',
                                  letterSpacing: 0.0,
                                  color: Colors.green,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ),

                            const SizedBox(height: 15),

                            Row(
                              children: [
                                Flexible(
                                  child: ElevatedButton(
                                    onPressed: () => _mostrarDialogoProducto(
                                      producto: producto,
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                    ),
                                    child: const Text("Editar"),
                                  ),
                                ),

                                const SizedBox(width: 10),

                                Flexible(
                                  child: ElevatedButton(
                                    onPressed: () => _eliminarProducto(producto.id),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                    child: const Text("Eliminar"),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
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
      );
}
