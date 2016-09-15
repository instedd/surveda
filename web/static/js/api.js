import { normalize, Schema, arrayOf } from 'normalizr'
import { camelizeKeys } from 'humps'
import 'isomorphic-fetch'

const projectSchema = new Schema('projects');
const surveySchema = new Schema('surveys');
const userSchema = new Schema('users');
const questionnaireSchema = new Schema('questionnaires');
const respondentSchema = new Schema('respondents');
const channelSchema = new Schema('channels');

projectSchema.define({owner: userSchema});
surveySchema.define({});
questionnaireSchema.define({});
respondentSchema.define({});
channelSchema.define({})

const apiFetch = (url, options) => {
  return fetch(url, {...options, credentials: 'same-origin'})
    .then(response => {
      if (!response.ok && response.status == 401) {
        window.location = "/login"
        return Promise.reject(response.statusText)
      } else {
        return response
      }
    })
}

const apiFetchJSON = (url, schema, options) => {
  return apiFetch(url, options)
    .then(response =>
      response.json().then(json => ({ json, response }))
    ).then(({ json, response }) => {
      if (!response.ok) {
        return Promise.reject(json)
      }
      return normalize(camelizeKeys(json.data), schema)
    })
}

const apiPutOrPostJSON = (url, schema, verb, body) => {
  let options = {
    method: verb,
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json'
    }
  }
  if (body) {
    options.body = JSON.stringify(body)
  }
  return apiFetchJSON(url, schema, options)
}

const apiPostJSON = (url, schema, body) => {
  return apiPutOrPostJSON(url, schema, 'POST', body)
}

const apiPutJSON = (url, schema, body) => {
  return apiPutOrPostJSON(url, schema, 'PUT', body)
}

export const fetchProjects = () => {
  return apiFetchJSON(`/api/v1/projects`, arrayOf(projectSchema))
}

export const fetchSurveys = (projectId) => {
  return apiFetchJSON(`/api/v1/projects/${projectId}/surveys`, arrayOf(surveySchema))
}

export const fetchQuestionnaires = (projectId) => {
  return apiFetchJSON(`/api/v1/projects/${projectId}/questionnaires`, arrayOf(questionnaireSchema))
}

export const fetchQuestionnaire = (projectId, id) => {
  return apiFetchJSON(`/api/v1/projects/${projectId}/questionnaires/${id}`, questionnaireSchema)
}

export const fetchProject = (id) => {
  return apiFetchJSON(`/api/v1/projects/${id}`, projectSchema)
}

export const fetchSurvey = (projectId, id) => {
  return apiFetchJSON(`/api/v1/projects/${projectId}/surveys/${id}`, surveySchema)
}

export const createProject = (project) => {
  return apiPostJSON('/api/v1/projects', projectSchema, {project})
}

export const createSurvey = (projectId) => {
  return apiPostJSON(`/api/v1/projects/${projectId}/surveys`, surveySchema)
}

export const uploadRespondents = (survey, files) => {
  const formData = new FormData();
  formData.append('file', files[0]);

  return apiFetchJSON(`/api/v1/projects/${survey.projectId}/surveys/${survey.id}/respondents`,
    arrayOf(respondentSchema), {
    method: 'POST',
    body: formData
  })
}

export const fetchRespondents = (projectId, surveyId) => {
  return apiFetchJSON(`/api/v1/projects/${projectId}/surveys/${surveyId}/respondents`, arrayOf(respondentSchema))
}

export const createQuestionnaire = (projectId, questionnaire) => {
  return apiPostJSON(`/api/v1/projects/${projectId}/questionnaires`, questionnaireSchema, {questionnaire})
}

export const updateProject = (project) => {
  return apiPutJSON(`/api/v1/projects/${project.id}`, projectSchema, {project})
}

export const updateSurvey = (projectId, survey) => {
  return apiPutJSON(`/api/v1/projects/${projectId}/surveys/${survey.id}`, surveySchema, {survey})
}

export const fetchChannels = () => {
  return apiFetchJSON(`/api/v1/channels`, arrayOf(channelSchema))
}

export const createChannel = (channel) => {
  return apiPostJSON('/api/v1/channels', channelSchema, {channel})
}

export const updateQuestionnaire = (projectId, questionnaire) => {
  return apiPutJSON(`/api/v1/projects/${projectId}/questionnaires/${questionnaire.id}`,
    questionnaireSchema, {questionnaire})
}

export const launchSurvey = (projectId, surveyId) => {
  return apiPostJSON(`/api/v1/projects/${projectId}/surveys/${surveyId}/launch`, surveySchema)
}
