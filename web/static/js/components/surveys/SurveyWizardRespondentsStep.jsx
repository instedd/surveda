import React, { PropTypes, Component } from 'react'
import { bindActionCreators } from 'redux'
import { connect } from 'react-redux'
import Dropzone from 'react-dropzone'
import { Input, Preloader } from 'react-materialize'
import { ConfirmationModal, Card } from '../ui'
import * as actions from '../../actions/respondentGroups'
import values from 'lodash/values'
import uniq from 'lodash/uniq'
import flatMap from 'lodash/flatMap'

class SurveyWizardRespondentsStep extends Component {
  static propTypes = {
    survey: PropTypes.object,
    respondentGroups: PropTypes.object.isRequired,
    respondentGroupsUploading: PropTypes.bool,
    invalidRespondents: PropTypes.object,
    channels: PropTypes.object,
    actions: PropTypes.object.isRequired,
    readOnly: PropTypes.bool.isRequired,
    surveyStarted: PropTypes.bool.isRequired
  }

  handleSubmit(files) {
    const { survey, actions } = this.props
    if (files.length > 0) actions.uploadRespondentGroup(survey.projectId, survey.id, files)
  }

  addMoreRespondents(groupId, file) {
    const { survey, actions } = this.props
    actions.addMoreRespondentsToGroup(survey.projectId, survey.id, groupId, file)
  }

  replaceRespondents(groupId, file) {
    const { survey, actions } = this.props
    actions.replaceRespondents(survey.projectId, survey.id, groupId, file)
  }

  removeRespondents(groupId) {
    const { survey, actions } = this.props
    actions.removeRespondentGroup(survey.projectId, survey.id, groupId)
  }

  clearInvalids(e) {
    e.preventDefault()

    this.props.actions.clearInvalids()
  }

  invalidRespondentsContent(data) {
    if (!data) return null

    const invalidEntriesText = data.invalidEntries.length === 1 ? 'An invalid entry was found at line ' : 'Invalid entries were found at lines '
    const lineNumbers = data.invalidEntries.slice(0, 3).map((entry) => entry.line_number)
    const extraLinesCount = data.invalidEntries.length - lineNumbers.length
    const lineNumbersText = lineNumbers.join(', ') + (extraLinesCount > 0 ? ' and ' + String(extraLinesCount) + ' more.' : '')
    return (
      <Card>
        <div className='card-content card-error'>
          <div><b>Errors found at '{data.filename}', file was not imported</b></div>
          <div>{invalidEntriesText} {lineNumbersText}</div>
          <div>Please fix those errors and upload again.</div>
        </div>
        <div className='card-action right-align'>
          <a className='blue-text' href='#' onClick={e => this.clearInvalids(e)}>
            UNDERSTOOD
          </a>
        </div>
      </Card>
    )
  }

  channelChange(e, group, mode, allChannels) {
    e.preventDefault()

    let currentChannels = group.channels || []
    currentChannels = currentChannels.filter(channel => channel.mode != mode)
    if (e.target.value != '') {
      currentChannels.push({
        mode: mode,
        id: parseInt(e.target.value)
      })
    }

    const { actions, survey } = this.props
    actions.selectChannels(survey.projectId, survey.id, group.id, currentChannels)
  }

  openAddOrReplaceModal(group, files) {
    if (files.length < 1) return
    const file = files[0]

    const { survey } = this.props

    // If the survey is running, the only option is to add more respondents
    if (survey.state == 'running') {
      this.addMoreRespondents(group.id, file)
      return
    }

    const addOrReplaceModal = this.refs.addOrReplaceModal
    addOrReplaceModal.open({
      modalText: <div>
        <p>Do you want to add more respondents to this group or completely replace them?</p>
      </div>,
      confirmationText: 'Add',
      noText: 'Replace',
      onConfirm: e => {
        this.addMoreRespondents(group.id, file)
        addOrReplaceModal.close()
      },
      onNo: e => {
        this.replaceRespondents(group.id, file)
        addOrReplaceModal.close()
      },
      showCancel: true
    })
  }

  renderGroup(group, channels, allModes, readOnly, surveyStarted) {
    let removeRespondents = null
    let addMoreRespondents = null

    const { survey } = this.props

    if (!readOnly) {
      const addMoreInputId = `addMoreRespondents${group.id}`

      const addMoreClck = (e) => {
        e.preventDefault()
        $(`#${addMoreInputId}`).click()
      }

      const addMore = (e) => {
        e.preventDefault()

        const files = e.target.files
        if (files.length < 1) return

        const file = files[0]
        this.addMoreRespondents(group.id, file)
      }

      if (!surveyFinished(survey)) {
        addMoreRespondents = [
          <input key='x' id={addMoreInputId} type='file' accept='.csv' style={{display: 'none'}} onChange={e => addMore(e)} />,
          <a key='y' href='#' onClick={addMoreClck} className='blue-text'>ADD MORE RESPONDENTS</a>
        ]
      }

      if (!surveyStarted) {
        removeRespondents = <ConfirmationModal showLink
          modalId={`removeRespondents${group.id}`} linkText='REMOVE RESPONDENTS'
          modalText="Are you sure you want to delete the respondents list? If you confirm, we won't be able to recover it. You will have to upload a new one."
          header='Please confirm that you want to delete the respondents list'
          confirmationText='DELETE THE RESPONDENTS LIST'
          style={{maxWidth: '600px'}} showCancel
          onConfirm={() => this.removeRespondents(group.id)} />
      }
    }

    return (
      <RespondentsList key={group.id} survey={survey} group={group} add={addMoreRespondents} remove={removeRespondents} modes={allModes}
        channels={channels} readOnly={readOnly} surveyStarted={surveyStarted}
        onChannelChange={(e, type, allChannels) => this.channelChange(e, group, type, allChannels)}
        onDrop={files => this.openAddOrReplaceModal(group, files)}
        >
        {group.sample.map((respondent, index) =>
          <PhoneNumberRow id={respondent} phoneNumber={respondent} key={index} />
        )}
      </RespondentsList>
    )
  }

  render() {
    let { survey, channels, respondentGroups, respondentGroupsUploading, invalidRespondents, readOnly, surveyStarted } = this.props
    let invalidRespondentsCard = this.invalidRespondentsContent(invalidRespondents)
    if (!survey || !channels) {
      return <div>Loading...</div>
    }

    const mode = survey.mode || []
    const allModes = uniq(flatMap(mode))

    let respondentsDropzone = null
    if (!readOnly && !surveyStarted) {
      respondentsDropzone = (
        <RespondentsDropzone survey={survey} uploading={respondentGroupsUploading} onDrop={file => this.handleSubmit(file)} onDropRejected={() => $('#invalidTypeFile').modal('open')} />
      )
    }

    return (
      <RespondentsContainer>
        {Object.keys(respondentGroups).map(groupId => this.renderGroup(respondentGroups[groupId], channels, allModes, readOnly, surveyStarted))}

        <ConfirmationModal modalId='addOrReplaceGroup' ref='addOrReplaceModal' header='Add or replace respondents' />
        <ConfirmationModal modalId='invalidTypeFile' modalText='The system only accepts CSV files' header='Invalid file type' confirmationText='accept' style={{maxWidth: '600px'}} />
        {invalidRespondentsCard || respondentsDropzone}
      </RespondentsContainer>
    )
  }
}

const RespondentsDropzone = ({ survey, uploading, onDrop, onDropRejected }) => {
  let className = 'drop-text csv'
  if (uploading) className += ' uploading'

  let icon = null
  if (uploading) {
    icon = (
      <div className='drop-uploading'>
        <div className='preloader-wrapper active center'>
          <Preloader />
        </div>
      </div>
    )
  } else {
    icon = <div className='drop-icon' />
  }

  return (
    <Dropzone {...dropzoneProps()} className='dropfile' onDrop={onDrop} onDropRejected={onDropRejected}>
      {icon}
      <div className={className} />
    </Dropzone>
  )
}

const dropzoneProps = () => {
  let commonProps = {activeClassName: 'active', rejectClassName: 'rejectedfile', multiple: false, accept: 'text/csv'}
  var isWindows = navigator.platform && navigator.platform.indexOf('Win') != -1
  if (isWindows) {
    commonProps = {
      ...commonProps,
      accept: '.csv',
      rejectClassName: ''
    }
  }
  return commonProps
}

RespondentsDropzone.propTypes = {
  survey: PropTypes.object,
  uploading: PropTypes.bool,
  onDrop: PropTypes.func.isRequired,
  onDropRejected: PropTypes.func.isRequired
}

const newChannelComponent = (mode, allChannels, currentChannels, onChange, readOnly, surveyStarted) => {
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
              {channel.name}
            </option>
              )}
        </Input>
      </div>
    </div>
  )
}

const RespondentsList = ({ survey, group, add, remove, channels, modes, onChannelChange, onDrop, readOnly, surveyStarted, children }) => {
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
    channelsComponent.push(newChannelComponent(targetMode, channels, currentChannels, onChannelChange, readOnly, surveyStarted))
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
  if (readOnly || surveyFinished(survey)) {
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

const PhoneNumberRow = ({ id, phoneNumber }) => {
  return (
    <tr key={id}>
      <td>
        {phoneNumber}
      </td>
    </tr>
  )
}

PhoneNumberRow.propTypes = {
  id: PropTypes.string,
  phoneNumber: PropTypes.string
}

const RespondentsContainer = ({ children }) => {
  return (
    <div>
      <div className='row'>
        <div className='col s12'>
          <h4>Upload your respondents list</h4>
          <p className='flow-text'>
            Upload a CSV file like
            <a href='#' onClick={(e) => { e.preventDefault(); window.open('/files/phone_numbers_example.csv') }} download='phone_numbers_example.csv'> this one </a>
            with your respondents. You can define how many of these respondents need to successfully answer the survey by setting up cutoff rules.
          </p>
        </div>
      </div>
      <div className='row'>
        <div className='col s12'>
          {children}
        </div>
      </div>
    </div>
  )
}

RespondentsContainer.propTypes = {
  children: PropTypes.node
}

const mapDispatchToProps = (dispatch) => ({
  actions: bindActionCreators(actions, dispatch)
})

const surveyFinished = (survey) => {
  return survey.state == 'completed' || survey.state == 'cancelled'
}

export default connect(null, mapDispatchToProps)(SurveyWizardRespondentsStep)
