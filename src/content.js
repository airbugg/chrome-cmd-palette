import './main.scss'
import { Main } from './Main.elm'
import { EVENTS } from './events'

const app = Main.embed(document.body.appendChild(document.createElement('div')))
const port = chrome.runtime.connect({ name: 'chrome-command-pallete' })

port.onMessage.addListener(({ actionType, payload = [] }) => {
  switch (actionType) {
    case EVENTS.TOGGLE_PALETTE:
      app.ports.consumeResponse.send({
        actionType: EVENTS.TOGGLE_PALETTE,
        payload
      })
      break
    case EVENTS.SUGGESTIONS_UPDATED:
      console.log(EVENTS.SUGGESTIONS_UPDATED)
      app.ports.consumeResponse.send({
        actionType: EVENTS.SUGGESTIONS_UPDATED,
        payload
      })
      break
    default:
      break
  }
})

app.ports.sendRequest.subscribe(request => {
  if (request.actionType === 'REQUEST_SUGGESTIONS') {
    console.log('inside sendRequest.subscribe in content script', request)
    port.postMessage({ actionType: EVENTS.REQUEST_SUGGESTIONS, payload: null })
  }
})

// port.onMessage.addListener(request => {})
