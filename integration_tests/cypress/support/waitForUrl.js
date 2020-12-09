import Route from 'route-parser'

export function waitForUrl(pattern) {
  let route = new Route(`${Cypress.env('host')}${pattern}`)
  return new Cypress.Promise((resolve, reject) => {
    let _try = (retries) => {
      if (retries > 0) {
        cy.url().then(url => {
          let match = route.match(url)

          if (match != false) {
            resolve(match)
          } else {
            cy.wait(500).then(() => {
              _try(retries - 1)
            })
          }
        })
      } else {
        assert.isOk(false, `Unable to reach url matching: ${pattern}`)
        reject()
      }
    }

    _try(3)
  })
}
