import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "button"]

  toggle() {
    // Toggle full workout visibility and update the button label.
    this.contentTarget.classList.toggle("hidden")
    const isHidden = this.contentTarget.classList.contains("hidden")
    this.buttonTarget.textContent = isHidden ? "View full workout" : "Hide full workout"
  }
}
