import React, { PropTypes } from 'react'
import { Card, channelFriendlyName } from '../ui'
import Dropzone from 'react-dropzone'
import { dropzoneProps } from './RespondentsDropzone'
import { Input } from 'react-materialize'
import values from 'lodash/values'
import { translate } from 'react-i18next'

export const RespondentsList = translate()(({ survey, group, add, remove, channels, modes, onChannelChange, onDrop, readOnly, surveyStarted, children, t }) => {
  let footer = null
  if (add || remove) {
    footer = (
      <div className='card-action'>
        <div className='row'>
          <div className='col s6 left-align'>
            {add}
          </div>
          <div className='col s6 right-align'>
            {remove}
          </div>
        </div>
      </div>
    )
  }

  let currentChannels = group.channels || []
  let channelsComponent = []
  for (const targetMode of modes) {
    channelsComponent.push(NewRespondentChannel(targetMode, channels, currentChannels, onChannelChange, readOnly, surveyStarted, t))
  }

  let card = (
    <Card>
      <div className='card-content'>
        <div className='row'>
          <div className='col s6'>
            <table className='ncdtable'>
              <thead>
                <tr>
                  <th>{t('{{groupName}} ({{count}} contact)', {groupName: group.name, count: group.respondentsCount})}</th>
                </tr>
              </thead>
              <tbody>
                {children}
              </tbody>
            </table>
          </div>
          <div className='col s6'>
            <table className='ncdtable'>
              <thead>
                <tr>
                  <th>{t('Channels')}</th>
                </tr>
              </thead>
              <tbody>
                <tr>
                  <td>{channelsComponent}</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>
      {footer}
    </Card>
  )

  // Only enable dropzone on existing respondent groups if the survey has not finished
  if (readOnly || survey.state == 'terminated') {
    return card
  } else {
    return (
      <Dropzone {...dropzoneProps()} className='dropfile-existing' onDrop={onDrop} disableClick>
        {card}
      </Dropzone>
    )
  }
})

RespondentsList.propTypes = {
  survey: PropTypes.object,
  group: PropTypes.object,
  modes: PropTypes.any,
  readOnly: PropTypes.bool,
  surveyStarted: PropTypes.bool,
  add: PropTypes.node,
  remove: PropTypes.node,
  channels: PropTypes.any,
  onChannelChange: PropTypes.func,
  children: PropTypes.node,
  onDrop: PropTypes.func
}

const NewRespondentChannel = (mode, allChannels, currentChannels, onChange, readOnly, surveyStarted, t) => {
  const currentChannel = currentChannels.find(channel => channel.mode == mode) || {}

  const type = mode == 'mobileweb' ? 'sms' : mode

  let label
  if (mode == 'mobileweb') {
    label = t('SMS for mobile web channel')
  } else if (mode == 'sms') {
    label = t('SMS channel')
  } else {
    label = t('Phone channel')
  }

  let channels = values(allChannels)
  channels = channels.filter(c => c.type == type)

  return (
    <div className='row' key={mode}>
      <div className='input-field col s12'>
        <Input s={12} type='select' label={label}
          value={currentChannel.id || ''}
          onChange={e => onChange(e, mode, allChannels)}
          disabled={readOnly || surveyStarted}>
          <option value=''>
            {t('Select a channel...')}
          </option>
          { channels.map((channel) =>
            <option key={channel.id} value={channel.id}>
              {channel.name + channelFriendlyName(channel)}
            </option>
          )}
        </Input>
      </div>
    </div>
  )
}
