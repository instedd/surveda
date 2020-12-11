/// <reference types="Cypress" />

describe('surveys', () => {
  beforeEach(() => {
    cy.loginGuisso(Cypress.env('email'), Cypress.env('password'))

    // Create "Cipoletti 1" questionnaire
    const projectId = Cypress.env('project_id')
    cy.deleteProjectQuestionnaires(projectId)
    cy.visitSurveda(`/projects/${projectId}/questionnaires`)
    cy.clickMainAction('Add questionnaire')
    cy.waitForUrl(`/projects/:projectId/questionnaires/:questionnaireId/edit`).then(r => {
      const { questionnaireId } = r
      cy.clickTitleMenu()
      cy.contains('Import questionnaire').click()
      cy.get('input[type="file"]').attachFile('2118.zip');
    })
  })

  it('can be created with existing questionnaire', () => {
    const projectId = Cypress.env('project_id')

    cy.visitSurveda(`/projects/${projectId}/surveys`)
    cy.clickMainAction('Add')
    cy.clickMainActionOption('Survey')

    cy.waitForUrl(`/projects/:projectId/surveys/:surveyId/edit`).then(r => {
      const { surveyId } = r

      // Set up questionnaire
      cy.contains('Select a questionnaire').click()
      cy.get("#questionnaire").within(() => {
        cy.contains('Cipoletti 1').click()
      })

      // Set up mode
      cy.contains('Select mode').click()
      cy.get("#channels").within(() => {
        cy.get('.card-action > .row > :nth-child(1) > .select-wrapper > input.select-dropdown').click({ force: true })
        cy.contains('SMS').click({ force: true })
      })

      // Upload respondents
      cy.contains('Upload your respondents list').click()
      cy.get('input[type="file"]').attachFile('respondents_sample.csv')

    })
  })
})
