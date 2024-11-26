import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VehicleDetailScreen extends StatefulWidget {
  final String vehicleId;

  const VehicleDetailScreen({Key? key, required this.vehicleId})
      : super(key: key);

  @override
  State<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends State<VehicleDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _plateController = TextEditingController();

  bool _isLoading = true;
  double? _averageConsumption; // Para armazenar o consumo médio

  @override
  void initState() {
    super.initState();
    _fetchVehicleData();
    _calculateAverageConsumption();
  }

  Future<void> _fetchVehicleData() async {
    try {
      DocumentSnapshot vehicleSnapshot = await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(widget.vehicleId)
          .get();

      if (vehicleSnapshot.exists) {
        final vehicleData = vehicleSnapshot.data() as Map<String, dynamic>;
        _nameController.text = vehicleData['name'] ?? '';
        _modelController.text = vehicleData['model'] ?? '';
        _yearController.text = vehicleData['year'] ?? '';
        _plateController.text = vehicleData['plate'] ?? '';
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar dados: ${e.toString()}')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _calculateAverageConsumption() async {
    try {
      QuerySnapshot refuelsSnapshot = await FirebaseFirestore.instance
          .collection('fuelRecords')
          .where('vehicleId', isEqualTo: widget.vehicleId)
          .get();

      if (refuelsSnapshot.docs.isNotEmpty) {
        double totalKilometers = 0;
        double totalLiters = 0;

        for (var refuel in refuelsSnapshot.docs) {
          final data = refuel.data() as Map<String, dynamic>;
          totalKilometers += (data['mileage'] ?? 0) as double;
          totalLiters += (data['liters'] ?? 0) as double;
        }

        if (totalLiters > 0) {
          _averageConsumption = totalKilometers / totalLiters;
        } else {
          _averageConsumption = 0; // Caso não haja abastecimento
        }
      } else {
        _averageConsumption = null; // Nenhum dado de abastecimento
      }

      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Erro ao calcular consumo médio: ${e.toString()}')),
      );
    }
  }

  Future<void> _updateVehicle() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseFirestore.instance
            .collection('vehicles')
            .doc(widget.vehicleId)
            .update({
          'name': _nameController.text.trim(),
          'model': _modelController.text.trim(),
          'year': _yearController.text.trim(),
          'plate': _plateController.text.trim(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veículo atualizado com sucesso!')),
        );

        Navigator.pop(context); // Fecha a tela após a atualização
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes do Veículo')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration:
                          const InputDecoration(labelText: 'Nome do Veículo'),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Insira o nome'
                          : null,
                    ),
                    TextFormField(
                      controller: _modelController,
                      decoration: const InputDecoration(labelText: 'Modelo'),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Insira o modelo'
                          : null,
                    ),
                    TextFormField(
                      controller: _yearController,
                      decoration: const InputDecoration(labelText: 'Ano'),
                      keyboardType: TextInputType.number,
                      validator: (value) => value == null || value.isEmpty
                          ? 'Insira o ano'
                          : null,
                    ),
                    TextFormField(
                      controller: _plateController,
                      decoration: const InputDecoration(labelText: 'Placa'),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Insira a placa'
                          : null,
                    ),
                    const SizedBox(height: 20),
                    if (_averageConsumption != null)
                      Text(
                        'Consumo Médio: ${_averageConsumption!.toStringAsFixed(2)} km/L',
                        style: const TextStyle(fontSize: 16),
                      )
                    else
                      const Text(
                        'Consumo Médio: Dados insuficientes',
                        style: TextStyle(fontSize: 16),
                      ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _updateVehicle,
                      child: const Text('Atualizar Veículo'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
