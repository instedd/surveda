// @flow
import findIndex from 'lodash/findIndex'
import React, { Component } from 'react'
import { connect } from 'react-redux'
import propsAreEqual from '../../propsAreEqual'
import { translate } from 'react-i18next'
import { hasSections } from '../../reducers/questionnaire'
import classNames from 'classnames/bind'

type Props = {
  value: ?string,
  onChange: Function,
  stepsBefore: Step[],
  stepsAfter: Step[],
  readOnly?: boolean,
  errorPath: string,
  errorsByPath: ErrorsByPath,
  hasSections: boolean,
  t: Function,
  label?: string
};

type State = {
  value: ?string
};

class SkipLogic extends Component<Props, State> {
  constructor(props: Props) {
    super(props)
    this.state = { ...this.stateFromProps(props) }
  }

  componentWillReceiveProps(newProps: Props) {
    if (propsAreEqual(this.props, newProps)) return

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
    const { t, errorPath, errorsByPath, hasSections } = this.props
    let currentValueIsValid = !errorsByPath[errorPath]

    let skipOptions = stepsAfter.slice().map(s => {
      return {
        id: s.id,
        title: this.stringOrUntitledQuestion(s.title),
        enabled: true
      }
    })

    skipOptions.unshift({
      id: 'end',
      title: t('Jump to the end of the questionnaire'),
      enabled: true
    })

    if (hasSections) {
      skipOptions.unshift({
        id: 'end_section',
        title: t('End section'),
        enabled: true
      })
    }

    skipOptions.unshift({
      id: '',
      title: t('Next step'),
      enabled: true
    })

    if (!currentValueIsValid && currentValue != null && currentValue != 'end' && currentValue != 'end_section') {
      const stepIndex = findIndex(stepsBefore, s => s.id === currentValue)

      skipOptions.unshift({
        id: currentValue,
        title: stepIndex == -1 ? t('Step missing') : this.stringOrUntitledQuestion(stepsBefore[stepIndex].title),
        enabled: false
      })
    }

    return { skipOptions, currentValueIsValid }
  }

  stringOrUntitledQuestion(string: string) {
    return string === '' ? this.props.t('Untitled question') : string
  }

  render() {
    const { stepsAfter, stepsBefore, label, readOnly } = this.props

    let { skipOptions, currentValueIsValid } = this.skipOptions(this.state.value, stepsAfter, stepsBefore)

    return (
      <select
        label={label}
        disabled={readOnly}
        onChange={e => this.change(e)}
        value={this.state.value != null ? this.state.value : ''}
        className={classNames('browser-default', {'invalidValue': !currentValueIsValid})}>
        { skipOptions.map((option) =>
          <option
            key={option.id}
            id={option.id}
            name={option.title}
            value={option.id}
            disabled={!(option.enabled)}>
            {option.title}
          </option>
        )}
      </select>
    )
  }
}

const mapStateToProps = (state) => {
  const steps = state.questionnaire.data.steps
  return {
    hasSections: hasSections(steps)
  }
}

export default translate()(connect(mapStateToProps)(SkipLogic))
