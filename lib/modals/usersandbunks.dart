import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UsersAndBunksModal extends StatelessWidget {
  final String roomId;

  const UsersAndBunksModal(this.roomId, {super.key});

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
                  .doc(roomId)
                  .collection('literas')
                  .orderBy('id', descending: false)
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
                      final literaId = litera['id'];
                      final isActive = litera['active'] == true;
                      final isOccupied = litera['occupied'] == true;

                      return FutureBuilder<QuerySnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('usuarios')
                            .where('litera', isEqualTo: literaId)
                            .limit(1)
                            .get(),
                        builder: (context, userSnapshot) {
                          return ListTile(
                            leading: Icon(
                              isOccupied ? Icons.bed : Icons.bed_outlined,
                              color: isOccupied ? Colors.orange : Colors.grey,
                            ),
                            title: Text(literaId ?? ''),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(isOccupied ? 'Ocupada' : 'Desocupada'),
                                if (isOccupied &&
                                    userSnapshot.hasData &&
                                    userSnapshot.data!.docs.isNotEmpty)
                                  Builder(
                                    builder: (_) {
                                      final userData =
                                          userSnapshot.data!.docs.first.data()
                                              as Map<String, dynamic>;
                                      final nombres = userData['nombres'] ?? '';
                                      final apellidos =
                                          userData['apellidos'] ?? '';
                                      final tipoDoc =
                                          userData['tipoDocumento'] ?? '';
                                      final numDoc =
                                          userData['numeroDocumento'] ?? '';
                                      final fechaIngreso =
                                          userData['fechaIngreso'];
                                      final fechaSalida =
                                          userData['fechaSalida'];

                                      String formatDate(dynamic fecha) {
                                        if (fecha is Timestamp) {
                                          final date = fecha.toDate();
                                          return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year.toString().substring(2)}';
                                        }
                                        return '-';
                                      }

                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Nombre: $nombres $apellidos',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            'Ingreso: ${formatDate(fechaIngreso)}',
                                          ),
                                          Text(
                                            'Salida: ${formatDate(fechaSalida)}',
                                          ),
                                          Text('Documento: $tipoDoc $numDoc'),
                                        ],
                                      );
                                    },
                                  ),
                              ],
                            ),
                          );
                        },
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
