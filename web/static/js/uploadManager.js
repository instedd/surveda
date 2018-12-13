// @flow
import uuidv4 from 'uuid/v4'

const k = (...args: any) => args
const uploads = {}
const DEFAULT_ERROR_DESCRIPTION = k('Questionnaire upload failed')

export const upload = (file: Object, url: string, onCompleted: ((response: Object) => mixed), onProgress: ((total: number, loaded: number) => mixed), onAbort: (() => mixed), onError: (description: ?string) => mixed) => {
  const formData = new FormData()
  formData.append('file', file)
  const xhr = new XMLHttpRequest()
  const uploadId = uuidv4()

  xhr.open('POST', url, true)

  xhr.onreadystatechange = function() {
    // readyState is compared with 4 instead of DONE because the latter is not supported by all the browsers, and it is not compatible with 'flow'.
    if (this.readyState === 4) {
      delete uploads[uploadId]
      if (this.status === 200) {
        onCompleted(this.response)
      } else if (this.status !== 0) {
        // Status is set to 0 when the request is cancelled, so we don't want to dispatch an error in this case
        onError(this.statusText || DEFAULT_ERROR_DESCRIPTION)
      }
    }
  }

  // onError contemplates the case when connection is lost
  xhr.onerror = function() {
    const defaultDescription = DEFAULT_ERROR_DESCRIPTION
    onError(this.statusText || defaultDescription)
  }

  xhr.upload.onprogress = function(progressEvent: Object) {
    if (progressEvent.lengthComputable) {
      onProgress(progressEvent.total, progressEvent.loaded)
    }
  }

  xhr.onabort = onAbort

  xhr.send(formData)
  Object.assign(uploads, {[uploadId]: xhr})
  return uploadId
}

export const cancel = (uploadId: number) => {
  if (uploads[uploadId]) {
    uploads[uploadId].abort()
  }
}
