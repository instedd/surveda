import React, { PropTypes, Component } from 'react'
import { connect } from 'react-redux'
import Dropzone from 'react-dropzone'
import { ConfirmationModal } from '../components/ConfirmationModal'
import { uploadRespondents, removeRespondents } from '../api'
import * as actions from '../actions/surveyEdit'
import * as respondentsActions from '../actions/respondents'

class SurveyWizardRespondentsStep extends Component {
  static propTypes = {
    survey: PropTypes.object,
    respondents: PropTypes.object.isRequired,
    respondentsCount: PropTypes.number.isRequired,
    dispatch: PropTypes.func.isRequired
  }

  handleSubmit(survey, files) {
    const { dispatch } = this.props
    uploadRespondents(survey, files)
      .then(respondents => {
        dispatch(respondentsActions.receiveRespondents(respondents))
        dispatch(actions.updateRespondentsCount(Object.keys(respondents).length))
      })
  }

  removeRespondents(event) {
    const { dispatch, survey } = this.props
    event.preventDefault()
    removeRespondents(survey)
      .then(respondents => {
        dispatch(respondentsActions.removeRespondents(respondents))
        dispatch(actions.updateRespondentsCount(0))
      })
  }

  render() {
    const { survey, respondentsCount, respondents } = this.props

    if (!survey) {
      return <div>Loading...</div>
    }

    if (respondentsCount !== 0) {
      return (
        <RespondentsContainer>
          <RespondentsList respondentsCount={respondentsCount}>
            {Object.keys(respondents).map((respondentId) =>
              <PhoneNumberRow id={respondentId} phoneNumber={respondents[respondentId].phoneNumber} key={respondentId} />
            )}
          </RespondentsList>
          <ConfirmationModal showLink modalId='removeRespondents' linkText='REMOVE RESPONDENTS' modalText='Are you sure?' header='Please confirm' confirmationText='Delete all' onConfirm={(event) => this.removeRespondents(event)} />
        </RespondentsContainer>
      )
    } else {
      return (
        <RespondentsContainer>
          <RespondentsDropzone survey={survey} onDrop={file => { this.handleSubmit(survey, file) }} />
        </RespondentsContainer>
      )
    }
  }
}

const RespondentsDropzone = ({ survey, onDrop }) => {
  return (
    <Dropzone className='dropfile' activeClassName='active' rejectClassName='rejectedfile' multiple={false} onDrop={onDrop} accept='text/csv'>
      <div className='drop-icon' />
      <div className='drop-text' />
    </Dropzone>
  )
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

const PhoneNumberRow = ({ id, phoneNumber }) => {
  return (
    <tr key={id}>
      <td>
        {phoneNumber}
      </td>
    </tr>
  )
}

const RespondentsContainer = ({ children }) => {
  return (
    <div>
      <div className='row'>
        <div className='col s12'>
          <h4 id='respondents'>Upload your respondents list</h4>
          <p className='flow-text'>
            Upload a CSV file like this one with your respondents. You can define how many of these respondents need to successfully answer the survey by setting up cutoff rules.
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

const mapStateToProps = (state, ownProps) => {
  return {
    respondentsCount: state.respondentsCount
  }
}

export default connect(mapStateToProps)(SurveyWizardRespondentsStep)
