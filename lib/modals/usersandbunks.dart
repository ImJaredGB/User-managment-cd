//Modal para ver los usuarios y literas de una habitación

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UsersAndBunksModal extends StatelessWidget {
  final String nombre;

  const UsersAndBunksModal(this.nombre, {super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Literas y Usuarios',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('habitaciones')
                  .doc(nombre)
                  .collection('literas')
                  .orderBy('nombre', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.data!.docs.isEmpty) {
                  return const Text('No hay literas registradas');
                }

                final literasDocs = snapshot.data!.docs;

                return SizedBox(
                  height: 350,
                  child: ListView.builder(
                    itemCount: literasDocs.length,
                    itemBuilder: (context, index) {
                      final litera =
                          literasDocs[index].data() as Map<String, dynamic>;
                      final literaId = '${litera['nombre']}';
                      final bool isOccupied = litera['occupied'] == true;
                      final String resident = litera['resident'] ?? '';
                      final fechaIngreso = litera['fechaIngreso'];
                      final fechaSalida = litera['fechaSalida'];

                      String formatDate(dynamic fecha) {
                        if (fecha is Timestamp) {
                          final date = fecha.toDate();
                          return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year.toString().substring(2)}';
                        }
                        return '-';
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.3),
                              spreadRadius: 1,
                              blurRadius: 3,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          leading: Icon(
                            isOccupied ? Icons.bed : Icons.bed_outlined,
                            color: isOccupied
                                ? const Color.fromARGB(255, 161, 28, 37)
                                : Colors.grey,
                          ),
                          title: Text(literaId),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(isOccupied ? 'Ocupada' : 'Desocupada'),
                              if (isOccupied)
                                FutureBuilder<QuerySnapshot>(
                                  future: FirebaseFirestore.instance
                                      .collection('usuarios')
                                      .where(
                                        'numeroDocumento',
                                        isEqualTo: resident,
                                      )
                                      .limit(1)
                                      .get(),
                                  builder: (context, userSnapshot) {
                                    if (userSnapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Text(
                                        'Cargando datos del usuario...',
                                      );
                                    }

                                    if (userSnapshot.hasError) {
                                      return const Text(
                                        'Error al cargar el usuario',
                                      );
                                    }

                                    String nombreCompleto = '';
                                    if (userSnapshot.hasData &&
                                        userSnapshot.data!.docs.isNotEmpty) {
                                      final userData =
                                          userSnapshot.data!.docs.first.data()
                                              as Map<String, dynamic>;
                                      final nombres = userData['nombres'] ?? '';
                                      final apellidos =
                                          userData['apellidos'] ?? '';
                                      nombreCompleto = '$nombres $apellidos';
                                    }

                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Documento: $resident'),
                                        if (nombreCompleto.isNotEmpty)
                                          Text('Nombre: $nombreCompleto'),
                                        Text(
                                          'Ingreso: ${formatDate(fechaIngreso)}',
                                        ),
                                        Text(
                                          'Salida: ${formatDate(fechaSalida)}',
                                        ),
                                      ],
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      ),
    );
  }
}
