import { Controller } from "@hotwired/stimulus"

const DEFAULT_LAT = 51.5074
const DEFAULT_LNG = -0.1278
const DEFAULT_ZOOM = 13
const LOOKUP_ZOOM = 14

export default class extends Controller {
  static targets = ["lat", "lng", "postcode", "map"]

  connect() {
    console.log("GymMapController connected")
    if (typeof L === "undefined") {
      console.warn("Leaflet (L) is not available on window.")
      return
    }

    const { lat, lng, usedDefault } = this.initialCoordinates()

    const mapElement = this.hasMapTarget ? this.mapTarget : this.element
    this.map = L.map(mapElement).setView([lat, lng], DEFAULT_ZOOM)
    L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
      attribution: "&copy; OpenStreetMap contributors"
    }).addTo(this.map)

    this.marker = L.marker([lat, lng], { draggable: true }).addTo(this.map)
    this.marker.on("dragend", () => this.updateFromMarker())

    if (usedDefault) {
      this.writeLatLng(lat, lng)
    }

    if (this.hasPostcodeTarget) {
      this.postcodeBlurHandler = this.lookupPostcode.bind(this)
      this.postcodeTarget.addEventListener("blur", this.postcodeBlurHandler)
    }

    requestAnimationFrame(() => {
      if (this.map) this.map.invalidateSize()
    })
  }

  disconnect() {
    if (this.postcodeBlurHandler && this.hasPostcodeTarget) {
      this.postcodeTarget.removeEventListener("blur", this.postcodeBlurHandler)
    }
    if (this.map) {
      this.map.remove()
      this.map = null
    }
  }

  initialCoordinates() {
    const lat = parseFloat(this.latTarget.value)
    const lng = parseFloat(this.lngTarget.value)

    if (Number.isFinite(lat) && Number.isFinite(lng)) {
      return { lat, lng, usedDefault: false }
    }

    return { lat: DEFAULT_LAT, lng: DEFAULT_LNG, usedDefault: true }
  }

  updateFromMarker() {
    const { lat, lng } = this.marker.getLatLng()
    this.writeLatLng(lat, lng)
  }

  writeLatLng(lat, lng) {
    this.latTarget.value = lat.toFixed(6)
    this.lngTarget.value = lng.toFixed(6)
  }

  async searchPostcode(event) {
    event.preventDefault()
    if (!this.map || !this.marker || !this.hasPostcodeTarget) return

    const postcode = this.postcodeTarget.value.trim()
    if (!postcode) return
    const normalized = postcode.toUpperCase().replace(/[^A-Z0-9]/g, "")

    try {
      let lat = null
      let lng = null

      const response = await fetch(
        `https://api.postcodes.io/postcodes/${encodeURIComponent(normalized)}`,
        { headers: { Accept: "application/json" } }
      )

      if (response.ok) {
        const payload = await response.json()
        if (payload?.status === 200 && payload?.result) {
          lat = parseFloat(payload.result.latitude)
          lng = parseFloat(payload.result.longitude)
        }
      } else {
        const fallback = await fetch(
          `https://api.postcodes.io/postcodes?q=${encodeURIComponent(postcode)}`,
          { headers: { Accept: "application/json" } }
        )

        if (fallback.ok) {
          const fallbackPayload = await fallback.json()
          const fallbackResult = fallbackPayload?.result?.[0]
          if (fallbackResult) {
            lat = parseFloat(fallbackResult.latitude)
            lng = parseFloat(fallbackResult.longitude)
          }
        }
      }

      if (!Number.isFinite(lat) || !Number.isFinite(lng)) {
        const nominatim = await fetch(
          `https://nominatim.openstreetmap.org/search?format=json&limit=1&q=${encodeURIComponent(postcode)}`,
          { headers: { Accept: "application/json" } }
        )

        if (nominatim.ok) {
          const results = await nominatim.json()
          const match = results?.[0]
          lat = parseFloat(match?.lat)
          lng = parseFloat(match?.lon)
        }
      }

      if (!Number.isFinite(lat) || !Number.isFinite(lng)) {
        alert("No location found for that postcode.")
        return
      }

      this.map.setView([lat, lng], LOOKUP_ZOOM)
      this.marker.setLatLng([lat, lng])
      this.writeLatLng(lat, lng)
    } catch (error) {
      alert("Could not look up that postcode.")
    }
  }

  async lookupPostcode() {
    if (!this.map || !this.marker) return

    const postcode = this.postcodeTarget.value.trim()
    if (!postcode) return
    const normalized = postcode.toUpperCase().replace(/[^A-Z0-9]/g, "")

    try {
      let lat = null
      let lng = null

      const response = await fetch(
        `https://api.postcodes.io/postcodes/${encodeURIComponent(normalized)}`,
        { headers: { Accept: "application/json" } }
      )

      if (response.ok) {
        const payload = await response.json()
        if (payload?.status === 200 && payload?.result) {
          lat = parseFloat(payload.result.latitude)
          lng = parseFloat(payload.result.longitude)
        }
      } else {
        const fallback = await fetch(
          `https://api.postcodes.io/postcodes?q=${encodeURIComponent(postcode)}`,
          { headers: { Accept: "application/json" } }
        )

        if (fallback.ok) {
          const fallbackPayload = await fallback.json()
          const fallbackResult = fallbackPayload?.result?.[0]
          if (fallbackResult) {
            lat = parseFloat(fallbackResult.latitude)
            lng = parseFloat(fallbackResult.longitude)
          }
        }
      }

      if (!Number.isFinite(lat) || !Number.isFinite(lng)) {
        const nominatim = await fetch(
          `https://nominatim.openstreetmap.org/search?format=json&limit=1&q=${encodeURIComponent(postcode)}`,
          { headers: { Accept: "application/json" } }
        )

        if (nominatim.ok) {
          const results = await nominatim.json()
          const match = results?.[0]
          lat = parseFloat(match?.lat)
          lng = parseFloat(match?.lon)
        }
      }

      if (!Number.isFinite(lat) || !Number.isFinite(lng)) return

      this.map.setView([lat, lng], LOOKUP_ZOOM)
      this.marker.setLatLng([lat, lng])
      this.writeLatLng(lat, lng)
    } catch (error) {
      // Ignore lookup failures to avoid blocking form interactions.
    }
  }
}
