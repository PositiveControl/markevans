import { Controller } from "@hotwired/stimulus"

/**
 * Playback — plays the home thread, one step at a time.
 *
 * The one owner of playback state (docs/rules/one-playback-state.md): the
 * step index, whether it is playing, and which done strips the reader has
 * reopened. Every view renders from these three values. render() writes them
 * onto the page as data-playing and data-ended on this element, data-state and data-open on
 * each row, data-state on each scope target, and ARIA state and words, and
 * the templates' in-data-* variants do the styling. No class name lives here.
 *
 * Without scripts none of this runs, and the page reads as a document (design
 * doc, section 6). On connect the controller reveals what only playback uses
 * (the "live" targets) and enables the strips.
 *
 * The event table it implements is in docs/system/home-thread-playback.md.
 */

// Keys the browser scrolls the page with. Space is left out: it plays and pauses.
const SCROLL_KEYS = new Set(["ArrowUp", "ArrowDown", "PageUp", "PageDown", "Home", "End"])

// Keys that only change what the next key types.
const MODIFIERS = new Set(["Shift", "CapsLock", "AltGraph"])

// How long g waits for its number, in milliseconds.
const GATE_WINDOW = 1500

// How long a wheel or touch scroll must go quiet before the next is a new one.
const SCROLL_QUIET = 300

export default class extends Controller {
  static targets = ["thread", "scope", "row", "strip", "status", "line", "target", "mark", "live", "play",
    "readoutName", "readoutDetail", "readoutStatus", "bay",
    "logEntry", "logEmpty", "gatesCleared", "artifacts"]

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
    const restored = this.rowTargets.some(row => row.dataset.state)
    this.touched = restored
    this.playingValue = false
    // A step's hash opens that step, paused, and it has been chosen, so the
    // thread does not start on view either. A restored page carries its own
    // step and scroll, and the hash its URL gained along the way is not a link.
    const linked = restored ? -1 : this.rowTargets.findIndex(row => location.hash === `#${row.id}`)
    if (linked >= 0) {
      this.stepValue = linked
      this.touched = true
    }
    this.connected = true
    this.resetClock()
    // The clock is not in an attribute, so a thread that had played out says
    // so in data-ended, and comes back played out rather than with the last
    // step's time full again.
    if (this.element.hasAttribute("data-ended") && this.onLastStep) this.remaining = 0
    this.settle()
    this.watchForThread()
    this.watchScope()
    // The browser scrolled to the hash before the bodies above it closed, so
    // the page goes to the step again, at once.
    if (linked >= 0) this.follow({ instant: true })
  }

  disconnect() {
    clearTimeout(this.timer)
    this.observer?.disconnect()
    this.dock?.disconnect()
    this.connected = false
  }

  // Actions

  // Play scrolls back to the active strip first, wherever the reader left
  // the page (docs/rules/playback-yields.md).
  toggle() {
    this.touched = true
    if (this.playingValue) {
      this.playingValue = false
      return
    }
    if (this.onLastStep) {
      this.openValue = []
      if (this.stepValue === 0) this.resetClock() // a one-step thread: go(0) stays put
      this.go(0)
    }
    this.follow()
    this.playingValue = true
  }

  back() { this.jumpTo(this.stepValue - 1) }

  forward() { this.jumpTo(this.stepValue + 1) }

  // A scope target or a docked mark: a link to its step without scripts, a
  // jump with them, and the page goes there. Each says which step in
  // data-playback-index-param.
  jump(event) {
    event.preventDefault()
    this.jumpTo(event.params.index)
    this.follow()
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

  // The reader scrolling, by wheel, touch, keys or the scrollbar, pauses, and
  // drops a follow still on its way and a g still waiting for its number.
  // Their input, not the scroll event: the controller's own scrolls fire none
  // of these, so following can never read as the reader. Before playback has
  // started, a scroll is how the thread comes into view, so it counts as
  // nothing.
  yield() {
    this.drop()
    if (!this.playingValue) return

    this.touched = true
    this.playingValue = false
  }

  // The wheel or a touch scroll. Where the thread starts below the fold, the
  // scroll that brings it into view starts it, and that same scroll goes on
  // for a moment after: it is how the reader got here, not a new one, so it
  // does not pause until it goes quiet for SCROLL_QUIET ms. It is still the
  // reader's hand on the page, so a follow on its way and a waiting g drop.
  scroll() {
    const now = performance.now()
    this.arriving = this.arriving && this.scrolling(now)
    this.scrolledAt = now
    if (!this.arriving) return this.yield()

    this.drop()
  }

  // What any scroll of the reader's cancels, paused or not.
  drop() {
    this.followingStep = null
    this.gateArmedAt = null
  }

  // A wheel or touch scroll heard less than SCROLL_QUIET ms ago.
  scrolling(now = performance.now()) {
    return now - this.scrolledAt < SCROLL_QUIET
  }

  // A press on the page's scrollbar: Chrome and Safari report it on <html>,
  // where nothing else on the page can be pressed.
  press(event) {
    if (event.target === document.documentElement) this.yield()
  }

  // The keyboard, listed in the footer: Space plays and pauses, j and k step,
  // and g then a number jumps to that gate. The keys that scroll the page
  // yield. Keys in a text field are the field's, and Space on a focused
  // button presses it; browser shortcuts (Ctrl, Alt, Cmd) pass through. g
  // waits 1.5 s for its number, and a scroll drops it.
  key(event) {
    if (event.ctrlKey || event.altKey || event.metaKey || this.typing(event)) return

    // A modifier pressed on its own is not the next key: on some layouts
    // the digit after g needs Shift.
    if (MODIFIERS.has(event.key)) return

    if (this.gateArmedAt != null) {
      const armed = performance.now() - this.gateArmedAt < GATE_WINDOW
      this.gateArmedAt = null
      const gate = armed ? this.gates[Number(event.key) - 1] : undefined
      if (gate !== undefined) return this.goToGate(gate)
    }

    switch (event.key.toLowerCase()) { // Caps Lock sends J, K and G
      case " ":
        // Shift+Space scrolls up, and on a link Space scrolls down: a link
        // takes Enter. On a button or summary it presses that.
        if (event.shiftKey || event.target.closest?.("a[href]")) return this.yield()
        if (event.target.closest?.("button, summary")) return
        event.preventDefault()
        if (event.repeat) return // held down: one press, not a flicker
        return this.toggle()
      case "j": return this.forward()
      case "k": return this.back()
      case "g":
        this.gateArmedAt = performance.now()
        return
      default:
        if (SCROLL_KEYS.has(event.key)) this.yield()
    }
  }

  goToGate(index) {
    this.jumpTo(index)
    this.follow()
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
    this.writeHash()
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
      this.remaining = 0
      this.playingValue = false
    } else {
      this.stepValue += 1
      this.follow()
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

  // Follow: the page scrolls the active strip to 96 px below the viewport's
  // top (the rows' scroll margin). Only the controller calls this: on a step
  // the clock moves to, on Play, and on an explicit jump. Nothing else moves
  // the page.
  //
  // A value change renders a moment later (Stimulus hears it as an attribute
  // change), so this waits a frame for that render. Then a body above that is
  // rolling up still has its height, and the strip will rise by it, so the
  // scroll waits for the roll-up to end too. Anything that happens meanwhile
  // (another step, or the reader taking over) drops it.
  follow({ instant = this.reducedMotion } = {}) {
    const step = this.followingStep = this.stepValue
    const current = () => this.connected && this.followingStep === step && this.stepValue === step

    requestAnimationFrame(async () => {
      const rollUps = this.element.getAnimations({ subtree: true })
        .filter(animation => animation.transitionProperty === "grid-template-rows")
      await Promise.allSettled(rollUps.map(animation => animation.finished))
      if (!current()) return

      this.followingStep = null
      this.rowTargets[step].scrollIntoView({ block: "start", behavior: instant ? "instant" : "smooth" })
    })
  }

  // Each step has its own hash, the row's id: a link to it opens it. A step
  // change rewrites the URL in place, so the back button still leaves the
  // page. Turbo's own entry in history.state is kept.
  writeHash() {
    const hash = `#${this.rowTargets[this.stepValue].id}`
    if (location.hash !== hash) history.replaceState(history.state, "", hash)
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
    if (!this.hasThreadTarget || this.reducedMotion) return

    this.observer = new IntersectionObserver(entries => {
      if (!entries.some(entry => entry.isIntersecting)) return
      this.observer.disconnect()
      if (this.touched) return
      // A thread already in view on load starts with no scroll behind it.
      this.arriving = this.scrolling()
      this.playingValue = true
    })
    this.observer.observe(this.threadTarget)
  }

  // Docks the bar while the scope is out of view: data-docked on this element
  // shows it. Where the reader is looking is not playback state; the bar is a
  // second view of the same three values.
  watchScope() {
    if (!this.hasScopeTarget) return

    // One callback can carry several crossings (Home then End); the last is now.
    this.dock = new IntersectionObserver(entries => {
      this.element.toggleAttribute("data-docked", !entries.at(-1).isIntersecting)
    })
    this.dock.observe(this.scopeTarget)
  }

  // Render: state onto the page

  render() {
    const step = this.stepValue
    const playing = this.playingValue
    const open = new Set(this.openValue)

    this.element.toggleAttribute("data-playing", playing)
    this.element.toggleAttribute("data-ended", this.ended)
    this.element.style.setProperty("--pace", this.paceValue)

    this.rowTargets.forEach((row, index) => {
      const state = index < step ? "done" : index === step ? "active" : "pending"
      const expanded = state === "active" || (state === "done" && open.has(index))
      row.dataset.state = state
      row.dataset.open = expanded
      this.stripTargets[index].setAttribute("aria-expanded", expanded)
      this.statusTargets[index].textContent = this.word(state, this.gateAt(index), playing)
    })

    // The scope's targets and the docked bar's marks: one per step, each.
    for (const marks of [this.targetTargets, this.markTargets]) {
      marks.forEach((mark, index) => {
        mark.dataset.state = index < step ? "done" : index === step ? "active" : "pending"
        index === step ? mark.setAttribute("aria-current", "step") : mark.removeAttribute("aria-current")
      })
    }

    this.renderReadout(step, playing)
    this.renderBay(step)
    this.renderLog(step)
    const label = playing ? "Pause" : this.onLastStep ? "Replay" : "Play"
    this.playTargets.forEach(play => play.setAttribute("aria-label", label))
  }

  renderReadout(step, playing) {
    const target = this.targetTargets[step]
    if (!target) return

    const { number, name, detail, kind, gate, angle } = target.dataset
    this.element.style.setProperty("--leader-angle", `${angle}deg`)
    this.readoutNameTargets.forEach(readout => { readout.textContent = `${number} ${name}` })
    if (this.hasReadoutDetailTarget) this.readoutDetailTarget.textContent = detail
    if (this.hasReadoutStatusTarget) {
      this.readoutStatusTarget.textContent = this.word("active", gate === "true", playing)
      this.readoutStatusTarget.dataset.kind = kind
    }
  }

  // The strip bay: the cell for the active step's bay is current.
  renderBay(step) {
    const bay = this.rowTargets[step]?.dataset.bay
    this.bayTargets.forEach(cell => {
      const current = cell.dataset.bay === bay
      cell.toggleAttribute("data-current", current)
      current ? cell.setAttribute("aria-current", "true") : cell.removeAttribute("aria-current")
    })
  }

  // The log: an entry for every step before the active one, and the last
  // step too once its time has run out; then what they add up to. The entries
  // are rendered newest first; this only shows them.
  renderLog(step) {
    const through = this.ended ? step + 1 : step
    this.logEntryTargets.forEach(entry => { entry.hidden = Number(entry.dataset.index) >= through })
    const finished = this.logEntryTargets.filter(entry => !entry.hidden)
    if (this.hasLogEmptyTarget) this.logEmptyTarget.hidden = finished.length > 0
    if (this.hasGatesClearedTarget) {
      this.gatesClearedTarget.textContent = finished.filter(entry => entry.dataset.gate === "true").length
    }
    if (this.hasArtifactsTarget) {
      this.artifactsTarget.textContent = finished.filter(entry => entry.dataset.artifact === "true").length
    }
  }

  // The status word (design doc, section 4): a gate holds while active and is
  // cleared once passed. Which steps are gates the server says, in data-gate.
  word(state, gate, playing) {
    if (state === "done") return gate ? "cleared" : "done"
    if (state === "pending") return "pending"
    if (!playing) return "paused"
    return gate ? "hold" : "active"
  }

  // The gates' step indexes, in order: g then 1 is the first.
  get gates() {
    return this.stripTargets.flatMap((strip, index) => strip.dataset.gate === "true" ? [index] : [])
  }

  gateAt(index) { return this.stripTargets[index].dataset.gate === "true" }

  secondsOf(index) {
    return Number(this.rowTargets[index]?.style.getPropertyValue("--seconds")) || 6
  }

  // Keys in a text field are the field's.
  typing({ target }) {
    return target.isContentEditable || ["INPUT", "TEXTAREA", "SELECT"].includes(target.tagName)
  }

  get reducedMotion() { return matchMedia("(prefers-reduced-motion: reduce)").matches }

  get onLastStep() { return this.stepValue === this.rowTargets.length - 1 }

  // The thread has played out: the last step's time ran to nothing. Any move,
  // a restart or a replay starts a step's clock again and ends this.
  get ended() { return this.onLastStep && !this.playingValue && this.remaining === 0 }
}
