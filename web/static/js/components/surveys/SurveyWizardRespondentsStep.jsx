import React, { PropTypes, Component } from 'react'
import { bindActionCreators } from 'redux'
import { connect } from 'react-redux'
import { Preloader } from 'react-materialize'
import { ConfirmationModal, Card } from '../ui'
import * as actions from '../../actions/respondentGroups'
import uniq from 'lodash/uniq'
import flatten from 'lodash/flatten'
import { RespondentsList } from './RespondentsList'
import { RespondentsDropzone } from './RespondentsDropzone'
import { RespondentsContainer } from './RespondentsContainer'
import { PhoneNumberRow } from './PhoneNumberRow'

class SurveyWizardRespondentsStep extends Component {
  static propTypes = {
    survey: PropTypes.object,
    respondentGroups: PropTypes.object.isRequired,
    respondentGroupsUploading: PropTypes.bool,
    respondentGroupsUploadingExisting: PropTypes.object,
    invalidRespondents: PropTypes.object,
    invalidGroup: PropTypes.bool,
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

    let { surveyStarted } = this.props
    if (surveyStarted) return

    let content = null

    if (data.invalidEntries.length == 0) {
      content = (
        <div className='card-content card-error'>
          <div><b>The file you uploaded does not contain any phone number.</b></div>
          <div>Please upload antother file.</div>
        </div>
      )
    } else {
      const invalidEntriesText = data.invalidEntries.length === 1 ? 'An invalid entry was found at line ' : 'Invalid entries were found at lines '
      const lineNumbers = data.invalidEntries.slice(0, 3).map((entry) => entry.line_number)
      const extraLinesCount = data.invalidEntries.length - lineNumbers.length
      const lineNumbersText = lineNumbers.join(', ') + (extraLinesCount > 0 ? ' and ' + String(extraLinesCount) + ' more.' : '')

      content = (
        <div className='card-content card-error'>
          <div><b>Errors found at '{data.filename}', file was not imported</b></div>
          <div>{invalidEntriesText} {lineNumbersText}</div>
          <div>Please fix those errors and upload again.</div>
        </div>
      )
    }

    return (
      <Card>
        <div className='card-content card-error'>
          {content}
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

  renderGroup(group, channels, allModes, readOnly, surveyStarted, uploading) {
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

      if (!survey.state == 'terminated') {
        if (uploading) {
          addMoreRespondents = <Preloader size='small' className='tiny' />
        } else {
          addMoreRespondents = [
            <input key='x' id={addMoreInputId} type='file' accept='.csv' style={{display: 'none'}} onChange={e => addMore(e)} />,
            <a key='y' href='#' onClick={addMoreClck} className='blue-text'>ADD MORE RESPONDENTS</a>
          ]
        }
      }

      if (!surveyStarted && !uploading) {
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

  componentWillReceiveProps(props) {
    // Check if any respondent group's respondentsCount changed, to show a toast
    const groups = this.props.respondentGroups
    if (!groups) return

    for (const id in groups) {
      const group = groups[id]
      const newGroup = props.respondentGroups && props.respondentGroups[id]
      if (!newGroup) continue

      const diff = newGroup.respondentsCount - group.respondentsCount
      if (diff == 1) {
        window.Materialize.toast('1 respondent has been added', 5000)
      } else if (diff > 0) {
        window.Materialize.toast(`${diff} respondents have been added`, 5000)
      }
    }
  }

  componentDidUpdate() {
    let { actions, invalidGroup } = this.props
    if (invalidGroup) {
      window.Materialize.toast("Couldn't upload CSV: it contains rows that are not phone numbers", 5000)
      actions.clearInvalidsRespondentsForGroup()
    }
  }

  render() {
    let { survey, channels, respondentGroups, respondentGroupsUploading, respondentGroupsUploadingExisting, invalidRespondents, readOnly, surveyStarted } = this.props
    let invalidRespondentsCard = this.invalidRespondentsContent(invalidRespondents)
    if (!survey || !channels) {
      return <div>Loading...</div>
    }

    const mode = survey.mode || []
    const allModes = uniq(flatten(mode))

    let respondentsDropzone = null
    if (!readOnly && !surveyStarted) {
      respondentsDropzone = (
        <RespondentsDropzone survey={survey} uploading={respondentGroupsUploading} onDrop={file => this.handleSubmit(file)} onDropRejected={() => $('#invalidTypeFile').modal('open')} />
      )
    }

    return (
      <RespondentsContainer>
        {Object.keys(respondentGroups).map(groupId => this.renderGroup(respondentGroups[groupId], channels, allModes, readOnly, surveyStarted, respondentGroupsUploadingExisting[groupId]))}

        <ConfirmationModal modalId='addOrReplaceGroup' ref='addOrReplaceModal' header='Add or replace respondents' />
        <ConfirmationModal modalId='invalidTypeFile' modalText='The system only accepts CSV files' header='Invalid file type' confirmationText='accept' style={{maxWidth: '600px'}} />
        {invalidRespondentsCard || respondentsDropzone}
      </RespondentsContainer>
    )
  }
}

const mapDispatchToProps = (dispatch) => ({
  actions: bindActionCreators(actions, dispatch)
})

export default connect(null, mapDispatchToProps)(SurveyWizardRespondentsStep)
