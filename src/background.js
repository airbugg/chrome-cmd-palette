import { EVENTS } from './events'
import { actionFactory } from './actions'

const ports = new Map()
const actions = actionFactory(chrome)

chrome.runtime.onConnect.addListener(port => {
  const tabId = port.sender.tab.id

  ports.set(tabId, port)

  port.onMessage.addListener(({ actionType, payload }) => {
    switch (actionType) {
      case 'REQUEST_SUGGESTIONS':
        actions.getAllTabs().then(allTabs =>
          port.postMessage({
            actionType: EVENTS.SUGGESTIONS_UPDATED,
            payload: allTabs
          })
        )
        break

      default:
        break
    }
  })

  port.onDisconnect.addListener(() => {
    ports.delete(tabId)
  })
})

chrome.runtime.onMessage.addListener((message, sender) => {
  const port = sender.tab && ports.get(sender.tab.id)
  if (port) {
    port.postMessage(message)
  }
})

chrome.tabs.onRemoved.addListener(tabId => {
  ports.delete(tabId)
})

chrome.tabs.onReplaced.addListener((newTabId, oldTabId) => {
  ports.delete(oldTabId)
})

// Add Cmd + Shift + A listener
chrome.commands.onCommand.addListener(() => {
  chrome.windows.getCurrent(window => {
    chrome.tabs.getAllInWindow(window.id, tabs => {
      tabs.forEach(tab => {
        if (tab.active) {
          ports.get(tab.id).postMessage({ actionType: EVENTS.TOGGLE_PALETTE })
        }
      })
    })
  })
})
