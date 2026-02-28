import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "button"]

  toggle() {
    this.contentTarget.classList.toggle("hidden")
    const isHidden = this.contentTarget.classList.contains("hidden")
    this.buttonTarget.textContent = isHidden ? "View full workout" : "Hide full workout"
  }
}
