const Map<String, String> zonasAbreviadas = {
  'Castillo': 'C',
  'Restaurante': 'R',
  'Piso': 'P',
  'Vilanova': 'V',
};

const Map<String, String> nivelesAbreviados = {
  'PlantaBaja': 'PB',
  'PlantaMedia': 'PM',
  'PlantaAlta': 'PA',
};

/// Genera las nomenclaturas de habitaciones y literas dinámicamente
Map<String, List<String>> generateNomenclaturas({
  int maxNumeroHabitacion = 30,
  int maxLiteras = 12,
}) {
  final Map<String, List<String>> resultado = {};

  zonasAbreviadas.forEach((zona, abrevZona) {
    final List<String> lista = [];

    nivelesAbreviados.forEach((nivel, abrevNivel) {
      for (int numero = 1; numero <= maxNumeroHabitacion; numero++) {
        // Habitacion base sin literas
        lista.add('$abrevZona$abrevNivel$numero');

        for (int espacio = 1; espacio <= 2; espacio++) {
          for (int litera = 1; litera <= maxLiteras; litera++) {
            lista.add('$abrevZona$abrevNivel$numero\_${espacio}L$litera');
          }
        }
      }
    });

    resultado[zona] = lista;
  });

  return resultado;
}
