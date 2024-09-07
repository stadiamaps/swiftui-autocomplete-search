import CoreLocation
import StadiaMaps
import SwiftUI

/// An autocomplete search view that searches for geographic locations as you type.
public struct AutocompleteSearch<T: View>: View {
    @State private var searchText = ""
    @State private var searchResults: [PeliasGeoJSONFeature] = []
    @State private var isLoading = false

    let userLocation: CLLocation?
    let onResultSelected: ((PeliasGeoJSONFeature) -> Void)?
    @ViewBuilder let resultViewBuilder: (PeliasGeoJSONFeature, CLLocation?) -> T

    /// Creates an autocomplete geographic search view.
    /// - Parameters:
    ///   - apiKey: Your Stadia Maps API key
    ///   - useEUEndpoint: Send requests to servers located in the European Union (may significantly degrade performance outside Europe)
    ///   - userLocation: If present, biases the search for results near a specific location and displays results with (straight-line) distances from this location
    ///   - onResultSelected: An optional callback invoked when a result is tapped in the list
    ///   - resultViewBuilder: An optional result view builder which lets you replace the default list element view (``SearchResult``) with your own
    public init(apiKey: String,
                useEUEndpoint: Bool = false,
                userLocation: CLLocation? = nil,
                onResultSelected: ((PeliasGeoJSONFeature) -> Void)? = nil,
                @ViewBuilder resultViewBuilder: @escaping (PeliasGeoJSONFeature, CLLocation?) -> T = { feature, userLocation in
                    SearchResult(feature: feature, relativeTo: userLocation)
                })
    {
        StadiaMapsAPI.customHeaders = ["Authorization": "Stadia-Auth \(apiKey)"]
        if useEUEndpoint {
            StadiaMapsAPI.basePath = "https://api-eu.stadiamaps.com"
        }
        self.userLocation = userLocation
        self.onResultSelected = onResultSelected
        self.resultViewBuilder = resultViewBuilder
    }

    public var body: some View {
        // TODO: Language override?
        // TODO: Min search length?
        TextField("Search", text: $searchText)
            .onChange(of: searchText) { query in
                Task {
                    try await search(query: query, autocomplete: true)
                }
            }
            .onSubmit {
                Task {
                    try await search(query: searchText, autocomplete: false)
                }
            }

        ZStack {
            List {
                ForEach(searchResults) { result in
                    makeResultView(feature: result, relativeTo: userLocation)
                }
            }

            if isLoading {
                ProgressView()
            }
        }
    }

    private func search(query: String, autocomplete: Bool) async throws {
        guard !query.isEmpty else {
            searchResults = []
            return
        }

        isLoading = true

        defer {
            self.isLoading = false
        }

        let result: PeliasResponse

        if autocomplete {
            result = try await GeocodingAPI.autocomplete(text: query, focusPointLat: userLocation?.coordinate.latitude, focusPointLon: userLocation?.coordinate.longitude)
        } else {
            result = try await GeocodingAPI.search(text: query, focusPointLat: userLocation?.coordinate.latitude, focusPointLon: userLocation?.coordinate.longitude)
        }

        // Only replace results if the text matches the current input
        if query == searchText {
            searchResults = result.features
        }
    }

    private func makeResultView(feature: PeliasGeoJSONFeature, relativeTo: CLLocation?) -> some View {
        resultViewBuilder(feature, relativeTo)
            .contentShape(.rect)
            .onTapGesture {
                onResultSelected?(feature)
            }
    }
}

// Set this to your own Stadia Maps API key.
// Get an free key at client.stadiamaps.com.
private let previewApiKey = "YOUR-API-KEY"

#Preview("Default UI") {
    if previewApiKey == "YOUR-API-KEY" {
        Text("You need an API key for this to be very useful. Get one at client.stadiamaps.com.")
    } else {
        AutocompleteSearch(apiKey: previewApiKey) { selection in
            print("Selected: \(selection)")
        }
    }
}

#Preview("Custom Result View") {
    if previewApiKey == "YOUR-API-KEY" {
        Text("You need an API key for this to be very useful. Get one at client.stadiamaps.com.")
    } else {
        AutocompleteSearch(apiKey: previewApiKey, onResultSelected: { selection in
            print("Selected: \(selection)")
        }) { feature, _ in
            HStack {
                Image(systemName: "laser.burst")
                Text(feature.properties?.name ?? "<No name>")
            }
        }
    }
}
