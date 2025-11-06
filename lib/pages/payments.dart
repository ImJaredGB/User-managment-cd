import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:rd_user_cd/modals/updatepayments.dart';

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
  String filtroBusqueda = '';

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
          'id': doc.id, // incluir el id del documento
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

  Color _colorPorMes(
    DateTime? ingreso,
    DateTime? salida,
    int mesIndex, [
    Map<String, dynamic>? pagos,
  ]) {
    final mesNombre = meses[mesIndex];

    // Si no hay fechas, se mantiene gris
    if (ingreso == null || salida == null) return Colors.grey[300]!;

    final inicio = DateTime(ingreso.year, ingreso.month);
    final fin = DateTime(salida.year, salida.month);
    final mesActual = DateTime(anioSeleccionado, mesIndex + 1);

    // Si el mes no está dentro del rango de estancia, se mantiene gris
    if (!(mesActual.isAfter(inicio.subtract(const Duration(days: 1))) &&
        mesActual.isBefore(fin.add(const Duration(days: 1))))) {
      return Colors.grey[300]!;
    }

    // Si está dentro del rango, determinar color según estado de pago
    if (pagos != null && pagos.containsKey(mesNombre)) {
      final pagado = pagos[mesNombre]['pagado'] ?? false;
      return pagado ? Colors.green[400]! : Colors.orange[400]!;
    }

    // Si no hay registro de pago, marcar en naranja (pendiente)
    return Colors.orange[400]!;
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
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Buscar usuario...',
                                prefixIcon: const Icon(Icons.search),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 0,
                                  horizontal: 12,
                                ),
                              ),
                              onChanged: (valor) {
                                setState(() {
                                  filtroBusqueda = valor.toLowerCase();
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          IconButton(
                            icon: const Icon(
                              Icons.refresh,
                              color: Color(0xFFA11C25),
                            ),
                            tooltip: 'Recargar',
                            onPressed: () {
                              setState(() {
                                isLoading = true;
                              });
                              _cargarUsuarios();
                            },
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: FractionallySizedBox(
                          widthFactor: 1,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width,
                              child: FutureBuilder<List<Map<String, dynamic>>>(
                                future: Future.wait(
                                  usuarios.map((usuario) async {
                                    final pagosSnapshot =
                                        await FirebaseFirestore.instance
                                            .collection('usuarios')
                                            .doc(usuario['id'])
                                            .collection('pagos')
                                            .get();

                                    final pagos = {
                                      for (var doc in pagosSnapshot.docs)
                                        doc.id: doc.data(),
                                    };

                                    return {'usuario': usuario, 'pagos': pagos};
                                  }).toList(),
                                ),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) {
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }
                                  final usuariosConPagos = snapshot.data!;

                                  return DataTable(
                                    columnSpacing: 20,
                                    headingRowColor: MaterialStateProperty.all(
                                      Colors.transparent,
                                    ),
                                    columns: [
                                      const DataColumn(label: Text('Usuarios')),
                                      ...mesesFormateados
                                          .map(
                                            (m) => DataColumn(label: Text(m)),
                                          )
                                          .toList(),
                                      const DataColumn(label: Text('Acciones')),
                                    ],
                                    rows: usuariosConPagos
                                        .where((usuarioConPagos) {
                                          final usuario =
                                              usuarioConPagos['usuario']
                                                  as Map<String, dynamic>;
                                          final nombreCompleto =
                                              '${usuario['nombre']} ${usuario['apellido']}'
                                                  .toLowerCase();
                                          return filtroBusqueda.isEmpty ||
                                              nombreCompleto.contains(
                                                filtroBusqueda,
                                              );
                                        })
                                        .map((usuarioConPagos) {
                                          final usuario =
                                              usuarioConPagos['usuario']
                                                  as Map<String, dynamic>;
                                          final pagos =
                                              usuarioConPagos['pagos']
                                                  as Map<String, dynamic>;
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
                                                        pagos,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            4,
                                                          ),
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
                                                      onPressed: () async {
                                                        final resultado =
                                                            await showDialog<
                                                              Map<String, bool>
                                                            >(
                                                              context: context,
                                                              builder: (context) => UpdatePaymentsModal(
                                                                usuarioRef: FirebaseFirestore
                                                                    .instance
                                                                    .collection(
                                                                      'usuarios',
                                                                    )
                                                                    .doc(
                                                                      usuario['id'],
                                                                    ),
                                                              ),
                                                            );

                                                        if (resultado != null) {
                                                          debugPrint(
                                                            'Estados de meses actualizados para ${usuario['nombre']}: $resultado',
                                                          );
                                                          // Aquí puedes guardar los cambios en Firestore si lo deseas
                                                        }
                                                      },
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            const Color(
                                                              0xFFA11C25,
                                                            ),
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 8,
                                                              vertical: 4,
                                                            ),
                                                        textStyle:
                                                            const TextStyle(
                                                              fontSize: 12,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                      ),
                                                      child: const Text(
                                                        'Actualizar',
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
                                        })
                                        .toList(),
                                  );
                                },
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
