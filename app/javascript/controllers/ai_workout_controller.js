import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "spinner"]

  start() {
    if (this.buttonTarget.disabled) return

    this.buttonTarget.disabled = true
    this.buttonTarget.classList.add("btn-disabled")
    this.buttonTarget.setAttribute("aria-busy", "true")
    this.spinnerTarget.classList.remove("ai-spinner--hidden")
  }

  stop() {
    this.buttonTarget.disabled = false
    this.buttonTarget.classList.remove("btn-disabled")
    this.buttonTarget.removeAttribute("aria-busy")
    this.spinnerTarget.classList.add("ai-spinner--hidden")
  }
}
