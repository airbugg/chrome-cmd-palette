import { EVENTS } from './events'

// const getAllTabs = pify(chrome.tabs.query, { errorFirst: false })

const getAllTabs = () =>
  new Promise((resolve, reject) => {
    chrome.tabs.query({}, tabs =>
      resolve(
        tabs.map(({ title, favIconUrl }) => ({
          title,
          favIconUrl: favIconUrl || ''
        }))
      )
    )
  })

// chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
//   console.log('background script request received', request)
//   if (request.actionType === 'REQUEST_SUGGESTIONS') {
//     getAllTabs().then(allTabs =>
//       sendResponse({
//         actionType: EVENTS.GET_TABS,
//         payload: allTabs
//       })
//     )
//   }
//   // handle response async
//   return true
// })
let ports = new Set()

chrome.runtime.onConnect.addListener(newPort => {
  ports.add(newPort)
  console.log('background script onConnect.addListener', newPort)

  newPort.onMessage.addListener(request => {
    console.log('background script port.onMessage.addListener', request)

    if (request.actionType === 'REQUEST_SUGGESTIONS') {
      getAllTabs().then(allTabs =>
        newPort.postMessage({
          actionType: EVENTS.SUGGESTIONS_UPDATED,
          payload: allTabs
        })
      )
    }
  })
  newPort.onDisconnect.addListener(() => {
    ports.delete(newPort)
  })
})
// Add Cmd + Shift + A listener
chrome.commands.onCommand.addListener(() => {
  console.log('background script commands.onCommand.addListener', ports)

  ports.forEach(port => port.postMessage({ actionType: EVENTS.TOGGLE_PALETTE }))
})
// setTimeout(() => {
//   chrome.tabs.query({ active: true, currentWindow: true }, function (tabs) {
//     getAllTabs().then(allTabs =>
//       chrome.tabs.sendMessage(tabs[0].id, {
//         actionType: EVENTS.GET_TABS,
//         payload: allTabs
//       })
//     )
//   })
// }, 11000)
