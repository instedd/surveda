import React, { PropTypes } from "react"
import { translate } from "react-i18next"
import { ConfirmationModal } from "../ui"

export const ProviderModal = ({
  t,
  provider,
  index,
  friendlyName,
  multiple,
  onConfirm,
  loading,
  surveys,
}) => {
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
          {loading ? <span>{t("Searching active surveys...")}</span> :
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

ProviderModal.propTypes = {
  t: PropTypes.func,
  provider: PropTypes.string,
  index: PropTypes.number,
  friendlyName: PropTypes.string,
  multiple: PropTypes.bool,
  onConfirm: PropTypes.func,
  loading: PropTypes.bool,
  surveys: PropTypes.any
}

export default translate()(ProviderModal)
