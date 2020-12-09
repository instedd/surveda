/// <reference types="Cypress" />

describe('projects', () => {
  beforeEach(() => {
    cy.loginGuisso(Cypress.env('email'), Cypress.env('password'))
  })

  it('show surveys by default', () => {
    const projectId = Cypress.env('project_id')
    cy.visitSurveda(`/projects/${projectId}`)

    cy.url().should('include', `/projects/${projectId}/surveys`)
  })
})
