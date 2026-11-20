import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: SubirFotoPage(),
  ));
}

class SubirFotoPage extends StatefulWidget {
  const SubirFotoPage({super.key});

  @override
  State<SubirFotoPage> createState() => _SubirFotoPageState();
}

class _SubirFotoPageState extends State<SubirFotoPage> {
  XFile? _imagen;
  final TextEditingController _descripcionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _subiendo = false;

  // URL para ejecutar en Chrome en tu misma computadora
  final String apiUrl = "http://localhost:8000/fotos";

  Future<void> _tomarFoto() async {
    final XFile? foto = await _picker.pickImage(source: ImageSource.camera);
    if (foto != null) {
      setState(() {
        _imagen = foto;
      });
    }
  }

  Future<void> _subirAApi() async {
    if (_imagen == null || _descripcionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor selecciona una foto y escribe una descripción")),
      );
      return;
    }

    setState(() {
      _subiendo = true;
    });

    try {
      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      request.fields['descripcion'] = _descripcionController.text.trim();
      
      // En Flutter Web (Chrome) se leen los bytes de la imagen
      final bytes = await _imagen!.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: _imagen!.name,
        ),
      );

      var response = await request.send();

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Foto subida correctamente ✅")),
        );
        setState(() {
          _imagen = null;
          _descripcionController.clear();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al subir: ${response.statusCode}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error de conexión: $e")),
      );
    } finally {
      setState(() {
        _subiendo = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Subir Foto"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 10),
            // Vista previa de imagen compatible con Chrome
            _imagen == null
                ? const Text(
                    "No hay imagen seleccionada",
                    style: TextStyle(fontSize: 16),
                  )
                : Image.network(
                    _imagen!.path,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
            const SizedBox(height: 20),
            // Campo Descripción
            TextField(
              controller: _descripcionController,
              decoration: const InputDecoration(
                labelText: "Descripción",
              ),
            ),
            const SizedBox(height: 20),
            // Botón Tomar / Seleccionar Foto
            ElevatedButton(
              onPressed: _tomarFoto,
              child: const Text("Tomar Foto"),
            ),
            const SizedBox(height: 10),
            // Botón Subir a API
            _subiendo
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _subirAApi,
                    child: const Text("Subir a API"),
                  ),
          ],
        ),
      ),
    );
  }
}