//Modal para añadir una nueva habitación

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HabitacionForm extends StatefulWidget {
  @override
  _HabitacionFormState createState() => _HabitacionFormState();
}

class _HabitacionFormState extends State<HabitacionForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _literasController = TextEditingController(
    text: '1',
  );
  String? _zona;
  String? _nivel = 'PB';
  int _literasCount = 1;

  final List<String> _zonas = ['Castillo', 'Restaurante', 'Piso', 'Vilanova'];
  final List<String> _niveles = ['PB', 'PM', 'PA'];

  void _showWaitAlert(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text("Cargando..."),
          ],
        ),
      ),
    );
    Future.delayed(Duration(seconds: 5), () {
      Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Agregar Habitación'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _zona,
                decoration: InputDecoration(labelText: 'Zona'),
                items: _zonas
                    .map(
                      (zona) => DropdownMenuItem<String>(
                        value: zona,
                        child: Text(zona),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _zona = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor seleccione una zona';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                value: _nivel,
                decoration: InputDecoration(labelText: 'Nivel'),
                items: _niveles
                    .map(
                      (nivel) => DropdownMenuItem<String>(
                        value: nivel,
                        child: Text(nivel),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _nivel = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor seleccione un nivel';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _literasController,
                decoration: InputDecoration(
                  labelText: 'Cantidad de literas (1-12)',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese la cantidad de literas';
                  }
                  int? num = int.tryParse(value);
                  if (num == null || num < 1 || num > 12) {
                    return 'Ingrese un número válido entre 1 y 12';
                  }
                  return null;
                },
                onChanged: (value) {
                  int? num = int.tryParse(value);
                  if (num != null && num >= 1 && num <= 12) {
                    setState(() {
                      _literasCount = num;
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          child: Text('Cancelar'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        ElevatedButton(
          child: Text('Guardar'),
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              _showWaitAlert(context);
              final habitacionesRef = FirebaseFirestore.instance.collection(
                'habitaciones',
              );
              final querySnapshot = await habitacionesRef
                  .where('zona', isEqualTo: _zona)
                  .where('nivel', isEqualTo: _nivel)
                  .get();

              int maxNumero = 0;
              for (var doc in querySnapshot.docs) {
                int numero = doc.data()['numero'] ?? 0;
                if (numero > maxNumero) maxNumero = numero;
              }
              int nextNumero = maxNumero + 1;

              // Map full zone name to initial letter
              String zonaInicial;
              switch (_zona) {
                case 'Castillo':
                  zonaInicial = 'C';
                  break;
                case 'Restaurante':
                  zonaInicial = 'R';
                  break;
                case 'Piso':
                  zonaInicial = 'P';
                  break;
                case 'Vilanova':
                  zonaInicial = 'V';
                  break;
                default:
                  zonaInicial = _zona![0];
              }
              String nomenclatura = '$zonaInicial${_nivel}$nextNumero';

              final habitacionDoc = await habitacionesRef.add({
                'nomenclatura': nomenclatura,
                'zona': _zona,
                'nivel': _nivel,
                'numero': nextNumero,
                'estado': true,
                'desactivada': false,
                'tamano': _literasCount,
                'createdAt': FieldValue.serverTimestamp(),
              });

              final literasRef = habitacionDoc.collection('literas');

              // Create literas: 1L1-1L12 and 2L1-2L12
              for (int i = 1; i <= 12; i++) {
                String litId1 =
                    '${nomenclatura}_1L${i.toString().padLeft(2, '0')}';
                bool isActive1 = i <= _literasCount;
                await literasRef.doc(litId1).set({
                  'id': litId1,
                  'active': isActive1,
                  'occupied': false,
                });
              }
              for (int i = 1; i <= 12; i++) {
                String litId2 =
                    '${nomenclatura}_2L${i.toString().padLeft(2, '0')}';
                bool isActive2 = i <= _literasCount;
                await literasRef.doc(litId2).set({
                  'id': litId2,
                  'active': isActive2,
                  'occupied': false,
                });
              }
            }
          },
        ),
      ],
    );
  }
}
