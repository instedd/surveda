import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import { InputWithLabel, Card } from '../ui'
import { bindActionCreators } from 'redux'
import * as questionnaireActions from '../../actions/questionnaire'
import { Input } from 'react-materialize'

class StepNumericEditor extends Component {
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
      rangesDelimiters: step.ranges ? this.delimitersFromRanges(step.ranges) : ''
    }
  }

  delimitersFromRanges(ranges) {
    let delimiters = []
    for (let [index, value] of ranges.entries()) {
      if (index > 0) {
        delimiters.push(value.from)
      }
    }

    return delimiters.join(',')
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

  skipLogicChange(e, rangeIndex) {
    let newRange = {
      ...this.state.ranges[rangeIndex],
      skipLogic: e.target.value == '' ? null : e.target.value
    }
    this.setState({
      ranges: [
        ...this.state.ranges.slice(0, rangeIndex),
        newRange,
        ...this.state.ranges.slice(rangeIndex + 1)
      ]
    })
    this.props.questionnaireActions.changeRangeSkipLogic(this.state.stepId,
      e.target.value, rangeIndex)
  }

  render() {
    const { step, skip } = this.props
    const { ranges } = step

    let skipOptions = skip.slice()
    let skipOptionsLength = skipOptions.length

    skipOptions.unshift({id: 'end', title: 'End survey'})
    if (skipOptionsLength != 0) {
      skipOptions.unshift({id: '', title: 'Next question'})
    }

    let minValue = <div className='row'>
      <div className='col input-field s2'>
        <InputWithLabel id='step_numeric_editor_min_value'
          value={`${this.state.minValue}`}
          label='Min value' >
          <input
            type='text'
            onChange={e => this.minValueChange(e)}
            onBlur={e => this.minValueSubmit(e)} />
        </InputWithLabel>
      </div>
    </div>

    let rangesDelimiters = <div className='row'>
      <div className='col input-field s2'>
        <InputWithLabel id='step_numeric_editor_range_delimiters'
          value={this.state.rangesDelimiters}
          label='Range delimiters' >
          <input
            type='text'
            onChange={e => this.rangesDelimitersChange(e)}
            onBlur={e => this.rangesDelimitersSubmit(e)} />
        </InputWithLabel>
      </div>
    </div>

    let maxValue = <div className='row'>
      <div className='col input-field s2'>
        <InputWithLabel id='step_numeric_editor_max_value'
          value={`${this.state.maxValue}`}
          label='Max value' >
          <input
            type='text'
            is length='20'
            onChange={e => this.maxValueChange(e)}
            onBlur={e => this.maxValueSubmit(e)} />
        </InputWithLabel>
      </div>
    </div>

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
                <tr key={index}>
                  <td>{range.from == null ? 'No limit' : range.from} </td>
                  <td>{range.to == null ? 'No limit' : range.to} </td>
                  <td>
                    <Input s={12} type='select'
                      onChange={e => this.skipLogicChange(e, index)}
                      defaultValue={range.skipLogic ? range.skipLogic : 'Null'}
                      >
                      { skipOptions.map((option) =>
                        <option key={option.id} id={option.id} name={option.title} value={option.id} >
                          {option.title == '' ? 'Untitled' : option.title }
                        </option>
                      )}
                    </Input>
                  </td>
                </tr>
                )}
            </tbody>
          </table>
        </div>
      </Card>
    }

    return <div>
      <h5>Responses</h5>
      <p><b>Setup a valid range for user input. Leave min or max empty if not
      applicable and enter range delimiters separated by comma if needed.</b></p>
      {minValue}
      {rangesDelimiters}
      {maxValue}
      {skipLogicTable}
    </div>
  }
}

StepNumericEditor.propTypes = {
  questionnaireActions: PropTypes.object.isRequired,
  stepId: PropTypes.number,
  minValue: PropTypes.number,
  maxValue: PropTypes.number,
  ranges: PropTypes.array,
  rageDelimiters: PropTypes.string,
  step: PropTypes.object.isRequired,
  skip: PropTypes.array.isRequired
}

const mapStateToProps = (state, ownProps) => ({})

const mapDispatchToProps = (dispatch) => ({
  questionnaireActions: bindActionCreators(questionnaireActions, dispatch)
})

export default connect(mapStateToProps, mapDispatchToProps)(StepNumericEditor)
