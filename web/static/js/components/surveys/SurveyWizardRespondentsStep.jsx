import React, { PropTypes, Component } from 'react'
import { bindActionCreators } from 'redux'
import { connect } from 'react-redux'
import Dropzone from 'react-dropzone'
import { ConfirmationModal, Card } from '../ui'
import * as actions from '../../actions/respondentGroups'

class SurveyWizardRespondentsStep extends Component {
  static propTypes = {
    survey: PropTypes.object,
    respondentGroups: PropTypes.object.isRequired,
    invalidRespondents: PropTypes.object,
    actions: PropTypes.object.isRequired,
    readOnly: PropTypes.bool.isRequired
  }

  handleSubmit(files) {
    const { survey, actions } = this.props
    actions.uploadRespondentGroup(survey.projectId, survey.id, files)
  }

  removeRespondents(event, groupId) {
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

  renderGroup(group, readOnly) {
    let removeRespondents = null
    if (!readOnly) {
      removeRespondents = <ConfirmationModal showLink
        modalId={`removeRespondents${group.id}`} linkText='REMOVE RESPONDENTS'
        modalText="Are you sure you want to delete the respondents list? If you confirm, we won't be able to recover it. You will have to upload a new one."
        header='Please confirm that you want to delete the respondents list'
        confirmationText='DELETE THE RESPONDENTS LIST'
        style={{maxWidth: '600px'}} showCancel
        onConfirm={e => this.removeRespondents(e, group.id)} />
    }

    return (
      <RespondentsList key={group.id} name={group.name} count={group.respondentsCount}
        remove={removeRespondents}>
        {group.sample.map((respondent, index) =>
          <PhoneNumberRow id={respondent} phoneNumber={respondent} key={index} />
        )}
      </RespondentsList>
    )
  }

  render() {
    let { survey, respondentGroups, invalidRespondents, readOnly } = this.props
    let invalidRespondentsCard = this.invalidRespondentsContent(invalidRespondents)
    if (!survey) {
      return <div>Loading...</div>
    }

    let respondentsDropzone = null
    if (!readOnly) {
      respondentsDropzone = (
        <RespondentsDropzone survey={survey} onDrop={file => this.handleSubmit(file)} onDropRejected={() => $('#invalidTypeFile').modal('open')} />
      )
    }

    return (
      <RespondentsContainer>
        {Object.keys(respondentGroups).map(groupId => this.renderGroup(respondentGroups[groupId], readOnly))}

        <ConfirmationModal modalId='invalidTypeFile' modalText='The system only accepts CSV files' header='Invalid file type' confirmationText='accept' onConfirm={(event) => event.preventDefault()} style={{maxWidth: '600px'}} />
        {invalidRespondentsCard || respondentsDropzone}
      </RespondentsContainer>
    )
  }
}

const RespondentsDropzone = ({ survey, onDrop, onDropRejected }) => {
  return (
    <Dropzone className='dropfile' activeClassName='active' multiple={false} onDrop={onDrop} accept='.csv' onDropRejected={onDropRejected} >
      <div className='drop-icon' />
      <div className='drop-text csv' />
    </Dropzone>
  )
}

RespondentsDropzone.propTypes = {
  survey: PropTypes.object,
  onDrop: PropTypes.func.isRequired,
  onDropRejected: PropTypes.func.isRequired
}

const RespondentsList = ({ count, name, remove, children }) => {
  let footer = null
  if (remove) {
    footer = (
      <div className='card-action'>
        {remove}
      </div>
    )
  }

  return (
    <Card>
      <div className='card-content'>
        <table className='ncdtable'>
          <thead>
            <tr>
              <th>
                {name} ({count} contacts)
              </th>
            </tr>
          </thead>
          <tbody>
            {children}
          </tbody>
        </table>
      </div>
      {footer}
    </Card>
  )
}

RespondentsList.propTypes = {
  count: PropTypes.number.isRequired,
  name: PropTypes.string.isRequired,
  children: PropTypes.node,
  remove: PropTypes.node
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

export default connect(null, mapDispatchToProps)(SurveyWizardRespondentsStep)
