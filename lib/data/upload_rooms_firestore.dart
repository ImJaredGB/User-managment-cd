import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/roomsnames.dart';

Future<void> uploadHabitacionesToFirestore() async {
  final firestore = FirebaseFirestore.instance;

  // Recorremos todas las zonas (Castillo, Restaurante, Piso, Vilanova)
  for (var zona in roomsData) {
    final literas = zona['literas'] as List;

    // Recorremos cada litera (por ejemplo CPB1, C14, etc.)
    for (var litera in literas) {
      final name = litera['name'];
      final levels = litera['levels'] as List;

      // 🔹 Creamos un documento en la colección "habitaciones"
      final habitacionDoc = firestore.collection('habitaciones').doc(name);
      await habitacionDoc.set({'nombre': name, 'zona': zona['zona']});

      // 🔹 Creamos una subcolección "literas" dentro de la habitación
      for (var level in levels) {
        await habitacionDoc.collection('literas').doc(level).set({
          'nombre': level,
          'active': true,
          'fechaIngreso': null,
          'fechaSalida': null,
          'occupied': false,
          'resident': null,
        });
      }

      print('✅ Habitación $name subida con ${levels.length} literas.');
    }
  }

  print(
    '🚀 Todas las habitaciones y literas fueron subidas correctamente a Firestore.',
  );
}

Future<void> updateLiterasStatusInFirestore() async {
  final firestore = FirebaseFirestore.instance;

  final habitacionesSnapshot = await firestore.collection('habitaciones').get();

  int totalLiteras = 0;

  for (var habitacionDoc in habitacionesSnapshot.docs) {
    final literasCollection = habitacionDoc.reference.collection('literas');
    final literasSnapshot = await literasCollection.get();

    int count = 0;

    for (var literaDoc in literasSnapshot.docs) {
      try {
        await literaDoc.reference.update({'active': true, 'occupied': false});
      } catch (e) {
        // Si no existe el documento o no tiene los campos, lo crea
        await literaDoc.reference.set({
          'active': true,
          'occupied': false,
        }, SetOptions(merge: true));
      }
      count++;
      totalLiteras++;
    }

    print('✅ ${habitacionDoc.id}: $count literas actualizadas.');
  }

  print('🚀 Total de literas actualizadas: $totalLiteras');
}
