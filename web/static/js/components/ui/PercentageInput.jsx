import React, { PropTypes, Component } from 'react'
import { InputWithLabel } from '../ui'

export class PercentageInput extends Component {
  static propTypes = {
    value: PropTypes.number.isRequired,
    label: PropTypes.node.isRequired,
    id: PropTypes.string.isRequired,
    onChange: PropTypes.func.isRequired,
    readOnly: PropTypes.bool
  }

  constructor(props) {
    super(props)
    this.state = {
      focused: false,
      percentage: this.percentageRepresentation(props.value)
    }
    this.valueChange = this.valueChange.bind(this)
    this.onFocus = this.onFocus.bind(this)
    this.onBlur = this.onBlur.bind(this)
    this.onChange = this.props.onChange.bind(this)
  }

  valueChange(e) {
    var onlyNumbers = this.onlyNumbers(e.target.value)

    if (onlyNumbers == e.target.value && onlyNumbers != `${onlyNumbers}%`) {
      let number = parseInt(onlyNumbers) || 0
      if (number > 100) {
        number = 100
      }
      this.setState({percentage: number.toString()})
      this.onChange(number, e.target.id)
    }
  }

  componentWillReceiveProps(props: Props) {
    if (!this.state.focused) {
      this.setState({percentage: this.percentageRepresentation(props.value)})
    }
  }

  onFocus(e) {
    this.setState({
      focused: true,
      percentage: this.onlyNumbers(e.target.value).toString()
    })
  }

  onBlur(e) {
    this.setState({
      focused: false,
      percentage: this.percentageRepresentation(e.target.value)
    })
  }

  onlyNumbers(value) {
    return value.replace(/[^0-9.]/g, '')
  }

  percentageRepresentation(numericValue) {
    return `${numericValue}%`
  }

  render() {
    const { label, id, readOnly } = this.props
    return (
      <InputWithLabel value={this.state.percentage} id={id} label={label} >
        <input
          type='text'
          onChange={this.valueChange}
          onBlur={this.onBlur}
          onFocus={this.onFocus}
          disabled={readOnly}
        />
      </InputWithLabel>
    )
  }
}
