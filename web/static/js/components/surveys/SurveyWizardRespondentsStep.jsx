import React, { PropTypes, Component } from 'react'
import { connect } from 'react-redux'
import Dropzone from 'react-dropzone'
import { ConfirmationModal, Card } from '../ui'
import { uploadRespondents, removeRespondents } from '../../api'
import * as actions from '../../actions/survey'
import * as respondentsActions from '../../actions/respondents'

class SurveyWizardRespondentsStep extends Component {
  static propTypes = {
    survey: PropTypes.object,
    respondents: PropTypes.object.isRequired,
    dispatch: PropTypes.func.isRequired
  }

  handleSubmit(survey, files) {
    const { dispatch } = this.props
    uploadRespondents(survey, files)
      .then(response => {
        dispatch(respondentsActions.receiveRespondents(survey.id, 1, response.entities.respondents || {}, response.respondentsCount))
        dispatch(actions.updateRespondentsCount(response.respondentsCount))
        dispatch(actions.save())
      }, (e) => {
        e.json().then((value) => {
          dispatch(respondentsActions.receiveInvalids(value))
        })
      })
  }

  removeRespondents(event) {
    const { dispatch, survey } = this.props
    event.preventDefault()
    removeRespondents(survey)
      .then(respondents => {
        dispatch(respondentsActions.removeRespondents(respondents))
        dispatch(actions.updateRespondentsCount(0))
        dispatch(actions.save())
      })
  }

  clearInvalids() {
    const { dispatch } = this.props
    dispatch(respondentsActions.clearInvalids())
  }

  invalidRespondentsContent(data) {
    if (data) {
      const invalidEntriesText = data.invalidEntries.length === 1 ? 'An invalid entry was found at line ' : 'Invalid entries were found at lines '
      const lineNumbers = data.invalidEntries.slice(0, 3).map((entry) => entry.line_number)
      const extraLinesCount = data.invalidEntries.length - lineNumbers.length
      const lineNumbersText = lineNumbers.join(', ') + (extraLinesCount > 0 ? ' and ' + String(extraLinesCount) + ' more.' : '')
      return (
        <div className='csv-errors'>
          <div>Errors found at '{data.filename}', file was not imported</div>
          <div>{invalidEntriesText} {lineNumbersText}</div>
          <div>Please fix those errors and upload again.</div>
          <a className='' href='#' onClick={() => this.clearInvalids()}>
            UNDERSTOOD
          </a>
        </div>
      )
    }
  }

  render() {
    let { survey, respondents } = this.props
    let invalidRespondentsCard = this.invalidRespondentsContent(respondents.invalidRespondents)
    if (!survey) {
      return <div>Loading...</div>
    }

    if (survey.respondentsCount != 0) {
      return (
        <RespondentsContainer>
          <RespondentsList respondentsCount={survey.respondentsCount}>
            {Object.keys(respondents.items || {}).map((respondentId) =>
              <PhoneNumberRow id={respondentId} phoneNumber={respondents.items[respondentId].phoneNumber} key={respondentId} />
            )}
          </RespondentsList>
          <ConfirmationModal showLink modalId='removeRespondents' linkText='REMOVE RESPONDENTS' modalText="Are you sure you want to delete the respondents list? If you confirm, we won't be able to recover it. You will have to upload a new one." header='Please confirm that you want to delete the respondents list' confirmationText='DELETE THE RESPONDENTS LIST' style={{maxWidth: '600px'}} showCancel onConfirm={(event) => this.removeRespondents(event)} />
        </RespondentsContainer>
      )
    } else {
      return (
        <RespondentsContainer>
          <ConfirmationModal modalId='invalidTypeFile' modalText='The system only accepts CSV files' header='Invalid file type' confirmationText='accept' onConfirm={(event) => event.preventDefault()} style={{maxWidth: '600px'}} />
          <Card>
            { invalidRespondentsCard }
          </Card>
          <RespondentsDropzone survey={survey} onDrop={file => this.handleSubmit(survey, file)} onDropRejected={() => $('#invalidTypeFile').modal('open')} />
        </RespondentsContainer>
      )
    }
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

const RespondentsList = ({ respondentsCount, children }) => {
  return (
    <table className='ncdtable'>
      <thead>
        <tr>
          <th>
            {`${respondentsCount} contacts imported`}
          </th>
        </tr>
      </thead>
      <tbody>
        {children}
      </tbody>
    </table>
  )
}

RespondentsList.propTypes = {
  respondentsCount: PropTypes.any.isRequired,
  children: PropTypes.node
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

export default connect()(SurveyWizardRespondentsStep)
