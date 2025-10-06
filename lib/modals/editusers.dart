import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditUserDialog extends StatefulWidget {
  final DocumentSnapshot usuarioDoc;

  const EditUserDialog({Key? key, required this.usuarioDoc}) : super(key: key);

  @override
  State<EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<EditUserDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombresController;
  late TextEditingController _apellidosController;
  late TextEditingController _numeroDocumentoController;
  late String _tipoDocumento;
  late bool _estado;
  late DateTime? _fechaIngreso;
  late DateTime? _fechaSalida;
  late TextEditingController _fechaIngresoController;
  late TextEditingController _fechaSalidaController;
  final List<String> _zonas = ['Castillo', 'Restaurante', 'Piso', 'Vilanova'];
  String? _zonaSeleccionada;
  String? _literaSeleccionada;
  List<String> _literasZona = [];
  bool _isLoadingLiteras = false;

  @override
  void initState() {
    super.initState();
    final dataRaw = widget.usuarioDoc.data();
    final data = (dataRaw is Map<String, dynamic>)
        ? dataRaw
        : <String, dynamic>{};

    _nombresController = TextEditingController(
      text: data['nombres']?.toString() ?? '',
    );
    _apellidosController = TextEditingController(
      text: data['apellidos']?.toString() ?? '',
    );
    _numeroDocumentoController = TextEditingController(
      text: data['numeroDocumento']?.toString() ?? '',
    );
    _tipoDocumento = data['tipoDocumento']?.toString() ?? 'DNI';
    _estado = data['estado'] ?? true;

    // Parse fechas (safe)
    _fechaIngreso = _parseDate(data['fechaIngreso']);
    _fechaSalida = _parseDate(data['fechaSalida']);
    _fechaIngresoController = TextEditingController(
      text: _fechaIngreso != null ? _formatDate(_fechaIngreso!) : '',
    );
    _fechaSalidaController = TextEditingController(
      text: _fechaSalida != null ? _formatDate(_fechaSalida!) : '',
    );

    // Parse zona/litera safely
    _zonaSeleccionada = data['zona']?.toString();
    _literaSeleccionada = data['litera']?.toString();
    if (_zonaSeleccionada != null) {
      _fetchLiteras(_zonaSeleccionada!, initial: true);
    }
  }

  @override
  void dispose() {
    _nombresController.dispose();
    _apellidosController.dispose();
    _numeroDocumentoController.dispose();
    _fechaIngresoController.dispose();
    _fechaSalidaController.dispose();
    super.dispose();
  }

  DateTime? _parseDate(dynamic val) {
    if (val == null) return null;
    if (val is Timestamp) return val.toDate();
    if (val is DateTime) return val;
    if (val is String) {
      try {
        return DateTime.parse(val);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  String _formatDate(DateTime date) {
    return "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  Future<void> _selectFechaIngreso() async {
    DateTime initialDate = _fechaIngreso ?? DateTime.now();
    DateTime firstDate = DateTime(2000);
    DateTime lastDate = _fechaSalida ?? DateTime(2100);
    if (_fechaSalida != null && initialDate.isAfter(_fechaSalida!)) {
      initialDate = _fechaSalida!;
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked != null) {
      setState(() {
        _fechaIngreso = picked;
        _fechaIngresoController.text = _formatDate(picked);
        // If salida < ingreso, clear salida
        if (_fechaSalida != null && _fechaSalida!.isBefore(picked)) {
          _fechaSalida = null;
          _fechaSalidaController.text = '';
        }
      });
    }
  }

  Future<void> _selectFechaSalida() async {
    DateTime initialDate = _fechaSalida ?? (_fechaIngreso ?? DateTime.now());
    DateTime firstDate = _fechaIngreso ?? DateTime(2000);
    DateTime lastDate = DateTime(2100);
    if (_fechaIngreso != null && initialDate.isBefore(_fechaIngreso!)) {
      initialDate = _fechaIngreso!;
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked != null) {
      setState(() {
        _fechaSalida = picked;
        _fechaSalidaController.text = _formatDate(picked);
        // If ingreso > salida, clear ingreso
        if (_fechaIngreso != null && _fechaIngreso!.isAfter(picked)) {
          _fechaIngreso = null;
          _fechaIngresoController.text = '';
        }
      });
    }
  }

  Future<void> _fetchLiteras(String zona, {bool initial = false}) async {
    setState(() {
      _isLoadingLiteras = true;
      _literasZona = [];
    });
    try {
      final habitacionesQuery = await FirebaseFirestore.instance
          .collection('habitaciones')
          .where('zona', isEqualTo: zona)
          .get();

      List<String> literas = [];

      for (final habDoc in habitacionesQuery.docs) {
        final literasSnap = await habDoc.reference.collection('literas').get();
        for (final literaDoc in literasSnap.docs) {
          final literaId = literaDoc.data()['id']?.toString() ?? literaDoc.id;
          literas.add(literaId);
        }
      }

      setState(() {
        _literasZona = literas;
        if (initial) {
          // Keep selection if valid
          if (_literaSeleccionada != null &&
              !_literasZona.contains(_literaSeleccionada)) {
            _literaSeleccionada = null;
          }
        } else {
          _literaSeleccionada = null;
        }
        _isLoadingLiteras = false;
      });
    } catch (_) {
      setState(() {
        _literasZona = [];
        _literaSeleccionada = null;
        _isLoadingLiteras = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataRaw = widget.usuarioDoc.data();
    final data = (dataRaw is Map<String, dynamic>)
        ? dataRaw
        : <String, dynamic>{};
    return AlertDialog(
      title: Text('Editar Usuario'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nombresController,
                decoration: InputDecoration(labelText: 'Nombres'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Ingrese nombres' : null,
              ),
              TextFormField(
                controller: _apellidosController,
                decoration: InputDecoration(labelText: 'Apellidos'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Ingrese apellidos' : null,
              ),
              DropdownButtonFormField<String>(
                value: _tipoDocumento,
                decoration: InputDecoration(labelText: 'Tipo de Documento'),
                items: ['DNI', 'Carne de extranjeria']
                    .map(
                      (tipo) =>
                          DropdownMenuItem(value: tipo, child: Text(tipo)),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _tipoDocumento = value);
                },
              ),
              TextFormField(
                controller: _numeroDocumentoController,
                decoration: InputDecoration(labelText: 'Número de Documento'),
                validator: (value) => value == null || value.isEmpty
                    ? 'Ingrese número de documento'
                    : null,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Estado'),
                  Switch(
                    value: _estado,
                    onChanged: (value) {
                      setState(() {
                        _estado = value;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Fecha Ingreso picker
              TextFormField(
                controller: _fechaIngresoController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Fecha Ingreso',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                onTap: _selectFechaIngreso,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Seleccione fecha de ingreso';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              // Fecha Salida picker
              TextFormField(
                controller: _fechaSalidaController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Fecha Salida',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                onTap: _selectFechaSalida,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Seleccione fecha de salida';
                  }
                  if (_fechaIngreso != null &&
                      _fechaSalida != null &&
                      _fechaSalida!.isBefore(_fechaIngreso!)) {
                    return 'Salida no puede ser antes de ingreso';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              // Zona dropdown
              DropdownButtonFormField<String>(
                value: _zonaSeleccionada,
                decoration: InputDecoration(labelText: 'Zona'),
                items: _zonas
                    .map(
                      (zona) =>
                          DropdownMenuItem(value: zona, child: Text(zona)),
                    )
                    .toList(),
                onChanged: (zona) {
                  if (zona != null && zona != _zonaSeleccionada) {
                    setState(() {
                      _zonaSeleccionada = zona;
                      _literaSeleccionada = null;
                      _fetchLiteras(zona);
                    });
                  }
                },
                validator: (value) =>
                    value == null || value.isEmpty ? 'Seleccione zona' : null,
              ),
              const SizedBox(height: 8),
              // Litera dropdown
              _isLoadingLiteras
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : DropdownButtonFormField<String>(
                      value: _literaSeleccionada,
                      decoration: InputDecoration(labelText: 'Litera'),
                      items: _literasZona
                          .map(
                            (litera) => DropdownMenuItem(
                              value: litera,
                              child: Text(litera),
                            ),
                          )
                          .toList(),
                      onChanged: (litera) {
                        setState(() {
                          _literaSeleccionada = litera;
                        });
                      },
                      validator: (value) => value == null || value.isEmpty
                          ? 'Seleccione litera'
                          : null,
                    ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState?.validate() ?? false) {
              // Save logic
              final updatedData = <String, dynamic>{
                'nombres': _nombresController.text,
                'apellidos': _apellidosController.text,
                'tipoDocumento': _tipoDocumento,
                'numeroDocumento': _numeroDocumentoController.text,
                'estado': _estado,
                'fechaIngreso': _fechaIngreso,
                'fechaSalida': _fechaSalida,
                'zona': _zonaSeleccionada,
                'litera': _literaSeleccionada,
              };
              await widget.usuarioDoc.reference.update(updatedData);

              if (_zonaSeleccionada != null && _literaSeleccionada != null) {
                final habitacionesQuery = await FirebaseFirestore.instance
                    .collection('habitaciones')
                    .where('zona', isEqualTo: _zonaSeleccionada)
                    .get();

                for (final habDoc in habitacionesQuery.docs) {
                  final literasSnap = await habDoc.reference
                      .collection('literas')
                      .get();
                  for (final literaDoc in literasSnap.docs) {
                    final literaId =
                        literaDoc.data()['id']?.toString() ?? literaDoc.id;
                    if (literaId == _literaSeleccionada) {
                      await literaDoc.reference.update({'occupied': true});
                      break;
                    }
                  }
                }
              }

              Navigator.of(context).pop();
            }
          },
          child: Text('Guardar'),
        ),
      ],
    );
  }
}

// _ReadOnlyField class remains for possible reuse elsewhere
class _ReadOnlyField extends StatelessWidget {
  final String label;
  final String value;
  const _ReadOnlyField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
