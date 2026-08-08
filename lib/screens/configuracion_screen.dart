import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class ConfiguracionScreen extends StatefulWidget {
  const ConfiguracionScreen({super.key});

  @override
  State<ConfiguracionScreen> createState() =>
      _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen> {
  final nombreCtrl = TextEditingController();
  final direccionCtrl = TextEditingController();
  final telefonoCtrl = TextEditingController();
  final adminNombreCtrl = TextEditingController();

  bool temaOscuro = true;

  Uint8List? logoBytes;

  bool cargando = false;

  @override
  void initState() {
    super.initState();
    cargarConfiguracion();
  }

  Future<void> cargarConfiguracion() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('configuracion')
          .doc('general')
          .get();

      if (doc.exists) {
        final data = doc.data()!;

        setState(() {
          nombreCtrl.text = data['nombreNegocio'] ?? '';
          direccionCtrl.text = data['direccion'] ?? '';
          telefonoCtrl.text = data['telefono'] ?? '';
          adminNombreCtrl.text = data['nombreAdmin'] ?? '';
          temaOscuro = data['temaOscuro'] ?? true;

          if (data['logoBase64'] != null && data['logoBase64'].toString().isNotEmpty) {
            logoBytes = base64Decode(data['logoBase64']);
          }
        });
      }
    } catch (e) {
      debugPrint("Error cargando configuración: $e");
    }
  }

  Future<void> seleccionarLogo() async {
    final picker = ImagePicker();
    final XFile? imagen = await picker.pickImage(source: ImageSource.gallery);

    if (imagen != null) {
      final bytes = await imagen.readAsBytes();

      setState(() {
        logoBytes = bytes;
      });
    }
  }

  String? _toBase64() {
    if (logoBytes == null) return null;
    return base64Encode(logoBytes!);
  }

  Future<void> guardarConfiguracion() async {
    setState(() => cargando = true);

    try {
      await FirebaseFirestore.instance
          .collection('configuracion')
          .doc('general')
          .set({
        'nombreNegocio': nombreCtrl.text.trim(),
        'nombreAdmin': adminNombreCtrl.text.trim(),
        'direccion': direccionCtrl.text.trim(),
        'telefono': telefonoCtrl.text.trim(),
        'temaOscuro': temaOscuro,
        'logoBase64': _toBase64(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Configuración guardada correctamente")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }

    setState(() => cargando = false);
  }

  Widget _previewLogo() {
    if (logoBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.memory(
          logoBytes!,
          width: 120,
          height: 120,
          fit: BoxFit.cover,
        ),
      );
    }

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Icon(
        Icons.image_outlined,
        color: Colors.white38,
        size: 50,
      ),
    );
  }

  Widget campoTexto(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54),
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Configuración",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 30),

          Expanded(
            child: GlassmorphicContainer(
              width: double.infinity,
              height: double.infinity,
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
                  Colors.white.withOpacity(0.1),
                  Colors.transparent,
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Center(child: _previewLogo()),

                      const SizedBox(height: 15),

                      ElevatedButton.icon(
                        onPressed: seleccionarLogo,
                        icon: const Icon(Icons.upload),
                        label: const Text("Subir Logo"),
                      ),

                      const SizedBox(height: 30),

                      campoTexto("Nombre del negocio", nombreCtrl),
                      campoTexto("Nombre del Administrador", adminNombreCtrl),
                      campoTexto("Dirección", direccionCtrl),
                      campoTexto("Teléfono", telefonoCtrl),

                      const SizedBox(height: 20),

                      SwitchListTile(
                        value: temaOscuro,
                        title: const Text(
                          "Tema oscuro",
                          style: TextStyle(color: Colors.white),
                        ),
                        onChanged: (v) {
                          setState(() => temaOscuro = v);
                        },
                      ),

                      const SizedBox(height: 30),

                      ElevatedButton.icon(
                        onPressed: cargando ? null : guardarConfiguracion,
                        icon: const Icon(Icons.save),
                        label: Text(cargando ? "Guardando..." : "Guardar"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}