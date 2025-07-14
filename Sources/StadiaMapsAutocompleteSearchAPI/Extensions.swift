import CoreLocation
import Foundation
import StadiaMaps

public extension FeaturePropertiesV2Properties {
    var systemName: String {
        let imageName = switch layer {
        case "venue", "poi":
            "mappin.and.ellipse"
        case "address":
            "123.rectangle"
        case "street":
            "road.lanes"
        case "postalcode":
            "mail.stack"
        case "locality", "localadmin", "borough", "neighbourhood", "macrohood", "coarse":
            "building.2.crop.circle"
        case "county", "macrocounty", "country", "disputed", "macroregion", "region", "dependency":
            "globe.americas"
        case "empire", "continent":
            "globe"
        case "marinearea", "ocean":
            "water.waves"
        default:
            "mappin.and.ellipse"
        }
        return imageName
    }
}

public extension FeaturePropertiesV2 {
    /// The approximate center of the feature.
    ///
    /// Note that the API does not currently include any more info than a bounding box for non-point features.
    /// We just compute the mathematical middle for now.
    var center: CLLocation? {
        if let geom = geometry, geom.type == "Point" {
            return CLLocation(latitude: geom.coordinates[1], longitude: geom.coordinates[0])
        } else if let bbox {
            let lat = (bbox[1] + bbox[3]) / 2
            let lon = (bbox[0] + bbox[2]) / 2
            return CLLocation(latitude: lat, longitude: lon)
        } else {
            return nil
        }
    }
}
