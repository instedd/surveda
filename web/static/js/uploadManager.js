// @flow
import random from 'lodash/random'

const uploads = {}

export const upload = (file: Object, url: string, onCompleted: ((response: Object) => mixed), onProgress: ((total: number, loaded: number) => mixed), onAbort: (() => mixed), onError: (description: ?string) => mixed) => {
  const formData = new FormData()
  formData.append('file', file)
  const xhr = new XMLHttpRequest()
  const uploadId = random(100)

  xhr.open('POST', url, true)

  xhr.onreadystatechange = function() {
    // state XMLHttpRequest.DONE == 4
    if (this.readyState === 4 && this.status === 200) {
      delete uploads[uploadId]
      onCompleted(this.response)
    } else if (this.status !== 200 && this.status !== 0) {
      // Status is set to 0 when the request is cancelled.
      // This is triggered, for example, when status changes to 400.
      onError(this.statusText)
    }
  }

  // onError contemplates the case when connection is lost
  xhr.onerror = function() {
    const defaultDescription = 'Questionnaire upload failed'
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
    delete uploads[uploadId]
  }
}
