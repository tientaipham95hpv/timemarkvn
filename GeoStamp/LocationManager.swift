import CoreLocation
import Network
import ImageIO
import Photos
import UIKit

protocol TelemetryData {
    var coordinate: CLLocationCoordinate2D? { get }
    var address: String { get }
    var altitude: Double { get }
    var heading: Double { get }
    var accuracy: Double { get }
    var temperature: String { get }
    var weatherText: String { get }
    var isTimeSpoofed: Bool { get }
    var isGpsSimulated: Bool { get }
    var gpsTimestamp: Date? { get }
    var isOffline: Bool { get }
    var timeZone: TimeZone? { get }
}

final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate, TelemetryData {
    private let manager = CLLocationManager()
    private let monitor = NWPathMonitor()

    @Published var coordinate: CLLocationCoordinate2D?
    @Published var address = NSLocalizedString("Đang xác định vị trí...", comment: "")
    @Published var altitude: Double = 0
    @Published var heading: Double = 0
    @Published var accuracy: Double = 0
    @Published var temperature = "--°C"
    @Published var weatherText = NSLocalizedString("Chưa có dữ liệu", comment: "")
    @Published var isTimeSpoofed = false
    @Published var isGpsSimulated = false
    @Published var gpsTimestamp: Date? = nil
    @Published var isOffline = false
    @Published var timeZone: TimeZone? = nil

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.headingFilter = 1
        
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isOffline = path.status != .satisfied
            }
        }
        monitor.start(queue: DispatchQueue.global(qos: .background))
    }

    func start() {
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
        if CLLocationManager.headingAvailable() { manager.startUpdatingHeading() }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        coordinate = loc.coordinate
        altitude = loc.altitude
        accuracy = loc.horizontalAccuracy
        
        let gpsTime = loc.timestamp
        gpsTimestamp = gpsTime
        
        let systemTime = Date()
        let diff = abs(systemTime.timeIntervalSince(gpsTime))
        isTimeSpoofed = diff > 300
        
        if #available(iOS 15.0, *) {
            if let source = loc.sourceInformation {
                isGpsSimulated = source.isSimulatedBySoftware
            }
        }

        CLGeocoder().reverseGeocodeLocation(loc) { [weak self] places, _ in
            guard let p = places?.first else { return }
            let parts = [p.name, p.subLocality, p.locality, p.administrativeArea]
                .compactMap { $0 }
            DispatchQueue.main.async {
                self?.address = parts.joined(separator: ", ")
                self?.timeZone = p.timeZone
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let value = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
        heading = value
    }

    func refreshWeather() {
        guard let c = coordinate else { return }
        WeatherService.load(latitude: c.latitude, longitude: c.longitude) { [weak self] temp, text in
            self?.temperature = temp
            self?.weatherText = text
        }
    }

    static func saveImageWithMetadata(image: UIImage, location: TelemetryData, completion: ((Bool) -> Void)? = nil) {
        guard let data = image.jpegData(compressionQuality: 0.9) else {
            completion?(false)
            return
        }
        
        var metadata: [String: [AnyHashable: Any]] = [
            kCGImagePropertyTIFFDictionary as String: [AnyHashable: Any](),
            kCGImagePropertyGPSDictionary as String: [AnyHashable: Any]()
        ]
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        if let tz = location.timeZone {
            formatter.timeZone = tz
        }
        let dateStr = formatter.string(from: location.gpsTimestamp ?? Date())
        metadata[kCGImagePropertyTIFFDictionary as String]?[kCGImagePropertyTIFFDateTime as String] = dateStr
        
        if let coord = location.coordinate {
            var gpsDict = [AnyHashable: Any]()
            gpsDict[kCGImagePropertyGPSLatitude as String] = abs(coord.latitude)
            gpsDict[kCGImagePropertyGPSLatitudeRef as String] = coord.latitude >= 0 ? "N" : "S"
            gpsDict[kCGImagePropertyGPSLongitude as String] = abs(coord.longitude)
            gpsDict[kCGImagePropertyGPSLongitudeRef as String] = coord.longitude >= 0 ? "E" : "W"
            gpsDict[kCGImagePropertyGPSAltitude as String] = abs(location.altitude)
            gpsDict[kCGImagePropertyGPSAltitudeRef as String] = location.altitude >= 0 ? 0 : 1
            
            let gpsDateFormatter = DateFormatter()
            gpsDateFormatter.dateFormat = "yyyy:MM:dd"
            gpsDateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
            let gpsTimeFormatter = DateFormatter()
            gpsTimeFormatter.dateFormat = "HH:mm:ss.SS"
            gpsTimeFormatter.timeZone = TimeZone(secondsFromGMT: 0)
            
            let dateToUse = location.gpsTimestamp ?? Date()
            gpsDict[kCGImagePropertyGPSDateStamp as String] = gpsDateFormatter.string(from: dateToUse)
            gpsDict[kCGImagePropertyGPSTimeStamp as String] = gpsTimeFormatter.string(from: dateToUse)
            
            metadata[kCGImagePropertyGPSDictionary as String] = gpsDict
        }
        
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let type = CGImageSourceGetType(source) else {
            completion?(false)
            return
        }
        
        let writeData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(writeData as CFMutableData, type, 1, nil) else {
            completion?(false)
            return
        }
        
        CGImageDestinationAddImageFromSource(destination, source, 0, metadata as CFDictionary)
        guard CGImageDestinationFinalize(destination) else {
            completion?(false)
            return
        }
        
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else {
                DispatchQueue.main.async { completion?(false) }
                return
            }
            PHPhotoLibrary.shared().performChanges {
                let creationRequest = PHAssetCreationRequest.forAsset()
                creationRequest.addResource(with: .photo, data: writeData as Data, options: nil)
            } completionHandler: { success, _ in
                DispatchQueue.main.async { completion?(success) }
            }
        }
    }
}
