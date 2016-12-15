// @flow
import React, { Component } from 'react'
import { Input } from 'react-materialize'

type Props = {
  value: ?string,
  onChange: Function,
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

  skipOptions(stepsAfter: Step[]): SkipOption[] {
    let skipOptions = stepsAfter.slice().map(s => {
      return {
        id: s.id,
        title: s.title
      }
    })

    let skipOptionsLength = skipOptions.length

    skipOptions.unshift({id: 'end', title: 'End survey'})
    if (skipOptionsLength != 0) {
      skipOptions.unshift({id: '', title: 'Next question'})
    }

    return skipOptions
  }

  render() {
    const { stepsAfter } = this.props

    let options = this.skipOptions(stepsAfter)

    return (
      <Input s={12} type='select'
        onChange={e => this.change(e)}
        defaultValue={this.state.value}>
        { options.map((option) =>
          <option key={option.id} id={option.id} name={option.title} value={option.id} >
            {option.title == '' ? 'Untitled' : option.title }
          </option>
        )}
      </Input>
    )
  }
}

export default SkipLogic
