import Foundation
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
