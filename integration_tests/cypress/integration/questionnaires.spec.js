/// <reference types="Cypress" />

describe('questionnaires', () => {
  beforeEach(() => {
    cy.loginGuisso(Cypress.env('email'), Cypress.env('password'))
    cy.deleteProjectQuestionnaires(Cypress.env('project_id'))
  })

  it('can be created by importing questionnaire', () => {
    const projectId = Cypress.env('project_id')
    cy.visitSurveda(`/projects/${projectId}/questionnaires`)
    cy.clickMainAction('Add questionnaire')

    cy.waitForUrl(`/projects/:projectId/questionnaires/:questionnaireId/edit`).then(r => {
      const { questionnaireId } = r

      cy.clickTitleMenu()
      cy.contains('Import questionnaire').click()
      cy.get('input[type="file"]').attachFile('2118.zip');

      // TODO add assertion
    })
  })
})
