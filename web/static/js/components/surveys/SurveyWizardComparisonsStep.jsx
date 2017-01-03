import React, { PropTypes, Component } from 'react'
import { connect } from 'react-redux'
import * as actions from '../../actions/survey'
import { UntitledIfEmpty, InputWithLabel } from '../ui'
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

  comparisonRatioChange(e) {
    e.preventDefault()
    const { dispatch, survey } = this.props
    var onlyNumbers = e.target.value.replace(/[^0-9.]/g, '')

    if (onlyNumbers == e.target.value && onlyNumbers < Math.pow(2, 31) - 1) {
      const bucket = find(survey.comparisons, (bucket) =>
        this.bucketId(bucket) == e.target.id
      )
      dispatch(actions.comparisonRatioChange(bucket.questionnaireId, bucket.mode, onlyNumbers))
    }
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
                <InputWithLabel value={bucket.ratio == null ? 0 : bucket.ratio} id={this.bucketId(bucket)} label={
                  <span>
                    {this.questionnaireName(bucket)}
                    {` - ${modeLabel(bucket.mode)}`}
                  </span>
                } >
                  <input
                    type='text'
                    onChange={this.comparisonRatioChange}
                  />
                </InputWithLabel>
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
