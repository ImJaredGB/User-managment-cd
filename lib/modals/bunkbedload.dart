import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LiterasModal extends StatefulWidget {
  final String roomId;
  const LiterasModal(this.roomId, {Key? key}) : super(key: key);

  @override
  State<LiterasModal> createState() => _LiterasModalState();
}

class _LiterasModalState extends State<LiterasModal> {
  String _searchText = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Helper to extract number from litera id for sorting (with leading zeros)
  int _parseLiteraId(String? id) {
    if (id == null) return 0;
    final match = RegExp(r'(\d+)').firstMatch(id);
    if (match != null) {
      return int.tryParse(match.group(1)!) ?? 0;
    }
    return 0;
  }

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
              'Literas de la habitación',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            // Search bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Buscar litera',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (value) {
                setState(() {
                  _searchText = value.trim().toLowerCase();
                });
              },
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('habitaciones')
                  .doc(widget.roomId)
                  .collection('literas')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.data!.docs.isEmpty) {
                  return const Text('No hay literas');
                }

                final literasDocs = snapshot.data!.docs;
                // Convert to list of maps with reference for updates
                final literasList = literasDocs
                    .map(
                      (doc) => {
                        'id': doc['id'],
                        'active': doc['active'],
                        'ref': doc.reference,
                      },
                    )
                    .toList();

                // Filter by search (case-insensitive, substring)
                final filteredLiteras = literasList.where((litera) {
                  if (_searchText.isEmpty) return true;
                  final id = (litera['id'] ?? '').toString().toLowerCase();
                  return id.contains(_searchText);
                }).toList();

                // Sort: active first, then numerically by id with leading zeros
                filteredLiteras.sort((a, b) {
                  final activeA = a['active'] == true ? 1 : 0;
                  final activeB = b['active'] == true ? 1 : 0;
                  if (activeA != activeB) {
                    return activeB - activeA; // active first
                  }
                  final idA = _parseLiteraId(a['id']);
                  final idB = _parseLiteraId(b['id']);
                  return idA.compareTo(idB);
                });

                return SizedBox(
                  height: 300,
                  child: ListView.builder(
                    itemCount: filteredLiteras.length,
                    itemBuilder: (context, index) {
                      final litera = filteredLiteras[index];
                      final bool isActive = litera['active'] == true;
                      final String literaId = litera['id'] ?? '';
                      return ListTile(
                        leading: Icon(
                          isActive ? Icons.bed : Icons.bed_outlined,
                          color: isActive
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey,
                        ),
                        title: Text(
                          literaId.padLeft(3, '0'),
                          style: TextStyle(
                            fontWeight: isActive
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isActive ? null : Colors.grey,
                          ),
                        ),
                        subtitle: Text(
                          isActive ? 'Activa' : 'Inactiva',
                          style: TextStyle(
                            color: isActive ? Colors.green : Colors.red,
                          ),
                        ),
                        trailing: Switch(
                          value: isActive,
                          onChanged: (value) async {
                            try {
                              await litera['ref'].update({'active': value});
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error al actualizar: $e'),
                                ),
                              );
                            }
                          },
                          activeColor: Theme.of(context).colorScheme.primary,
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
