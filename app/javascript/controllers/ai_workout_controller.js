import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "spinner"]

  start() {
    // Disable the button and show the spinner while AI is running.
    if (this.buttonTarget.disabled) return

    this.buttonTarget.disabled = true
    this.buttonTarget.classList.add("btn-disabled")
    this.buttonTarget.setAttribute("aria-busy", "true")
    this.spinnerTarget.classList.remove("ai-spinner--hidden")
  }

  stop() {
    // Re-enable the button and hide the spinner when AI completes.
    this.buttonTarget.disabled = false
    this.buttonTarget.classList.remove("btn-disabled")
    this.buttonTarget.removeAttribute("aria-busy")
    this.spinnerTarget.classList.add("ai-spinner--hidden")
  }
}
