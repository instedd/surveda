// @flow
import React, { Component } from 'react'
import { translate } from 'react-i18next'

type Props = {
  t: Function,
  inputValue: string,
  onChange: Function,
  onEnter: Function,
}

type State = {
  inputValue: string,
}

class RespondentsFilter extends Component<Props, State> {
  constructor(props) {
    super(props)
    this.state = { inputValue: props.inputValue }
  }

  onInputKeyPress = (event) => {
    const { onEnter } = this.props
    if (event.key === 'Enter') onEnter()
  }
  onInputChange = (event) => {
    const { onChange } = this.props
    const inputValue = event.target.value
    this.setState({ inputValue: inputValue })
    onChange(inputValue)
  };

  render = () => {
    const { t } = this.props
    const { inputValue } = this.state

    return (
      <div className='input-field'>
        <input
          value={inputValue}
          type='search'
          className='search-input'
          onChange={this.onInputChange}
          onKeyPress={this.onInputKeyPress}
        />
        <i className='material-icons grey-text'>search</i>
        <span className='small-text-bellow'>
          {t('Filter by supported properties')}
          <em>{t(' disposition, since, final')}</em>
          {t(' using the following format')}
          <em>{t(' property1:value1[ property2:value2, ...]')}</em>
          {/* In the future, we plan to support advanced search */}
          {/* <a href="#">View advanced search syntax</a> */}
        </span>
      </div>
    )
  }
}

export default translate()(RespondentsFilter)
