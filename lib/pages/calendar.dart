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
  int _paginaDias = 0;

  // CACHÉ EN MEMORIA
  Map<String, List<QueryDocumentSnapshot>> _habitacionesCache = {};
  Map<String, List<QueryDocumentSnapshot>> _literasCache = {};
  Map<String, Map<String, dynamic>> _usuariosCache = {};
  bool _cargandoCache = true;
  String? _errorCache;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    mesActivo = meses[now.month - 1];
    _precargarDatos();
  }

  Future<void> _precargarDatos() async {
    try {
      // Cargar todos los usuarios
      final usuariosSnapshot = await FirebaseFirestore.instance
          .collection('usuarios')
          .get();
      for (var doc in usuariosSnapshot.docs) {
        _usuariosCache[doc['numeroDocumento']] = doc.data();
      }

      // Cargar todas las habitaciones por zona
      for (var zona in zonas) {
        final habSnapshot = await FirebaseFirestore.instance
            .collection('habitaciones')
            .where('zona', isEqualTo: zona)
            .get();
        _habitacionesCache[zona] = habSnapshot.docs;

        // Cargar todas las literas de cada habitación
        final futures = habSnapshot.docs.map((habDoc) async {
          final literasSnapshot = await habDoc.reference
              .collection('literas')
              .get();
          return literasSnapshot.docs;
        });
        final literasList = await Future.wait(futures);
        _literasCache[zona] = literasList.expand((x) => x).toList();
      }
      setState(() {
        _cargandoCache = false;
        _errorCache = null;
      });
    } catch (e) {
      setState(() {
        _cargandoCache = false;
        _errorCache = e.toString();
      });
    }
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
    final width = MediaQuery.of(context).size.width;
    int diasPorPagina;
    if (width < 600) {
      diasPorPagina = 10;
    } else if (width < 900) {
      diasPorPagina = 15;
    } else {
      diasPorPagina = totalDias;
    }
    int totalPaginas = (totalDias / diasPorPagina).ceil();
    int startDia = _paginaDias * diasPorPagina;
    int endDia = (startDia + diasPorPagina).clamp(0, totalDias);

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
      ...List.generate(endDia - startDia, (index) {
        final diaNumero = startDia + index + 1;
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

    // Si estamos cargando la caché, mostrar loader
    if (_cargandoCache) {
      return const Expanded(child: Center(child: CircularProgressIndicator()));
    }
    if (_errorCache != null) {
      return Expanded(child: Center(child: Text('Error: $_errorCache')));
    }

    final habitaciones = _habitacionesCache[zona] ?? [];
    final literas = _literasCache[zona] ?? [];

    final searchText = searchController.text.trim().toLowerCase();
    final filteredLiteras =
        (searchText.isEmpty
                ? literas
                : literas.where((literaDoc) {
                    final data = literaDoc.data() as Map<String, dynamic>;
                    final nombre = (data['nombres'] ?? '')
                        .toString()
                        .toLowerCase();
                    final resident = (data['resident'] ?? '')
                        .toString()
                        .toLowerCase();
                    return nombre.contains(searchText) ||
                        resident.contains(searchText);
                  }).toList())
            // Mostrar solo literas con un residente asignado por defecto
            .where((literaDoc) {
              final data = literaDoc.data() as Map<String, dynamic>;
              final resident = (data['resident'] ?? '').toString().trim();
              return resident.isNotEmpty;
            })
            .toList();

    List<DataRow> filas = filteredLiteras.map((literaDoc) {
      final data = literaDoc.data() as Map<String, dynamic>;
      final literaName = data['nombre'] ?? '-';
      final resident = data['resident'] ?? '-';
      final fechaIngreso = (data['fechaIngreso'] is Timestamp)
          ? (data['fechaIngreso'] as Timestamp).toDate()
          : null;
      final fechaSalida = (data['fechaSalida'] is Timestamp)
          ? (data['fechaSalida'] as Timestamp).toDate()
          : null;
      final occupied = data['occupied'] == true;
      final active = data['active'] == true;

      // Generar las celdas por día
      List<DataCell> diaCeldas = List.generate(endDia - startDia, (index) {
        final dia = startDia + index + 1;
        bool ocupado = false;

        if (fechaIngreso != null && fechaSalida != null) {
          final primerDiaMes = DateTime(anioActual, mesIndex, 1);
          final ultimoDiaMes = DateTime(anioActual, mesIndex, totalDias);
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
              color: ocupado
                  ? Colors.green
                  : (active ? Colors.grey[300] : Colors.red[100]),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      });

      // Obtener nombre del residente desde la caché de usuarios
      String nombreResidente = resident;
      if (resident != '-' && resident.toString().trim().isNotEmpty) {
        nombreResidente = _usuariosCache[resident]?['nombres'] ?? resident;
      }

      return DataRow(
        cells: [
          DataCell(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(literaName, style: const TextStyle(fontSize: 12)),
                if (resident != '-' && resident.toString().trim().isNotEmpty)
                  Text(
                    nombreResidente,
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  )
                else
                  const SizedBox.shrink(),
              ],
            ),
          ),
          ...diaCeldas,
        ],
      );
    }).toList();

    // Mostrar la tabla final
    return Expanded(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
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
            ),
          ),
          // Controles de paginación de días
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_left),
                onPressed: _paginaDias > 0
                    ? () => setState(() => _paginaDias--)
                    : null,
              ),
              Text('Días ${startDia + 1}-${endDia}'),
              IconButton(
                icon: const Icon(Icons.arrow_right),
                onPressed: _paginaDias < totalPaginas - 1
                    ? () => setState(() => _paginaDias++)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(title: const Text("Calendario")),
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
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(
                              67,
                              221,
                              231,
                              236,
                            ),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: Colors.transparent,
                                width: 1,
                              ),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: TextField(
                            controller: searchController,
                            style: const TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                              hintText: "Buscar...",
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25),
                                borderSide: const BorderSide(),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25),
                                borderSide: const BorderSide(),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 12,
                              ),
                            ),
                            onSubmitted: (value) {
                              setState(() {
                                searchController.text = value;
                              });
                            },
                          ),
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
                              label: Text(
                                zona,
                                style: TextStyle(
                                  color: esActivo ? Colors.white : Colors.black,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              selected: esActivo,
                              onSelected: (_) {
                                setState(() {
                                  zonaActual = zona;
                                });
                              },
                              selectedColor: const Color(0xFFA11C25),
                              backgroundColor: const Color.fromARGB(
                                67,
                                221,
                                231,
                                236,
                              ),
                              checkmarkColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(
                                  color: esActivo
                                      ? const Color(0xFFA11C25)
                                      : Colors.transparent,
                                  width: 1,
                                ),
                              ),
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
                                  label: Text(
                                    zona,
                                    style: TextStyle(
                                      color: esActivo
                                          ? Colors.white
                                          : Colors.black,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  selected: esActivo,
                                  onSelected: (_) {
                                    setState(() {
                                      zonaActual = zona;
                                    });
                                  },
                                  selectedColor: const Color(0xFFA11C25),
                                  backgroundColor: const Color.fromARGB(
                                    67,
                                    221,
                                    231,
                                    236,
                                  ),
                                  checkmarkColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    side: BorderSide(
                                      color: esActivo
                                          ? const Color(0xFFA11C25)
                                          : Colors.transparent,
                                      width: 1,
                                    ),
                                  ),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(67, 221, 231, 236),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.transparent, width: 1),
                ),
                elevation: 0,
              ),
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
                  label: Text(
                    mes,
                    style: TextStyle(
                      color: esActivo
                          ? const Color.fromARGB(255, 255, 255, 255)
                          : const Color.fromARGB(221, 0, 0, 0),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  checkmarkColor: Colors.white,
                  selected: esActivo,
                  onSelected: (_) => widget.onMesSelected(mes),
                  selectedColor: const Color(0xFFA11C25),
                  backgroundColor: const Color.fromARGB(67, 221, 231, 236),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: esActivo
                          ? const Color(0xFFA11C25)
                          : const Color.fromARGB(0, 254, 254, 254),
                      width: 1,
                    ),
                  ),
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
                      label: Text(
                        mes,
                        style: TextStyle(
                          color: esActivo
                              ? const Color.fromARGB(255, 255, 255, 255)
                              : const Color.fromARGB(221, 0, 0, 0),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      checkmarkColor: Colors.white,
                      selected: esActivo,
                      onSelected: (_) => widget.onMesSelected(mes),
                      selectedColor: const Color(0xFFA11C25),
                      backgroundColor: const Color.fromARGB(67, 221, 231, 236),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: esActivo
                              ? const Color(0xFFA11C25)
                              : const Color.fromARGB(0, 254, 254, 254),
                          width: 1,
                        ),
                      ),
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
                      label: Text(
                        mes,
                        style: TextStyle(
                          color: esActivo
                              ? const Color.fromARGB(255, 255, 255, 255)
                              : const Color.fromARGB(221, 0, 0, 0),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      checkmarkColor: Colors.white,
                      selected: esActivo,
                      onSelected: (_) => widget.onMesSelected(mes),
                      selectedColor: const Color(0xFFA11C25),
                      backgroundColor: const Color.fromARGB(67, 221, 231, 236),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: esActivo
                              ? const Color(0xFFA11C25)
                              : const Color.fromARGB(0, 254, 254, 254),
                          width: 1,
                        ),
                      ),
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
