import { Controller } from "@hotwired/stimulus"

const DISPLAY_ZOOM = 14

export default class extends Controller {
  static values = {
    lat: Number,
    lng: Number
  }

  connect() {
    if (!window.L) return
    if (!this.hasLatValue || !this.hasLngValue) return

    this.map = L.map(this.element, {
      zoomControl: false,
      dragging: false,
      scrollWheelZoom: false,
      doubleClickZoom: false,
      boxZoom: false,
      keyboard: false,
      tap: false,
      touchZoom: false
    }).setView([this.latValue, this.lngValue], DISPLAY_ZOOM)

    L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
      attribution: "&copy; OpenStreetMap contributors"
    }).addTo(this.map)

    L.marker([this.latValue, this.lngValue], { interactive: false }).addTo(this.map)

    requestAnimationFrame(() => {
      if (this.map) this.map.invalidateSize()
    })
  }

  disconnect() {
    if (this.map) {
      this.map.remove()
      this.map = null
    }
  }
}
