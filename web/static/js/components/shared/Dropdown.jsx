import React, { PropTypes} from 'react'
import { uniqueId } from 'lodash'

export const Dropdown = ({text, icon = 'arrow_drop_down', children}) => {
  const dropdownId = uniqueId('dropdown')
  const onButtonClick = (event) => {
    event.preventDefault()
  }

  return (
    <div>
      <a className='dropdown-button' href='#!' onClick={onButtonClick} data-induration='100' data-outduration='50' data-beloworigin='true' data-activates={dropdownId}>
        {text}
        <i className='material-icons right'>{icon}</i>
      </a>
      <ul id={dropdownId} className='dropdown-content'>
        {children}
      </ul>
    </div>
  )
}

Dropdown.propTypes = {
  text: PropTypes.string.isRequired,
  icon: PropTypes.string,
  children: PropTypes.node
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
