import { normalize, Schema, arrayOf } from 'normalizr'
import { camelizeKeys } from 'humps'
import 'isomorphic-fetch'

const projectSchema = new Schema('projects');
const surveySchema = new Schema('surveys');
const userSchema = new Schema('users');

projectSchema.define({
  owner: userSchema
});

surveySchema.define({

});

export const fetchProjects = () => {
  return fetch('/api/v1/projects')
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
  return fetch(`/api/v1/projects/${project_id}/surveys`)
    .then(response =>
      response.json().then(json => ({ json, response }))
    ).then(({ json, response }) => {
      if (!response.ok) {
        return Promise.reject(json)
      }

    return normalize(camelizeKeys(json.data), arrayOf(surveySchema))
  })
}

export const fetchProject = (id) => {
  return fetch(`/api/v1/projects/${id}`)
    .then(response =>
      response.json().then(json => ({ json, response }))
    ).then(({ json, response }) => {
      if (!response.ok) {
        return Promise.reject(json)
      }

    return normalize(camelizeKeys(json.data), projectSchema)
  })
}

export const createProject = (project) => {
  return fetch('/api/v1/projects', {
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

export const updateProject = (project) => {
  return fetch(`/api/v1/projects/${project.id}`, {
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
