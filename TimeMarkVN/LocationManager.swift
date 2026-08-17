import CoreLocation
import Network

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
}
