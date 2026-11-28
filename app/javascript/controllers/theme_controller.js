import { Controller } from "@hotwired/stimulus"

// The layout reads the cookie into <html data-theme>; no cookie means "follow the system".
export default class extends Controller {
  toggle() {
    const root = document.documentElement
    const system = matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light"
    const chosen = (root.dataset.theme || system) == "dark" ? "light" : "dark"

    if (chosen == system) {
      delete root.dataset.theme
      document.cookie = "theme=; path=/; max-age=0; samesite=lax"
    } else {
      root.dataset.theme = chosen
      document.cookie = `theme=${chosen}; path=/; max-age=31536000; samesite=lax`
    }
  }
}
