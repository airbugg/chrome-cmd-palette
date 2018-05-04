import './main.css'
import { Main } from './Main.elm'
import { EVENTS } from './events'

const app = Main.embed(document.body.appendChild(document.createElement('div')))

chrome.runtime.onMessage.addListener((request, sender) => {
  console.log('request received, yo', request, sender)
  if (request.kind === EVENTS.TOGGLE_PALETTE) {
    app.ports.consumeEvent.send(null)
  }
})
