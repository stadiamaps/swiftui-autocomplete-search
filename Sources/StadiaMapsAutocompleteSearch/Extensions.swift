import Foundation
import StadiaMaps
import SwiftUI

extension PeliasGeoJSONFeature: Identifiable {
    public var id: String? {
        properties?.gid
    }
}

public extension PeliasGeoJSONFeature {
    var subtitle: String? {
        if let layer = properties?.layer {
            switch layer {
            case .venue, .address, .street, .neighbourhood, .postalcode, .macrohood:
                return properties?.locality ?? properties?.region ?? properties?.country
            case .country, .dependency, .disputed, .continent:
                return properties?.continent
            case .macroregion, .region:
                return properties?.country
            case .locality, .localadmin, .borough, .macrocounty, .county:
                return properties?.region ?? properties?.country
            case .coarse, .marinearea, .empire, .ocean:
                return nil
            }
        } else {
            return nil
        }
    }
}

extension PeliasLayer {
    var iconImage: Image {
        let imageName = switch self {
        case .venue:
            "building.2.crop.circle"
        case .address:
            "123.rectangle"
        case .street:
            "road.lanes"
        case .country:
            "globe.americas"
        case .macroregion:
            "globe.americas"
        case .region:
            "globe.americas"
        case .macrocounty:
            "mappin.and.ellipse"
        case .county:
            "mappin.and.ellipse"
        case .locality:
            "mappin.and.ellipse"
        case .localadmin:
            "mappin.and.ellipse"
        case .borough:
            "mappin.and.ellipse"
        case .neighbourhood:
            "mappin.and.ellipse"
        case .postalcode:
            "mappin.and.ellipse"
        case .coarse:
            "mappin.and.ellipse"
        case .dependency:
            "globe.americas"
        case .macrohood:
            "globe.americas"
        case .marinearea:
            "water.waves"
        case .disputed:
            "questionmark.circle"
        case .empire:
            "globe.americas"
        case .continent:
            "globe.americas"
        case .ocean:
            "water.waves"
        }

        return Image(systemName: imageName)
    }
}
