import CoreLocation
import StadiaMaps
import SwiftUI
import OSLog

/// An autocomplete search view that searches for geographic locations as you type.
public struct AutocompleteSearch<T: View>: View {
    @State private var searchText = ""
    @State private var searchResults: [GeocodingGeoJSONFeature] = []
    @State private var isLoading = false

    let userLocation: CLLocation?
    let limitLayers: [GeocodingLayer]?
    let minSearchLength: Int
    let onResultSelected: ((GeocodingGeoJSONFeature) -> Void)?
    @ViewBuilder let resultViewBuilder: (GeocodingGeoJSONFeature, CLLocation?) -> T

    /// Creates an search view with text input
    /// and a result list that updates as the user types.
    /// - Parameters:
    ///   - apiKey: Your [Stadia Maps API key](https://docs.stadiamaps.com/authentication/).
    ///   - useEUEndpoint: Send requests to servers located in the European Union. Note that this may significantly degrade performance for users outside Europe.
    ///   - userLocation: If present, biases the search for results near a specific location. Additionally, results using the default (``SearchResult``) view will display the straight-line distances from this location.
    ///   - limitLayers: Optionally limits the searched layers to the specified set.
    ///   - minSearchLength: Requires at least this many characters of input before searching. This can save API credits, but setting it higher than 1 or 2 will make the autocomplete functionality significantly less useful for some languages.
    ///   - onResultSelected: An optional callback invoked when the user taps on a result in the list. This allows you to build interactivity, such as launching navigation or flying to a location on a map.
    ///   - resultViewBuilder: An optional result view builder which lets you replace the default list element view (``SearchResult``) with your own.
    public init(apiKey: String,
                useEUEndpoint: Bool = false,
                userLocation: CLLocation? = nil,
                limitLayers: [GeocodingLayer]? = nil,
                minSearchLength: Int = 1,
                onResultSelected: ((GeocodingGeoJSONFeature) -> Void)? = nil,
                @ViewBuilder resultViewBuilder: @escaping (GeocodingGeoJSONFeature, CLLocation?) -> T = { feature, userLocation in
                    SearchResult(feature: feature, relativeTo: userLocation)
                })
    {
        StadiaMapsAPI.customHeaders = ["Authorization": "Stadia-Auth \(apiKey)"]
        if useEUEndpoint {
            StadiaMapsAPI.basePath = "https://api-eu.stadiamaps.com"
        }
        self.userLocation = userLocation
        self.limitLayers = limitLayers
        self.minSearchLength = minSearchLength
        self.onResultSelected = onResultSelected
        self.resultViewBuilder = resultViewBuilder
    }

    public var body: some View {
        TextField("Search", text: $searchText)
            // TODO: Smarter safe area padding
            .padding(8)
            .textFieldStyle(.roundedBorder)
            .onChange(of: searchText) { query in
                Task {
                    await search(query: query, autocomplete: true)
                }
            }
            .onSubmit {
                Task {
                    await search(query: searchText, autocomplete: false)
                }
            }

        ZStack {
            List {
                ForEach(searchResults) { result in
                    makeResultView(feature: result, relativeTo: userLocation)
                }
            }
            .scrollContentBackground(.hidden)

            if isLoading {
                ProgressView()
            }
        }
    }

    private func search(query: String, autocomplete: Bool) async {
        guard query.count >= minSearchLength else {
            searchResults = []
            return
        }

        isLoading = true

        defer {
            self.isLoading = false
        }

        let result: GeocodeResponse

        do {
            if autocomplete {
                result = try await GeocodingAPI.autocomplete(text: query, focusPointLat: userLocation?.coordinate.latitude, focusPointLon: userLocation?.coordinate.longitude, layers: limitLayers)
            } else {
                result = try await GeocodingAPI.search(text: query, focusPointLat: userLocation?.coordinate.latitude, focusPointLon: userLocation?.coordinate.longitude, layers: limitLayers)
            }

            // Only replace results if the text matches the current input
            if query == searchText {
                searchResults = result.features.filter({ $0.center != nil })
            }
        } catch {
            if let res = error as? ErrorResponse {
                switch res {
                case let .error(code, _, res, err):
                    if code == 401 {
                        Logger.api.error("API request failed with status \(code). This usually means your API key is invalid, missing, or has been revoked. Please check your API key at client.stadiamaps.com.")
                    } else if code == 403 {
                        Logger.api.error("API request failed with status \(code). You provided a valid API key, but your account does not have access to the \(autocomplete ? "autocomplete" : "search") API. You can upgrade your account at client.stadiamaps.com.")
                    } else {
                        Logger.api.error("API request failed with status \(code): \(err).")
                    }
                }
            } else {
                Logger.api.error("Error executing API request: \(error.localizedDescription)")
            }
        }
    }

    private func makeResultView(feature: GeocodingGeoJSONFeature, relativeTo: CLLocation?) -> some View {
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
        AutocompleteSearch(apiKey: previewApiKey, minSearchLength: 2) { selection in
            print("Selected: \(selection)")
        }
    }
}

// This shows how to limit the search layers.
// The coarse meta-layer allows for quicker lookups,
// by excluding the address and venue layers.
#Preview("Coarse Lookup") {
    if previewApiKey == "YOUR-API-KEY" {
        Text("You need an API key for this to be very useful. Get one at client.stadiamaps.com.")
    } else {
        AutocompleteSearch(apiKey: previewApiKey, limitLayers: [.coarse]) { selection in
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
