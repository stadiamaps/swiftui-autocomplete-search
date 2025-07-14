import CoreLocation
import Foundation
import StadiaMaps

public extension GeocodingAPI {
    static func autocompletingSearch(query: String,
                                     autocomplete: Bool,
                                     apiKey: String,
                                     useEUEndpoint: Bool = false,
                                     userLocation: CLLocation? = nil,
                                     minSearchLength: Int = 1,
                                     limitLayers: [LayerId]? = nil) async throws -> [FeaturePropertiesV2]
    {
        guard query.count >= minSearchLength else {
            return []
        }

        StadiaMapsAPI.customHeaders = ["Authorization": "Stadia-Auth \(apiKey)"]
        if useEUEndpoint {
            StadiaMapsAPI.basePath = "https://api-eu.stadiamaps.com"
        }

        let features: [FeaturePropertiesV2]

        if autocomplete {
            let result = try await Self.autocompleteV2(text: query, focusPointLat: userLocation?.coordinate.latitude, focusPointLon: userLocation?.coordinate.longitude, layers: limitLayers)
            features = result.features
        } else {
            let result = try await Self.searchV2(text: query, focusPointLat: userLocation?.coordinate.latitude, focusPointLon: userLocation?.coordinate.longitude, layers: limitLayers)
            features = result.features
        }

        return features
    }
}

public extension FeaturePropertiesV2 {
    func getPlaceGeometryDetails() async throws -> [FeaturePropertiesV2] {
        guard geometry == nil else { return [self] }

        let response = try await GeocodingAPI.placeDetailsV2(ids: [properties.gid])
        return response.features
    }
}
