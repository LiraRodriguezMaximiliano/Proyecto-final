class Empleado {
  String id;
  String nombre;
  String puesto;
  int numeroEmpleado;

  Empleado({required this.id, required this.nombre, required this.puesto, required this.numeroEmpleado});

  // Convierte de Firestore a Objeto
  factory Empleado.fromMap(Map<String, dynamic> data, String id) {
    return Empleado(
      id: id,
      nombre: data['nombre'] ?? '',
      puesto: data['puesto'] ?? '',
      numeroEmpleado: data['numeroEmpleado'] ?? 0,
    );
  }

  // Convierte de Objeto a JSON para enviar a Firestore
  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'puesto': puesto,
      'numeroEmpleado': numeroEmpleado,
    };
  }
}