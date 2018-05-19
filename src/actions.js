export const actionFactory = chrome => ({
  getAllTabs () {
    return new Promise((resolve, reject) => {
      chrome.tabs.query({}, tabs =>
        resolve(
          tabs.map(({ title, favIconUrl }, id) => ({
            id,
            title,
            favIconUrl: favIconUrl || ''
          }))
        )
      )
    })
  }
})
