import { Controller } from "@hotwired/stimulus"

// A scene is a run of CSS animations ending on its resting state. This holds it until it is seen,
// and tells CSS how far its one travelling thing has to fly (--fly-x, --fly-y, --fly-scale).
export default class extends Controller {
  static classes = [ "playing", "waiting" ]
  static targets = [ "from", "to" ]

  connect() {
    this.element.classList.add(this.waitingClass)
    this.#rewind()
    this.observer = new IntersectionObserver(([ entry ]) => {
      if (entry.isIntersecting) this.#start()
    }, { threshold: 0.4 })
    this.observer.observe(this.element)
  }

  disconnect() {
    this.observer.disconnect()
  }

  replay() {
    this.#rewind()
    this.#start()
  }

  // Measured at rest: mid-animation both ends are somewhere else. Reading the boxes is also the
  // reflow without which the animations would not restart.
  #rewind() {
    const style = this.element.style
    this.element.classList.remove(this.playingClass)
    for (const name of [ "--fly-x", "--fly-y", "--fly-scale" ]) style.removeProperty(name)

    const box = this.element.getBoundingClientRect()
    if (this.hasFromTarget && this.hasToTarget) {
      const from = this.fromTarget.getBoundingClientRect(), to = this.toTarget.getBoundingClientRect()
      style.setProperty("--fly-x", `${from.x + from.width / 2 - to.x - to.width / 2}px`)
      style.setProperty("--fly-y", `${from.y + from.height / 2 - to.y - to.height / 2}px`)
      style.setProperty("--fly-scale", from.width / to.width)
    }
    if (box) this.element.classList.add(this.playingClass)
  }

  #start() {
    this.element.classList.remove(this.waitingClass)
    this.observer.disconnect()
  }
}
