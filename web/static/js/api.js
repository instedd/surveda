import { v4 } from 'node-uuid'
import { camelizeKeys } from 'humps'
import 'isomorphic-fetch'

/**
 * Mocking client-server processing
 */

const delay = (ms) =>
  new Promise(resolve => setTimeout(resolve, ms))

// const studies = [{id:v4(), name: 'foo'}, {id: v4(), name: 'bar'}]

export const fetchStudies = () => {
  return fetch('http://localhost:4000/api/v1/studies')
    .then(response =>
      response.json().then(json => ({ json, response }))
    ).then(({ json, response }) => {
      if (!response.ok) {
        return Promise.reject(json)
      }

    return camelizeKeys(json.data)
  })
}

export const createStudy = () => {
  return fetch('http://localhost:4000/api/v1/studies', {
    method: 'POST',
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      study: {
        name: `nuevo!${v4().substring(0,4)}`,
      }
    })
  })
  .then(response =>
    response.json().then(json => ({ json, response }))
  ).then(({ json, response }) => {
    if (!response.ok) {
      return Promise.reject(json)
    }
    return json.data
  })
}
