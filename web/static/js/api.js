import { normalize, Schema, arrayOf } from 'normalizr'
import { camelizeKeys, decamelizeKeys } from 'humps'
import 'isomorphic-fetch'

const projectSchema = new Schema('projects')
const surveySchema = new Schema('surveys')
const questionnaireSchema = new Schema('questionnaires')
const respondentSchema = new Schema('respondents')
const responseSchema = new Schema('response')
const respondentsStatsSchema = new Schema('respondents')
const channelSchema = new Schema('channels')

surveySchema.define({
  channels: arrayOf(channelSchema)
})

responseSchema.define({
  channels: arrayOf(responseSchema)
})

const apiFetch = (url, options) => {
  return fetch(`/api/v1/${url}`, { ...options, credentials: 'same-origin' })
    .then(response => {
      if (!response.ok && response.status == 401) {
        window.location = '/login'
        return Promise.reject(response.statusText)
      } else {
        return response
      }
    })
}

const apiFetchJSON = (url, schema, options) => {
  return apiFetch(url, options)
    .then(response => response.json().then(json => ({ json, response }))
  ).then(({ json, response }) => {
    if (!response.ok) {
      return Promise.reject(json)
    }
    return normalize(camelizeKeys(json.data), schema)
  })
}

const apiPutOrPostJSON = (url, schema, verb, body) => {
  const options = {
    method: verb,
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json'
    }
  }
  if (body) {
    options.body = JSON.stringify(decamelizeKeys(body, { separator: '_' }))
  }
  return apiFetchJSON(url, schema, options)
}

const apiPostJSON = (url, schema, body) => {
  return apiPutOrPostJSON(url, schema, 'POST', body)
}

const apiPutJSON = (url, schema, body) => {
  return apiPutOrPostJSON(url, schema, 'PUT', body)
}

const apiDelete = (url, schema) => {
  return apiPutOrPostJSON(url, schema, 'DELETE', null)
}

export const fetchProjects = () => {
  return apiFetchJSON(`projects`, arrayOf(projectSchema))
}

export const fetchSurveys = (projectId) => {
  return apiFetchJSON(`projects/${projectId}/surveys`, arrayOf(surveySchema))
}

export const fetchQuestionnaires = (projectId) => {
  return apiFetchJSON(`projects/${projectId}/questionnaires`, arrayOf(questionnaireSchema))
}

export const fetchQuestionnaire = (projectId, id) => {
  return apiFetchJSON(`projects/${projectId}/questionnaires/${id}`, questionnaireSchema)
}

export const fetchProject = (id) => {
  return apiFetchJSON(`projects/${id}`, projectSchema)
}

export const fetchSurvey = (projectId, id) => {
  return apiFetchJSON(`projects/${projectId}/surveys/${id}`, surveySchema)
}

export const createProject = (project) => {
  return apiPostJSON('projects', projectSchema, { project })
}

export const createSurvey = (projectId) => {
  return apiPostJSON(`projects/${projectId}/surveys`, surveySchema)
}

export const uploadRespondents = (survey, files) => {
  const formData = new FormData()
  formData.append('file', files[0])

  return apiFetchJSON(`projects/${survey.projectId}/surveys/${survey.id}/respondents`,
    arrayOf(respondentSchema), {
      method: 'POST',
      body: formData
    })
}

export const removeRespondents = (survey) => {
  return apiDelete(`projects/${survey.projectId}/surveys/${survey.id}/respondents/-1`, respondentSchema)
}

export const fetchRespondents = (projectId, surveyId) => {
  return apiFetchJSON(`projects/${projectId}/surveys/${surveyId}/respondents`, arrayOf(respondentSchema))
}

export const fetchRespondentsStats = (projectId, surveyId) => {
  return apiFetchJSON(`projects/${projectId}/surveys/${surveyId}/respondents/stats`, arrayOf(respondentsStatsSchema))
}

export const createQuestionnaire = (projectId, questionnaire) => {
  return apiPostJSON(`projects/${projectId}/questionnaires`, questionnaireSchema, { questionnaire })
}

export const updateProject = (project) => {
  return apiPutJSON(`projects/${project.id}`, projectSchema, { project })
}

export const updateSurvey = (projectId, survey) => {
  return apiPutJSON(`projects/${projectId}/surveys/${survey.id}`, surveySchema, { survey })
}

export const fetchChannels = () => {
  return apiFetchJSON(`channels`, arrayOf(channelSchema))
}

export const createChannel = (channel) => {
  return apiPostJSON('channels', channelSchema, { channel })
}

export const updateQuestionnaire = (projectId, questionnaire) => {
  return apiPutJSON(`projects/${projectId}/questionnaires/${questionnaire.id}`,
    questionnaireSchema, { questionnaire })
}

export const launchSurvey = (projectId, surveyId) => {
  return apiPostJSON(`projects/${projectId}/surveys/${surveyId}/launch`, surveySchema)
}

export const logout = () => {
  fetch('/logout', {
    method: 'DELETE',
    credentials: 'same-origin'
  }).then(() => window.location.reload())
}
