part of 'ble_cubit.dart';

enum BleStatus {
  initial,
  scanning,
  connecting,
  syncing,
  connected,
  disconnected,
  error,
}

class BleState extends Equatable {
  final BleStatus status;
  final List<ScanResult> scanResults;
  final List<double> spectralData; // 18 channels
  final String statusMessage;
  final String? errorMessage;
  final bool isLoading;
  final bool whiteLedOn;
  final bool irLedOn;
  final bool uvLedOn;
  final int gainIndex; // 0=1x, 1=3.7x, 2=16x, 3=64x
  final int integrationValue; // Range 1-255

  const BleState({
    this.status = BleStatus.initial,
    this.scanResults = const [],
    this.spectralData = const [],
    this.statusMessage = "",
    this.errorMessage,
    this.isLoading = false,
    this.whiteLedOn = false,
    this.irLedOn = false,
    this.uvLedOn = false,
    this.gainIndex = 3, // Default 64x
    this.integrationValue = 50, // Default ~140ms
  });

  BleState copyWith({
    BleStatus? status,
    List<ScanResult>? scanResults,
    List<double>? spectralData,
    String? statusMessage,
    String? errorMessage,
    bool? isLoading,
    bool? whiteLedOn,
    bool? irLedOn,
    bool? uvLedOn,
    int? gainIndex,
    int? integrationValue,
  }) {
    return BleState(
      status: status ?? this.status,
      scanResults: scanResults ?? this.scanResults,
      spectralData: spectralData ?? this.spectralData,
      statusMessage: statusMessage ?? this.statusMessage,
      errorMessage: errorMessage ?? this.errorMessage,
      isLoading: isLoading ?? this.isLoading,
      whiteLedOn: whiteLedOn ?? this.whiteLedOn,
      irLedOn: irLedOn ?? this.irLedOn,
      uvLedOn: uvLedOn ?? this.uvLedOn,
      gainIndex: gainIndex ?? this.gainIndex,
      integrationValue: integrationValue ?? this.integrationValue,
    );
  }

  @override
  List<Object?> get props => [
    status,
    scanResults,
    spectralData,
    statusMessage,
    errorMessage,
    isLoading,
    whiteLedOn,
    irLedOn,
    uvLedOn,
    gainIndex,
    integrationValue,
  ];

  // Convert state to JSON for exporting
  Map<String, dynamic> toJson() {
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'status': status.toString(),
      'spectral_data': spectralData,
      'settings': {
        'gain_index': gainIndex,
        'integration_value': integrationValue,
        'led_status': {'white': whiteLedOn, 'ir': irLedOn, 'uv': uvLedOn},
      },
      'wavelength_labels': sortedLabels,
    };
  }
}
