import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() =>
      _DashboardScreenState();
}

class _DashboardScreenState
    extends State<DashboardScreen> {
  String _filtroFinanzas = "Este Mes";
  String _nombreAdmin = "Admin";

  @override
  void initState() {
    super.initState();
    _cargarNombreAdmin();
  }

  Future<void> _cargarNombreAdmin() async {
    final doc = await FirebaseFirestore.instance
        .collection('configuracion')
        .doc('general')
        .get();
    if (doc.exists && doc.data()?['nombreAdmin'] != null) {
      setState(() {
        _nombreAdmin = doc.data()!['nombreAdmin'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F172A),
              Color(0xFF020617),
            ],
          ),
        ),
        child: Row(
          children: [
            const SidebarWidget(),

            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 25,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      HeaderWidget(nombreAdmin: _nombreAdmin),

                      const SizedBox(height: 35),

                      // ===== CARDS SUPERIORES =====

                      Row(
                        children: [
                          Expanded(
                            child: _buildMiniAcceso(
                              "Clientes",
                              Icons.people_outline,
                              Colors.blue,
                            ),
                          ),

                          const SizedBox(width: 15),

                          Expanded(
                            child: _buildMiniAcceso(
                              "Reparaciones",
                              Icons.build_circle_outlined,
                              Colors.orange,
                            ),
                          ),

                          const SizedBox(width: 15),

                          Expanded(
                            child: _buildMiniAcceso(
                              "Ventas",
                              Icons.shopping_cart_outlined,
                              Colors.green,
                            ),
                          ),

                          const SizedBox(width: 15),

                          Expanded(
                            child: _buildMiniAcceso(
                              "Inventario",
                              Icons
                                  .inventory_2_outlined,
                              Colors.purple,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 25),

                      // ===== FINANZAS =====

                      _buildFinanzasInteligentes(),

                      const SizedBox(height: 25),

                      // ===== PARTE INFERIOR =====

                      Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Expanded(
                            flex: 2,
                            child:
                                GlassRecentOrders(),
                          ),

                          const SizedBox(width: 20),

                          const Expanded(
                            flex: 1,
                            child:
                                GlassInventorySummary(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== CARDS PEQUEÑAS =====

  Widget _buildMiniAcceso(
    String title,
    IconData icon,
    Color color,
  ) {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 115,
      borderRadius: 20,
      blur: 20,
      alignment: Alignment.center,
      border: 1,
      linearGradient: LinearGradient(
        colors: [
          Colors.white.withOpacity(0.08),
          Colors.white.withOpacity(0.03),
        ],
      ),
      borderGradient: LinearGradient(
        colors: [
          color.withOpacity(0.5),
          Colors.transparent,
        ],
      ),
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Container(
            padding:
                const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius:
                  BorderRadius.circular(15),
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ===== TARJETA FINANZAS =====

  Widget _buildFinanzasInteligentes() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('facturas')
          .snapshots(),
      builder: (context, snapshot) {
        double ingresos = 0;
        double gastos = 0;

        if (snapshot.hasData) {
          final ahora = DateTime.now();

          for (var doc
              in snapshot.data!.docs) {
            final data =
                doc.data()
                    as Map<String, dynamic>;

            DateTime fecha =
                (data['fecha']
                        as Timestamp)
                    .toDate();

            bool incluir = false;

            if (_filtroFinanzas ==
                "Esta Semana") {
              incluir = fecha.isAfter(
                ahora.subtract(
                  const Duration(days: 7),
                ),
              );
            } else if (_filtroFinanzas ==
                "Este Mes") {
              incluir =
                  fecha.month ==
                          ahora.month &&
                      fecha.year ==
                          ahora.year;
            } else {
              incluir =
                  fecha.year ==
                      ahora.year;
            }

            if (incluir) {
              ingresos +=
                  (data['total'] ?? 0)
                      .toDouble();

              gastos +=
                  ((data['gastos'] ?? 0)
                          as num)
                      .toDouble();
            }
          }
        }

        double ganancia =
            ingresos - gastos;

        return GlassmorphicContainer(
          width: double.infinity,
          height: 230,
          borderRadius: 25,
          blur: 20,
          alignment: Alignment.topLeft,
          border: 1,
          linearGradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.08),
              Colors.white.withOpacity(0.03),
            ],
          ),
          borderGradient: LinearGradient(
            colors: [
              Colors.greenAccent
                  .withOpacity(0.4),
              Colors.transparent,
            ],
          ),
          child: Padding(
            padding:
                const EdgeInsets.all(25),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Text(
                          "Resumen Financiero",
                          style: TextStyle(
                            color:
                                Colors.white,
                            fontSize: 22,
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),

                        SizedBox(height: 4),

                        Text(
                          "Ingresos, gastos y ganancias",
                          style: TextStyle(
                            color:
                                Colors.white54,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),

                    Container(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 15,
                        vertical: 5,
                      ),
                      decoration:
                          BoxDecoration(
                        color: Colors.white
                            .withOpacity(
                                0.05),
                        borderRadius:
                            BorderRadius
                                .circular(
                                    12),
                      ),
                      child:
                          DropdownButton<
                              String>(
                        value:
                            _filtroFinanzas,
                        dropdownColor:
                            const Color(
                                0xFF1E293B),
                        underline:
                            const SizedBox(),
                        icon: const Icon(
                          Icons
                              .keyboard_arrow_down,
                          color: Colors
                              .greenAccent,
                        ),
                        style:
                            const TextStyle(
                          color: Colors
                              .greenAccent,
                          fontWeight:
                              FontWeight
                                  .bold,
                        ),
                        onChanged: (val) {
                          setState(() {
                            _filtroFinanzas =
                                val!;
                          });
                        },
                        items: [
                          "Esta Semana",
                          "Este Mes",
                          "Este Año",
                        ]
                            .map(
                              (e) =>
                                  DropdownMenuItem(
                                value: e,
                                child: Text(e),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildFinanceCard(
                          "Ingresos",
                          "\$${ingresos.toStringAsFixed(0)}",
                          Icons.trending_up,
                          Colors.white,
                        ),
                      ),

                      const SizedBox(height: 18),

                      Expanded(
                        flex: 1,
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildFinanceCard(
                                "Gastos",
                                "\$${gastos.toStringAsFixed(0)}",
                                Icons.trending_down,
                                Colors.red,
                              ),
                            ),

                            const SizedBox(width: 18),

                            Expanded(
                              child: _buildFinanceCard(
                                "Ganancia",
                                "\$${ganancia.toStringAsFixed(0)}",
                                Icons.payments_outlined,
                                Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFinanceCard(
    String titulo,
    String valor,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white10,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: color,
            size: 28,
          ),

          const SizedBox(height: 15),

          Text(
            titulo,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              "$valor ",
              overflow:
                  TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'WhiskeyGirlsCondensedItalic',
                letterSpacing: 0.0,
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===== SIDEBAR =====

class SidebarWidget extends StatelessWidget {
  const SidebarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(20),
      child: const Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.flash_on,
                color: Color(0xFF3B82F6),
                size: 30,
              ),

              SizedBox(width: 10),

              Text(
                "Conección One",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),

          SizedBox(height: 40),

          SidebarItem(
            label: "Dashboard",
            icon:
                Icons.grid_view_rounded,
            isActive: true,
          ),

          SidebarItem(
            label: "Clientes",
            icon: Icons.people_outline,
          ),

          SidebarItem(
            label: "Reparaciones",
            icon:
                Icons.build_circle_outlined,
          ),

          SidebarItem(
            label: "Inventario",
            icon:
                Icons.inventory_2_outlined,
          ),

          SidebarItem(
            label: "Facturación",
            icon:
                Icons.receipt_long_outlined,
          ),

          SidebarItem(
            label: "Reportes",
            icon:
                Icons.bar_chart_outlined,
          ),

          Spacer(),

          SidebarItem(
            label: "Configuración",
            icon:
                Icons.settings_outlined,
          ),
        ],
      ),
    );
  }
}

class SidebarItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;

  const SidebarItem({
    super.key,
    required this.label,
    required this.icon,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      padding:
          const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFF3B82F6)
            : Colors.transparent,
        borderRadius:
            BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: isActive
                ? Colors.white
                : Colors.white54,
            size: 22,
          ),

          const SizedBox(width: 15),

          Text(
            label,
            style: TextStyle(
              color: isActive
                  ? Colors.white
                  : Colors.white70,
              fontWeight: isActive
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

// ===== HEADER =====

class HeaderWidget extends StatelessWidget {
  final String nombreAdmin;
  const HeaderWidget({super.key, required this.nombreAdmin});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              "¡Bienvenido, $nombreAdmin!",
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            SizedBox(height: 6),

            Text(
              "Panel principal de Conección One",
              style: TextStyle(
                color: Colors.white54,
                fontSize: 14,
              ),
            ),
          ],
        ),

        Row(
          children: [
            Icon(
              Icons.notifications_none,
              color: Colors.white70,
            ),

            SizedBox(width: 20),

            CircleAvatar(
              backgroundColor:
                  Color(0xFF3B82F6),
              child: Icon(
                Icons.person,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ===== REPARACIONES =====

class GlassRecentOrders
    extends StatelessWidget {
  const GlassRecentOrders({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 280,
      borderRadius: 25,
      blur: 15,
      alignment: Alignment.topLeft,
      border: 1,
      linearGradient: LinearGradient(
        colors: [
          Colors.white.withOpacity(0.05),
          Colors.white.withOpacity(0.02),
        ],
      ),
      borderGradient: LinearGradient(
        colors: [
          Colors.white.withOpacity(0.1),
          Colors.transparent,
        ],
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              "Reparaciones Recientes",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 25),

            _rowItem(
              "Samsung S22 Ultra",
              "Juan Pérez",
              "Pendiente",
              Colors.orange,
            ),

            _rowItem(
              "iPhone 13 Pro",
              "Marina Silva",
              "Terminado",
              Colors.green,
            ),

            _rowItem(
              "Motorola G200",
              "Carlos Ramos",
              "Diagnóstico",
              Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _rowItem(
    String equipo,
    String cliente,
    String estado,
    Color color,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 18,
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment
                .spaceBetween,
        children: [
          Column(
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,
            children: [
              Text(
                equipo,
                style:
                    const TextStyle(
                  color: Colors.white,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                cliente,
                style:
                    const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
            ],
          ),

          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color:
                  color.withOpacity(0.15),
              borderRadius:
                  BorderRadius.circular(
                      10),
            ),
            child: Text(
              estado,
              style: TextStyle(
                color: color,
                fontWeight:
                    FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===== STOCK =====

class GlassInventorySummary
    extends StatelessWidget {
  const GlassInventorySummary({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 280,
      borderRadius: 25,
      blur: 15,
      alignment: Alignment.topLeft,
      border: 1,
      linearGradient: LinearGradient(
        colors: [
          Colors.white.withOpacity(0.05),
          Colors.white.withOpacity(0.02),
        ],
      ),
      borderGradient: LinearGradient(
        colors: [
          Colors.redAccent
              .withOpacity(0.3),
          Colors.transparent,
        ],
      ),
      child: const Padding(
        padding: EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              "Stock Crítico",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            SizedBox(height: 25),

            Text(
              "• Módulo Samsung A10 (2u)",
              style: TextStyle(
                color: Colors.white70,
              ),
            ),

            SizedBox(height: 14),

            Text(
              "• Batería iPhone 11 (1u)",
              style: TextStyle(
                color: Colors.white70,
              ),
            ),

            SizedBox(height: 14),

            Text(
              "• Pin Moto G9 (0u)",
              style: TextStyle(
                color: Colors.redAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}