// @flow
import findIndex from 'lodash/findIndex'
import React, { Component } from 'react'
import { Input } from 'react-materialize'

type Props = {
  value: ?string,
  onChange: Function,
  stepsBefore: Step[],
  stepsAfter: Step[]
};

type State = {
  value: ?string
};

class SkipLogic extends Component {
  props: Props
  state: State

  constructor(props: Props) {
    super(props)
    this.state = { ...this.stateFromProps(props) }
  }

  componentWillReceiveProps(newProps: Props) {
    this.setState(this.stateFromProps(newProps))
  }

  stateFromProps(props: Props) {
    const { value } = props
    return {
      value: value
    }
  }

  change(event: any) {
    const { onChange } = this.props
    const newValue: ?string = event.target.value == '' ? null : event.target.value
    this.setState({
      ...this.state,
      value: newValue
    }, () => onChange(this.state.value))
  }

  skipOptions(currentValue: ?string, stepsAfter: Step[], stepsBefore: Step[]) {
    let currentValueIsValid = false

    if (currentValue == null || currentValue === 'end') {
      currentValueIsValid = true
    }

    let skipOptions = stepsAfter.slice().map(s => {
      if (currentValue === s.id) {
        currentValueIsValid = true
      }

      return {
        id: s.id,
        title: s.title === '' ? 'Untitled' : s.title,
        enabled: true
      }
    })

    let skipOptionsLength = skipOptions.length

    skipOptions.unshift({
      id: 'end',
      title: 'End survey',
      enabled: true
    })

    if (skipOptionsLength != 0) {
      skipOptions.unshift({
        id: '',
        title: 'Next question',
        enabled: true
      })
    }

    if (!currentValueIsValid && currentValue != null && currentValue != 'end') {
      const stepIndex = findIndex(stepsBefore, s => s.id === currentValue)

      skipOptions.unshift({
        id: currentValue,
        title: stepIndex == -1 ? 'Step missing' : stepsBefore[stepIndex].title,
        enabled: false
      })
    }

    return { skipOptions, currentValueIsValid }
  }

  render() {
    const { stepsAfter, stepsBefore } = this.props

    let { skipOptions, currentValueIsValid } = this.skipOptions(this.state.value, stepsAfter, stepsBefore)

    return (
      <Input s={12} type='select'
        onChange={e => this.change(e)}
        defaultValue={this.state.value}
        className={currentValueIsValid ? '' : 'invalidValue'}>
        { skipOptions.map((option) =>
          <option
            key={option.id}
            id={option.id}
            name={option.title}
            value={option.id}
            disabled={!(option.enabled)} >
            {option.title}
          </option>
        )}
      </Input>
    )
  }
}

export default SkipLogic
