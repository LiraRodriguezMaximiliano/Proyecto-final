import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Importación necesaria
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LALA CRUD Admin',
      theme: ThemeData(
        primarySwatch: Colors.red,
        useMaterial3: false, // Usamos v2 para mantener el estilo clásico de los botones
      ),
      home: const LoginPage(),
    );
  }
}

// --- PANTALLA DE LOGIN REAL ---
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  bool _isLoading = false;

  // Función para autenticar con Firebase
  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passController.text.trim(),
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ProductsPage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String mensaje = "Error de autenticación";
      if (e.code == 'user-not-found') mensaje = "El usuario no existe";
      if (e.code == 'wrong-password') mensaje = "Contraseña incorrecta";
      if (e.code == 'invalid-email') mensaje = "Formato de correo no válido";

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensaje), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("LALA - Acceso Administrativo"), backgroundColor: Colors.red),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const Icon(Icons.delivery_dining, size: 100, color: Colors.red),
                const SizedBox(height: 20),
                const Text("Panel de Control", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 30),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: "Correo Electrónico", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: _passController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "Contraseña", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("INICIAR SESIÓN", style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- PANTALLA CRUD ---
class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final CollectionReference productos = FirebaseFirestore.instance.collection('productos');

  void _confirmarEliminar(String id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirmar"),
          content: const Text("¿Estás seguro de que quieres eliminar este producto?"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCELAR")),
            TextButton(
              onPressed: () async {
                await productos.doc(id).delete();
                Navigator.pop(context);
              }, 
              child: const Text("ELIMINAR", style: TextStyle(color: Colors.red))
            ),
          ],
        );
      },
    );
  }

  void showForm([DocumentSnapshot? doc]) {
    final nameCtrl = TextEditingController(text: doc != null ? doc['nombre'] : '');
    final priceCtrl = TextEditingController(text: doc != null ? doc['precio'].toString() : '');
    final stockCtrl = TextEditingController(text: doc != null ? doc['stock'].toString() : '');
    bool esLacteo = doc != null ? (doc['tipo'] == 'Lácteo') : true;

    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            top: 20, left: 20, right: 20, 
            bottom: MediaQuery.of(context).viewInsets.bottom + 20
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(doc == null ? "Nuevo Producto LALA" : "Editar Producto", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Nombre")),
              TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: "Precio"), keyboardType: TextInputType.number),
              TextField(controller: stockCtrl, decoration: const InputDecoration(labelText: "Stock"), keyboardType: TextInputType.number),
              const SizedBox(height: 10),
              const Text("Tipo de Producto:"),
              Row(
                children: [
                  Radio(value: true, groupValue: esLacteo, onChanged: (val) => setModalState(() => esLacteo = val as bool)),
                  const Text("Lácteo"),
                  Radio(value: false, groupValue: esLacteo, onChanged: (val) => setModalState(() => esLacteo = val as bool)),
                  const Text("No Lácteo"),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () async {
                  Map<String, dynamic> data = {
                    'nombre': nameCtrl.text,
                    'precio': priceCtrl.text,
                    'stock': stockCtrl.text,
                    'tipo': esLacteo ? 'Lácteo' : 'No Lácteo',
                  };

                  if (doc == null) {
                    await productos.add(data);
                  } else {
                    await productos.doc(doc.id).update(data);
                  }
                  Navigator.pop(context);
                },
                child: Text(doc == null ? "Guardar en Firebase" : "Actualizar", style: const TextStyle(color: Colors.white)),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Inventario LALA"),
        backgroundColor: Colors.red,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout), 
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()));
              }
            }
          )
        ],
      ),
      body: StreamBuilder(
        stream: productos.snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: Icon(
                    doc['tipo'] == 'Lácteo' ? Icons.local_drink : Icons.local_drink, 
                    color: Colors.red[300]
                  ),
                  title: Text(doc['nombre'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Precio: \$${doc['precio']} | Stock: ${doc['stock']} \nTipo: ${doc['tipo']}"),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => showForm(doc)),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _confirmarEliminar(doc.id)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.red,
        onPressed: () => showForm(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}