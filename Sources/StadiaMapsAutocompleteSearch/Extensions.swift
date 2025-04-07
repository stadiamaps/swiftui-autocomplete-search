import Foundation
import CoreLocation
import StadiaMaps
import SwiftUI

extension FeaturePropertiesV2: Identifiable {
    public var id: String? {
        properties.gid
    }
}

/// Legacy support until we have a v2 /search endpoint
public extension GeocodingGeoJSONFeature {
    var subtitle: String? {
        let components: [String?]
        if let layer = properties?.layer {
            switch layer {
            case "venue", "poi", "address", "street", "neighbourhood", "postalcode", "macrohood":
                components = [properties?.locality ?? properties?.region, properties?.country]
            case "country", "dependency", "disputed":
                components = [properties?.continent]
            case "macroregion", "region":
                components = [properties?.country]
            case "locality", "localadmin", "borough", "macrocounty", "county":
                components = [properties?.region, properties?.country]
            case "coarse", "marinearea", "empire", "continent", "ocean":
                components = []
            default:
                components = []
            }
        } else {
            components = []
        }

        let stringResult = components.compactMap({ $0 }).joined(separator: ", ")
        if stringResult.isEmpty {
            return nil
        } else {
            return stringResult
        }
    }
}

extension GeocodingGeoJSONFeature {
    /// Temp function until we have a v2 search API
    func upcast() -> FeaturePropertiesV2? {
        guard let properties = self.properties else {
            return nil
        }
        return FeaturePropertiesV2(bbox: self.bbox,
                                   geometry: Point(coordinates: self.geometry.coordinates, type: "Point"),
                                   properties: FeaturePropertiesV2Properties(
                                    addressComponents: AddressComponentsV2(number: properties.housenumber, postalCode: properties.postalcode, street: properties.street),
                                    coarseLocation: self.subtitle,
                                    confidence: properties.confidence,
                                    context: Context(iso3166A2: properties.countryCode, iso3166A3: properties.countryA, whosonfirst: WofContext(
                                        borough: contextComponentOrNil(gid: properties.boroughGid, name: properties.borough, abbreviation: nil),
                                        continent: contextComponentOrNil(gid: properties.continentGid, name: properties.continent, abbreviation: nil),
                                        country: contextComponentOrNil(gid: properties.countryGid, name: properties.country, abbreviation: properties.countryA),
                                    county: contextComponentOrNil(gid: properties.countyGid, name: properties.county, abbreviation: nil),
                                        localadmin: contextComponentOrNil(gid: properties.localadminGid, name: properties.localadmin, abbreviation: nil),
                                    locality: contextComponentOrNil(gid: properties.localityGid, name: properties.locality, abbreviation: nil),
                                    neighbourhood: contextComponentOrNil(gid: properties.neighbourhoodGid, name: properties.neighbourhood, abbreviation: nil))),
                                    distance: nil,
                                    gid: properties.gid!,
                                    layer: properties.layer!,
                                    name: properties.name!,
                                    precision: properties.accuracy == .point ? .point : .centroid),
                                   type: "Feature")
    }
}

private func contextComponentOrNil(gid: String?, name: String?, abbreviation: String?) -> WofContextComponent? {
    if let gid, let name {
        return WofContextComponent(abbreviation: abbreviation, gid: gid, name: name)
    } else {
        return nil
    }
}

extension FeaturePropertiesV2Properties {
    var iconImage: Image {
        let imageName = switch self.layer {
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

        return Image(systemName: imageName)
    }
}

extension FeaturePropertiesV2 {
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
