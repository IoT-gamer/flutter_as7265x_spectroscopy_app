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
  final bool statusLedOn; //blue status LED
  final int gainIndex; // 0=1x, 1=3.7x, 2=16x, 3=64x
  final int integrationValue; // Range 1-255
  final int tempNIR;
  final int tempVIS;
  final int tempUV;
  final CalibrationSnapshot? darkCalibration;
  final CalibrationSnapshot? whiteCalibration;

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
    this.statusLedOn = false,
    this.gainIndex = 3, // Default 64x
    this.integrationValue = 50, // Default ~140ms
    this.tempNIR = 0,
    this.tempVIS = 0,
    this.tempUV = 0,
    this.darkCalibration,
    this.whiteCalibration,
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
    bool? statusLedOn,
    int? gainIndex,
    int? integrationValue,
    int? tempNIR,
    int? tempVIS,
    int? tempUV,
    CalibrationSnapshot? darkCalibration,
    CalibrationSnapshot? whiteCalibration,
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
      statusLedOn: statusLedOn ?? this.statusLedOn,
      gainIndex: gainIndex ?? this.gainIndex,
      integrationValue: integrationValue ?? this.integrationValue,
      tempNIR: tempNIR ?? this.tempNIR,
      tempVIS: tempVIS ?? this.tempVIS,
      tempUV: tempUV ?? this.tempUV,
      darkCalibration: darkCalibration ?? this.darkCalibration,
      whiteCalibration: whiteCalibration ?? this.whiteCalibration,
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
    statusLedOn,
    gainIndex,
    integrationValue,
    tempNIR,
    tempVIS,
    tempUV,
    darkCalibration,
    whiteCalibration,
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
      'temperatures_celsius': {
        'nir_master': tempNIR,
        'vis_slave1': tempVIS,
        'uv_slave2': tempUV,
      },
      'wavelength_labels': sortedLabels,
      // Add calibration data if it exists
      if (darkCalibration != null)
        'dark_calibration': darkCalibration!.toJson(),
      if (whiteCalibration != null)
        'white_calibration': whiteCalibration!.toJson(),
    };
  }
}

class CalibrationSnapshot extends Equatable {
  final String timestamp;
  final List<double> spectralData;
  final int gainIndex;
  final int integrationValue;
  final Map<String, bool> ledStatus;
  final Map<String, int> temperatures;

  const CalibrationSnapshot({
    required this.timestamp,
    required this.spectralData,
    required this.gainIndex,
    required this.integrationValue,
    required this.ledStatus,
    required this.temperatures,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp,
      'spectral_data': spectralData,
      'settings': {
        'gain_index': gainIndex,
        'integration_value': integrationValue,
        'led_status': ledStatus,
      },
      'temperatures_celsius': temperatures,
    };
  }

  @override
  List<Object?> get props => [
    timestamp,
    spectralData,
    gainIndex,
    integrationValue,
    ledStatus,
    temperatures,
  ];
}
