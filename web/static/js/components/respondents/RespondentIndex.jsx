import React, { Component, PropTypes } from 'react'
import { bindActionCreators } from 'redux'
import { connect } from 'react-redux'
import * as actions from '../../actions/respondents'
import * as surveyActions from '../../actions/survey'
import * as questionnairesActions from '../../actions/questionnaires'
import range from 'lodash/range'
import values from 'lodash/values'
import { CardTable, Tooltip, UntitledIfEmpty } from '../ui'
import * as routes from '../../routes'
import dateformat from 'dateformat'
import { modeLabel } from '../../reducers/survey'

class RespondentIndex extends Component {
  componentDidMount() {
    const { projectId, surveyId, pageSize } = this.props
    if (projectId && surveyId) {
      this.props.surveyActions.fetchSurvey(projectId, surveyId)
      this.props.questionnairesActions.fetchQuestionnaires(projectId)
      this.props.actions.fetchRespondents(projectId, surveyId, pageSize, 1)
    }
  }

  nextPage(e) {
    e.preventDefault()

    const { projectId, surveyId, pageNumber, pageSize } = this.props
    this.props.actions.fetchRespondents(projectId, surveyId, pageSize, pageNumber + 1)
  }

  previousPage(e) {
    e.preventDefault()

    const { projectId, surveyId, pageNumber, pageSize } = this.props
    this.props.actions.fetchRespondents(projectId, surveyId, pageSize, pageNumber - 1)
  }

  downloadCSV() {
    const { projectId, surveyId } = this.props
    const offset = new Date().getTimezoneOffset()
    window.location = routes.respondentsCSV(projectId, surveyId, offset)
  }

  render() {
    if (!this.props.respondents || !this.props.survey || !this.props.questionnaires) {
      return <div>Loading...</div>
    }

    const { survey, questionnaires, totalCount } = this.props

    const hasComparisons = survey.comparisons.length > 0

    /* jQuery extend clones respondents object, in order to build an easy to manage structure without
    modify state */
    const respondents = generateResponsesDictionaryFor($.extend(true, {}, this.props.respondents))
    const respondentsList = values(respondents)

    function generateResponsesDictionaryFor(rs) {
      Object.keys(rs).forEach((respondentId, _) => {
        rs[respondentId].responses = responsesDictionaryFrom(rs[respondentId].responses)
      })
      return rs
    }

    function responsesDictionaryFrom(responseArray) {
      const res = {}
      for (const key in responseArray) {
        res[responseArray[key].name] = responseArray[key].value
      }
      return res
    }

    function allFieldNames(rs) {
      let fieldNames = Object.keys(rs).map((key) => (rs[key].responses))
      fieldNames = fieldNames.map((response) => Object.keys(response))
      return [].concat.apply([], fieldNames)
    }

    function hasResponded(rs, respondentId, fieldName) {
      return Object.keys(rs[respondentId].responses).includes(fieldName)
    }

    function responseOf(rs, respondentId, fieldName) {
      return hasResponded(rs, respondentId, fieldName) ? rs[respondentId].responses[fieldName] : '-'
    }

    const { startIndex, endIndex, hasPreviousPage, hasNextPage, pageSize } = this.props

    const title = `${totalCount} ${(totalCount == 1) ? ' respondent' : ' respondents'}`
    const footer = (
      <div className='card-action right-align'>
        <ul className='pagination'>
          <li><span className='grey-text'>{startIndex}-{endIndex} of {totalCount}</span></li>
          { hasPreviousPage
            ? <li><a href='#!' onClick={e => this.previousPage(e)}><i className='material-icons'>chevron_left</i></a></li>
            : <li className='disabled'><i className='material-icons'>chevron_left</i></li>
          }
          { hasNextPage
            ? <li><a href='#!' onClick={e => this.nextPage(e)}><i className='material-icons'>chevron_right</i></a></li>
            : <li className='disabled'><i className='material-icons'>chevron_right</i></li>
          }
        </ul>
      </div>
    )

    const respondentsFieldName = allFieldNames(respondents)

    let colspan = respondentsFieldName.length + 2
    let variantHeader = null
    if (hasComparisons) {
      variantHeader = <th>Variant</th>
      colspan += 1
    }

    return (
      <div className='white'>
        <Tooltip text='Download CSV'>
          <a className='btn-floating btn-large waves-effect waves-light green right mtop' onClick={() => this.downloadCSV()}>
            <i className='material-icons'>get_app</i>
          </a>
        </Tooltip>
        <CardTable title={title} footer={footer}>
          <thead>
            <tr>
              <th>Phone number</th>
              {respondentsFieldName.map(field =>
                <th key={field}>{field}</th>
              )}
              {variantHeader}
              <th>Date</th>
            </tr>
          </thead>
          <tbody>
            { range(0, pageSize).map(index => {
              const respondent = respondentsList[index]
              if (!respondent) return <tr key={-index} className='empty-row'><td colSpan={colspan} /></tr>

              let variantColumn = null
              if (hasComparisons) {
                let variantValue
                let questionnaire
                if (respondent.questionnaireId && respondent.mode && (questionnaire = questionnaires[respondent.questionnaireId])) {
                  const questionnaireName = <UntitledIfEmpty text={questionnaire.name} entityName='questionnaire' />
                  variantValue = <span>{questionnaireName} - {modeLabel(respondent.mode)}</span>
                } else {
                  variantValue = '-'
                }

                variantColumn = <td>{variantValue}</td>
              }

              return (
                <tr key={respondent.id}>
                  <td> {respondent.phoneNumber}</td>
                  {respondentsFieldName.map(function(field) {
                    return <td key={parseInt(respondent.id) + field}>{responseOf(respondents, respondent.id, field)}</td>
                  })}
                  {variantColumn}
                  <td>
                    {respondent.date ? dateformat(new Date(respondent.date), 'mmm d, yyyy HH:MM') : '-'}
                  </td>
                </tr>
              )
            })}
          </tbody>
        </CardTable>
      </div>
    )
  }
}

RespondentIndex.propTypes = {
  actions: PropTypes.object.isRequired,
  surveyActions: PropTypes.object.isRequired,
  questionnairesActions: PropTypes.object.isRequired,
  projectId: PropTypes.any,
  surveyId: PropTypes.any,
  survey: PropTypes.object,
  questionnaires: PropTypes.object,
  respondents: PropTypes.object,
  pageNumber: PropTypes.number.isRequired,
  pageSize: PropTypes.number.isRequired,
  startIndex: PropTypes.number.isRequired,
  endIndex: PropTypes.number.isRequired,
  totalCount: PropTypes.number.isRequired,
  hasPreviousPage: PropTypes.bool.isRequired,
  hasNextPage: PropTypes.bool.isRequired
}

const mapStateToProps = (state, ownProps) => {
  const pageNumber = state.respondents.page.number
  const pageSize = state.respondents.page.size
  const totalCount = state.respondents.page.totalCount
  const startIndex = (pageNumber - 1) * state.respondents.page.size + 1
  const endIndex = Math.min(startIndex + state.respondents.page.size - 1, totalCount)
  const hasPreviousPage = state.respondents.page.number > 1
  const hasNextPage = endIndex < totalCount
  return {
    projectId: ownProps.params.projectId,
    surveyId: ownProps.params.surveyId,
    respondents: state.respondents.items,
    survey: state.survey.data,
    questionnaires: state.questionnaires.items,
    pageNumber,
    pageSize,
    startIndex,
    endIndex,
    totalCount,
    hasPreviousPage,
    hasNextPage
  }
}

const mapDispatchToProps = (dispatch) => ({
  actions: bindActionCreators(actions, dispatch),
  surveyActions: bindActionCreators(surveyActions, dispatch),
  questionnairesActions: bindActionCreators(questionnairesActions, dispatch)
})

export default connect(mapStateToProps, mapDispatchToProps)(RespondentIndex)
