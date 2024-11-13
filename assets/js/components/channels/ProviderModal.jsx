import React, { Component, PropTypes } from "react"
import { translate } from "react-i18next"
import * as api from "../../api"
import { ConfirmationModal } from "../ui"
import { config } from "../../config"

export class ProviderModal extends Component {
  constructor(props) {
    super(props)
    this.state = {
      loading: false,
      surveys: [],
    }
  }

  componentDidMount() {
    const { provider, index } = this.props
    const { baseUrl } = config[provider][index]
    this.setState({
      loading: true,
      surveys: [],
    })
    api.fetchActiveSurveys(provider, baseUrl)
    .then((response) => {
      const surveys = response || []
      this.setState({
        loading: false,
        surveys,
      })
    })
    .catch(() => {
      this.setState({
        loading: false,
        surveys: [],
      })
    })
  }

  render() {
    const {
      t,
      provider,
      index,
      friendlyName,
      multiple,
      onConfirm,
    } = this.props

    const { loading, surveys } = this.state

    let name = `${provider[0].toUpperCase()}${provider.slice(1)}`
    if (multiple) name = `${name} (${friendlyName})`

    return (
      <ConfirmationModal
        modalId={`${provider}Modal-${index}`}
        header={t("Turn off {{name}}", { name })}
        confirmationText={t("Yes")}
        onConfirm={onConfirm}
        style={{ maxWidth: "600px" }}
        showCancel
      >
        <div>
          <p>{t("Do you want to delete the channels provided by {{name}}?", { name })}</p>

          <div className="provider-surveys">
            {loading ? <span>{t("Loading surveys...")}</span> :
              surveys.length == 0 ? <span>{t("No active surveys")}</span> :
                <div>
                  <span>{t("Active surveys")}</span>
                  <ul>
                    {surveys.map((survey) => (
                      <li key={`survey-${survey.id}`}>
                        <span>{survey.name}</span>
                      </li>
                    ))}
                  </ul>
                </div>}
          </div>
        </div>
      </ConfirmationModal>
    )
  }
}

ProviderModal.propTypes = {
  t: PropTypes.func,
  provider: PropTypes.any,
  index: PropTypes.number,
  friendlyName: PropTypes.string,
  multiple: PropTypes.bool,
  onConfirm: PropTypes.func,
}

export default translate()(ProviderModal)
