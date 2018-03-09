import React from 'react'
import { Input } from 'react-materialize'
import values from 'lodash/values'
import { channelFriendlyName } from '../../channelFriendlyName'

export const NewRespondentChannel = (mode, allChannels, currentChannels, onChange, readOnly, surveyStarted) => {
  const currentChannel = currentChannels.find(channel => channel.mode == mode) || {}

  const type = mode == 'mobileweb' ? 'sms' : mode

  let label
  if (mode == 'mobileweb') {
    label = 'SMS for mobile web'
  } else if (mode == 'sms') {
    label = 'SMS'
  } else {
    label = 'Phone'
  }
  label += ' channel'

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
            Select a channel...
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
