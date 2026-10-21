// Optimistic tab feedback; LiveView remains responsible for the page and URL.
export const SectionNavigation = {
  mounted() {
    this.pendingSection = null
    this.onSectionClick = event => {
      const button = event.target.closest(".navigation-tab")
      if (!button || !this.el.contains(button) || button.disabled || event.defaultPrevented) return
      if (this.pendingSection) {
        event.preventDefault()
        event.stopImmediatePropagation()
        return
      }
      const section = button.getAttribute("phx-value-section")
      if (!section || section === this.el.dataset.section) return
      this.pendingSection = section
      this.paintPending()
    }
    this.el.addEventListener("click", this.onSectionClick, true)
  },
  paintPending() {
    document.documentElement.dataset.sectionNavigationPending = "true"
    this.el.setAttribute("aria-busy", "true")
    for (const button of this.el.querySelectorAll(".navigation-tab")) {
      const selected = button.getAttribute("phx-value-section") === this.pendingSection
      if (selected) {
        button.setAttribute("aria-current", "page")
        button.setAttribute("data-pending", "true")
      } else {
        button.removeAttribute("aria-current")
        button.removeAttribute("data-pending")
      }
    }
  },
  clearPending() {
    this.pendingSection = null
    delete document.documentElement.dataset.sectionNavigationPending
    this.el.setAttribute("aria-busy", this.el.dataset.loading || "false")
    for (const button of this.el.querySelectorAll(".navigation-tab")) {
      button.removeAttribute("data-pending")
      if (button.getAttribute("phx-value-section") === this.el.dataset.section) {
        button.setAttribute("aria-current", "page")
      } else {
        button.removeAttribute("aria-current")
      }
    }
  },
  updated() {
    if (!this.pendingSection) return
    if (this.el.dataset.section === this.pendingSection && this.el.dataset.loading === "false") {
      this.clearPending()
    } else {
      this.paintPending()
    }
  },
  disconnected() { this.clearPending() },
  destroyed() {
    this.el.removeEventListener("click", this.onSectionClick, true)
    this.clearPending()
  }
}
