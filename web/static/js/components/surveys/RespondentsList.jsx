import React, { PropTypes } from 'react'
import { Card } from '../ui'
import Dropzone from 'react-dropzone'
import { NewRespondentChannel } from './NewRespondentChannel'
import { dropzoneProps } from './RespondentsDropzone'

export const RespondentsList = ({ survey, group, add, remove, channels, modes, onChannelChange, onDrop, readOnly, surveyStarted, children }) => {
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
    channelsComponent.push(NewRespondentChannel(targetMode, channels, currentChannels, onChannelChange, readOnly, surveyStarted))
  }

  let card = (
    <Card>
      <div className='card-content'>
        <div className='row'>
          <div className='col s6'>
            <table className='ncdtable'>
              <thead>
                <tr>
                  <th>{group.name} ({group.respondentsCount} contacts)</th>
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
                  <th>Channels</th>
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
}

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
