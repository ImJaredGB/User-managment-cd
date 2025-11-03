import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PaymentsPage extends StatefulWidget {
  const PaymentsPage({super.key});

  @override
  State<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends State<PaymentsPage> {
  final List<String> meses = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];

  int anioSeleccionado = DateTime.now().year;
  bool isLoading = true;
  List<Map<String, dynamic>> usuarios = [];

  @override
  void initState() {
    super.initState();
    _cargarUsuarios();
  }

  Future<void> _cargarUsuarios() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('usuarios')
          .get();

      final data = snapshot.docs.map((doc) {
        final info = doc.data();
        return {
          'nombre': info['nombres'] ?? '',
          'apellido': info['apellidos'] ?? '',
          'fechaIngreso': (info['fechaIngreso'] as Timestamp?)?.toDate(),
          'fechaSalida': (info['fechaSalida'] as Timestamp?)?.toDate(),
        };
      }).toList();

      setState(() {
        usuarios = data;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error al cargar usuarios: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Color _colorPorMes(DateTime? ingreso, DateTime? salida, int mesIndex) {
    if (ingreso == null || salida == null) return Colors.grey[300]!;
    final inicio = DateTime(ingreso.year, ingreso.month);
    final fin = DateTime(salida.year, salida.month);
    final mesActual = DateTime(anioSeleccionado, mesIndex + 1);

    return (mesActual.isAfter(inicio.subtract(const Duration(days: 1))) &&
            mesActual.isBefore(fin.add(const Duration(days: 1))))
        ? Colors.green[400]!
        : Colors.grey[300]!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gestión de pagos',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                List<String> mesesFormateados;

                if (constraints.maxWidth < 900) {
                  mesesFormateados = meses
                      .map((m) => m.substring(0, 3))
                      .toList();
                } else {
                  mesesFormateados = meses;
                }

                return Column(
                  children: [
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_left),
                          onPressed: () {
                            setState(() {
                              anioSeleccionado--;
                            });
                          },
                        ),
                        Text(
                          anioSeleccionado.toString(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_right),
                          onPressed: () {
                            setState(() {
                              anioSeleccionado++;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Expanded(
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: FractionallySizedBox(
                          widthFactor: 1,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width,
                              child: DataTable(
                                columnSpacing: 20,
                                headingRowColor: MaterialStateProperty.all(
                                  Colors.transparent,
                                ),
                                columns: [
                                  const DataColumn(label: Text('Usuarios')),
                                  ...mesesFormateados
                                      .map((m) => DataColumn(label: Text(m)))
                                      .toList(),
                                  const DataColumn(label: Text('Acciones')),
                                ],
                                rows: usuarios.map((usuario) {
                                  final nombreCompleto =
                                      '${usuario['nombre']} ${usuario['apellido']}';
                                  return DataRow(
                                    cells: [
                                      DataCell(Text(nombreCompleto)),
                                      ...List.generate(
                                        meses.length,
                                        (index) => DataCell(
                                          Container(
                                            width: 30,
                                            height: 25,
                                            decoration: BoxDecoration(
                                              color: _colorPorMes(
                                                usuario['fechaIngreso'],
                                                usuario['fechaSalida'],
                                                index,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            ElevatedButton(
                                              onPressed: () {
                                                debugPrint(
                                                  'Actualizar ${usuario['nombre']}',
                                                );
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(
                                                  0xFFA11C25,
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                textStyle: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              child: const Text(
                                                'Actualizar',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            ElevatedButton(
                                              onPressed: () {
                                                debugPrint(
                                                  'Ver información de ${usuario['nombre']}',
                                                );
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(
                                                  0xFFA11C25,
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                textStyle: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              child: const Text(
                                                'Ver',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
