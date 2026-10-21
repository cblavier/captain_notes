import {test} from "node:test"
import assert from "node:assert/strict"
import {SectionNavigation} from "../js/section_navigation.js"

function setup() {
  globalThis.document = {documentElement: {dataset: {}}}
  const buttons = ["agenda", "notes", "devoirs"].map(section => ({
    attrs: {"phx-value-section": section, ...(section === "agenda" ? {"aria-current": "page"} : {})},
    getAttribute(name) { return this.attrs[name] },
    setAttribute(name, value) { this.attrs[name] = value },
    removeAttribute(name) { delete this.attrs[name] },
    closest() { return this }
  }))
  const el = {
    dataset: {section: "agenda", loading: "false"},
    contains: b => buttons.includes(b), querySelectorAll: () => buttons,
    setAttribute(name, value) { this[name] = value },
    addEventListener() {}, removeEventListener() {}
  }
  const hook = {...SectionNavigation, el}
  hook.mounted()
  return {hook, el, buttons}
}

test("selects immediately, survives intermediate patches, and clears only when content is ready", () => {
  const {hook, el, buttons} = setup()
  hook.onSectionClick({target: buttons[1]})
  assert.equal(buttons[1].attrs["aria-current"], "page")
  assert.equal(buttons[0].attrs["aria-current"], undefined)
  assert.equal(document.documentElement.dataset.sectionNavigationPending, "true")
  hook.updated() // An unrelated update for the old page.
  assert.equal(hook.pendingSection, "notes")
  el.dataset.section = "notes"
  el.dataset.loading = "true"
  hook.updated()
  assert.equal(buttons[1].attrs["data-pending"], "true")
  el.dataset.loading = "false"
  hook.updated()
  assert.equal(hook.pendingSection, null)
  assert.equal(document.documentElement.dataset.sectionNavigationPending, undefined)
  assert.equal(buttons[1].attrs["data-pending"], undefined)
})

test("blocks competing clicks and restores the current page after disconnection", () => {
  const {hook, buttons} = setup()
  hook.onSectionClick({target: buttons[1]})
  let prevented = false, stopped = false
  hook.onSectionClick({target: buttons[2], preventDefault() { prevented = true }, stopImmediatePropagation() { stopped = true }})
  assert.ok(prevented && stopped)
  hook.disconnected()
  assert.equal(document.documentElement.dataset.sectionNavigationPending, undefined)
  assert.equal(buttons[0].attrs["aria-current"], "page")
})

test("does not start a transition for the current or a disabled tab", () => {
  const {hook, buttons} = setup()
  hook.onSectionClick({target: buttons[0]})
  buttons[1].disabled = true
  hook.onSectionClick({target: buttons[1]})
  assert.equal(hook.pendingSection, null)
})
