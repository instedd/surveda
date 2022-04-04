import Raven from "raven-js"
import { config } from "./config"
import { Unauthorized } from "./api"
import * as routes from "./routes"
import React from "react"
import { render } from "react-dom"
import { showError } from "components/ui"

if (typeof config != "undefined") {
  Raven.config(config.sentryDsn, { release: config.version }).install()
  Raven.setUserContext({ email: config.user })
}

window.addEventListener("unhandledrejection", (e) => {
  e.preventDefault()
  console.log(e)

  if (e.reason instanceof Unauthorized) {
    window.location = routes.root
    // Ignore unauthorized errors
    return
  }

  if (e.reason instanceof Error) {
    Raven.captureException(e.reason)
    onError(e.reason)
  } else {
    Raven.captureMessage("Unhandled promise rejection", {
      extra: { reason: e.reason },
    })
    onError(new Error("Unhandled promise rejection"))
  }
})

window.addEventListener("error", (e) => {
  e.preventDefault()
  console.log(e)
  onError(e.error)
})

const onError = (error) => {
  const errorId = Raven.lastEventId()

  const onDetails = (e) => {
    e.preventDefault()
    $(".error-toast").remove()
    showError(errorId, error)
  }

  const onReload = (e) => {
    e.preventDefault()
    window.location.href = "/"
  }

  const message = (
    <div style={{ width: "500px" }}>
      Something went wrong
      <a className="btn-flat red-text" onClick={onDetails}>
        DETAILS
      </a>
      <a className="btn-flat red-text" onClick={onReload}>
        RELOAD
      </a>
    </div>
  )

  const messageDom = document.createElement("div")
  render(message, messageDom)
  window.Materialize.toast(messageDom, null, "error-toast")
}
