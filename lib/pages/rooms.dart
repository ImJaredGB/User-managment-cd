import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../modals/newroomform.dart';
import '../modals/bunkbedload.dart';

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
                        return SingleChildScrollView(
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('Nomenclatura')),
                              DataColumn(label: Text('Tamaño')),
                              DataColumn(label: Text('Disponibilidad')),
                              DataColumn(label: Text('Estado')),
                              DataColumn(label: Text('Acciones')),
                            ],
                            rows: docs.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final disponibles = data['disponibles'] ?? 0;
                              final ocupadas = data['ocupadas'] ?? 0;
                              final disponible = (disponibles > 0)
                                  ? 'Disponible'
                                  : 'No disponible';
                              final estado = (data['desactivada'] == true)
                                  ? 'Desactiva'
                                  : 'Activa';

                              return DataRow(
                                cells: [
                                  DataCell(Text(data['nomenclatura'] ?? '-')),
                                  DataCell(
                                    FutureBuilder<QuerySnapshot>(
                                      future: FirebaseFirestore.instance
                                          .collection('habitaciones')
                                          .doc(doc.id)
                                          .collection('literas')
                                          .where('active', isEqualTo: true)
                                          .get(),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          );
                                        }
                                        if (!snapshot.hasData) {
                                          return Text('0');
                                        }
                                        final activeCount =
                                            snapshot.data!.docs.length;
                                        return Text(activeCount.toString());
                                      },
                                    ),
                                  ),
                                  DataCell(Text(disponible)),
                                  DataCell(Text(estado)),
                                  DataCell(
                                    Row(
                                      children: [
                                        IconButton(
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (context) =>
                                                  LiterasModal(doc.id),
                                            );
                                          },
                                          icon: Icon(Icons.visibility),
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.edit),
                                          onPressed: () {},
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.delete),
                                          onPressed: () {},
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
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
