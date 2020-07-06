// @flow
import React, { Component } from 'react'
import { translate } from 'react-i18next'

type Props = {
  t: Function,
  defaultValue: string,
  onChange: Function
}

class RespondentsFilter extends Component<Props> {
  _timeoutId = null

  onInputChange = event => {
    this.applyFilter({ value: event.target.value, debounced: true })
  }

  onInputKeyPress = event => {
    if (event.key === 'Enter') this.applyFilter({ value: event.target.value, debounced: false })
  }

  applyFilter = ({ value, debounced }) => {
    const { onChange } = this.props
    if (this._timeoutId != null) {
      clearTimeout(this._timeoutId)
      this._timeoutId = null
    }
    if (debounced) {
      this._timeoutId = setTimeout(() => {
        this._timeoutId = null
        onChange(value)
      }, 500)
    } else {
      onChange(value)
    }
  }

  render = () => {
    const { t, defaultValue } = this.props

    return (
      <div className='input-field'
        style={{marginRight: '3.8rem', marginLeft: '0.7rem'}}>
        <input
          defaultValue={defaultValue}
          type='search'
          className='search-input'
          onChange={this.onInputChange}
          onKeyPress={this.onInputKeyPress}
        />
        <i className='material-icons grey-text'>search</i>
        <span className='small-text-bellow'>
          {t('Filter using the following format')}:&nbsp;
          <em>disposition:completed since:2020-06-20</em>.&nbsp;
          <a
            href='https://github.com/instedd/surveda/wiki/How-to-filter-respondents'
            target='_blank'
          >
            {t('View advanced search syntax')}
          </a>
        </span>
      </div>
    )
  }
}

export default translate()(RespondentsFilter)
