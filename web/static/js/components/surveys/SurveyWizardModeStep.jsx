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
import { Dropdown, DropdownItem } from '../ui'
import { availableOptions } from '../../surveyModes'

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

  availableModes = (modes) => {
    return this.filterQuestionnaireMatchingModes(availableOptions(modes))
  }

  primaryOptionsFor = (modes) => {
    return uniq(map(modes, (mode) => mode[0]))
  }

  comparisonPrimarySelectedIfLast = () => {
    const { survey } = this.props
    const primaryOptions = this.primaryOptionsFor(this.availableModes(survey.mode))
    return primaryOptions.length == 1 ? primaryOptions[0] : null
  }

  comparisonFallbackSelectedIfLast = (primarySelected) => {
    const { survey } = this.props
    const options = this.availableModes(survey.mode).filter((mode) => (mode[0] == primarySelected))
    return options.length == 1 && options[0].length == 2 ? options[0][1] : null
  }

  addModeComparison = (primary, fallback) => {
    const { dispatch } = this.props
    if (!primary) {
      return
    } else {
      if (primary && !fallback) {
        this.modeChange(null, [primary])
      } else {
        this.modeChange(null, [primary, fallback])
      }
    }
    dispatch(uiActions.addModeComparison())
  }

  selectPrimaryModeForComparison = (mode) => {
    const { dispatch } = this.props
    dispatch(uiActions.comparisonPrimarySelected(mode))
  }

  selectFallbackModeForComparison = (primary, fallback) => {
    const { dispatch } = this.props
    dispatch(uiActions.comparisonFallbackSelected(fallback))
  }

  selectSingleMode = (primary, fallback) => {
    const { dispatch } = this.props
    const mode = fallback ? [primary, fallback] : [primary]
    dispatch(actions.selectMode(mode))
  }

  primarySingleMode = (modes) => (
    !modes || modes.length == 0 ? null : modes[0][0]
  )

  fallbackSingleMode = (modes) => (
    !modes || (modes.length == 0) || (modes[0].length == 1) ? null : modes[0][1]
  )

  selectorForPrimaryMode = (comparison, primary, label, options, handler, readOnly) => {
    if (comparison && options.length == 1) {
      return (<div>
        {options[0]}
      </div>)
    } else {
      return (<div>
        <Dropdown label={<span>{ primary || label}</span>} readOnly={readOnly}>
          {options.map((mode) => {
            return (
              <DropdownItem>
                <a onClick={() => handler(mode)}>{mode}</a>
              </DropdownItem>
            )
          })}
        </Dropdown>
      </div>)
    }
  }

  selectorForFallbackMode = (comparison, primary, fallback, label, options, handler, readOnly) => {
    if (comparison && options.length == 1) {
      return (<div>
        {options[0] || 'no fallback'}
      </div>)
    } else {
      return (<div>
        <Dropdown label={<span>{ fallback || label}</span>} readOnly={readOnly}>
          {options.map((mode) => {
            return (
              <DropdownItem>
                <a onClick={() => handler(primary, mode)}>{mode || 'no fallback'}</a>
              </DropdownItem>
            )
          })}
        </Dropdown>
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
    const availableModes = this.availableModes(survey.mode)
    const primaryOptions = this.primaryOptionsFor(availableModes)

    let selectedPrimary
    let selectedFallback
    let selectPrimaryHandler
    let selectFallbackHandler
    let modeDescriptions
    let addModeButton
    let showSelectors = true

    if (modeComparison) {
      selectedPrimary = comparisonModes.primaryModeSelected || this.comparisonPrimarySelectedIfLast()
      selectedFallback = comparisonModes.fallbackModeSelected || this.comparisonFallbackSelectedIfLast(selectedPrimary)
      selectPrimaryHandler = this.selectPrimaryModeForComparison
      selectFallbackHandler = this.selectFallbackModeForComparison

      modeDescriptions = mode.map((mode) => (
        <div>
          {modeLabel(mode)}
          {
            !readOnly ? <a href='#!' onClick={(e) => { this.modeChange(e, mode) }}><i className='material-icons grey-text'>delete</i></a> : null
          }
        </div>
      ))

      addModeButton = (primaryOptions.length > 0)
      ? <div onClick={() => this.addModeComparison(selectedPrimary, selectedFallback)}>
          Add mode
      </div> : null

      showSelectors = primaryOptions.length > 0 && !readOnly
    } else {
      selectedPrimary = this.primarySingleMode(survey.mode)
      selectedFallback = this.fallbackSingleMode(survey.mode)
      selectPrimaryHandler = this.selectSingleMode
      selectFallbackHandler = this.selectSingleMode
      modeDescriptions = null
      addModeButton = null
    }

    const fallbackOptions = availableModes.filter((mode) => { return mode[0] == selectedPrimary }).map((mode) => mode.length == 2 ? mode[1] : null)

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
