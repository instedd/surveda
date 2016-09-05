import { normalize, Schema, arrayOf } from 'normalizr'
import { camelizeKeys } from 'humps'
import 'isomorphic-fetch'

const projectSchema = new Schema('projects');
const surveySchema = new Schema('surveys');
const userSchema = new Schema('users');
const questionnaireSchema = new Schema('questionnaires');

projectSchema.define({
  owner: userSchema
});

surveySchema.define({

});

questionnaireSchema.define({

});

const apiFetch = (url, options) => {
  return fetch(url, {...options, credentials: 'same-origin'})
    .then(response => {
      if (!response.ok && response.status == 403) {
        window.location = "/login"
        return Promise.reject(response.statusText)
      } else {
        return response
      }
    })
}

export const fetchProjects = () => {
  return apiFetch(`/api/v1/projects`)
    .then(response =>
      response.json().then(json => ({ json, response }))
    ).then(({ json, response }) => {
      if (!response.ok) {
        return Promise.reject(json)
      }

    return normalize(camelizeKeys(json.data), arrayOf(projectSchema))
  })
}

export const fetchSurveys = (project_id) => {
  return apiFetch(`/api/v1/projects/${project_id}/surveys`)
    .then(response =>
      response.json().then(json => ({ json, response }))
    ).then(({ json, response }) => {
      if (!response.ok) {
        return Promise.reject(json)
      }

    return normalize(camelizeKeys(json.data), arrayOf(surveySchema))
  })
}

export const fetchQuestionnaires = (project_id) => {
  return apiFetch(`/api/v1/projects/${project_id}/questionnaires`)
    .then(response =>
      response.json().then(json => ({ json, response }))
    ).then(({ json, response }) => {
      if (!response.ok) {
        return Promise.reject(json)
      }

    return normalize(camelizeKeys(json.data), arrayOf(questionnaireSchema))
  })
}

export const fetchProject = (id) => {
  return apiFetch(`/api/v1/projects/${id}`)
    .then(response =>
      response.json().then(json => ({ json, response }))
    ).then(({ json, response }) => {
      if (!response.ok) {
        return Promise.reject(json)
      }

    return normalize(camelizeKeys(json.data), projectSchema)
  })
}

export const fetchSurvey = (project_id, id) => {
  return apiFetch(`/api/v1/projects/${project_id}/surveys/${id}`)
    .then(response =>
      response.json().then(json => ({ json, response }))
    ).then(({ json, response }) => {
      if (!response.ok) {
        return Promise.reject(json)
      }

    return normalize(camelizeKeys(json.data), surveySchema)
  })
}

export const createProject = (project) => {
  return apiFetch('/api/v1/projects', {
    method: 'POST',
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      project: project
    })
  })
  .then(response =>
    response.json().then(json => ({ json, response }))
  ).then(({ json, response }) => {
    if (!response.ok) {
      return Promise.reject(json)
    }
    return normalize(camelizeKeys(json.data), projectSchema)
  })
}

export const createSurvey = (project_id) => {
  return apiFetch(`/api/v1/projects/${project_id}/surveys`, {
    method: 'POST',
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json'
    }
  })
  .then(response =>
    response.json().then(json => ({ json, response }))
  ).then(({ json, response }) => {
    if (!response.ok) {
      return Promise.reject(json)
    }
    return normalize(camelizeKeys(json.data), surveySchema)
  })
}

export const updateProject = (project) => {
  return apiFetch(`/api/v1/projects/${project.id}`, {
    method: 'PUT',
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      project: project
    })
  })
  .then(response =>
    response.json().then(json => ({ json, response }))
  ).then(({ json, response }) => {
    if (!response.ok) {
      return Promise.reject(json)
    }
    return normalize(camelizeKeys(json.data), projectSchema)
  })
}

export const updateSurvey = (project_id, survey) => {
  return apiFetch(`/api/v1/projects/${project_id}/surveys/${survey.id}`, {
    method: 'PUT',
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      survey: survey
    })
  })
  .then(response =>
    response.json().then(json => ({ json, response }))
  ).then(({ json, response }) => {
    if (!response.ok) {
      return Promise.reject(json)
    }
    return normalize(camelizeKeys(json.data), surveySchema)
  })
}
