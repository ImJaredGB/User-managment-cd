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
                          foregroundColor: selectedZone == zone
                              ? Colors.white
                              : Colors.black,
                          backgroundColor: selectedZone == zone
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey[200],
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
                          backgroundColor: Colors.blueGrey,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
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

                        // Prepare a future per habitacion to get its active literas
                        final literasFutures = docs.map((doc) {
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

                            for (var i = 0; i < docs.length; i++) {
                              final doc = docs[i];
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
                                            onPressed: () {
                                              showDialog(
                                                context: context,
                                                builder: (context) =>
                                                    UsersAndBunksModal(doc.id),
                                              );
                                            },
                                            icon: Icon(Icons.visibility),
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.edit),
                                            onPressed: () {
                                              showDialog(
                                                context: context,
                                                builder: (context) =>
                                                    LiterasModal(doc.id),
                                              );
                                            },
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.delete),
                                            onPressed: () {},
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
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
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
                  ),
                  SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: Icon(Icons.tune),
                    label: Text('Organizar'),
                    onPressed: () {
                      // Placeholder for organize action
                    },
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
