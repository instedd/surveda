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

function validRespondentStateDisposition(respondent) {
  const validStateDisposition = [
    { disposition: 'contacted', state: 'active' },
    { disposition: 'interim partial', state: 'active' },
    { disposition: 'queued', state: 'active' },
    { disposition: 'started', state: 'active' },
    { disposition: 'breakoff', state: 'cancelled' },
    { disposition: 'contacted', state: 'cancelled' },
    { disposition: 'failed', state: 'cancelled' },
    { disposition: 'inelegible', state: 'cancelled' },
    { disposition: 'interim partial', state: 'cancelled' },
    { disposition: 'queued', state: 'cancelled' },
    { disposition: 'refused', state: 'cancelled' },
    { disposition: 'started', state: 'cancelled' },
    { disposition: 'unresponsive', state: 'cancelled' },
    { disposition: 'completed', state: 'completed' },
    { disposition: 'ineligible', state: 'completed' },
    { disposition: 'partial', state: 'completed' },
    { disposition: 'refused', state: 'completed' },
    { disposition: 'rejected', state: 'completed' },
    { disposition: 'breakoff', state: 'failed' }, 
    { disposition: 'failed', state: 'failed' }, 
    { disposition: 'unresponsive', state: 'failed' }, 
    { disposition: 'registered', state: 'pending' }, 
    { disposition: 'rejected', state: 'rejected' },
  ]
  return !!validStateDisposition.find(x => x.disposition == respondent.disposition && x.state == respondent.state)
}

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

Cypress.Commands.add('setUpSurvey', (respondentsSample) => {
  const projectId = Cypress.env('project_id')
  const smsChannelId = Cypress.env('sms_channel_id')

  cy.visit(`/projects/${projectId}/surveys`)
  cy.clickMainAction('Add')
  cy.clickMainActionOption('Survey')

  cy.waitForUrl(`/projects/:projectId/surveys/:surveyId/edit`).then(r => {
    const { surveyId } = r

    // Set up questionnaire
    cy.contains('Select a questionnaire').click()
    cy.get("#questionnaire").within(() => {
      //TODO get title from the imported questionnaire
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
    cy.get("#respondents").within(() => {
      cy.get('input[type="file"]').attachFile(respondentsSample)
      cy.get('input.select-dropdown + * + select').select(smsChannelId, { force: true })
    })

    // Set up schedule
    cy.contains('Setup a schedule').click()
    cy.get("#schedule").within(() => {
      cy.get(':nth-child(3) > :nth-child(2) > .select-wrapper > input.select-dropdown')
        .click()
      cy.get('select').last().select('23:00:00', { force: true })
      cy.get(':nth-child(2) > .btn-floating').click()
      cy.get(':nth-child(3) > .btn-floating').click()
      cy.get(':nth-child(4) > .btn-floating').click()
      cy.get(':nth-child(5) > .btn-floating').click()
      cy.get(':nth-child(6) > .btn-floating').click()
    })

    // Define quotas
    cy.contains('Setup cutoff rules').click()
    cy.get("#cutoff").within(() => {
      cy.get('.quotas > :nth-child(1) > label').click()
      cy.get(':nth-child(1) > .col > .right > label').click()
      cy.contains('Done').click()
      cy.get(':nth-child(1) > :nth-child(4) > .col > div > input')
        .clear()
        .type('70')
    })

    // Launch survey
    cy.clickMainAction('Launch survey')

    // Assert started status
    cy.get(".cockpit").within(() => {
      cy.get('.survey-status-container').should('contain', 'Started')
    })

    return cy.wrap(surveyId);
  })
})

Cypress.Commands.add('prepareSurvey', (questionnaireTemplate, respondentsSample) => {
  cy.importQuestionnaire(questionnaireTemplate)

  cy.setUpSurvey(respondentsSample)
})

Cypress.Commands.add('importQuestionnaire', (questionnaireTemplate) => {
  const projectId = Cypress.env('project_id')
  cy.visit(`/projects/${projectId}/questionnaires`)
  cy.clickMainAction('Add questionnaire')

  cy.waitForUrl(`/projects/:projectId/questionnaires/:questionnaireId/edit`).then(r => {
    const { questionnaireId } = r

    cy.clickTitleMenu()
    cy.contains('Import questionnaire').click()
    cy.get('input[type="file"]').attachFile(questionnaireTemplate);
  })
})

Cypress.Commands.add('waitUntilStale', (projectId, surveyId, timeout) => {
  var YMinutesLater = new Date();
  var timeOutMinutes = timeout
  YMinutesLater.setMinutes(YMinutesLater.getMinutes() + timeOutMinutes);
  let _try = () => {
    cy.request({
      url: `/api/v1/projects/${projectId}/surveys/${surveyId}`
    }).then((response) => {
      const surveyState = response.body.data.state
      // check if survey has terminated if Y minutes haven't passed
      if (new Date() < YMinutesLater) {
        // check state after 20 seconds
        if (surveyState == 'running') {
          cy.wait(20000).then(() => {
            _try()
          })
        }
      }
      else {
        assert.isOk(false, `After ${timeOutMinutes} minutes the survey didn't finish`)
      }
    })
  }
  _try()
})
