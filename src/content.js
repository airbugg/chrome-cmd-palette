import './main.css'
import { Main } from './Main.elm'
import { EVENTS } from './events'

const app = Main.embed(document.body.appendChild(document.createElement('div')))

chrome.runtime.onMessage.addListener((request, sender) => {
  if (request.actionType === EVENTS.TOGGLE_PALETTE) {
    console.log(request, sender)

    app.ports.consumeResponse.send({
      actionType: EVENTS.TOGGLE_PALETTE,
      payload: []
    })
  }
  if (request.actionType === EVENTS.GET_TABS) {
    console.log(request, sender)
    app.ports.consumeResponse.send({
      actionType: EVENTS.GET_TABS,
      payload: request.payload
    })
  }
})
