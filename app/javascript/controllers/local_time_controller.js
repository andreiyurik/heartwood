import { Controller } from "@hotwired/stimulus"

const UNITS = [
  [ "year", 365 * 24 * 3600 ],
  [ "month", 30 * 24 * 3600 ],
  [ "week", 7 * 24 * 3600 ],
  [ "day", 24 * 3600 ],
  [ "hour", 3600 ],
  [ "minute", 60 ]
]

export default class extends Controller {
  static targets = [ "time", "date", "datetime", "ago" ]

  initialize() {
    const locale = document.documentElement.lang || undefined
    this.timeFormatter = new Intl.DateTimeFormat(locale, { timeStyle: "short" })
    this.dateFormatter = new Intl.DateTimeFormat(locale, { dateStyle: "long" })
    this.dateTimeFormatter = new Intl.DateTimeFormat(locale, { timeStyle: "short", dateStyle: "short" })
    this.relativeFormatter = new Intl.RelativeTimeFormat(locale, { numeric: "auto" })
  }

  timeTargetConnected(target) {
    this.#formatTime(this.timeFormatter, target)
  }

  dateTargetConnected(target) {
    this.#formatTime(this.dateFormatter, target)
  }

  datetimeTargetConnected(target) {
    this.#formatTime(this.dateTimeFormatter, target)
  }

  agoTargetConnected(target) {
    const dt = new Date(target.getAttribute("datetime"))
    target.textContent = this.#relative(dt)
    target.title = this.dateTimeFormatter.format(dt)
  }

  #formatTime(formatter, target) {
    const dt = new Date(target.getAttribute("datetime"))
    target.textContent = formatter.format(dt)
    target.title = this.dateTimeFormatter.format(dt)
  }

  #relative(dt) {
    const seconds = (dt - Date.now()) / 1000
    const [ unit, size ] = UNITS.find(([ , size ]) => Math.abs(seconds) >= size) || [ "minute", 60 ]
    return this.relativeFormatter.format(Math.round(seconds / size), unit)
  }
}
