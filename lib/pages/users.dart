import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../modals/editusers.dart';
import '../modals/newuser.dart';

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
                Text(
                  "Llegada: ${usuarioSeleccionado?['fechaIngreso'] != null ? ((usuarioSeleccionado?['fechaIngreso'] as Timestamp).toDate().day.toString().padLeft(2, '0') + '/' + (usuarioSeleccionado?['fechaIngreso'] as Timestamp).toDate().month.toString().padLeft(2, '0') + '/' + (usuarioSeleccionado?['fechaIngreso'] as Timestamp).toDate().year.toString()) : '-'}",
                ),
                Text(
                  "Salida: ${usuarioSeleccionado?['fechaSalida'] != null ? ((usuarioSeleccionado?['fechaSalida'] as Timestamp).toDate().day.toString().padLeft(2, '0') + '/' + (usuarioSeleccionado?['fechaSalida'] as Timestamp).toDate().month.toString().padLeft(2, '0') + '/' + (usuarioSeleccionado?['fechaSalida'] as Timestamp).toDate().year.toString()) : '-'}",
                ),
                Text("Estado: ${usuario['estado'] ?? '-'}"),
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
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => const NewUserModal(),
                  );
                },
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text("Añadir usuario"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFA11C25),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                labelText: 'Buscar por nombre o documento',
                prefixIcon: const Icon(
                  Icons.search,
                  color: Colors.black54, // Ícono gris oscuro
                ),
                filled: true,
                fillColor: Colors.white, // Fondo blanco
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: const BorderSide(color: Colors.black, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: const BorderSide(color: Colors.black, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
              ),
              style: const TextStyle(fontSize: 13, color: Colors.black87),
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

                  final screenWidth = MediaQuery.of(context).size.width;

                  if (screenWidth < 1150) {
                    return const Center(
                      child: Text(
                        'Agranda un poco la pantalla para mostrar la información',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }

                  return SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SizedBox(
                      width: screenWidth,
                      child: DataTable(
                        columns: [
                          const DataColumn(label: Text("Nombres")),
                          const DataColumn(label: Text("Apellidos")),
                          DataColumn(
                            label: Text(
                              screenWidth < 1400 ? "T. Doc." : "Tipo Documento",
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              screenWidth < 1400
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
                                Text(() {
                                  final docNum =
                                      usuario["numeroDocumento"]?.toString() ??
                                      '-';
                                  if (docNum.length > 10) {
                                    return '${docNum.substring(0, 9)}...';
                                  }
                                  return docNum;
                                }()),
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
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFFA11C25,
                                        ),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          side: BorderSide.none,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8,
                                          horizontal: 12,
                                        ),
                                      ),
                                      onPressed: () =>
                                          _mostrarInfoUsuario(usuario),
                                      child: const Text("Ver más"),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFFA11C25,
                                        ),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          side: BorderSide.none,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8,
                                          horizontal: 12,
                                        ),
                                      ),
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
