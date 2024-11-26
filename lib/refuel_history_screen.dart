import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_fuel_record_screen.dart';
import 'refuel_detail_screen.dart'; // Importando a tela de detalhes de abastecimento
import 'widgets/custom_drawer.dart';

class RefuelHistoryScreen extends StatelessWidget {
  const RefuelHistoryScreen({Key? key}) : super(key: key);

  Future<void> _deleteRefuel(BuildContext context, String refuelId) async {
    // Exibe um diálogo de confirmação para exclusão
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Excluir Abastecimento'),
          content: const Text(
              'Tem certeza de que deseja excluir este abastecimento?'),
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
                      .collection('fuelRecords')
                      .doc(refuelId)
                      .delete(); // Exclui o abastecimento
                  Navigator.pop(context); // Fecha o diálogo após excluir
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Abastecimento excluído com sucesso!')),
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
      appBar: AppBar(title: const Text('Histórico de Abastecimentos')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('fuelRecords')
            .where('userId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(
                child: Text('Erro ao carregar os abastecimentos.'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
                child: Text('Nenhum abastecimento encontrado.'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final refuel = snapshot.data!.docs[index];
              final date = (refuel['date'] as Timestamp).toDate();

              return GestureDetector(
                onTap: () {
                  // Navega para a tela de detalhes ao clicar no item
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RefuelDetailScreen(
                        refuelId: refuel
                            .id, // Passa o id do abastecimento para a tela de detalhes
                      ),
                    ),
                  );
                },
                child: ListTile(
                  leading: const Icon(Icons.local_gas_station),
                  title: Text('Litros: ${refuel['liters']}'),
                  subtitle: Text(
                    'Data: ${date.day}/${date.month}/${date.year}\nKM: ${refuel['mileage']}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteRefuel(context, refuel.id),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const AddFuelRecordScreen()),
          ).then((result) {
            if (result != null) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(result)));
            }
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
