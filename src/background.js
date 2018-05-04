import { EVENTS } from './events'
import pify from 'pify'

// Add Cmd + Shift + A listener
chrome.commands.onCommand.addListener(() => {
  chrome.tabs.query({ active: true, currentWindow: true }, function (tabs) {
    chrome.tabs.sendMessage(tabs[0].id, { kind: EVENTS.TOGGLE_PALETTE })
  })
})

const getAllTabs = pify(chrome.tabs.query, { errorFirst: false })

getAllTabs({})
  .then(console.log)
  .catch(console.error)
