import React, { PropTypes, Component } from "react"
import { connect } from "react-redux"
import * as actions from "../../actions/survey"
import { UntitledIfEmpty, PercentageInput } from "../ui"
import find from "lodash/find"
import { modeLabel } from "../../questionnaire.mode"
import { translate } from "react-i18next"

class SurveyWizardComparisonsStep extends Component {
  static propTypes = {
    t: PropTypes.func,
    survey: PropTypes.object.isRequired,
    questionnaires: PropTypes.object,
    dispatch: PropTypes.func.isRequired,
    readOnly: PropTypes.bool.isRequired,
  }

  constructor(props) {
    super(props)
    this.state = {
      buckets: {},
    }
    this.comparisonRatioChange = this.comparisonRatioChange.bind(this)
  }

  comparisonRatioChange(numbers, id) {
    const { dispatch, survey } = this.props
    const bucket = find(survey.comparisons, (bucket) => this.bucketId(bucket) == id)
    dispatch(actions.comparisonRatioChange(bucket.questionnaireId, bucket.mode, numbers))
  }

  bucketId(bucket) {
    return `${bucket.questionnaireId}_${bucket.mode}`
  }

  questionnaireName(bucket) {
    const { questionnaires, t } = this.props
    const questionnaireName = questionnaires[bucket.questionnaireId]
      ? questionnaires[bucket.questionnaireId].name
      : ""
    return <UntitledIfEmpty text={questionnaireName} emptyText={t("Untitled questionnaire")} />
  }

  render() {
    const { survey, readOnly, t } = this.props

    let comparisonRows = null
    let comparisonTotal = null
    if (survey.comparisons) {
      let total = 0
      comparisonRows = survey.comparisons.map((bucket, index) => {
        let ratio = bucket.ratio == null ? 0 : bucket.ratio
        total += ratio
        return (
          <div className="row comparisons" key={index}>
            <div className="col s12">
              <PercentageInput
                value={ratio}
                readOnly={readOnly}
                id={this.bucketId(bucket)}
                label={
                  <span>
                    {this.questionnaireName(bucket)}
                    {` - ${modeLabel(bucket.mode)}`}
                  </span>
                }
                onChange={this.comparisonRatioChange}
              />
            </div>
          </div>
        )
      })

      let totalComponent
      if (total == 100) {
        totalComponent = (
          <div className="green-text">
            <div className="col s1 comparisons-total">{total}%</div>
            <div className="col s1 comparisons-total-icon">
              <i className="material-icons green-text">check_circle</i>
            </div>
          </div>
        )
      } else {
        totalComponent = (
          <div>
            <div className="col s1 comparisons-total">{total}%</div>
          </div>
        )
      }

      comparisonTotal = (
        <div className="row comparisons">
          <div className="col s12">{totalComponent}</div>
        </div>
      )
    }

    return (
      <div>
        <div className="row">
          <div className="col s12">
            <h4>{t("Comparisons")}</h4>
            <p className="flow-text">
              {t(
                "Indicate percentages of all sampled cases that will be allocated to each experimental condition"
              )}
            </p>
          </div>
        </div>
        {comparisonRows}
        {comparisonTotal}
      </div>
    )
  }
}

export default translate()(connect()(SurveyWizardComparisonsStep))
