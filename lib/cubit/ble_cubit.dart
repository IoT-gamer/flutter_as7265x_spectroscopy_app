import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

part 'ble_state.dart';

// --- Pico Spectral Sensor BLE Definitions ---
final Guid spectralServiceUuid = Guid("0000FF00-0000-1000-8000-00805F9B34FB");
final Guid charControlUuid = Guid("0000FF04-0000-1000-8000-00805F9B34FB");

class BleCubit extends Cubit<BleState> {
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  BluetoothDevice? _connectedDevice;

  // Cache the control characteristic to avoid redundant discovery
  BluetoothCharacteristic? _cachedControlChar;

  BleCubit() : super(const BleState()) {
    requestPermissions();
  }

  Future<void> requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    if (statuses[Permission.bluetoothScan]!.isGranted &&
        statuses[Permission.bluetoothConnect]!.isGranted) {
      emit(state.copyWith(status: BleStatus.initial));
    } else {
      emit(
        state.copyWith(
          status: BleStatus.error,
          errorMessage: "Permissions Denied",
        ),
      );
    }
  }

  void startScan() {
    emit(state.copyWith(status: BleStatus.scanning, scanResults: []));
    _scanSubscription?.cancel();
    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      final filtered = results
          .where(
            (r) =>
                r.device.platformName.contains('Pico-Spectral') ||
                r.advertisementData.serviceUuids.contains(spectralServiceUuid),
          )
          .toList();
      emit(state.copyWith(scanResults: filtered));
    });

    FlutterBluePlus.startScan(
      withServices: [spectralServiceUuid],
      timeout: const Duration(seconds: 15),
    );
  }

  Future<void> connect(BluetoothDevice device) async {
    try {
      await FlutterBluePlus.stopScan();
      emit(
        state.copyWith(
          status: BleStatus.connecting,
          statusMessage: "Connecting...",
        ),
      );

      await device.connect(timeout: const Duration(seconds: 10));
      _connectedDevice = device;

      // Discover and setup services once
      await _discoverServices(device);

      emit(
        state.copyWith(
          status: BleStatus.syncing,
          statusMessage: "Syncing Sensor...",
        ),
      );

      // Sync the hardware to the App's initial state
      await initializeSensorSettings();

      emit(
        state.copyWith(
          status: BleStatus.connected,
          statusMessage: "Connected & Ready",
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: BleStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> initializeSensorSettings() async {
    // Sync Gain (Default 3 / 64x)
    await sendCommand(0x03, state.gainIndex);
    await Future.delayed(const Duration(milliseconds: 50));

    // Sync Integration Time (Default 50 / ~140ms)
    await sendCommand(0x02, state.integrationValue);
    await Future.delayed(const Duration(milliseconds: 50));

    // Ensure LEDs are Off (Matching initial app state)
    await sendCommand(0x03, state.whiteLedOn ? 1 : 0);
    await Future.delayed(const Duration(milliseconds: 50));

    await sendCommand(0x04, state.irLedOn ? 1 : 0);
    await Future.delayed(const Duration(milliseconds: 50));

    await sendCommand(0x05, state.uvLedOn ? 1 : 0);

    print("Sensor initialization sequence complete.");
  }

  Future<void> _discoverServices(BluetoothDevice device) async {
    List<BluetoothService> services = await device.discoverServices();
    for (var service in services) {
      if (service.uuid == spectralServiceUuid) {
        for (var char in service.characteristics) {
          // Cache control characteristic
          if (char.uuid == charControlUuid) {
            _cachedControlChar = char;
          }

          // Setup notifications for NIR, VIS, UV
          if (char.properties.notify) {
            await char.setNotifyValue(true);
            char.onValueReceived.listen((value) {
              _handleIncomingData(char.uuid.toString(), value);
            });
          }
        }
      }
    }
  }

  void _handleIncomingData(String uuid, List<int> value) {
    if (value.length < 24) return;
    final bytes = Uint8List.fromList(value).buffer.asByteData();
    List<double> incomingFloats = [];
    for (int i = 0; i < 6; i++) {
      incomingFloats.add(bytes.getFloat32(i * 4, Endian.little));
    }

    int offset = 0;
    String id = uuid.toUpperCase();
    if (id.contains("FF01")) {
      offset = 0; // WHITE LED
    } else if (id.contains("FF02")) {
      offset = 6; // IR
    } else if (id.contains("FF03")) {
      offset = 12; // UV
    } else {
      return;
    }
    List<double> updatedData = state.spectralData.isEmpty
        ? List.filled(18, 0.0)
        : List.from(state.spectralData);

    for (int i = 0; i < 6; i++) {
      updatedData[offset + i] = incomingFloats[i];
    }
    emit(state.copyWith(spectralData: updatedData));
  }

  Future<void> sendCommand(int commandId, int value) async {
    print("Attempting to send command: $commandId, value: $value");

    if (_cachedControlChar == null) {
      print(
        "Error: _cachedControlChar is NULL. Discovery may have failed for 0xFF04.",
      );
      return;
    }

    try {
      List<int> bytes = [commandId, value];
      print("Writing bytes $bytes to ${_cachedControlChar!.uuid}");

      // Explicitly use withoutResponse as per spectral.gatt
      await _cachedControlChar!.write(bytes, withoutResponse: true);
      print("Write operation complete.");
    } catch (e) {
      print("BLE Write Exception: $e");
      emit(state.copyWith(errorMessage: "Failed to send command: $e"));
    }
  }

  void toggleLed(int commandId) {
    bool newValue;
    switch (commandId) {
      case 0x03: // White
        newValue = !state.whiteLedOn;
        emit(state.copyWith(whiteLedOn: newValue));
        break;
      case 0x04: // IR
        newValue = !state.irLedOn;
        emit(state.copyWith(irLedOn: newValue));
        break;
      case 0x05: // UV
        newValue = !state.uvLedOn;
        emit(state.copyWith(uvLedOn: newValue));
        break;
      default:
        return;
    }

    // Send 1 for true (On), 0 for false (Off)
    sendCommand(commandId, newValue ? 1 : 0);
  }

  void setGain(int index) {
    emit(state.copyWith(gainIndex: index));
    // Command 0x01 is for Gain
    sendCommand(0x01, index);
  }

  void setIntegrationTime(int value) {
    // Clamp value to valid sensor range 1-255
    final clampedValue = value.clamp(1, 255);
    emit(state.copyWith(integrationValue: clampedValue));

    // Command 0x02 is for Integration Time
    sendCommand(0x02, clampedValue);
  }

  Future<void> disconnect() async {
    if (_connectedDevice == null) return;
    try {
      emit(state.copyWith(isLoading: true, statusMessage: "Disconnecting..."));
      await _connectedDevice!.disconnect();
      _connectedDevice = null;
      _cachedControlChar = null; // Clear cache on disconnect
      emit(
        state.copyWith(
          status: BleStatus.initial,
          statusMessage: "Disconnected.",
          spectralData: [],
          isLoading: false,
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: BleStatus.error, errorMessage: e.toString()));
    }
  }

  @override
  Future<void> close() {
    _scanSubscription?.cancel();
    _connectedDevice?.disconnect();
    return super.close();
  }
}
