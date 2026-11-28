import { Controller } from "@hotwired/stimulus"

// Russian patronymics and surnames say the sex; it is picked for the person until they pick it themself.
// A patronymic is the last of two or more given names and is trusted over the surname.
const PATRONYMIC = { M: /(вич|ич|оглы)$/i, F: /(вна|чна|кызы)$/i }
const SURNAME = { F: /(ова|ева|ёва|ина|ына|ская|цкая)$/i, M: /(ов|ев|ёв|ин|ын|ский|цкий)$/i }
const UNSTATED = "U"

export default class extends Controller {
  static targets = [ "name", "sex" ]

  connect() {
    this.decided = this.#checked?.value != UNSTATED
  }

  chosen() {
    this.decided = true
  }

  guess() {
    if (this.decided) return

    const [ given, surname ] = this.nameTargets.map(input => input.value.trim().split(/\s+/).filter(Boolean))
    const sex = (given.length > 1 && this.#read(given.at(-1), PATRONYMIC)) || this.#read(surname?.at(-1), SURNAME) || UNSTATED
    const radio = this.sexTargets.find(input => input.value == sex)
    if (radio) radio.checked = true
  }

  #read(word, endings) {
    return word && Object.keys(endings).find(sex => endings[sex].test(word))
  }

  get #checked() {
    return this.sexTargets.find(input => input.checked)
  }
}
