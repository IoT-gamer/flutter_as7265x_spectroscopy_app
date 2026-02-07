import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/ble_cubit.dart';

class SensorControls extends StatelessWidget {
  const SensorControls({super.key});

  // Map the index to the physical gain labels
  static const Map<int, String> gainOptions = {
    0: "1x",
    1: "3.7x",
    2: "16x",
    3: "64x",
  };

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BleCubit, BleState>(
      builder: (context, state) {
        final bleCubit = context.read<BleCubit>();
        // Calculate actual time: value * 2.8ms
        final double actualMs = state.integrationValue * 2.8;

        return Column(
          children: [
            // LED Toggles from previous step
            Wrap(
              spacing: 10,
              children: [
                _ledButton(
                  "WHITE",
                  state.whiteLedOn,
                  () => bleCubit.toggleLed(0x03),
                ),
                _ledButton("IR", state.irLedOn, () => bleCubit.toggleLed(0x04)),
                _ledButton("UV", state.uvLedOn, () => bleCubit.toggleLed(0x05)),
              ],
            ),
            const SizedBox(height: 15),
            // Gain Dropdown
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Sensor Gain: "),
                DropdownButton<int>(
                  value: state.gainIndex,
                  items: gainOptions.entries.map((entry) {
                    return DropdownMenuItem<int>(
                      value: entry.key,
                      child: Text(entry.value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) bleCubit.setGain(value);
                  },
                ),
              ],
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                "Integration Time",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),

            Slider(
              value: state.integrationValue.toDouble(),
              min: 1,
              max: 255,
              divisions: 254,
              label: "${state.integrationValue}",
              onChanged: (value) => bleCubit.setIntegrationTime(value.toInt()),
            ),

            Text(
              "Value: ${state.integrationValue} (~${actualMs.toStringAsFixed(1)} ms)",
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        );
      },
    );
  }

  Widget _ledButton(String label, bool isOn, VoidCallback onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isOn ? Colors.blue.shade200 : null,
      ),
      onPressed: onPressed,
      child: Text(label),
    );
  }
}
