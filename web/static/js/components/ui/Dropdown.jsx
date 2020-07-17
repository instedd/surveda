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

export class DropdownItem extends Component {
  static propTypes = {
    className: PropTypes.string,
    children: PropTypes.node,
    onClickKeepMenuOpen: PropTypes.bool,
    onClick: PropTypes.func
  }

  componentDidMount() {
    const { onClick, onClickKeepMenuOpen } = this.props
    if (onClickKeepMenuOpen) {
      $(this.refs.node).on('click', function(event) {
        if (onClick) onClick()
        event.stopPropagation()
      })
    }
  }

  render() {
    const { className, children } = this.props
    return <li className={className} ref='node'>{children}</li>
  }
}

export const DropdownDivider = () => (
  <li className='divider' />
)
