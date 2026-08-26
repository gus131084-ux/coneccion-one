import 'package:cloud_firestore/cloud_firestore.dart';

class AiDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> buildCompleteContext() async {
    // Consulta todas las colecciones en paralelo con timeout seguro
    final results = await Future.wait([
      _firestore.collection('clientes').get().timeout(const Duration(seconds: 15)),
      _firestore.collection('reparaciones').get().timeout(const Duration(seconds: 15)),
      _firestore.collection('inventario').get().timeout(const Duration(seconds: 15)),
      _firestore.collection('facturas').get().timeout(const Duration(seconds: 15)),
      _firestore.collection('configuracion').doc('general').get().timeout(const Duration(seconds: 15)),
    ]);

    final clientesDocs = (results[0] as QuerySnapshot).docs;
    final reparacionesDocs = (results[1] as QuerySnapshot).docs;
    final inventarioDocs = (results[2] as QuerySnapshot).docs;
    final facturasDocs = (results[3] as QuerySnapshot).docs;
    final configDoc = results[4] as DocumentSnapshot;

    // 1. Configuración del negocio
    final configData = configDoc.exists && configDoc.data() != null
        ? configDoc.data() as Map<String, dynamic>
        : <String, dynamic>{};
    final nombreNegocio = configData['nombreNegocio'] ?? 'Conección One';
    final nombreAdmin = configData['nombreAdmin'] ?? 'Admin';
    final contactoNegocio = configData['telefono'] ?? '';
    final direccionNegocio = configData['direccion'] ?? '';

    // 2. Clientes detallados
    final List<Map<String, dynamic>> listaClientes = [];
    for (final doc in clientesDocs) {
      final data = doc.data() as Map<String, dynamic>;
      listaClientes.add({
        'id': doc.id,
        'nombre': (data['nombre'] ?? '').toString().trim(),
        'telefono': (data['telefono'] ?? '').toString().trim(),
        'dni': (data['dni'] ?? '').toString().trim(),
        'direccion': (data['direccion'] ?? '').toString().trim(),
        'email': (data['email'] ?? '').toString().trim(),
        'notas': (data['notas'] ?? '').toString().trim(),
        'fecha_registro': _formatDate(data['fecha_registro'] ?? data['fechaRegistro'] ?? data['createdAt']),
      });
    }

    // 3. Reparaciones detalladas
    final List<Map<String, dynamic>> listaReparaciones = [];
    final Map<String, int> conteoEstados = {
      'Pendiente': 0,
      'En proceso': 0,
      'Terminado': 0,
      'Entregado': 0,
    };
    final Map<String, int> conteoFallas = {};

    for (final doc in reparacionesDocs) {
      final data = doc.data() as Map<String, dynamic>;
      final estado = _normalizeStatus(data['estado'] ?? data['status']);
      conteoEstados[estado] = (conteoEstados[estado] ?? 0) + 1;

      final falla = (data['falla'] ?? 'Sin especificar').toString().trim();
      if (falla.isNotEmpty && falla != 'Sin especificar') {
        conteoFallas[falla] = (conteoFallas[falla] ?? 0) + 1;
      }

      final presupuesto = _toDouble(data['presupuesto']);
      final entrega = _toDouble(data['entrega']);
      final saldo = presupuesto > entrega ? presupuesto - entrega : 0.0;

      listaReparaciones.add({
        'id': doc.id,
        'cliente': (data['cliente'] ?? '').toString().trim(),
        'equipo': (data['equipo'] ?? '${data['marca'] ?? ''} ${data['modelo'] ?? ''}').toString().trim(),
        'marca': (data['marca'] ?? '').toString().trim(),
        'modelo': (data['modelo'] ?? '').toString().trim(),
        'falla': falla,
        'estado': estado,
        'presupuesto': presupuesto,
        'seña_o_entrega': entrega,
        'saldo_pendiente': saldo,
        'imei': (data['imei'] ?? '').toString().trim(),
        'observaciones': (data['observaciones'] ?? '').toString().trim(),
        'tiene_patron': data['tiene_patron'] == true,
        'tiene_pin': data['tiene_pin'] == true,
        'fecha_ingreso': _formatDate(data['fecha_ingreso'] ?? data['fecha']),
      });
    }

    // 4. Inventario y Repuestos
    final List<Map<String, dynamic>> listaInventario = [];
    final List<String> itemsBajoStock = [];
    double valorTotalInventario = 0.0;

    for (final doc in inventarioDocs) {
      final data = doc.data() as Map<String, dynamic>;
      final nombre = (data['nombre'] ?? data['producto'] ?? '').toString().trim();
      final stock = _toInt(data['stock'] ?? data['cantidad']);
      final precio = _toDouble(data['precio'] ?? data['precioVenta']);
      final costo = _toDouble(data['costo'] ?? data['precioCompra']);

      valorTotalInventario += stock * precio;
      if (stock < 5) {
        itemsBajoStock.add('$nombre (Stock: $stock unidades)');
      }

      listaInventario.add({
        'id': doc.id,
        'producto': nombre,
        'stock': stock,
        'precio': precio,
        if (costo > 0) 'costo': costo,
        'bajo_stock': stock < 5,
      });
    }

    // 5. Facturas y Ventas
    final List<Map<String, dynamic>> listaFacturas = [];
    final now = DateTime.now();
    double totalVentasHistoricas = 0.0;
    double ventasMes = 0.0;
    double gastosMes = 0.0;
    final List<Map<String, dynamic>> clientesConDeuda = [];

    for (final doc in facturasDocs) {
      final data = doc.data() as Map<String, dynamic>;
      final total = _toDouble(data['total']);
      final saldoRestante = _toDouble(data['saldoRestante']);
      final repuesto = _toDouble(data['repuesto']);
      final envio = _toDouble(data['envio']);
      final gastosFactura = repuesto + envio;

      final date = _parseDate(data['fechaFactura'] ?? data['fecha']);
      final esMesActual = date != null && date.year == now.year && date.month == now.month;

      totalVentasHistoricas += total;
      if (esMesActual) {
        ventasMes += total;
        gastosMes += gastosFactura;
      }

      final cliente = (data['nombreCliente'] ?? data['cliente'] ?? '').toString().trim();
      if (saldoRestante > 0 && cliente.isNotEmpty) {
        clientesConDeuda.add({
          'cliente': cliente,
          'numeroFactura': data['numeroFactura'] ?? 0,
          'saldo_adeudado': saldoRestante,
          'total_factura': total,
        });
      }

      listaFacturas.add({
        'id': doc.id,
        'numeroFactura': data['numeroFactura'] ?? 0,
        'cliente': cliente,
        'equipo': (data['equipo'] ?? '').toString().trim(),
        'falla': (data['falla'] ?? '').toString().trim(),
        'reparacion': (data['reparacion'] ?? '').toString().trim(),
        'total': total,
        'montoEntrega': _toDouble(data['montoEntrega']),
        'saldoRestante': saldoRestante,
        'estadoPago': (data['estadoPago'] ?? 'Pagado').toString().trim(),
        'metodoPago': (data['metodoPago'] ?? 'Efectivo').toString().trim(),
        'fecha': _formatDate(data['fechaFactura'] ?? data['fecha']),
      });
    }

    final rankingFallas = conteoFallas.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return {
      'negocio': {
        'nombre_negocio': nombreNegocio,
        'administrador': nombreAdmin,
        'contacto': contactoNegocio,
        'direccion': direccionNegocio,
        'fecha_consulta': now.toIso8601String(),
      },
      'resumen_estadistico': {
        'total_clientes': listaClientes.length,
        'total_reparaciones': listaReparaciones.length,
        'reparaciones_por_estado': conteoEstados,
        'total_productos_inventario': listaInventario.length,
        'productos_con_bajo_stock': itemsBajoStock,
        'valor_total_inventario': valorTotalInventario,
        'ventas_mes_actual': ventasMes,
        'gastos_mes_actual': gastosMes,
        'ganancia_mes_actual': ventasMes - gastosMes,
        'total_facturado_historico': totalVentasHistoricas,
        'fallas_mas_frecuentes': rankingFallas.take(5).map((e) => '${e.key}: ${e.value} casos').toList(),
        'clientes_con_saldo_pendiente': clientesConDeuda,
      },
      'clientes': listaClientes,
      'reparaciones': listaReparaciones,
      'inventario': listaInventario,
      'facturas': listaFacturas,
    };
  }

  static double _toDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }

  static int _toInt(dynamic val) {
    if (val == null) return 0;
    if (val is num) return val.toInt();
    return int.tryParse(val.toString()) ?? 0;
  }

  static DateTime? _parseDate(dynamic val) {
    if (val == null) return null;
    if (val is Timestamp) return val.toDate();
    if (val is DateTime) return val;
    if (val is String) return DateTime.tryParse(val);
    return null;
  }

  static String _formatDate(dynamic val) {
    final date = _parseDate(val);
    if (date == null) return '-';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  static String _normalizeStatus(dynamic val) {
    final s = val?.toString().trim().toLowerCase() ?? '';
    if (s.contains('proceso') || s.contains('reparaci')) return 'En proceso';
    if (s.contains('terminad') || s.contains('listo')) return 'Terminado';
    if (s.contains('entregad')) return 'Entregado';
    return 'Pendiente';
  }

  // Helpers para pruebas unitarias
  static double toDoubleForTest(dynamic val) => _toDouble(val);
  static int toIntForTest(dynamic val) => _toInt(val);
  static String normalizeStatusForTest(dynamic val) => _normalizeStatus(val);
}
