// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"

let Hooks = {}

Hooks.SearchHighlight = {
  mounted() {
    this.input = this.el.querySelector('#search-input')
    this.highlight = this.el.querySelector('#search-highlight')

    this.updateHighlight()

    // Update on every input change for real-time highlighting
    this.input.addEventListener('input', () => {
      this.updateHighlight()
    })

    // Also update on keyup to catch all changes
    this.input.addEventListener('keyup', () => {
      this.updateHighlight()
    })
  },

  updated() {
    this.updateHighlight()
  },

  updateHighlight() {
    const text = this.input.value || ''
    const regex = /^(.*)(\w+):(\S+)(.*)$/
    const match = text.match(regex)

    // Get computed text color from input for normal text
    const inputStyles = window.getComputedStyle(this.input)
    const textColor = inputStyles.color

    if (match) {
      const [, prefix, key, value, suffix] = match
      // Show all text, but highlight only the value part
      this.highlight.innerHTML = `
        <span class="text-primary-text">
          ${this.escapeHtml(prefix)}${this.escapeHtml(key)}:
        </span>
        <span class="bg-accent/10 text-accent">
          ${this.escapeHtml(value)}
        </span>
        <span class="text-primary-text ml-1">
          ${this.escapeHtml(suffix)}
        </span>
      `
    } else {
      // Show all text normally when no highlighting needed
      this.highlight.innerHTML = `<span class="text-primary-text">${this.escapeHtml(text)}</span>`
    }
  },

  escapeHtml(text) {
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  }
}

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: Hooks
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
// Add a big 3s delay until we add Otel to understand where the latency is.
// Remove the feeling that the site is not loading when it takes ~1s.
// Being conservative because we do want to show a topbar if it takes > 3s.
window.addEventListener("phx:page-loading-start", _info => topbar.show(3000))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

