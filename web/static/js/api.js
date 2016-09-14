import { normalize, Schema, arrayOf } from 'normalizr'
import { camelizeKeys } from 'humps'
import 'isomorphic-fetch'

const projectSchema = new Schema('projects');
const surveySchema = new Schema('surveys');
const userSchema = new Schema('users');
const questionnaireSchema = new Schema('questionnaires');
const respondentSchema = new Schema('respondents');
const channelSchema = new Schema('channels');

projectSchema.define({
  owner: userSchema
});

surveySchema.define({

});

questionnaireSchema.define({

});

respondentSchema.define({

});

channelSchema.define({
})

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

export const fetchSurveys = (projectId) => {
  return apiFetch(`/api/v1/projects/${projectId}/surveys`)
    .then(response =>
      response.json().then(json => ({ json, response }))
    ).then(({ json, response }) => {
      if (!response.ok) {
        return Promise.reject(json)
      }

    return normalize(camelizeKeys(json.data), arrayOf(surveySchema))
  })
}

export const fetchQuestionnaires = (projectId) => {
  return apiFetch(`/api/v1/projects/${projectId}/questionnaires`)
    .then(response =>
      response.json().then(json => ({ json, response }))
    ).then(({ json, response }) => {
      if (!response.ok) {
        return Promise.reject(json)
      }

    return normalize(camelizeKeys(json.data), arrayOf(questionnaireSchema))
  })
}

export const fetchQuestionnaire = (projectId, id) => {
  return apiFetch(`/api/v1/projects/${projectId}/questionnaires/${id}`)
    .then(response =>
      response.json().then(json => ({ json, response }))
    ).then(({ json, response }) => {
      if (!response.ok) {
        return Promise.reject(json)
      }

    return normalize(camelizeKeys(json.data), questionnaireSchema)
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

export const fetchSurvey = (projectId, id) => {
  return apiFetch(`/api/v1/projects/${projectId}/surveys/${id}`)
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

export const createSurvey = (projectId) => {
  return apiFetch(`/api/v1/projects/${projectId}/surveys`, {
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

export const uploadRespondents = (survey, files) => {
  const formData = new FormData();
  formData.append('file', files[0]);

  return apiFetch(`/api/v1/projects/${survey.projectId}/surveys/${survey.id}/respondents`, {
    method: 'POST',
    body: formData
  })
  .then(response =>
    response.json().then(json => ({ json, response }))
  ).then(({ json, response }) => {
    if (!response.ok) {
      return Promise.reject(json)
    }
    return normalize(camelizeKeys(json.data), arrayOf(respondentSchema))
  })
}

export const fetchRespondents = (projectId, surveyId) => {
  return apiFetch(`/api/v1/projects/${projectId}/surveys/${surveyId}/respondents`)
    .then(response =>
      response.json().then(json => ({ json, response }))
    ).then(({ json, response }) => {
      if (!response.ok) {
        return Promise.reject(json)
      }

    return normalize(camelizeKeys(json.data), arrayOf(respondentSchema))
  })
}

export const createQuestionnaire = (projectId, questionnaire) => {
  return apiFetch(`/api/v1/projects/${projectId}/questionnaires`, {
    method: 'POST',
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      questionnaire: questionnaire
    })
  })
  .then(response =>
    response.json().then(json => ({ json, response }))
  ).then(({ json, response }) => {
    if (!response.ok) {
      return Promise.reject(json)
    }
    return normalize(camelizeKeys(json.data), questionnaireSchema)
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

export const updateSurvey = (projectId, survey) => {
  return apiFetch(`/api/v1/projects/${projectId}/surveys/${survey.id}`, {
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

export const fetchChannels = () => {
  return apiFetch(`/api/v1/channels`)
    .then(response =>
      response.json().then(json => ({ json, response }))
    ).then(({ json, response }) => {
      if (!response.ok) {
        return Promise.reject(json)
      }

    return normalize(camelizeKeys(json.data), arrayOf(channelSchema))
  })
}

export const createChannel = (channel) => {
  return apiFetch('/api/v1/channels', {
    method: 'POST',
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      channel: channel
    })
  })
  .then(response =>
    response.json().then(json => ({ json, response }))
  ).then(({ json, response }) => {
    if (!response.ok) {
      return Promise.reject(json)
    }
    return normalize(camelizeKeys(json.data), channelSchema)
  })
}


export const updateQuestionnaire = (projectId, questionnaire) => {
  return apiFetch(`/api/v1/projects/${projectId}/questionnaires/${questionnaire.id}`, {
    method: 'PUT',
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      questionnaire: questionnaire
    })
  })
  .then(response =>
    response.json().then(json => ({ json, response }))
  ).then(({ json, response }) => {
    if (!response.ok) {
      return Promise.reject(json)
    }
    return normalize(camelizeKeys(json.data), questionnaireSchema)
  })
}

export const launchSurvey = (projectId, surveyId) => {
  return apiFetch(`/api/v1/projects/${projectId}/surveys/${surveyId}/launch`, {
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
