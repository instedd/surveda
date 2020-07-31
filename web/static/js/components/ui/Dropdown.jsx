// TODO: Add flow check
import { uniqueId } from 'lodash'
import React, { Component, PropTypes } from 'react'
export class Dropdown extends Component {
  static propTypes = {
    label: PropTypes.node.isRequired,
    icon: PropTypes.string,
    iconLeft: PropTypes.bool,
    children: PropTypes.node,
    constrainWidth: PropTypes.bool,
    readOnly: PropTypes.bool,
    dataBelowOrigin: PropTypes.bool,
    className: PropTypes.string
  }

  constructor(props) {
    super(props)
    this.dropdownId = uniqueId('dropdown')
  }

  componentDidMount() {
    const {readOnly} = this.props
    if (!readOnly) $(this.refs.node).dropdown()
  }

  render() {
    const { label, icon = 'arrow_drop_down', dataBelowOrigin = true, children, constrainWidth = true, className, readOnly, iconLeft = false } = this.props
    const onButtonClick = (event) => {
      event.preventDefault()
    }

    return (
      <span className={className}>
        <a className='dropdown-button' href='#!' onClick={onButtonClick} data-induration='100' data-outduration='50' data-beloworigin={dataBelowOrigin} data-activates={this.dropdownId} data-constrainwidth={constrainWidth} ref='node'>
          {label}
          {readOnly ? null : <i className={iconLeft ? 'material-icons left' : 'material-icons right'}>{icon}</i> }
        </a>
        <ul id={this.dropdownId} className='dropdown-content' onClick={event => { event.stopPropagation() }}>
          {children}
        </ul>
      </span>
    )
  }
}

export const DropdownItem = ({children, className}) => (
  <li className={className}>{children}</li>
)

DropdownItem.propTypes = {
  children: PropTypes.node,
  className: PropTypes.string
}

export class DropdownDropdownCheckboxItem extends Component {
  static propTypes = {
    onClick: PropTypes.func,
    defaultChecked: PropTypes.bool,
    id: PropTypes.string,
    displayText: PropTypes.string
  }

  componentDidMount() {
    const { onClick } = this.props
    $(this.refs.li).on('click', function(event) {
      // Prevent the menu from closing
      event.stopPropagation()
    })
    $(this.refs.input).on('click', function(event) {
      // Prevent the menu from closing
      event.preventDefault()
      onClick()
    })
  }

  render() {
    const { defaultChecked, id, displayText } = this.props
    return (
      <li ref='li' className='checkbox'>
        <input
          id={id}
          ref='input'
          type='checkbox'
          defaultChecked={defaultChecked}
          className='filled-in'
        />
        <label htmlFor={id}>{displayText}</label>
      </li>
    )
  }
}

export const DropdownDivider = () => (
  <li className='divider' />
)
