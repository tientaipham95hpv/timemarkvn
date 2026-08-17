import MapKit
import CoreLocation
import UIKit

enum MapSnapshotService {
    static func snapshot(coordinate: CLLocationCoordinate2D,
                         size: CGSize = CGSize(width: 360, height: 240),
                         completion: @escaping (UIImage?) -> Void) {
        let options = MKMapSnapshotter.Options()
        options.region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: 1000,
            longitudinalMeters: 1000
        )
        options.size = size
        options.scale = UIScreen.main.scale

        MKMapSnapshotter(options: options).start { snapshot, _ in
            completion(snapshot?.image)
        }
    }
}
