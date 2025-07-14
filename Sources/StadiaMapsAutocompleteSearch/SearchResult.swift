import CoreLocation
import MapKit
import StadiaMaps
import SwiftUI

/// A search result view featuring a category image from SFSymbols,
/// the name of the feature, and (where available) some location context
/// such as the city, region, or country containing the result.
public struct SearchResult: View {
    let feature: FeaturePropertiesV2
    let formatter: MKDistanceFormatter

    public init(feature: FeaturePropertiesV2, formatter: MKDistanceFormatter) {
        self.feature = feature
        self.formatter = formatter
    }

    /// Creates a search result view wtih a default MKDistanceFormatter
    /// using the abbreviated unit style.
    public init(feature: FeaturePropertiesV2) {
        let formatter = MKDistanceFormatter()
        formatter.unitStyle = .abbreviated

        self.init(feature: feature, formatter: formatter)
    }

    public var body: some View {
        HStack(spacing: 8) {
            feature.properties.iconImage
                .frame(width: 18)
            VStack(alignment: .leading) {
                Text(feature.properties.name)
                if let subtitle = feature.properties.coarseLocation {
                    Text(subtitle)
                        .font(.caption)
                }
            }
            if let distance = feature.properties.distance {
                // Display the distance from the API, if available (note: originally in km)
                Text(formatter.string(fromDistance: distance * 1000.0))
                    .font(.caption)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }
}

#Preview("Plain result") {
    SearchResult(feature: FeaturePropertiesV2(properties: FeaturePropertiesV2Properties(gid: "foo", layer: "address", name: "Test", precision: .point)))
}

#Preview("Result with coarse location") {
    SearchResult(feature: FeaturePropertiesV2(properties: FeaturePropertiesV2Properties(coarseLocation: "Some City, USA", gid: "foo", layer: "address", name: "Test", precision: .point)))
}

#Preview("Relative distance") {
    SearchResult(feature: FeaturePropertiesV2(properties: FeaturePropertiesV2Properties(coarseLocation: "Some City, USA", distance: 12.0, gid: "foo", layer: "address", name: "Test", precision: .point)))
}

#Preview("Multiple Results") {
    List {
        SearchResult(feature: FeaturePropertiesV2(properties: FeaturePropertiesV2Properties(gid: "foo", layer: "address", name: "Test", precision: .point)))
        SearchResult(feature: FeaturePropertiesV2(properties: FeaturePropertiesV2Properties(distance: 12.0, gid: "foo", layer: "address", name: "Test", precision: .point)))
        SearchResult(feature: FeaturePropertiesV2(geometry: Point(coordinates: [0, 0], type: "Point"), properties: FeaturePropertiesV2Properties(coarseLocation: "Some City, USA", distance: 12.0, gid: "foo", layer: "address", name: "Test", precision: .point)))
    }
}
