import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../modals/newroomform.dart';
import '../modals/bunkbedload.dart';
import '../modals/usersandbunks.dart';

class RoomsPage extends StatefulWidget {
  const RoomsPage({super.key});

  @override
  _RoomsPageState createState() => _RoomsPageState();
}

class _RoomsPageState extends State<RoomsPage> {
  final List<String> zones = ['Castillo', 'Restaurante', 'Piso', 'Vilanova'];
  String selectedZone = 'Castillo';
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Habitaciones')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sidebar: Zone selection
            Container(
              width: 150,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Zonas', style: Theme.of(context).textTheme.titleMedium),
                  SizedBox(height: 16),
                  ...zones.map(
                    (zone) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selectedZone == zone
                              ? Colors.blueGrey
                              : const Color.fromARGB(255, 241, 241, 241),
                          foregroundColor: selectedZone == zone
                              ? Colors.white
                              : const Color.fromARGB(221, 0, 0, 0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: selectedZone == zone
                                  ? Colors.blueGrey
                                  : const Color.fromARGB(0, 254, 254, 254),
                              width: 1,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 8,
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            selectedZone = zone;
                          });
                        },
                        child: Text(zone),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 24),
            // Main area: DataTable
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Habitaciones en $selectedZone',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('Recargar'),
                        onPressed: () {
                          setState(
                            () {},
                          ); // Fuerza reconstrucción solo de esta sección
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(
                            255,
                            96,
                            125,
                            139,
                          ),
                          foregroundColor: const Color.fromARGB(
                            255,
                            255,
                            255,
                            255,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('habitaciones')
                          .where('zona', isEqualTo: selectedZone)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Center(child: Text('No hay habitaciones'));
                        }
                        final docs = snapshot.data!.docs;
                        final filteredDocs = docs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final nomenclatura = (data['nomenclatura'] ?? '')
                              .toString()
                              .toLowerCase();
                          return nomenclatura.contains(
                            searchQuery.toLowerCase(),
                          );
                        }).toList();

                        // Prepare a future per habitacion to get its active literas
                        final literasFutures = filteredDocs.map((doc) {
                          return FirebaseFirestore.instance
                              .collection('habitaciones')
                              .doc(doc.id)
                              .collection('literas')
                              .where('active', isEqualTo: true)
                              .get();
                        }).toList();

                        return FutureBuilder<List<QuerySnapshot>>(
                          future: Future.wait(literasFutures),
                          builder: (context, litSnapshots) {
                            if (litSnapshots.connectionState ==
                                ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator());
                            }
                            if (litSnapshots.hasError) {
                              return Center(
                                child: Text('Error: ${litSnapshots.error}'),
                              );
                            }
                            final litList = litSnapshots.data ?? [];

                            List<DataRow> rows = [];

                            for (var i = 0; i < filteredDocs.length; i++) {
                              final doc = filteredDocs[i];
                              final data = doc.data() as Map<String, dynamic>;

                              final literasSnap = litList.length > i
                                  ? litList[i]
                                  : null;
                              final literasActivas = literasSnap?.docs ?? [];

                              final totalActivas = literasActivas.length;
                              final ocupadas = literasActivas
                                  .where(
                                    (l) =>
                                        (l.data()
                                            as Map<
                                              String,
                                              dynamic
                                            >)['occupied'] ==
                                        true,
                                  )
                                  .length;

                              String disponibilidad;
                              if (totalActivas == 0) {
                                disponibilidad = 'Disponible';
                              } else if (ocupadas == 0) {
                                disponibilidad = 'Disponible';
                              } else if (ocupadas == totalActivas) {
                                disponibilidad = 'Lleno';
                              } else {
                                disponibilidad = 'Disponible';
                              }

                              rows.add(
                                DataRow(
                                  cells: [
                                    DataCell(Text(data['nomenclatura'] ?? '-')),
                                    DataCell(Text(totalActivas.toString())),
                                    DataCell(Text(disponibilidad)),
                                    DataCell(
                                      Text(
                                        (data['desactivada'] == true)
                                            ? 'Desactiva'
                                            : 'Activa',
                                      ),
                                    ),
                                    DataCell(
                                      Row(
                                        children: [
                                          IconButton(
                                            onPressed:
                                                (data['desactivada'] == true)
                                                ? null
                                                : () {
                                                    showDialog(
                                                      context: context,
                                                      builder: (context) =>
                                                          UsersAndBunksModal(
                                                            doc.id,
                                                          ),
                                                    );
                                                  },
                                            icon: Icon(Icons.visibility),
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.edit),
                                            onPressed:
                                                (data['desactivada'] == true)
                                                ? null
                                                : () {
                                                    showDialog(
                                                      context: context,
                                                      builder: (context) =>
                                                          LiterasModal(doc.id),
                                                    );
                                                  },
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              Icons.delete,
                                              color:
                                                  (data['desactivada'] == true)
                                                  ? Colors.red
                                                  : Colors.grey[800],
                                            ),
                                            onPressed: () async {
                                              final literasSnap =
                                                  await FirebaseFirestore
                                                      .instance
                                                      .collection(
                                                        'habitaciones',
                                                      )
                                                      .doc(doc.id)
                                                      .collection('literas')
                                                      .get();

                                              final tieneDatos = literasSnap
                                                  .docs
                                                  .any((litera) {
                                                    final lData = litera.data();
                                                    return (lData['occupied'] ==
                                                        true);
                                                  });

                                              if (tieneDatos) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'No se puede desactivar esta habitación porque tiene literas ocupadas.',
                                                    ),
                                                  ),
                                                );
                                                return;
                                              }

                                              final nuevoEstado =
                                                  !(data['desactivada'] ==
                                                      true);
                                              await FirebaseFirestore.instance
                                                  .collection('habitaciones')
                                                  .doc(doc.id)
                                                  .update({
                                                    'desactivada': nuevoEstado,
                                                  });

                                              setState(() {});
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return SingleChildScrollView(
                              child: DataTable(
                                columns: const [
                                  DataColumn(label: Text('Nomenclatura')),
                                  DataColumn(label: Text('Tamaño')),
                                  DataColumn(label: Text('Disponibilidad')),
                                  DataColumn(label: Text('Estado')),
                                  DataColumn(label: Text('Acciones')),
                                ],
                                rows: rows,
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 24),
            // Tool sidebar: Search and actions
            Container(
              width: 200,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Buscar',
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Colors.black54, // icono gris oscuro
                      ),
                      filled: true,
                      fillColor: Colors.white, // fondo blanco
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: const BorderSide(
                          color: Colors.black,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: const BorderSide(
                          color: Colors.black,
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                    ),
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                  ),
                  SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: Icon(Icons.add),
                    label: Text('Agregar'),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => HabitacionForm(),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromARGB(255, 241, 241, 241),
                      foregroundColor: const Color.fromARGB(221, 0, 0, 0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide.none,
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: Icon(Icons.tune),
                    label: Text('Organizar'),
                    onPressed: () {
                      // Placeholder for organize action
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromARGB(255, 241, 241, 241),
                      foregroundColor: const Color.fromARGB(221, 0, 0, 0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
