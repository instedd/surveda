import React, { PropTypes, Component } from 'react'
import { connect } from 'react-redux'
import * as actions from '../../actions/survey'
import { UntitledIfEmpty, PercentageInput } from '../ui'
import find from 'lodash/find'
import { modeLabel } from '../../reducers/survey'

class SurveyWizardComparisonsStep extends Component {
  static propTypes = {
    survey: PropTypes.object.isRequired,
    questionnaires: PropTypes.object,
    dispatch: PropTypes.func.isRequired
  }

  constructor(props) {
    super(props)
    this.state = {
      buckets: {}
    }
    this.comparisonRatioChange = this.comparisonRatioChange.bind(this)
  }

  comparisonRatioChange(numbers, id) {
    const { dispatch, survey } = this.props
    const bucket = find(survey.comparisons, (bucket) =>
      this.bucketId(bucket) == id
    )
    dispatch(actions.comparisonRatioChange(bucket.questionnaireId, bucket.mode, numbers))
  }

  bucketId(bucket) {
    return `${bucket.questionnaireId}_${bucket.mode}`
  }

  questionnaireName(bucket) {
    const { questionnaires } = this.props
    const questionnaireName = questionnaires[bucket.questionnaireId] ? questionnaires[bucket.questionnaireId].name : ''
    return <UntitledIfEmpty text={questionnaireName} />
  }

  render() {
    const { survey } = this.props

    return (
      <div>
        <div className='row'>
          <div className='col s12'>
            <h4>Comparisons</h4>
            <p className='flow-text'>
              Indicate percentages of all sampled cases that will be allocated to each experimental condition
            </p>
          </div>
        </div>
        { survey.comparisons
          ? survey.comparisons.map((bucket, index) =>
            <div className='row comparisons' key={index} >
              <div className='col s12'>
                <PercentageInput
                  value={bucket.ratio == null ? 0 : bucket.ratio}
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
          : ''
        }
      </div>
    )
  }
}
const mapStateToProps = (state) => ({
  questionnaires: state.questionnaires.items || {}
})

export default connect(mapStateToProps)(SurveyWizardComparisonsStep)
