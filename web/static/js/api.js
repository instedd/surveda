import { v4 } from 'node-uuid'

/**
 * Mocking client-server processing
 */

const delay = (ms) =>
  new Promise(resolve => setTimeout(resolve, ms))

const studies = [{id:v4(), name: 'foo'}, {id: v4(), name: 'bar'}]

export const fetchStudies = () => {
  return delay(500).then(() => {
    return studies
  })
}

export const createStudy = () => {
  return delay(500).then(() => {
    return {
      name: `nuevo!${v4().substring(0,4)}`,
      id: v4()
    }
  })
}
