import { Controller } from "@hotwired/stimulus"

/**
 * Playback — plays the home thread, one step at a time.
 *
 * The one owner of playback state (docs/rules/one-playback-state.md): the
 * step index, whether it is playing, and which done strips the reader has
 * reopened. Every view renders from these three values. render() writes them
 * onto the page as data-playing on this element, data-state and data-open on
 * each row, data-state on each scope target, and ARIA state and words, and
 * the templates' in-data-* variants do the styling. No class name lives here.
 *
 * Without scripts none of this runs, and the page reads as a document (design
 * doc, section 6). On connect the controller reveals what only playback uses
 * (the "live" targets) and enables the strips.
 *
 * The event table it implements is in docs/system/home-thread-playback.md.
 */

const GATES = ["human", "machine"]

export default class extends Controller {
  static targets = ["thread", "row", "strip", "status", "line", "target", "live", "play",
    "readoutName", "readoutDetail", "readoutStatus"]

  static values = {
    step: Number,
    playing: Boolean,
    open: Array,
    // Milliseconds per second of step time. Only system tests change it.
    pace: { type: Number, default: 1000 }
  }

  connect() {
    this.liveTargets.forEach(element => { element.hidden = false })
    this.stripTargets.forEach(strip => { strip.disabled = false })
    // Values live in data attributes, so a page Turbo restores from its cache
    // comes back saying it was playing. It must not resume by itself
    // (docs/rules/playback-yields.md): it comes back paused, and rows that
    // already carry a state (only render() writes one) mark it as a page the
    // reader has been on, so it does not start again on view either.
    this.touched = this.rowTargets.some(row => row.dataset.state)
    this.playingValue = false
    this.connected = true
    this.resetClock()
    this.settle()
    this.watchForThread()
  }

  disconnect() {
    clearTimeout(this.timer)
    this.observer?.disconnect()
    this.connected = false
  }

  // Actions

  toggle() {
    this.touched = true
    if (this.playingValue) {
      this.playingValue = false
    } else if (this.onLastStep) {
      this.openValue = []
      this.go(0)
      this.playingValue = true
    } else {
      this.playingValue = true
    }
  }

  back() { this.jumpTo(this.stepValue - 1) }

  forward() { this.jumpTo(this.stepValue + 1) }

  // A scope target: a link to its step without scripts, a jump with them.
  jump(event) {
    event.preventDefault()
    this.jumpTo(this.targetTargets.indexOf(event.currentTarget))
  }

  // A strip: a done one opens or closes and playback carries on; any other
  // is a jump.
  select(event) {
    const index = this.stripTargets.indexOf(event.currentTarget)
    if (index >= this.stepValue) return this.jumpTo(index)

    this.touched = true
    const open = new Set(this.openValue)
    open.has(index) ? open.delete(index) : open.add(index)
    this.openValue = [...open]
  }

  restart() {
    this.touched = true
    this.playingValue = false
    this.openValue = []
    if (this.stepValue === 0) this.resetClock()
    this.go(0)
  }

  // Leaving the tab pauses. Nothing resumes by itself (docs/rules/playback-yields.md).
  hide() {
    if (document.visibilityState === "hidden") this.playingValue = false
  }

  // Value callbacks. Stimulus calls them once before connect, when there is
  // nothing to render yet.

  stepValueChanged() {
    if (!this.connected) return
    this.resetClock()
    this.render()
  }

  playingValueChanged(playing) {
    if (!this.connected) return
    playing ? this.startClock() : this.stopClock()
    this.render()
  }

  openValueChanged() {
    if (this.connected) this.render()
  }

  paceValueChanged() {
    if (!this.connected) return
    this.resetClock()
    this.render()
  }

  // The step clock. The active step plays for its seconds at the pace; a
  // pause keeps what is left, and a new step starts it full. The strip's
  // remaining-time line is the same clock drawn in CSS, restarted with it.

  resetClock() {
    clearTimeout(this.timer)
    this.startedAt = null
    this.remaining = this.secondsOf(this.stepValue) * this.paceValue
    this.lineTargets[this.stepValue]?.getAnimations().forEach(animation => { animation.currentTime = 0 })
    if (this.playingValue) this.startClock()
  }

  startClock() {
    clearTimeout(this.timer)
    this.startedAt = performance.now()
    this.timer = setTimeout(() => this.advance(), this.remaining)
  }

  stopClock() {
    clearTimeout(this.timer)
    if (this.startedAt === null) return
    this.remaining = Math.max(0, this.remaining - (performance.now() - this.startedAt))
    this.startedAt = null
  }

  advance() {
    this.startedAt = null
    if (this.onLastStep) {
      this.playingValue = false
    } else {
      this.stepValue += 1
    }
  }

  // Moves

  jumpTo(index) {
    this.touched = true
    this.playingValue = false
    this.go(index)
  }

  // A new step starts its clock full (stepValueChanged). Going to the step
  // already active keeps what it has left: selecting it again, or back on the
  // first step and forward on the last, which clamp to it.
  go(index) {
    const step = Math.max(0, Math.min(this.rowTargets.length - 1, index))
    if (step === this.stepValue) {
      this.render()
    } else {
      this.stepValue = step
    }
  }

  // The first render closes every body but the active one. That is the page
  // taking its starting state, not a change of state, so it must not animate
  // (docs/rules/motion-budget.md): data-settling turns transitions off until
  // the browser has drawn it.
  settle() {
    this.element.toggleAttribute("data-settling", true)
    this.render()
    requestAnimationFrame(() => requestAnimationFrame(() => this.element.removeAttribute("data-settling")))
  }

  // Starts playing the first time the thread scrolls into view, unless the
  // reader has already taken the controls or asked for reduced motion.
  watchForThread() {
    if (!this.hasThreadTarget || matchMedia("(prefers-reduced-motion: reduce)").matches) return

    this.observer = new IntersectionObserver(entries => {
      if (!entries.some(entry => entry.isIntersecting)) return
      this.observer.disconnect()
      if (!this.touched) this.playingValue = true
    })
    this.observer.observe(this.threadTarget)
  }

  // Render: state onto the page

  render() {
    const step = this.stepValue
    const playing = this.playingValue
    const open = new Set(this.openValue)

    this.element.toggleAttribute("data-playing", playing)
    this.element.style.setProperty("--pace", this.paceValue)

    this.rowTargets.forEach((row, index) => {
      const state = index < step ? "done" : index === step ? "active" : "pending"
      const expanded = state === "active" || (state === "done" && open.has(index))
      row.dataset.state = state
      row.dataset.open = expanded
      this.stripTargets[index].setAttribute("aria-expanded", expanded)
      this.statusTargets[index].textContent = this.word(state, this.kindOf(index), playing)
    })

    this.targetTargets.forEach((target, index) => {
      target.dataset.state = index < step ? "done" : index === step ? "active" : "pending"
      index === step ? target.setAttribute("aria-current", "step") : target.removeAttribute("aria-current")
    })

    this.renderReadout(step, playing)
    if (this.hasPlayTarget) {
      this.playTarget.setAttribute("aria-label", playing ? "Pause" : this.onLastStep ? "Replay" : "Play")
    }
  }

  renderReadout(step, playing) {
    const target = this.targetTargets[step]
    if (!target) return

    const { number, name, detail, kind, angle } = target.dataset
    this.element.style.setProperty("--leader-angle", `${angle}deg`)
    if (this.hasReadoutNameTarget) this.readoutNameTarget.textContent = `${number} ${name}`
    if (this.hasReadoutDetailTarget) this.readoutDetailTarget.textContent = detail
    if (this.hasReadoutStatusTarget) {
      this.readoutStatusTarget.textContent = this.word("active", kind, playing)
      this.readoutStatusTarget.dataset.kind = kind
    }
  }

  // The status word (design doc, section 4): a gate holds while active and is
  // cleared once passed.
  word(state, kind, playing) {
    const gate = GATES.includes(kind)
    if (state === "done") return gate ? "cleared" : "done"
    if (state === "pending") return "pending"
    if (!playing) return "paused"
    return gate ? "hold" : "active"
  }

  kindOf(index) { return this.stripTargets[index].dataset.kind }

  secondsOf(index) {
    return Number(this.rowTargets[index]?.style.getPropertyValue("--seconds")) || 6
  }

  get onLastStep() { return this.stepValue === this.rowTargets.length - 1 }
}
