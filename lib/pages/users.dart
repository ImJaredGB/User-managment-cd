import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../modals/editusers.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  Map<String, dynamic>? usuarioSeleccionado;
  String _searchQuery = '';

  void _mostrarInfoUsuario(Map<String, dynamic> usuario) {
    setState(() {
      usuarioSeleccionado = usuario;
    });

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Información del Usuario"),
        content: SizedBox(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Nombre: ${usuarioSeleccionado?['nombres'] ?? '-'}"),
                Text("Apellido: ${usuarioSeleccionado?['apellidos'] ?? '-'}"),
                Text(
                  "Documento: ${usuarioSeleccionado?['tipoDocumento'] ?? '-'} ${usuarioSeleccionado?['numeroDocumento'] ?? '-'}",
                ),
                Text("Llegada: ${usuarioSeleccionado?['llegada'] ?? '-'}"),
                Text("Salida: ${usuario['salida'] ?? '-'}"),
                Text("Estado: ${usuario['estado'] ?? '-'}"),
                const SizedBox(height: 16),
                SizedBox(
                  width: 150,
                  height: 150,
                  child: QrImageView(
                    data: usuario['numeroDocumento']?.toString() ?? '',
                    version: QrVersions.auto,
                    size: 150,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cerrar"),
          ),
        ],
      ),
    );
  }

  void _editarUsuario(DocumentSnapshot doc) {
    showDialog(
      context: context,
      builder: (ctx) => EditUserDialog(usuarioDoc: doc),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Usuarios")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // Search bar
            TextField(
              decoration: const InputDecoration(
                labelText: 'Buscar por nombre o documento',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
            const SizedBox(height: 16),
            // 📊 Tabla de usuarios scrollable
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('usuarios')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data?.docs ?? [];

                  // Filter documents based on _searchQuery
                  final filteredDocs = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final nombre = (data['nombres'] ?? '')
                        .toString()
                        .toLowerCase();
                    final documento = (data['numeroDocumento'] ?? '')
                        .toString()
                        .toLowerCase();
                    final queryLower = _searchQuery.toLowerCase();
                    return nombre.contains(queryLower) ||
                        documento.contains(queryLower);
                  }).toList();

                  return SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width,
                      child: DataTable(
                        columns: [
                          const DataColumn(label: Text("Nombres")),
                          const DataColumn(label: Text("Apellidos")),
                          DataColumn(
                            label: Text(
                              MediaQuery.of(context).size.width < 1400
                                  ? "T. Doc."
                                  : "Tipo Documento",
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              MediaQuery.of(context).size.width < 1400
                                  ? "N. Doc."
                                  : "Número Documento",
                            ),
                          ),
                          const DataColumn(label: Text("Llegada")),
                          const DataColumn(label: Text("Salida")),
                          const DataColumn(label: Text("Acciones")),
                          const DataColumn(label: Text("Estado")),
                        ],
                        rows: filteredDocs.map((doc) {
                          final usuario = doc.data() as Map<String, dynamic>;
                          return DataRow(
                            cells: [
                              DataCell(
                                Text(usuario["nombres"]?.toString() ?? '-'),
                              ),
                              DataCell(
                                Text(usuario["apellidos"]?.toString() ?? '-'),
                              ),
                              DataCell(
                                Text(
                                  usuario["tipoDocumento"]?.toString() ?? '-',
                                ),
                              ),
                              DataCell(
                                Text(
                                  usuario["numeroDocumento"]?.toString() ?? '-',
                                ),
                              ),
                              DataCell(
                                Text(
                                  usuario["fechaIngreso"] != null
                                      ? (usuario["fechaIngreso"] as Timestamp)
                                            .toDate()
                                            .toString()
                                            .split(' ')[0]
                                      : '-',
                                ),
                              ),
                              DataCell(
                                Text(
                                  usuario["fechaSalida"] != null
                                      ? (usuario["fechaSalida"] as Timestamp)
                                            .toDate()
                                            .toString()
                                            .split(' ')[0]
                                      : '-',
                                ),
                              ),
                              DataCell(
                                Row(
                                  children: [
                                    ElevatedButton(
                                      onPressed: () =>
                                          _mostrarInfoUsuario(usuario),
                                      child: const Text("Ver más"),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: () => _editarUsuario(doc),
                                      child: const Text("Editar"),
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(
                                Text(
                                  usuario["estado"] == null
                                      ? '-'
                                      : (usuario["estado"] == true
                                            ? 'Activo'
                                            : (usuario["estado"] == false
                                                  ? 'Inactivo'
                                                  : '-')),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
