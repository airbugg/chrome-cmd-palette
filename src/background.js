import { EVENTS } from './events'

// Add Cmd + Shift + A listener
chrome.commands.onCommand.addListener(() => {
  chrome.tabs.query({ active: true, currentWindow: true }, function (tabs) {
    chrome.tabs.sendMessage(tabs[0].id, { actionType: EVENTS.TOGGLE_PALETTE })
  })
})

// const getAllTabs = pify(chrome.tabs.query, { errorFirst: false })

const getAllTabs = () =>
  new Promise((resolve, reject) => {
    chrome.tabs.query({}, tabs => resolve(tabs.map(({ title }) => title)))
  })

setTimeout(() => {
  chrome.tabs.query({ active: true, currentWindow: true }, function (tabs) {
    getAllTabs().then(allTabs =>
      chrome.tabs.sendMessage(tabs[0].id, {
        actionType: EVENTS.GET_TABS,
        payload: allTabs
      })
    )
  })
}, 10000)
