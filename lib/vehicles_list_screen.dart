import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_3/vehicle_details_screen.dart';
import 'add_vehicle_screen.dart';
import 'widgets/custom_drawer.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VehicleListScreen extends StatelessWidget {
  const VehicleListScreen({Key? key}) : super(key: key);

  Future<void> _deleteVehicle(BuildContext context, String vehicleId) async {
    // Exibe um diálogo de confirmação para exclusão
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Excluir Veículo'),
          content:
              const Text('Tem certeza de que deseja excluir este veículo?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Fecha o diálogo
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await FirebaseFirestore.instance
                      .collection('vehicles')
                      .doc(vehicleId)
                      .delete(); // Exclui o veículo
                  Navigator.pop(context); // Fecha o diálogo após excluir
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Veículo excluído com sucesso!')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao excluir: ${e.toString()}')),
                  );
                }
              },
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Obtém o usuário autenticado
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // Se o usuário não estiver logado, exibe uma mensagem
      return const Center(child: Text('Você precisa estar logado.'));
    }
    return Scaffold(
      drawer: const CustomDrawer(),
      appBar: AppBar(title: const Text('Meus Veículos')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('vehicles')
            .where('userId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Erro ao carregar veículos.'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Nenhum veículo encontrado.'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final vehicle = snapshot.data!.docs[index];

              return ListTile(
                title: Text(vehicle['name']),
                subtitle: Text(vehicle['model']),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_forward),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                VehicleDetailScreen(vehicleId: vehicle.id),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deleteVehicle(context, vehicle.id),
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          VehicleDetailScreen(vehicleId: vehicle.id),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddVehicleScreen()),
          ).then((result) {
            if (result != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(result)),
              );
            }
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
