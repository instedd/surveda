import React, { PropTypes } from 'react'
import i18n from '../../i18next'
import { Tooltip } from '../ui'
import { Input } from 'react-materialize'

export const ArchiveFilter = ({ archived, onChange }) => (
  <div className='row filterIndex'>
    <Input
      type='select'
      value={archived ? 'archived' : 'active'}
      onChange={event => onChange(event.target.value)}
    >
      <option key='archived' id='archived' name='archived' value='archived'>{i18n.t('Archived')}</option>
      <option key='active' id='active' name='active' value='active'>{i18n.t('Active')}</option>
    </Input>
  </div>
)

ArchiveFilter.propTypes = {
  archived: PropTypes.bool.isRequired,
  onChange: PropTypes.func.isRequired
}

export const ArchiveIcon = ({ archived, onClick }) => {
  const tooltipText = archived ? i18n.t('Unarchive') : i18n.t('Archive')
  const iconName = archived ? 'unarchive' : 'archive'
  return (
    <Tooltip text={tooltipText}>
      <a onClick={onClick}>
        <i className='material-icons'>{iconName}</i>
      </a>
    </Tooltip>
  )
}

ArchiveIcon.propTypes = {
  archived: PropTypes.bool.isRequired,
  onClick: PropTypes.func.isRequired
}
