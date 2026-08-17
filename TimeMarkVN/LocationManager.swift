import CoreLocation

final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    @Published var coordinate: CLLocationCoordinate2D?
    @Published var address = NSLocalizedString("Đang xác định vị trí...", comment: "")
    @Published var altitude: Double = 0
    @Published var heading: Double = 0
    @Published var accuracy: Double = 0
    @Published var temperature = "--°C"
    @Published var weatherText = NSLocalizedString("Chưa có dữ liệu", comment: "")

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.headingFilter = 1
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

        CLGeocoder().reverseGeocodeLocation(loc) { [weak self] places, _ in
            guard let p = places?.first else { return }
            let parts = [p.name, p.subLocality, p.locality, p.administrativeArea]
                .compactMap { $0 }
            DispatchQueue.main.async {
                self?.address = parts.joined(separator: ", ")
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
