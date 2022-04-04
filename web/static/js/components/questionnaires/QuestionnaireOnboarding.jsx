import React, { PropTypes, Component } from "react"
import { translate } from "react-i18next"

class QuestionnaireOnboarding extends Component {
  static propTypes = {
    onDismiss: PropTypes.func,
    t: PropTypes.func,
  }

  componentDidMount() {
    $(".carousel.carousel-slider").carousel({
      fullWidth: true,
    })
  }

  render() {
    const { onDismiss, t } = this.props
    return (
      <div className="col s12 m5 offset-m2">
        <div className="carousel carousel-slider center" data-indicators="true">
          <div className="carousel-fixed-item center">
            <a className="btn btn-flat-link" onClick={() => onDismiss()}>
              {t("Understood, create the first step")}
            </a>
          </div>
          <div className="carousel-item grey-text" href="#one!">
            <div className="icons">
              <i className="material-icons large">flag</i>
            </div>
            <h2>{t("Multi-language questionnaires")}</h2>
            <p>
              {t(
                "When you add more than one language a step for language selection will be enabled and you'll be able to define every step in each of the selected languages."
              )}
            </p>
          </div>
          <div className="carousel-item grey-text" href="#two!">
            <div className="icons">
              <i className="material-icons large">textsms</i>
              <i className="material-icons large">phone</i>
            </div>
            <h2>{t("Questionnaire modes")}</h2>
            <p>
              {t(
                "When more than one mode is enabled you'll be able to set up messages and interactions at every step for each selected mode."
              )}
            </p>
          </div>
          <div className="carousel-item grey-text" href="#three!">
            <div className="icons">
              <i className="material-icons large">list</i>
              <i className="material-icons large">dialpad</i>
              <i className="material-icons large">chat_bubble_outline</i>
              <i className="material-icons large">call_split</i>
            </div>
            <h2>{t("Questionnaire steps")}</h2>
            <p>
              {t(
                "Questionnaires are organized in steps. Each step type offers different features like multiple choice, numeric input or just an explanation . The comparison steps allow A/B testing."
              )}
            </p>
          </div>
        </div>
      </div>
    )
  }
}

export default translate()(QuestionnaireOnboarding)
