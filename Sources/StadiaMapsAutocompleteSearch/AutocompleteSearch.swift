import CoreLocation
import StadiaMaps
import StadiaMapsAutocompleteSearchAPI
import SwiftUI
import OSLog

/// An autocomplete search view that searches for geographic locations as you type.
public struct AutocompleteSearch<T: View>: View {
    @State private var searchText = ""
    @State private var searchResults: [FeaturePropertiesV2] = []
    @State private var isLoading = false

    private let apiKey: String
    private let useEUEndpoint : Bool
    let userLocation: CLLocation?
    let limitLayers: [LayerId]?
    let minSearchLength: Int
    let onResultSelected: ((FeaturePropertiesV2) -> Void)?
    @ViewBuilder let resultViewBuilder: (FeaturePropertiesV2, CLLocation?) -> T

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
                limitLayers: [LayerId]? = nil,
                minSearchLength: Int = 1,
                onResultSelected: ((FeaturePropertiesV2) -> Void)? = nil,
                @ViewBuilder resultViewBuilder: @escaping (FeaturePropertiesV2, CLLocation?) -> T = { feature, userLocation in
                    SearchResult(feature: feature, relativeTo: userLocation)
                })
    {
        self.apiKey = apiKey
        self.useEUEndpoint = useEUEndpoint
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
                ForEach(searchResults, id: \.properties.gid) { result in
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
        isLoading = true

        defer {
            self.isLoading = false
        }

        do {
            let features = try await GeocodingAPI.autocompletingSearch(query: query, autocomplete: autocomplete, apiKey: apiKey, useEUEndpoint: useEUEndpoint, userLocation: userLocation, minSearchLength: minSearchLength, limitLayers: limitLayers)

            // Only replace results if the text matches the current input
            if query == searchText {
                searchResults = features
            }
        } catch {
            handleError(error)
        }
    }

    private func makeResultView(feature: FeaturePropertiesV2, relativeTo: CLLocation?) -> some View {
        resultViewBuilder(feature, relativeTo)
            .contentShape(.rect)
            .onTapGesture {
                guard let callback = onResultSelected else { return }

                Task(priority: .userInitiated) {
                  do {
                    let detailResults = try await feature.getPlaceGeometryDetails()
                    guard let result = detailResults.first else {
                      throw InternalError.noResultsFoundForPlaceGID
                    }
                    callback(result)
                  } catch {
                    handleError(error)
                  }
                }
            }
    }
}

func handleError(_ error: Error) {
    if let res = error as? ErrorResponse {
        switch res {
        case let .error(code, _, _, err):
            if code == 401 {
                Logger.api.error("API request failed with status \(code). This usually means your API key is invalid, missing, or has been revoked. Please check your API key at client.stadiamaps.com.")
            } else {
                Logger.api.error("API request failed with status \(code): \(err).")
            }
        }
    } else {
        Logger.api.error("Error executing API request: \(error.localizedDescription)")
    }
}

enum InternalError: Error {
    case noResultsFoundForPlaceGID
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
                Text(feature.properties.name)
            }
        }
    }
}
