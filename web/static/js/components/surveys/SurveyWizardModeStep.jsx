import React, { PropTypes, Component } from 'react'
import { connect } from 'react-redux'
import * as actions from '../../actions/survey'
import every from 'lodash/every'
import map from 'lodash/map'
import uniq from 'lodash/uniq'
import some from 'lodash/some'
import each from 'lodash/each'
import isEqual from 'lodash/isEqual'
import { modeLabel } from '../../reducers/survey'
import * as respondentActions from '../../actions/respondentGroups'
import * as uiActions from '../../actions/ui'
import { Input } from 'react-materialize'
import { availableOptions, allOptions } from '../../surveyModes'

class SurveyWizardModeStep extends Component {
  static propTypes = {
    survey: PropTypes.object.isRequired,
    respondentGroups: PropTypes.object,
    questionnaires: PropTypes.object,
    dispatch: PropTypes.func.isRequired,
    readOnly: PropTypes.bool.isRequired,
    comparisonModes: PropTypes.object
  }

  modeChange(e, modes) {
    const { dispatch, survey, respondentGroups } = this.props
    dispatch(actions.selectMode(modes))
    each(Object.keys(respondentGroups), groupId => {
      let currentChannels = respondentGroups[groupId].channels || []
      currentChannels = currentChannels.filter(channel => some(modes, mode => channel.mode == mode))
      dispatch(respondentActions.selectChannels(survey.projectId, survey.id, groupId, currentChannels))
    })
  }

  modeComparisonChange(e) {
    const { dispatch } = this.props
    dispatch(actions.changeModeComparison())
    dispatch(uiActions.addModeComparison())
  }

  modeIncludes(modes, target) {
    return some(modes, ary => isEqual(ary, target))
  }

  questionnairesMatchMode(mode, ids, questionnaires) {
    return every(mode, m =>
      ids && every(ids, id =>
        questionnaires[id] && questionnaires[id].modes && questionnaires[id].modes.indexOf(m) != -1))
  }

  filterQuestionnaireMatchingModes = (availableModes) => {
    const { survey, questionnaires } = this.props
    const questionnaireIds = survey.questionnaireIds
    return availableModes.filter((mode) => this.questionnairesMatchMode(mode, questionnaireIds, questionnaires))
  }

  availableModesForSingle = (modes) => {
    return this.filterQuestionnaireMatchingModes(allOptions())
  }

  availableModesForComparisons = (modes) => {
    return this.filterQuestionnaireMatchingModes(availableOptions(modes))
  }

  primaryOptionsFor = (modes) => {
    return uniq(map(modes, (mode) => mode[0]))
  }

  comparisonPrimarySelectedIfLast = () => {
    const { survey } = this.props
    const primaryOptions = this.primaryOptionsFor(this.availableModesForComparisons(survey.mode))
    return primaryOptions.length == 1 ? primaryOptions[0] : null
  }

  comparisonFallbackSelectedIfLast = (primarySelected) => {
    const { survey } = this.props
    const options = this.availableModesForComparisons(survey.mode).filter((mode) => (mode[0] == primarySelected))
    return options.length == 1 && options[0].length == 2 ? options[0][1] : null
  }

  addModeComparison = (primary, fallback) => {
    const { dispatch } = this.props
    if (!primary) {
      return
    } else {
      const mode = this.modeFromPrimaryAndFallback(primary, fallback)
      if (!this.modeIncluded(mode)) {
        this.modeChange(null, mode)
        dispatch(uiActions.addModeComparison())
      }
    }
  }

  modeIncluded = (mode) => {
    const { survey } = this.props
    return this.modeIncludes(survey.mode, mode)
  }

  modeFromPrimaryAndFallback = (primary, fallback) => (
    primary && !fallback ? [primary] : [primary, fallback]
  )

  selectPrimaryModeForComparison = (event) => {
    const { dispatch } = this.props
    const primary = event.target.value
    if (primary) {
      dispatch(uiActions.comparisonPrimarySelected(event.target.value))
    }
  }

  selectPrimaryModeForSingle = (event) => {
    const { dispatch } = this.props
    const primary = event.target.value
    if (primary) {
      dispatch(actions.selectMode([primary]))
    }
  }

  selectFallbackModeForComparison = (event) => {
    const { dispatch } = this.props
    const fallback = event.target.value
    if (fallback != '') {
      dispatch(uiActions.comparisonFallbackSelected(fallback))
    } else {
      dispatch(uiActions.comparisonFallbackSelected(null))
    }
  }

  selectFallbackModeForSingle = (event) => {
    const { dispatch, survey } = this.props
    const primary = this.primarySingleMode(survey.mode)
    const fallback = event.target.value
    const mode = this.modeFromPrimaryAndFallback(primary, fallback)
    dispatch(actions.selectMode(mode))
  }

  primarySingleMode = (modes) => (
    !modes || modes.length == 0 ? null : modes[0][0]
  )

  fallbackSingleMode = (modes) => (
    !modes || (modes.length == 0) || (modes[0].length == 1) ? null : modes[0][1]
  )

  selectorForPrimaryMode = (comparison, primary, label, options, handler, readOnly) => {
    const lastPrimary = this.comparisonPrimarySelectedIfLast()
    const selectorOptions = options.map((mode, index) => (
      <option value={mode} key={mode + index}>{mode}</option>
    ))
    if (!primary) {
      selectorOptions.unshift(<option value='' key='select-primary-mode'>Select primary mode</option>)
    }
    if (lastPrimary) {
      return (<div>
        <Input s={12} m={5} type='select' label={label} value={lastPrimary} disabled={readOnly} onChange={handler}>
          <option value={lastPrimary} key={lastPrimary}>{lastPrimary}</option>
        </Input>
      </div>)
    } else {
      return (<div>
        <Input s={12} m={5} type='select' label={label} value={primary || ''} disabled={readOnly} onChange={handler}>
          {selectorOptions}
        </Input>
      </div>)
    }
  }

  selectorForFallbackMode = (comparison, primary, fallback, label, options, handler, readOnly) => {
    const lastFallback = this.comparisonFallbackSelectedIfLast(primary)
    if (lastFallback) {
      return (<div>
        <Input s={12} m={5} type='select' label={label} value={lastFallback} disabled={readOnly} onChange={handler}>
          <option value={lastFallback} key={lastFallback}>{lastFallback}</option>
        </Input>
      </div>)
    } else {
      return (<div>
        <Input s={12} m={5} type='select' label={label} value={fallback || ''} disabled={readOnly} onChange={handler}>
          {<option value=''>No fallback</option>}
          {options.map((mode, index) => {
            return <option value={mode} key={mode + index}>{mode}</option>
          })}
        </Input>
      </div>)
    }
  }

  render() {
    const { survey, readOnly, comparisonModes } = this.props

    if (!survey) {
      return <div>Loading...</div>
    }

    const mode = survey.mode || []
    const modeComparison = mode.length > 1 || (!!survey.modeComparison)

    let availableModes
    let selectedPrimary
    let selectedFallback
    let selectPrimaryHandler
    let selectFallbackHandler
    let modeDescriptions
    let addModeButton
    let showSelectors = true

    if (modeComparison) {
      availableModes = this.availableModesForComparisons(survey.mode)
      selectedPrimary = comparisonModes.primaryModeSelected || this.comparisonPrimarySelectedIfLast()
      selectedFallback = comparisonModes.fallbackModeSelected || this.comparisonFallbackSelectedIfLast(selectedPrimary)
      selectPrimaryHandler = this.selectPrimaryModeForComparison
      selectFallbackHandler = this.selectFallbackModeForComparison

      modeDescriptions = mode.map((mode) => (
        <p key={mode}>
          {modeLabel(mode)}
          {
            !readOnly ? <a href='#!' onClick={(e) => { this.modeChange(e, mode) }}><i className='material-icons grey-text'>delete</i></a> : null
          }
        </p>
      ))
    } else {
      availableModes = this.availableModesForSingle()
      selectedPrimary = this.primarySingleMode(survey.mode)
      selectedFallback = this.fallbackSingleMode(survey.mode)
      selectPrimaryHandler = this.selectPrimaryModeForSingle
      selectFallbackHandler = this.selectFallbackModeForSingle
      modeDescriptions = null
      addModeButton = null
    }

    const primaryOptions = this.primaryOptionsFor(availableModes)
    const fallbackOptions = availableModes.filter((mode) => { return mode[0] == selectedPrimary && mode.length == 2 }).map((mode) => mode[1])

    showSelectors = !modeComparison || (primaryOptions.length > 0 && !readOnly)

    addModeButton = (primaryOptions.length > 0 && modeComparison)
    ? <a className={this.modeIncluded(this.modeFromPrimaryAndFallback(selectedPrimary, selectedFallback)) ? 'disabled' : ''} onClick={() => this.addModeComparison(selectedPrimary, selectedFallback)}>
      <i className='material-icons'>add</i>
    </a> : null

    return (
      <div>
        <div className='row'>
          <div className='col s12'>
            <h4>Select mode</h4>
            <p className='flow-text'>
              Select which modes you want to use.
            </p>
          </div>
        </div>
        <div className='row'>
          <div className='col s12'>
            <p>
              <input
                id='questionnaire_mode_comparison'
                type='checkbox'
                checked={modeComparison}
                onChange={e => this.modeComparisonChange(e)}
                className='filled-in'
                disabled={readOnly}
                />
              <label htmlFor='questionnaire_mode_comparison'>Run a comparison to contrast performance between different primary and fallback modes combinations (you can set up the allocations later in the comparisons section)</label>
            </p>
            {
              modeDescriptions
            }
            {
              showSelectors
              ? <div>
                {this.selectorForPrimaryMode(modeComparison, selectedPrimary, 'Primary mode', primaryOptions, selectPrimaryHandler, readOnly)}
                {this.selectorForFallbackMode(modeComparison, selectedPrimary, selectedFallback, 'Fallback mode', fallbackOptions, selectFallbackHandler, readOnly)}
              </div>
              : null
            }
            {
              !readOnly ? addModeButton : null
            }
          </div>
        </div>
      </div>
    )
  }
}

const mapStateToProps = (state) => ({
  comparisonModes: state.ui.data.surveyWizard
})

export default connect(mapStateToProps)(SurveyWizardModeStep)
