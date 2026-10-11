import { Controller } from "@hotwired/stimulus"

/**
 * Filter — narrows a list to the rows that share one value of a key.
 *
 * The key names a data attribute both the options and the rows carry: lane on
 * the home thread (all, human, agent or ci), kind on a project's findings
 * (all, learning, surprise or takeaway). It is set in the markup, so a page
 * says what it filters on. It is read through dataset, so it is one lowercase
 * word: data-due-date would be dueDate there, not due-date. The controller
 * holds one value, the one picked. render() writes aria-pressed on each option
 * and data-dim on every row whose value does not match, and the templates'
 * data-dim variants drop those rows back. A row is never hidden. No class name
 * lives here.
 *
 * Not playback state (docs/rules/one-playback-state.md): picking a lane leaves
 * the step, playing and reopened strips as they are.
 *
 * Without scripts there is nothing to filter with, so the options render
 * hidden (design doc, section 6) and connect() reveals them.
 */
export default class extends Controller {
  static targets = ["row", "option", "live"]

  static values = { key: String, picked: { type: String, default: "all" } }

  connect() {
    this.liveTargets.forEach(element => { element.hidden = false })
    this.render()
  }

  pick(event) {
    this.pickedValue = event.currentTarget.dataset[this.keyValue]
  }

  pickedValueChanged() {
    this.render()
  }

  render() {
    const picked = this.pickedValue
    this.optionTargets.forEach(option => option.setAttribute("aria-pressed", option.dataset[this.keyValue] === picked))
    this.rowTargets.forEach(row => row.toggleAttribute("data-dim", picked !== "all" && row.dataset[this.keyValue] !== picked))
  }
}
