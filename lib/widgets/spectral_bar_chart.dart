import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/ble_cubit.dart';

const List<String> wavelengthLabels = [
  "610", "680", "730", "760", "810", "860", // NIR (FF01) AS72651
  "560", "585", "645", "705", "900", "940", // VIS (FF02) AS72652
  "410", "435", "460", "485", "510", "535", // UV  (FF03) AS72653
];

// Sorted wavelengths from UV (low) to NIR (high)
const List<String> sortedLabels = [
  "410", "435", "460", "485", "510", "535", // UV (Index 12-17)
  "560", "585", "610", "645", "680", "705", // Mix of VIS & NIR
  "730", "760", "810", "860", "900", "940", // NIR & Upper VIS
];

// Map the visual X-axis position to the raw state.spectralData index
const List<int> wavelengthMap = [
  12, 13, 14, 15, 16, 17, // 410nm - 535nm (Sensor UV / 0xFF03)
  6, 7, 0, 8, 1, 9, // 560nm - 705nm (Mixed VIS/NIR)
  2, 3, 4, 5, 10, 11, // 730nm - 940nm (Mixed NIR/VIS)
];

class SpectralBarChart extends StatelessWidget {
  const SpectralBarChart({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BleCubit, BleState>(
      builder: (context, state) {
        // Ensure we have data; if not, show a placeholder
        if (state.spectralData.isEmpty) {
          return const Center(child: Text("Waiting for sensor data..."));
        }

        return Column(
          children: [
            // Color Key / Legend
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _legendItem("AS72651", Colors.green),
                  const SizedBox(width: 15),
                  _legendItem("AS72652", Colors.red),
                  const SizedBox(width: 15),
                  _legendItem("AS72653", Colors.purple),
                ],
              ),
            ),
            Container(
              height: 300,
              padding: const EdgeInsets.all(16),
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY:
                      state.spectralData.reduce((a, b) => a > b ? a : b) +
                      10, // Dynamic scale
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          int index = value.toInt();
                          if (index < 0 || index >= sortedLabels.length) {
                            return const SizedBox();
                          }

                          // Only show every 2nd or 3rd label to avoid overlap
                          if (index % 3 != 0) return const SizedBox();

                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              sortedLabels[index],
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  barGroups: List.generate(wavelengthMap.length, (visualIndex) {
                    final dataIndex = wavelengthMap[visualIndex];
                    final value = state.spectralData[dataIndex];

                    return BarChartGroupData(
                      x: visualIndex,
                      barRods: [
                        BarChartRodData(
                          toY: value,
                          color: _getWavelengthColor(
                            dataIndex,
                          ), // Uses raw index to keep color logic
                          width: 10,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Visual helper to color bars based on sensor type
  Color _getWavelengthColor(int index) {
    if (index >= 0 && index <= 5) {
      return Colors.green; // AS72651 (NIR)
    } else if (index >= 6 && index <= 11) {
      return Colors.red; // AS72652 (VIS)
    } else if (index >= 12 && index <= 17) {
      return Colors.purple; // AS72653 (UV)
    }
    return Colors.grey;
  }

  Widget _legendItem(String name, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 4),
        Text(
          name,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
