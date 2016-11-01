import { uniqueId } from 'lodash'
import React, { Component, PropTypes } from 'react'
export class Dropdown extends Component {
  static propTypes = {
    label: PropTypes.node.isRequired,
    icon: PropTypes.string,
    children: PropTypes.node,
    constrainWidth: PropTypes.bool
  }

  componentDidMount() {
    $('.dropdown-button').dropdown()
  }

  render() {
    const {label, icon = 'arrow_drop_down', children, constrainWidth = true} = this.props
    const dropdownId = uniqueId('dropdown')
    const onButtonClick = (event) => {
      event.preventDefault()
    }

    return (
      <span>
        <a className='dropdown-button' href='#!' onClick={onButtonClick} data-induration='100' data-outduration='50' data-beloworigin='true' data-activates={dropdownId} data-constrainwidth={constrainWidth}>
          {label}
          <i className='material-icons right'>{icon}</i>
        </a>
        <ul id={dropdownId} className='dropdown-content'>
          {children}
        </ul>
      </span>
    )
  }
}

export const DropdownItem = ({children}) => (
  <li>{children}</li>
)

DropdownItem.propTypes = {
  children: PropTypes.node
}

export const DropdownDivider = () => (
  <li className='divider' />
)
