import { Controller } from "@hotwired/stimulus"

/**
 * Filter — narrows the home thread to one controller's steps.
 *
 * Holds one value, the lane picked: all, human, agent or ci. render() writes
 * aria-pressed on each option and data-dim on every row whose lane does not
 * match, and the templates' in-data-dim variants drop those rows back. A row
 * is never hidden. No class name lives here.
 *
 * Not playback state (docs/rules/one-playback-state.md): picking a lane leaves
 * the step, playing and reopened strips as they are.
 *
 * Without scripts there is nothing to filter with, so the options render
 * hidden (design doc, section 6) and connect() reveals them.
 */
export default class extends Controller {
  static targets = ["row", "option", "live"]

  static values = { lane: { type: String, default: "all" } }

  connect() {
    this.liveTargets.forEach(element => { element.hidden = false })
    this.render()
  }

  pick(event) {
    this.laneValue = event.currentTarget.dataset.lane
  }

  laneValueChanged() {
    this.render()
  }

  render() {
    const lane = this.laneValue
    this.optionTargets.forEach(option => option.setAttribute("aria-pressed", option.dataset.lane === lane))
    this.rowTargets.forEach(row => row.toggleAttribute("data-dim", lane !== "all" && row.dataset.lane !== lane))
  }
}
