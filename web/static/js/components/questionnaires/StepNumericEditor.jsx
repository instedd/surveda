// @flow
import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import { InputWithLabel, Card, Tooltip } from '../ui'
import { bindActionCreators } from 'redux'
import * as questionnaireActions from '../../actions/questionnaire'
import { newRefusal } from '../../step'
import ChoiceEditor from './ChoiceEditor'
import { translateLangCode } from '../timezones/util'
import SkipLogic from './SkipLogic'
import propsAreEqual from '../../propsAreEqual'
import { config } from '../../config'
import { difference } from 'lodash'
import map from 'lodash/map'
import { translate } from 'react-i18next'

type State = {
  stepId: string,
  minValue: string,
  maxValue: string,
  rangesDelimiters: string,
  ranges: Range[]
};

class StepNumericEditor extends Component {
  state: State

  constructor(props) {
    super(props)
    this.state = this.stateFromProps(props)
  }

  stateFromProps(props) {
    const { step } = props
    return {
      stepId: step.id,
      minValue: step.minValue == null ? '' : step.minValue,
      maxValue: step.maxValue == null ? '' : step.maxValue,
      ranges: step.ranges || [],
      rangesDelimiters: step.rangesDelimiters == null ? '' : step.rangesDelimiters
    }
  }

  componentWillReceiveProps(newProps) {
    if (propsAreEqual(this.props, newProps)) return

    this.setState(this.stateFromProps(newProps))
  }

  minValueChange(e) {
    this.setState({minValue: e.target.value})
  }

  minValueSubmit(e) {
    this.props.questionnaireActions.changeNumericRanges(this.state.stepId, this.state.minValue,
      this.state.maxValue, this.state.rangesDelimiters)
  }

  maxValueChange(e) {
    this.setState({maxValue: e.target.value})
  }

  maxValueSubmit(e) {
    this.props.questionnaireActions.changeNumericRanges(this.state.stepId, this.state.minValue,
      this.state.maxValue, this.state.rangesDelimiters)
  }

  rangesDelimitersChange(e) {
    this.setState({rangesDelimiters: e.target.value})
  }

  rangesDelimitersSubmit(e) {
    this.props.questionnaireActions.changeNumericRanges(this.state.stepId, this.state.minValue,
      this.state.maxValue, this.state.rangesDelimiters)
  }

  skipLogicChange(skipOption, rangeIndex) {
    const { questionnaireActions } = this.props

    let newRange = {
      ...this.state.ranges[rangeIndex],
      skipLogic: skipOption
    }

    this.setState({
      ranges: [
        ...this.state.ranges.slice(0, rangeIndex),
        newRange,
        ...this.state.ranges.slice(rangeIndex + 1)
      ]
    }, () => {
      questionnaireActions.changeRangeSkipLogic(
        this.state.stepId,
        this.state.ranges[rangeIndex].skipLogic,
        rangeIndex)
    })
  }

  toggleAcceptsRefusals(e) {
    const { questionnaireActions } = this.props
    questionnaireActions.toggleAcceptsRefusals(this.state.stepId)
  }

  toggleAcceptsAlphabeticalAnswers(e) {
    const { questionnaireActions } = this.props
    questionnaireActions.toggleAcceptsAlphabeticalAnswers(this.state.stepId)
  }

  changeRefusal() {
    const { questionnaireActions } = this.props
    return (response, smsValues, ivrValues, mobilewebValues, skipLogic, autoComplete = false) => {
      questionnaireActions.changeRefusal(this.state.stepId, smsValues, ivrValues, mobilewebValues, skipLogic)
    }
  }

  maybeTooltip(component, errors) {
    const { t } = this.props
    if (errors && errors.length > 0) {
      return (
        <Tooltip text={map(errors, (error) => t(...error)).join(', ')} position='bottom' className='error'>
          {component}
        </Tooltip>
      )
    } else {
      return component
    }
  }

  render() {
    const { step, stepIndex, questionnaire, stepsAfter, stepsBefore, errorPath, errorsByPath, isNew, readOnly } = this.props
    const { ranges } = step

    const sms = questionnaire.activeMode == 'sms'
    const ivr = questionnaire.activeMode == 'ivr'
    const mobileweb = questionnaire.activeMode == 'mobileweb'

    const refusal = step.refusal || newRefusal()
    const acceptsRefusals = !!refusal.enabled
    const acceptsAlphabeticalAnswers = step.alphabeticalAnswers

    let minErrors = isNew ? null : errorsByPath[`${errorPath}.minValue`]
    let minClassName = minErrors && minErrors.length > 0 ? 'invalid' : null

    let minValue =
      <div className='col s12 m2 input-field inline'>
        <InputWithLabel id='step_numeric_editor_min_value'
          value={`${this.state.minValue}`}
          label='Min value' >
          <input
            disabled={readOnly}
            type='number'
            className={minClassName}
            onChange={e => this.minValueChange(e)}
            onBlur={e => this.minValueSubmit(e)}
            draggable
            onDragStart={e => { e.stopPropagation(); e.preventDefault(); return false }}
            />
        </InputWithLabel>
      </div>
    minValue = this.maybeTooltip(minValue, minErrors)

    let rangeErrors = isNew ? null : errorsByPath[`${errorPath}.rangesDelimiters`]
    let rangeClassName = rangeErrors && rangeErrors.length > 0 ? 'invalid' : null

    let rangesDelimiters =
      <div className='col s12 m2 input-field inline delimiters'>
        <InputWithLabel id='step_numeric_editor_range_delimiters'
          value={this.state.rangesDelimiters}
          label='Range delimiters'
          >
          <input
            type='text'
            className={rangeClassName}
            disabled={readOnly}
            onChange={e => this.rangesDelimitersChange(e)}
            onBlur={e => this.rangesDelimitersSubmit(e)}
            draggable
            onDragStart={e => { e.stopPropagation(); e.preventDefault(); return false }}
            />
        </InputWithLabel>
      </div>
    rangesDelimiters = this.maybeTooltip(rangesDelimiters, rangeErrors)

    let maxErrors = isNew ? null : errorsByPath[`${errorPath}.maxValue`]
    let maxClassName = maxErrors && maxErrors.length > 0 ? 'invalid' : null

    let maxValue =
      <div className='col s12 m2 input-field inline'>
        <InputWithLabel id='step_numeric_editor_max_value'
          value={`${this.state.maxValue}`}
          label='Max value' >
          <input
            type='number'
            className={maxClassName}
            disabled={readOnly}
            onChange={e => this.maxValueChange(e)}
            onBlur={e => this.maxValueSubmit(e)}
            draggable
            onDragStart={e => { e.stopPropagation(); e.preventDefault(); return false }}
            />
        </InputWithLabel>
      </div>
    maxValue = this.maybeTooltip(maxValue, maxErrors)

    let skipLogicTable = null
    if (ranges) {
      skipLogicTable = <Card>
        <div className='card-table'>
          <table className='responses-table'>
            <thead>
              <tr>
                <th style={{width: '30%'}}>From</th>
                <th style={{width: '30%'}}>To</th>
                <th style={{width: '30%'}}>Skip logic</th>
              </tr>
            </thead>
            <tbody>
              { ranges.map((range, index) =>
                <tr key={`${range.from},${range.to}`}>
                  <td>{range.from == null ? 'No limit' : range.from} </td>
                  <td>{range.to == null ? 'No limit' : range.to} </td>
                  <td>
                    <SkipLogic
                      onChange={skipOption => this.skipLogicChange(skipOption, index)}
                      readOnly={readOnly}
                      value={range.skipLogic}
                      stepsAfter={stepsAfter}
                      stepsBefore={stepsBefore}
                      />
                  </td>
                </tr>
                )}
            </tbody>
          </table>
        </div>
      </Card>
    }

    let refusalComponent = null
    if (acceptsRefusals) {
      let smsHeader = null
      if (sms) {
        smsHeader = <th style={{width: '30%'}}>SMS</th>
      }

      let ivrHeader = null
      if (ivr) {
        ivrHeader = <th style={{width: '30%'}}>Phone call</th>
      }

      let mobilewebHeader = null
      if (mobileweb) {
        mobilewebHeader = <th style={{width: '30%'}}>Mobile web</th>
      }

      refusalComponent = <Card>
        <div className='card-table'>
          <table className='responses-table'>
            <thead>
              <tr>
                {smsHeader}
                {ivrHeader}
                {mobilewebHeader}
                <th style={{width: '30%'}}>Skip logic</th>
              </tr>
            </thead>
            <tbody>
              <ChoiceEditor
                stepIndex={stepIndex}
                choiceIndex={'refusal'}
                lang={questionnaire.activeLanguage}
                choice={refusal}
                readOnly={readOnly}
                onDelete={e => null}
                onChoiceChange={this.changeRefusal()}
                stepsAfter={stepsAfter}
                stepsBefore={stepsBefore}
                sms={sms}
                ivr={ivr}
                mobileweb={mobileweb}
                errorPath={`${errorPath}.refusal`}
                errorsByPath={errorsByPath}
                isNew={isNew}
                smsAutocompleteGetData={(value, callback) => null}
                smsAutocompleteOnSelect={item => null}
              />
            </tbody>
          </table>
        </div>
      </Card>
    }

    let alphabeticalAnswersComponent = null
    if (sms) {
      const missingLanguages =
        difference(questionnaire.languages, config.available_languages_for_numbers)
        .map(lang => translateLangCode(lang))
        .join(', ')

      alphabeticalAnswersComponent =
        <div>
          <p>
            <input id='accepts_alphabetical_answers' type='checkbox' checked={acceptsAlphabeticalAnswers} onChange={e => { this.toggleAcceptsAlphabeticalAnswers(e) }} disabled={readOnly} />
            <label htmlFor='accepts_alphabetical_answers'>Accepts alphabetical answers
        </label>
            <Tooltip className='large-tooltip' text='Checking this box will make the survey accept written numbers as valid numeric responses, like "one" or "fifty five". Written numbers are supported up to one hundred (100).' acceptsHtml >
              <i className='material-icons grey-text v-middle'>info_outline</i>
            </Tooltip>
          </p>
          <p>
            { (missingLanguages.length > 0)
          ? <span className='text-error checkbox-error'>Not supported for: {missingLanguages}</span>
          : <span />
        }
          </p>
        </div>
    }

    return <div>
      <h5>Responses</h5>
      <p><b>Setup a valid range for user input. Leave min or max empty if not
      applicable and enter range delimiters separated by comma if needed.</b></p>
      <div className='row range-fields'>
        {minValue}
        {rangesDelimiters}
        {maxValue}
      </div>
      {skipLogicTable}
      <br />
      <p>
        <input id='accepts_refusals' type='checkbox' defaultChecked={acceptsRefusals} onClick={e => { this.toggleAcceptsRefusals(e) }} disabled={readOnly} />
        <label htmlFor='accepts_refusals'>Accepts refusals</label>
      </p>
      {refusalComponent}
      {alphabeticalAnswersComponent}
    </div>
  }
}

StepNumericEditor.propTypes = {
  t: PropTypes.func,
  questionnaireActions: PropTypes.object.isRequired,
  stepId: PropTypes.number,
  minValue: PropTypes.number,
  maxValue: PropTypes.number,
  ranges: PropTypes.array,
  rageDelimiters: PropTypes.string,
  questionnaire: PropTypes.object.isRequired,
  readOnly: PropTypes.bool,
  step: PropTypes.object.isRequired,
  stepIndex: PropTypes.number,
  stepsAfter: PropTypes.array.isRequired,
  stepsBefore: PropTypes.array.isRequired,
  errorPath: PropTypes.string,
  errorsByPath: PropTypes.object,
  isNew: PropTypes.bool
}

const mapDispatchToProps = (dispatch) => ({
  questionnaireActions: bindActionCreators(questionnaireActions, dispatch)
})

export default translate()(connect(null, mapDispatchToProps)(StepNumericEditor))
