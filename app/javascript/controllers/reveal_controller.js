import { Controller } from "@hotwired/stimulus"

/**
 * Reveal Controller - fades items in as they scroll into view.
 *
 * Usage:
 *   <div data-controller="reveal" data-reveal-visible-class="reveal-in">
 *     <div data-reveal-target="item" class="reveal">…</div>
 *     <div data-reveal-target="item" class="reveal" style="--reveal-delay: 80ms">…</div>
 *   </div>
 *
 * Items that are already on screen at connect() reveal immediately, so a page
 * restored from the Turbo cache never shows a blank hero.
 */
export default class extends Controller {
  static targets = ["item"]
  static classes = ["visible"]
  static values = {
    threshold: { type: Number, default: 0.15 }
  }

  connect() {
    this.visible = this.hasVisibleClass ? this.visibleClass : "reveal-in"

    if (!("IntersectionObserver" in window)) {
      this.itemTargets.forEach((el) => el.classList.add(this.visible))
      return
    }

    this.observer = new IntersectionObserver(
      (entries) => this.handle(entries),
      { threshold: this.thresholdValue, rootMargin: "0px 0px -8% 0px" }
    )

    this.itemTargets.forEach((el) => this.observer.observe(el))
  }

  disconnect() {
    this.observer?.disconnect()
    this.observer = null
  }

  itemTargetConnected(el) {
    this.observer?.observe(el)
  }

  handle(entries) {
    entries.forEach((entry) => {
      if (!entry.isIntersecting) return

      entry.target.classList.add(this.visible)
      this.observer.unobserve(entry.target)
    })
  }
}
