# Data and privacy

StoreKit communicates with Apple for purchases outside local testing. The app has no analytics, advertising, or account backend.

App data is stored in the current user's Application Support directory using atomic file replacement. The files are not additionally encrypted by this app; device storage protections and backup settings apply. There is no telemetry or third-party analytics SDK.

Exports create temporary files and then hand them to the system share sheet or save panel. Where those files go depends on the action you choose. Review reports and source images before sharing them.

App permissions are requested only for the relevant platform feature. This document describes the repository implementation; it is not a privacy policy for a separately operated service.
