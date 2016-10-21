import React, { PropTypes, Component } from 'react'
import { connect } from 'react-redux'
import Dropzone from 'react-dropzone'
import ConfirmationModal from '../components/ConfirmationModal'
import { uploadRespondents, removeRespondents } from '../api'
import * as actions from '../actions/surveyEdit'
import * as surveyActions from '../actions/surveys'
import * as respondentsActions from '../actions/respondents'

class SurveyWizardRespondentsStep extends Component {
  static propTypes = {
    survey: PropTypes.object,
    respondents: PropTypes.object.isRequired,
    respondentsCount: PropTypes.any.isRequired,
    dispatch: PropTypes.func.isRequired
  }

  handleSubmit(survey, files) {
    const { dispatch } = this.props
    uploadRespondents(survey, files)
      .then(respondents => {
        dispatch(respondentsActions.receiveRespondents(respondents))
        dispatch(actions.updateRespondentsCount(Object.keys(respondents).length))
        dispatch(surveyActions.fetchSurvey(survey.projectId, survey.id))
          .then(survey => dispatch(actions.setState(survey.state)))
          .catch((e) => dispatch(surveyActions.receiveSurveysError(e)))
      })
  }

  removeRespondents(event) {
    const { dispatch, survey } = this.props
    event.preventDefault()
    removeRespondents(survey)
      .then(respondents => {
        dispatch(respondentsActions.removeRespondents(respondents))
        dispatch(actions.updateRespondentsCount(0))
        dispatch(surveyActions.fetchSurvey(survey.projectId, survey.id))
          .then(survey => dispatch(actions.setState(survey.state)))
          .catch((e) => dispatch(surveyActions.receiveSurveysError(e)))
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
          <ConfirmationModal showLink modalId='removeRespondents' linkText='REMOVE RESPONDENTS' modalText="Are you sure you want to delete the respondents list? If you confirm, we won't be able to recover it. You will have to upload a new one." header='Please confirm that you want to delete the respondents list' confirmationText='DELETE THE RESPONDENTS LIST' style={{maxWidth: '600px'}} onConfirm={(event) => this.removeRespondents(event)} />
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

RespondentsDropzone.propTypes = {
  survey: PropTypes.object,
  onDrop: PropTypes.func.isRequired
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

const mapStateToProps = (state, ownProps) => {
  return {
    respondentsCount: state.respondentsCount
  }
}

export default connect(mapStateToProps)(SurveyWizardRespondentsStep)
