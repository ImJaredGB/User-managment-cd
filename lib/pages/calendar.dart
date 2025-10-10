import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CalendarioPage extends StatefulWidget {
  const CalendarioPage({super.key});

  @override
  State<CalendarioPage> createState() => _CalendarioPageState();
}

class _CalendarioPageState extends State<CalendarioPage> {
  String zonaActual = "Castillo";
  String mesActivo = "Enero";
  int _anioActual = DateTime.now().year;
  final searchController = TextEditingController();
  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    mesActivo = meses[now.month - 1];
  }

  final List<String> meses = [
    "Enero",
    "Febrero",
    "Marzo",
    "Abril",
    "Mayo",
    "Junio",
    "Julio",
    "Agosto",
    "Septiembre",
    "Octubre",
    "Noviembre",
    "Diciembre",
  ];

  final List<String> zonas = ["Castillo", "Restaurante", "Piso", "Vilanova"];

  int diasEnMes(int mes, int anio) {
    List<int> diasPorMes = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    // Ajustar para año bisiesto
    if (mes == 2) {
      if ((anio % 4 == 0 && anio % 100 != 0) || (anio % 400 == 0)) {
        return 29;
      }
    }
    return diasPorMes[mes - 1];
  }

  Widget buildTablaMes(String mes, String zona, int anioActual) {
    int mesIndex = meses.indexOf(mes) + 1;
    int totalDias = diasEnMes(mesIndex, anioActual);

    List<DataColumn> columnas = [
      const DataColumn(
        label: Text(
          'Literas',
          style: TextStyle(
            fontSize: 10,
            color: Color.fromARGB(255, 81, 81, 81),
          ),
        ),
      ),
      ...List.generate(totalDias, (index) {
        final diaNumero = index + 1;
        final hoy = DateTime.now();
        final esHoy =
            hoy.day == diaNumero &&
            hoy.month == mesIndex &&
            hoy.year == anioActual;
        return DataColumn(
          label: Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
            decoration: BoxDecoration(
              color: esHoy
                  ? const Color.fromARGB(255, 158, 158, 158).withOpacity(0.3)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '$diaNumero',
              style: const TextStyle(
                fontSize: 10,
                color: Color.fromARGB(255, 81, 81, 81),
              ),
            ),
          ),
        );
      }),
    ];

    return Expanded(
      child: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('habitaciones')
            .where('zona', isEqualTo: zona)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // Filter habitaciones by zona
          final habitaciones = (snapshot.data?.docs ?? []).where((
            habitacionDoc,
          ) {
            final data = habitacionDoc.data() as Map<String, dynamic>;
            return data['zona'] == zona;
          }).toList();

          // Outer FutureBuilder for usuarios
          return FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance.collection('usuarios').get(),
            builder: (context, usuariosSnapshot) {
              if (usuariosSnapshot.hasError) {
                return Center(child: Text('Error: ${usuariosSnapshot.error}'));
              }
              if (usuariosSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final usuariosDocs = usuariosSnapshot.data?.docs ?? [];
              // List of usuario maps, for easier lookup
              final usuariosList = usuariosDocs
                  .map((doc) => doc.data() as Map<String, dynamic>)
                  .toList();

              return FutureBuilder<List<QueryDocumentSnapshot>>(
                future: Future.wait(
                  habitaciones.map((habitacionDoc) async {
                    final literasSnapshot = await habitacionDoc.reference
                        .collection('literas')
                        .where('occupied', isEqualTo: true)
                        .get();
                    return literasSnapshot.docs;
                  }),
                ).then((listOfLists) => listOfLists.expand((x) => x).toList()),
                builder: (context, literasSnapshot) {
                  if (literasSnapshot.hasError) {
                    return Center(
                      child: Text('Error: ${literasSnapshot.error}'),
                    );
                  }
                  if (literasSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final literas = literasSnapshot.data ?? [];
                  // Filter literas by searchController.text (case-insensitive, contains in data['id'])
                  final searchText = searchController.text.trim().toLowerCase();
                  final filteredLiteras = searchText.isEmpty
                      ? literas
                      : literas.where((literaDoc) {
                          final data = literaDoc.data() as Map<String, dynamic>;
                          final id = (data['id'] ?? '')
                              .toString()
                              .toLowerCase();
                          return id.contains(searchText);
                        }).toList();

                  List<DataRow> filas = filteredLiteras.map((literaDoc) {
                    final data = literaDoc.data() as Map<String, dynamic>;
                    final literaId = data['id'];
                    // Buscar usuario que tenga esta litera asignada
                    final usuario = usuariosList.firstWhere(
                      (u) => u['litera'] == literaId,
                      orElse: () => <String, dynamic>{},
                    );
                    DateTime? fechaIngreso;
                    DateTime? fechaSalida;
                    if (usuario.isNotEmpty) {
                      final ingreso = usuario['fechaIngreso'];
                      final salida = usuario['fechaSalida'];
                      if (ingreso is Timestamp) {
                        fechaIngreso = ingreso.toDate();
                      }
                      if (salida is Timestamp) {
                        fechaSalida = salida.toDate();
                      }
                    }
                    // Nueva lógica: celdas verdes por días ocupados, grises por días libres
                    List<DataCell> diaCeldas = List.generate(totalDias, (
                      index,
                    ) {
                      final dia = index + 1;
                      bool ocupado = false;

                      if (fechaIngreso != null && fechaSalida != null) {
                        final primerDiaMes = DateTime(anioActual, mesIndex, 1);
                        final ultimoDiaMes = DateTime(
                          anioActual,
                          mesIndex,
                          totalDias,
                        );
                        final inicio = fechaIngreso.isAfter(primerDiaMes)
                            ? fechaIngreso
                            : primerDiaMes;
                        final fin = fechaSalida.isBefore(ultimoDiaMes)
                            ? fechaSalida
                            : ultimoDiaMes;

                        if (!fin.isBefore(inicio)) {
                          ocupado = dia >= inicio.day && dia <= fin.day;
                        }
                      }

                      return DataCell(
                        Container(
                          height: 18,
                          width: 20,
                          decoration: BoxDecoration(
                            color: ocupado ? Colors.green : Colors.grey[300],
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      );
                    });

                    String? nombreUsuarioActual;
                    if (usuario.isNotEmpty &&
                        fechaIngreso != null &&
                        fechaSalida != null) {
                      final now = DateTime.now();
                      if (!now.isBefore(fechaIngreso) &&
                          !now.isAfter(fechaSalida)) {
                        final nombre = (usuario['nombres'] ?? '').toString();
                        final apellido = (usuario['apellidos'] ?? '')
                            .toString();
                        nombreUsuarioActual = '$nombre $apellido'.trim();
                      }
                    }

                    return DataRow(
                      cells: [
                        DataCell(
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['id'] ?? '-',
                                style: const TextStyle(fontSize: 12),
                              ),
                              if (nombreUsuarioActual != null)
                                Text(
                                  nombreUsuarioActual,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        ...diaCeldas,
                      ],
                    );
                  }).toList();

                  // Wrap DataTable in vertical and horizontal scroll views, and ensure full width
                  return SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width,
                        child: DataTable(
                          columnSpacing: 10,
                          horizontalMargin: 4,
                          columns: columnas,
                          rows: filas,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Calendario"),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              _abrirMenuUsuario(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 🔍 Toolbar and zones combined with responsive layout
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: width > 600
                ? Row(
                    children: [
                      SizedBox(
                        width: 120,
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.filter_list),
                          label: const Text("Filtros"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: searchController,
                          decoration: const InputDecoration(
                            hintText: "Buscar...",
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                          ),
                          onSubmitted: (value) {
                            setState(() {
                              searchController.text = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Row(
                        children: zonas.map((zona) {
                          final esActivo = zona == zonaActual;
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4.0,
                            ),
                            child: ChoiceChip(
                              label: Text(zona),
                              selected: esActivo,
                              onSelected: (_) {
                                setState(() {
                                  zonaActual = zona;
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.filter_list),
                        onPressed: () {
                          _mostrarFiltros(context);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () {
                          _mostrarBusqueda(context);
                        },
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: zonas.map((zona) {
                              final esActivo = zona == zonaActual;
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4.0,
                                ),
                                child: ChoiceChip(
                                  label: Text(zona),
                                  selected: esActivo,
                                  onSelected: (_) {
                                    setState(() {
                                      zonaActual = zona;
                                    });
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),

          const Divider(),

          // 📅 Navegación de meses (responsive) y año
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_left),
                    onPressed: () {
                      setState(() {
                        _anioActual--;
                      });
                    },
                  ),
                  Text(
                    _anioActual.toString(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_right),
                    onPressed: () {
                      setState(() {
                        _anioActual++;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _MesesNavigation(
                meses: meses,
                mesActivo: mesActivo,
                onMesSelected: (mes) {
                  setState(() {
                    mesActivo = mes;
                  });
                },
              ),
            ],
          ),

          const Divider(),

          // 📊 Tabla placeholder
          buildTablaMes(mesActivo, zonaActual, _anioActual),
        ],
      ),
    );
  }

  // Menú lateral de usuario
  void _abrirMenuUsuario(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text("Perfil"),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text("Cerrar sesión"),
            onTap: () {
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  void _mostrarFiltros(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          height: 100,
          child: Center(
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.filter_list),
              label: const Text("Filtros"),
            ),
          ),
        ),
      ),
    );
  }

  void _mostrarBusqueda(BuildContext context) {
    final modalController = TextEditingController(text: searchController.text);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: modalController,
              decoration: const InputDecoration(
                hintText: "Buscar...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              autofocus: true,
              onSubmitted: (value) {
                setState(() {
                  searchController.text = value;
                });
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  searchController.text = modalController.text;
                });
                Navigator.pop(ctx);
              },
              child: const Text("Buscar"),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget de navegación de meses responsive
class _MesesNavigation extends StatefulWidget {
  final List<String> meses;
  final String mesActivo;
  final ValueChanged<String> onMesSelected;
  const _MesesNavigation({
    required this.meses,
    required this.mesActivo,
    required this.onMesSelected,
    Key? key,
  }) : super(key: key);

  @override
  State<_MesesNavigation> createState() => _MesesNavigationState();
}

class _MesesNavigationState extends State<_MesesNavigation> {
  int _paginaMeses = 0;
  int _anioActual = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 900) {
      // Mostrar todos los meses en una fila, con padding horizontal 10.0 cada uno
      return SizedBox(
        height: 50,
        child: Row(
          children: widget.meses.map((mes) {
            final esActivo = mes == widget.mesActivo;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: ChoiceChip(
                  label: Text(mes),
                  selected: esActivo,
                  onSelected: (_) => widget.onMesSelected(mes),
                ),
              ),
            );
          }).toList(),
        ),
      );
    } else if (width > 700 && width <= 900) {
      // Agrupar meses en páginas de 6
      const int mesesPorPagina = 6;
      int totalPaginas = (widget.meses.length / mesesPorPagina).ceil();
      int start = _paginaMeses * mesesPorPagina;
      int end = (start + mesesPorPagina).clamp(0, widget.meses.length);
      List<String> mesesPagina = widget.meses.sublist(start, end);

      return SizedBox(
        height: 50,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_left),
              onPressed: _paginaMeses > 0
                  ? () {
                      setState(() {
                        _paginaMeses--;
                      });
                    }
                  : null,
            ),
            Expanded(
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 0,
                runSpacing: 0,
                children: mesesPagina.map((mes) {
                  final esActivo = mes == widget.mesActivo;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: ChoiceChip(
                      label: Text(mes),
                      selected: esActivo,
                      onSelected: (_) => widget.onMesSelected(mes),
                    ),
                  );
                }).toList(),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_right),
              onPressed: _paginaMeses < totalPaginas - 1
                  ? () {
                      setState(() {
                        _paginaMeses++;
                      });
                    }
                  : null,
            ),
          ],
        ),
      );
    } else {
      // Agrupar meses en páginas de 4
      const int mesesPorPagina = 4;
      int totalPaginas = (widget.meses.length / mesesPorPagina).ceil();
      int start = _paginaMeses * mesesPorPagina;
      int end = (start + mesesPorPagina).clamp(0, widget.meses.length);
      List<String> mesesPagina = widget.meses.sublist(start, end);

      return SizedBox(
        height: 50,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_left),
              onPressed: _paginaMeses > 0
                  ? () {
                      setState(() {
                        _paginaMeses--;
                      });
                    }
                  : null,
            ),
            Expanded(
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 0,
                runSpacing: 0,
                children: mesesPagina.map((mes) {
                  final esActivo = mes == widget.mesActivo;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: ChoiceChip(
                      label: Text(mes),
                      selected: esActivo,
                      onSelected: (_) => widget.onMesSelected(mes),
                    ),
                  );
                }).toList(),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_right),
              onPressed: _paginaMeses < totalPaginas - 1
                  ? () {
                      setState(() {
                        _paginaMeses++;
                      });
                    }
                  : null,
            ),
          ],
        ),
      );
    }
  }
}
