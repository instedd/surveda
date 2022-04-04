// @flow
import React, { Component } from "react"
import { translate } from "react-i18next"

type MobileWebWindowProps = {
  indexUrl: string,
  t: Function,
}

class MobileWebWindow extends Component<MobileWebWindowProps> {
  render() {
    const { indexUrl, t } = this.props

    return (
      <div className="mobile-web-iframe-container">
        <div className="chat-header">
          <div className="title">{t("Mobileweb mode")}</div>
        </div>
        <iframe src={indexUrl} className={"mobile-web"} />
      </div>
    )
  }
}

export default translate()(MobileWebWindow)
