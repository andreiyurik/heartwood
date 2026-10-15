import { Controller } from "@hotwired/stimulus"

// A menu item outside the tree can still print it: the tree controller is an outlet.
export default class extends Controller {
  static outlets = [ "tree" ]

  print() {
    this.treeOutlet.print()
  }
}
