import { normalize, Schema, arrayOf } from 'normalizr'
import { camelizeKeys } from 'humps'
import 'isomorphic-fetch'

const studySchema = new Schema('studies');
const userSchema = new Schema('users');

studySchema.define({
  owner: userSchema
});

export const fetchStudies = () => {
  return fetch('/api/v1/studies')
    .then(response =>
      response.json().then(json => ({ json, response }))
    ).then(({ json, response }) => {
      if (!response.ok) {
        return Promise.reject(json)
      }

    return normalize(camelizeKeys(json.data), arrayOf(studySchema))
  })
}

export const fetchStudy = (id) => {
  return fetch(`/api/v1/studies/${id}`)
    .then(response =>
      response.json().then(json => ({ json, response }))
    ).then(({ json, response }) => {
      if (!response.ok) {
        return Promise.reject(json)
      }

    return normalize(camelizeKeys(json.data), studySchema)
  })
}

export const createStudy = (study) => {
  return fetch('/api/v1/studies', {
    method: 'POST',
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      study: study
    })
  })
  .then(response =>
    response.json().then(json => ({ json, response }))
  ).then(({ json, response }) => {
    if (!response.ok) {
      return Promise.reject(json)
    }
    return normalize(camelizeKeys(json.data), studySchema)
  })
}
