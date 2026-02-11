import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../cubit/ble_cubit.dart';
import '../widgets/sensor_controls.dart';
import '../widgets/spectral_bar_chart.dart';

class SpectralSensorScreen extends StatelessWidget {
  const SpectralSensorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pico Spectral Sensor"),
        actions: [
          BlocBuilder<BleCubit, BleState>(
            builder: (context, state) {
              return IconButton(
                icon: Icon(
                  state.status == BleStatus.scanning
                      ? Icons.stop
                      : Icons.search,
                ),
                onPressed: () => context.read<BleCubit>().startScan(),
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<BleCubit, BleState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
          }
        },
        builder: (context, state) {
          switch (state.status) {
            case BleStatus.initial:
              return const Center(
                child: Text("Tap search to find Pico-Spectral"),
              );

            case BleStatus.scanning:
              return _buildScanList(state.scanResults, context);

            case BleStatus.connecting:
              return const Center(child: CircularProgressIndicator());

            case BleStatus.syncing:
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: Colors.orange),
                    const SizedBox(height: 20),
                    Text(
                      state.statusMessage,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      "Configuring hardware registers...",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              );

            case BleStatus.connected:
              return _buildDashboard(context);

            case BleStatus.disconnected:
              return const Center(
                child: Text("Disconnected. Please scan again."),
              );

            case BleStatus.error:
              return Center(child: Text("Error: ${state.errorMessage}"));
          }
        },
      ),
    );
  }

  // List of discovered devices
  Widget _buildScanList(List<ScanResult> results, BuildContext context) {
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final device = results[index].device;
        return ListTile(
          title: Text(
            device.platformName.isEmpty
                ? "Unknown Device"
                : device.platformName,
          ),
          subtitle: Text(device.remoteId.toString()),
          trailing: ElevatedButton(
            onPressed: () => context.read<BleCubit>().connect(device),
            child: const Text("Connect"),
          ),
        );
      },
    );
  }

  // The main data view
  Widget _buildDashboard(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text(
              "Live Spectral Data (Counts)",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SpectralBarChart(), // The bar chart widget
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text("Sensor Controls"),
          ),
          const SensorControls(), // LED and Gain controls widget
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade100,
            ),
            onPressed: () =>
                context.read<BleCubit>().disconnect(), // Call the cubit
            child: const Text(
              "Disconnect",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
