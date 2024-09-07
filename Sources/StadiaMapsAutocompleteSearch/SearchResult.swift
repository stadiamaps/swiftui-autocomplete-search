import CoreLocation
import MapKit
import StadiaMaps
import SwiftUI

/// A search result view featuring a category image from SFSymbols,
/// the name of the feature, and (where available) some location context
/// such as the city, region, or country containing the result.
public struct SearchResult: View {
    let feature: PeliasGeoJSONFeature
    let relativeTo: CLLocation?
    let formatter: MKDistanceFormatter

    public init(feature: PeliasGeoJSONFeature, relativeTo: CLLocation?, formatter: MKDistanceFormatter) {
        self.feature = feature
        self.relativeTo = relativeTo
        self.formatter = formatter
    }

    /// Creates a search result view wtih a default MKDistanceFormatter
    /// using the abbreviated unit style.
    public init(feature: PeliasGeoJSONFeature, relativeTo: CLLocation?) {
        let formatter = MKDistanceFormatter()
        formatter.unitStyle = .abbreviated

        self.init(feature: feature, relativeTo: relativeTo, formatter: formatter)
    }

    public var body: some View {
        HStack(spacing: 8) {
            feature.properties?.layer?.iconImage
                .frame(width: 18)
            VStack(alignment: .leading) {
                Text(feature.properties?.name ?? "<No info>")
                if let subtitle = feature.subtitle {
                    Text(subtitle)
                        .font(.caption)
                }
            }
            if let relativeTo {
                let distance = relativeTo.distance(from: CLLocation(latitude: feature.geometry.coordinates[1], longitude: feature.geometry.coordinates[0]))
                Text(formatter.string(fromDistance: distance))
                    .font(.caption)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }
}

#Preview("Plain result") {
    SearchResult(feature: PeliasGeoJSONFeature(type: .feature, geometry: GeoJSONPoint(type: .point, coordinates: [0, 0]), properties: PeliasGeoJSONProperties(layer: .address, name: "Test")), relativeTo: nil)
}

#Preview("Result with locality") {
    SearchResult(feature: PeliasGeoJSONFeature(type: .feature, geometry: GeoJSONPoint(type: .point, coordinates: [0, 0]), properties: PeliasGeoJSONProperties(layer: .address, name: "Test", locality: "Some City")), relativeTo: nil)
}

#Preview("Relative distance") {
    SearchResult(feature: PeliasGeoJSONFeature(type: .feature, geometry: GeoJSONPoint(type: .point, coordinates: [0, 0]), properties: PeliasGeoJSONProperties(layer: .address, name: "Test")), relativeTo: CLLocation(latitude: 0.25, longitude: 0.25))
}

#Preview("Multiple Results") {
    List {
        SearchResult(feature: PeliasGeoJSONFeature(type: .feature, geometry: GeoJSONPoint(type: .point, coordinates: [0, 0]), properties: PeliasGeoJSONProperties(layer: .address, name: "Test")), relativeTo: CLLocation(latitude: 0.25, longitude: 0.25))
        SearchResult(feature: PeliasGeoJSONFeature(type: .feature, geometry: GeoJSONPoint(type: .point, coordinates: [0, 0]), properties: PeliasGeoJSONProperties(layer: .street, name: "Test")), relativeTo: CLLocation(latitude: 0.25, longitude: 0.25))
        SearchResult(feature: PeliasGeoJSONFeature(type: .feature, geometry: GeoJSONPoint(type: .point, coordinates: [0, 0]), properties: PeliasGeoJSONProperties(layer: .venue, name: "Test")), relativeTo: CLLocation(latitude: 0.25, longitude: 0.25))
    }
}
