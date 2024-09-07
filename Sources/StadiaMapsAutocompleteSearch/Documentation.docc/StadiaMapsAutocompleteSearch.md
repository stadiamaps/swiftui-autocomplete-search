# ``StadiaMapsAutocompleteSearch``


## Overview

This package helps you easily add geographic autocomplete search to a SwiftUI app.
It supports most use cases out of the box, and is easily extensible to create a tailored design.

* Displays a search box and list which you can embed in other views
* Provides a callback handler with the result details when users tap a result
* Can bias search results to be nearby a specific location
* Automatically localizes place names based on the user's device settings (where available)

![Screenshot](screenshot)

## Quickstart

First, you'll need a Stadia Maps API key.
Create one for free [here](https://client.stadiamaps.com/signup/?utm_source=spm&utm_campaign=sdk_readme&utm_content=swiftui_autocomplete_landing).

Then, add it to your SwiftUI view like this:

```swift
AutocompleteSearch(apiKey: previewApiKey, onResultSelected: { selection in
    // TODO: Selection logic
})
```

Refer to the ``AutocompleteSearch`` documentation for more details on customization.
