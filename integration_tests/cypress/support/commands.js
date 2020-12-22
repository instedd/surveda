// ***********************************************
// This example commands.js shows you how to
// create various custom commands and overwrite
// existing commands.
//
// For more comprehensive examples of custom
// commands please read more here:
// https://on.cypress.io/custom-commands
// ***********************************************
//
//
// -- This is a parent command --
// Cypress.Commands.add("login", (email, password) => { ... })
//
//
// -- This is a child command --
// Cypress.Commands.add("drag", { prevSubject: 'element'}, (subject, options) => { ... })
//
//
// -- This is a dual command --
// Cypress.Commands.add("dismiss", { prevSubject: 'optional'}, (subject, options) => { ... })
//
//
// -- This will overwrite an existing command --
// Cypress.Commands.overwrite("visit", (originalFn, url, options) => { ... })

import 'cypress-file-upload'
import Route from 'route-parser'

Cypress.Commands.add('loginGuisso', (email, pwd) => {
  cy.visit(Cypress.env('guisso_host'))

  cy.get('.fieldset')
    .find('input[name="user[email]"]')
    .invoke('attr', 'value', email)
    .should('have.value', email)

  cy.get('.fieldset')
    .find('input[name="user[password]"]')
    .invoke('attr', 'value', pwd)
    .should('have.value', pwd)

  cy.contains('Log in').click()

  // go to root to force the login cookie in Surveda's side.
  // Otherwise, next visit will cause a redirect.
  cy.visit(`/`)
})

Cypress.Commands.add('clickMainAction', (title) => {
  // TODO: Add better selector.
  //      Add questionnaire                                   Add survey
  //                 v--- no i                                            v--- an i element
  cy.get(`main a.mtop[data-tooltip=${JSON.stringify(title)}], main a.mtop i[data-tooltip=${JSON.stringify(title)}]`).click();
})

Cypress.Commands.add('clickMainActionOption', (title) => {
  cy.get(`main button.mbottom i[data-tooltip=${JSON.stringify(title)}]`).click();
})

Cypress.Commands.add('clickTitleMenu', (title) => {
  cy.get('#MainNav').within(() => {
    // TODO: Add better selector
    cy.get(".title-options > a").click()
  })
})

Cypress.Commands.add('deleteProjectQuestionnaires', (projectId) => {
  cy.request(`/api/v1/projects/${projectId}/questionnaires?archived=false`)
    .then((response) => {
      for (const q of response.body.data) {
        cy.request('DELETE', `/api/v1/projects/${projectId}/questionnaires/${q.id}`)
      }
    })
})

Cypress.Commands.add('waitForUrl', (pattern) => {
  let route = new Route(pattern)

  return cy.location('pathname').should(pathname => {
    let match = route.match(pathname)
    expect(match).to.be.an('object')
    return match
  }).then(pathname => {
    let match = route.match(pathname)
    return match
  })
})

Cypress.Commands.add('surveyRespondents', (projectId, surveyId) => {
  // TODO watch out for pagination
  const respondentsWithState = (state) => {
    cy.request({
      url: `/api/v1/projects/${projectId}/surveys/${surveyId}/respondents`,
      qs: { q: `state:${state}` }
    }).then((response) => {
      const respondents = response.body.data.respondents
      return respondents.map(r => ({ ...r, state: state }))
    })
  }
  const states = ['pending', 'active', 'completed', 'failed', 'rejected', 'cancelled']
  Promise.all(states.map(respondentsWithState)).then(result => [...result])
})
