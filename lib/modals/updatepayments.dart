import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdatePaymentsModal extends StatefulWidget {
  final DocumentReference usuarioRef;
  const UpdatePaymentsModal({super.key, required this.usuarioRef});

  @override
  State<UpdatePaymentsModal> createState() => _UpdatePaymentsModalState();
}

class _UpdatePaymentsModalState extends State<UpdatePaymentsModal> {
  final Map<String, bool> estadoMes = {};
  final Map<String, int> anioMes = {};

  @override
  void initState() {
    super.initState();
    _cargarPagos();
  }

  Future<void> _cargarPagos() async {
    final snapshot = await widget.usuarioRef.collection('pagos').get();

    final mesesOrden = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];

    final temp = <String, Map<String, dynamic>>{};
    for (final doc in snapshot.docs) {
      temp[doc.id] = {
        'pagado': doc['pagado'] ?? false,
        'anio': doc['anio'] ?? DateTime.now().year,
      };
    }

    // Crear una lista de pares (mes, año)
    final mesesConAnio = temp.entries
        .map((e) => {'mes': e.key, 'anio': e.value['anio']})
        .toList();

    // Ordenar primero por año, luego por orden natural del mes
    mesesConAnio.sort((a, b) {
      final anioComp = (a['anio'] as int).compareTo(b['anio'] as int);
      if (anioComp != 0) return anioComp;
      return mesesOrden
          .indexOf(a['mes'] as String)
          .compareTo(mesesOrden.indexOf(b['mes'] as String));
    });

    estadoMes.clear();
    anioMes.clear();
    for (final item in mesesConAnio) {
      final mes = item['mes'] as String;
      estadoMes[mes] = temp[mes]!['pagado'];
      anioMes[mes] = temp[mes]!['anio'];
    }

    setState(() {});
  }

  int tempAnio(String mes) {
    // Obtiene el año del documento del mes si existe, o el actual si no
    return anioMes[mes] ?? DateTime.now().year;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      title: const Text(
        'Actualizar Pagos',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 400,
        child: estadoMes.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                shrinkWrap: true,
                itemCount: estadoMes.length,
                itemBuilder: (context, index) {
                  final mes = estadoMes.keys.elementAt(index);
                  return ListTile(
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mes,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          tempAnio(mes).toString(),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: estadoMes[mes] ?? false,
                          activeColor: const Color(0xFFA11C25),
                          onChanged: (value) async {
                            setState(() {
                              estadoMes[mes] = value;
                            });
                            await widget.usuarioRef
                                .collection('pagos')
                                .doc(mes)
                                .update({'pagado': value});
                          },
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: (estadoMes[mes] ?? false)
                              ? () async {
                                  DocumentSnapshot usuarioDoc;
                                  try {
                                    usuarioDoc = await widget.usuarioRef.get();
                                  } catch (e) {
                                    debugPrint(
                                      'Error al obtener el documento del usuario: $e',
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Error al obtener los datos del usuario: $e',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return;
                                  }

                                  if (!usuarioDoc.exists) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'No se encontró el usuario en la base de datos',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return;
                                  }

                                  final usuario =
                                      usuarioDoc.data() as Map<String, dynamic>;

                                  final correo = usuario['correo'];
                                  final nombres = usuario['nombres'] ?? '';
                                  final apellidos = usuario['apellidos'] ?? '';
                                  final numeroDocumento =
                                      usuario['numeroDocumento'] ??
                                      'No especificado';
                                  final litera =
                                      usuario['litera'] ??
                                      'Sin litera asignada';
                                  final fechaIngreso =
                                      (usuario['fechaIngreso'] as Timestamp?)
                                          ?.toDate();
                                  final fechaSalida =
                                      (usuario['fechaSalida'] as Timestamp?)
                                          ?.toDate();
                                  final zona =
                                      usuario['zona'] ?? 'No especificada';
                                  final anio = tempAnio(mes);

                                  if (correo == null || correo.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'El usuario no tiene correo registrado',
                                        ),
                                        backgroundColor: Colors.orange,
                                      ),
                                    );
                                    return;
                                  }

                                  // Armar correo personalizado
                                  try {
                                    final uri = Uri(
                                      scheme: 'mailto',
                                      path: correo,
                                      query: Uri.encodeQueryComponent(
                                        'subject=Boleta de pago - $mes $anio&body=Estimado/a $nombres,\n\n'
                                        'Se confirma la recepción del pago correspondiente al mes de $mes del año $anio.\n\n'
                                        'Detalles del pago:\n'
                                        '- Nombre completo: $nombres $apellidos\n'
                                        '- Número de documento: $numeroDocumento\n'
                                        '- Litera asignada: $litera\n'
                                        '- Mes cancelado: $mes $anio\n\n'
                                        'Gracias por cumplir con su obligación de pago.\n\n'
                                        'Atentamente,\nAdministración de Residencia de British',
                                      ),
                                    );

                                    if (await canLaunchUrl(uri)) {
                                      await launchUrl(
                                        uri,
                                        mode: LaunchMode.externalApplication,
                                      );
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Boleta preparada para enviar a $correo',
                                          ),
                                          backgroundColor: Colors.green[600],
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'No se pudo abrir el cliente de correo.',
                                          ),
                                          backgroundColor: Colors.orange,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    debugPrint(
                                      'Error al intentar enviar correo: $e',
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Error al intentar enviar el correo: $e',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFA11C25),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            textStyle: const TextStyle(fontSize: 12),
                          ),
                          child: const Text(
                            'Enviar boleta',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, estadoMes);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFA11C25),
          ),
          child: const Text('Guardar', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
