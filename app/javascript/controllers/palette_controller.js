import { Controller } from "@hotwired/stimulus"

/**
 * Palette Controller - a keyboard command palette for a single-page site.
 *
 * Opens on ⌘K / Ctrl+K, or on "/" when the caret is not already in a field.
 * Filters a server-rendered list of links, moves a highlight with the arrow
 * keys, and activates the highlighted row on Enter. ESC closes and returns
 * focus to whatever had it before.
 *
 * Usage:
 *   <div data-controller="palette"
 *        data-action="keydown@window->palette#hotkey"
 *        data-palette-active-class="bg-raised text-fg">
 *     <button data-action="click->palette#open">⌘K</button>
 *
 *     <div data-palette-target="dialog" hidden
 *          data-action="keydown->palette#dialogKeys click->palette#backdrop">
 *       <input data-palette-target="input" data-action="input->palette#filter">
 *       <ul>
 *         <li><a id="palette-work" role="option" href="#work"
 *                data-palette-target="item" data-palette-label="work experience"
 *                data-action="click->palette#close">Work</a></li>
 *       </ul>
 *       <p data-palette-target="empty" hidden>No match</p>
 *     </div>
 *   </div>
 *
 * Rows are hidden with the `hidden` attribute rather than a utility class:
 * Tailwind's preflight declares `[hidden] { display: none !important }`, so it
 * beats whatever display utility the row carries, and no class string has to
 * live in JavaScript.
 */
export default class extends Controller {
  static targets = ["dialog", "input", "item", "empty", "copyLabel"]
  static classes = ["active"]
  static values = {
    open: { type: Boolean, default: false },
    copiedLabel: { type: String, default: "copied" }
  }

  connect() {
    this.activeIndex = 0
    this.restoreFocusTo = null
    this.copyResetTimer = null
  }

  disconnect() {
    this.enableBodyScroll()
    clearTimeout(this.copyResetTimer)
    this.copyResetTimer = null
  }

  // -- opening and closing --------------------------------------------------

  // Bound to keydown@window so the shortcut works wherever the caret is.
  hotkey(event) {
    if ((event.metaKey || event.ctrlKey) && event.key.toLowerCase() === "k") {
      event.preventDefault()
      this.toggle()
      return
    }

    if (event.key === "Escape" && this.openValue) {
      event.preventDefault()
      this.close()
      return
    }

    if (event.key === "/" && !this.openValue && !this.isTypingIn(event.target)) {
      event.preventDefault()
      this.open()
    }
  }

  open() {
    this.openValue = true
  }

  close() {
    this.openValue = false
  }

  toggle() {
    this.openValue = !this.openValue
  }

  // A click that reaches the dialog element itself landed on the backdrop —
  // anything inside stops at its own handler first.
  backdrop(event) {
    if (event.target === this.dialogTarget) this.close()
  }

  openValueChanged(open, wasOpen) {
    if (!this.hasDialogTarget) return

    this.dialogTarget.hidden = !open

    if (open) {
      this.restoreFocusTo = document.activeElement
      this.disableBodyScroll()
      this.inputTarget.value = ""
      this.filter()
      this.inputTarget.focus()
      return
    }

    this.enableBodyScroll()
    // wasOpen is undefined on the initial call at connect; nothing to restore.
    if (wasOpen) this.restoreFocusTo?.focus()
  }

  // -- filtering and selection ----------------------------------------------

  filter() {
    const query = this.inputTarget.value.trim().toLowerCase()

    this.itemTargets.forEach((item) => {
      item.hidden = query !== "" && !item.dataset.paletteLabel.includes(query)
    })

    if (this.hasEmptyTarget) this.emptyTarget.hidden = this.visibleItems.length > 0

    this.setActive(0)
  }

  dialogKeys(event) {
    switch (event.key) {
      case "ArrowDown":
        event.preventDefault()
        this.setActive(this.activeIndex + 1)
        break
      case "ArrowUp":
        event.preventDefault()
        this.setActive(this.activeIndex - 1)
        break
      case "Enter":
        if (!this.activeItem) return
        event.preventDefault()
        this.activeItem.click()
        break
      case "Tab":
        this.trapTab(event)
        break
    }
  }

  setActive(index) {
    const items = this.visibleItems

    if (items.length === 0) {
      this.activeIndex = 0
      this.clearActive()
      this.inputTarget.removeAttribute("aria-activedescendant")
      return
    }

    this.activeIndex = (index + items.length) % items.length
    const active = items[this.activeIndex]

    this.itemTargets.forEach((item) => {
      const on = item === active
      this.activeClasses.forEach((name) => item.classList.toggle(name, on))
      item.setAttribute("aria-selected", on ? "true" : "false")
    })

    this.inputTarget.setAttribute("aria-activedescendant", active.id)
    active.scrollIntoView({ block: "nearest" })
  }

  clearActive() {
    this.itemTargets.forEach((item) => {
      this.activeClasses.forEach((name) => item.classList.remove(name))
      item.setAttribute("aria-selected", "false")
    })
  }

  get visibleItems() {
    return this.itemTargets.filter((item) => !item.hidden)
  }

  get activeItem() {
    return this.visibleItems[this.activeIndex]
  }

  // -- actions --------------------------------------------------------------

  // Rows that copy rather than navigate. The palette stays open so the label
  // change is visible.
  async copy(event) {
    const text = event.currentTarget.dataset.paletteCopy
    if (!text || !navigator.clipboard) return

    try {
      await navigator.clipboard.writeText(text)
    } catch {
      return
    }

    if (!this.hasCopyLabelTarget) return

    const original = this.copyLabelTarget.dataset.paletteOriginal || this.copyLabelTarget.textContent
    this.copyLabelTarget.dataset.paletteOriginal = original
    this.copyLabelTarget.textContent = this.copiedLabelValue

    clearTimeout(this.copyResetTimer)
    this.copyResetTimer = setTimeout(() => {
      this.copyLabelTarget.textContent = original
    }, 1600)
  }

  // -- helpers --------------------------------------------------------------

  trapTab(event) {
    const focusable = [this.inputTarget, ...this.visibleItems]
    const current = focusable.indexOf(document.activeElement)
    const next = event.shiftKey ? current - 1 : current + 1

    if (current !== -1 && next >= 0 && next < focusable.length) return

    event.preventDefault()
    focusable[event.shiftKey ? focusable.length - 1 : 0].focus()
  }

  isTypingIn(element) {
    if (!element) return false
    if (element.isContentEditable) return true

    return ["INPUT", "TEXTAREA", "SELECT"].includes(element.tagName)
  }

  disableBodyScroll() {
    document.body.style.overflow = "hidden"
  }

  enableBodyScroll() {
    document.body.style.overflow = ""
  }
}
