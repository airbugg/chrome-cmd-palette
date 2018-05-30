export const actionFactory = chrome => ({
  getAllTabs () {
    return new Promise((resolve, reject) => {
      chrome.tabs.query({}, tabs =>
        resolve(
          tabs.map(({ id, title, favIconUrl }) => ({
            id,
            title,
            favIconUrl: favIconUrl || ''
          }))
        )
      )
    })
  },
  navigateToTab (tabId) {
    chrome.tabs.update(tabId, { active: true })
  }
})
