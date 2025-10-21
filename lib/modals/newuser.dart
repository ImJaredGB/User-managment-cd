import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NewUserModal extends StatefulWidget {
  const NewUserModal({Key? key}) : super(key: key);

  @override
  State<NewUserModal> createState() => _NewUserModalState();
}

class _NewUserModalState extends State<NewUserModal> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombresController = TextEditingController();
  final TextEditingController _apellidosController = TextEditingController();
  final TextEditingController _numeroDocumentoController =
      TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _tipoDocumento;

  Future<void> _crearUsuario() async {
    if (_formKey.currentState!.validate()) {
      await FirebaseFirestore.instance.collection('usuarios').add({
        'nombres': _nombresController.text.trim(),
        'apellidos': _apellidosController.text.trim(),
        'tipoDocumento': _tipoDocumento,
        'numeroDocumento': _numeroDocumentoController.text.trim(),
        'password': _passwordController.text.trim(),
      });
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Añadir nuevo usuario'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nombresController,
                decoration: const InputDecoration(labelText: 'Nombres'),
                validator: (v) => v!.isEmpty ? 'Campo obligatorio' : null,
              ),
              TextFormField(
                controller: _apellidosController,
                decoration: const InputDecoration(labelText: 'Apellidos'),
                validator: (v) => v!.isEmpty ? 'Campo obligatorio' : null,
              ),
              DropdownButtonFormField<String>(
                value: _tipoDocumento,
                decoration: const InputDecoration(
                  labelText: 'Tipo de documento',
                ),
                items: const [
                  DropdownMenuItem(value: 'DNI', child: Text('DNI')),
                  DropdownMenuItem(
                    value: 'Pasaporte',
                    child: Text('Pasaporte'),
                  ),
                ],
                onChanged: (value) => setState(() => _tipoDocumento = value),
                validator: (v) => v == null ? 'Seleccione un tipo' : null,
              ),
              TextFormField(
                controller: _numeroDocumentoController,
                decoration: const InputDecoration(
                  labelText: 'Número de documento',
                ),
                validator: (v) => v!.isEmpty ? 'Campo obligatorio' : null,
              ),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Contraseña'),
                validator: (v) => v!.isEmpty ? 'Campo obligatorio' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _crearUsuario,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFA11C25),
            foregroundColor: Colors.white,
          ),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
