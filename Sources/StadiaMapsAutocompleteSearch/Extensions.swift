import Foundation
import CoreLocation
import StadiaMaps
import SwiftUI

extension PeliasGeoJSONFeature: Identifiable {
    public var id: String? {
        properties?.gid
    }
}

public extension PeliasGeoJSONFeature {
    var subtitle: String {
        let components: [String?]
        if let layer = properties?.layer {
            switch layer {
            case .venue, .address, .street, .neighbourhood, .postalcode, .macrohood:
                components = [properties?.locality ?? properties?.region, properties?.country]
            case .country, .dependency, .disputed:
                components = [properties?.continent]
            case .macroregion, .region:
                components = [properties?.country]
            case .locality, .localadmin, .borough, .macrocounty, .county:
                components = [properties?.region, properties?.country]
            case .coarse, .marinearea, .empire, .continent, .ocean:
                components = []
            }
        } else {
            components = []
        }

        return components.compactMap({ $0 }).joined(separator: ", ")
    }

    /// The approximate center of the feature.
    ///
    /// Note that the API does not currently include any more info than a bounding box for non-point features.
    /// We just compute the mathematical middle for now.
    var center: CLLocation? {
        if (geometry.type == .point) {
            return CLLocation(latitude: geometry.coordinates[1], longitude: geometry.coordinates[0])
        } else if let bbox {
            let lat = (bbox[1] + bbox[3]) / 2
            let lon = (bbox[0] + bbox[2]) / 2
            return CLLocation(latitude: lat, longitude: lon)
        } else {
            return nil
        }
    }
}

extension PeliasLayer {
    var iconImage: Image {
        let imageName = switch self {
        case .venue:
            "mappin.and.ellipse"
        case .address:
            "123.rectangle"
        case .street:
            "road.lanes"
        case .postalcode:
            "mail.stack"
        case .locality, .localadmin, .borough, .neighbourhood, .macrohood, .coarse:
            "building.2.crop.circle"
        case .county, .macrocounty, .country, .disputed, .macroregion, .region, .dependency:
            "globe.americas"
        case .empire, .continent:
            "globe"
        case .marinearea, .ocean:
            "water.waves"
        }

        return Image(systemName: imageName)
    }
}
