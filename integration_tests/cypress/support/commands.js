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
  cy.visitSurveda(`/`)
})

Cypress.Commands.add('visitSurveda', (url) => {
  cy.visit(Cypress.env('host') + url)
})

Cypress.Commands.add('clickMainAction', (title) => {
  // TODO: Add better selector
  cy.get(`main a.mtop[data-tooltip=${JSON.stringify(title)}]`).click();
})

Cypress.Commands.add('clickTitleMenu', (title) => {
  cy.get('#MainNav').within(() => {
    // TODO: Add better selector
    cy.get(".title-options > a").click()
  })
})
