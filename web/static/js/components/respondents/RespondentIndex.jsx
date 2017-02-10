// @flow
import React, { Component } from 'react'
import { bindActionCreators } from 'redux'
import { connect } from 'react-redux'
import * as actions from '../../actions/respondents'
import * as surveyActions from '../../actions/survey'
import * as questionnairesActions from '../../actions/questionnaires'
import range from 'lodash/range'
import values from 'lodash/values'
import { CardTable, Tooltip, UntitledIfEmpty } from '../ui'
import RespondentRow from './RespondentRow'
import * as routes from '../../routes'
import { modeLabel } from '../../reducers/survey'

type Props = {
  projectId: number,
  surveyId: number,
  survey: Survey,
  questionnaires: Questionnaire[],
  respondents: Respondent[],
  pageSize: number,
  pageNumber: number,
  totalCount: number,
  startIndex: number,
  endIndex: number,
  hasPreviousPage: boolean,
  hasNextPage: boolean,
  surveyActions: any,
  questionnairesActions: any,
  actions: any
}

class RespondentIndex extends Component {
  props: Props

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
    const respondentsList: Respondent[] = values(respondents)

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

    let colspan = respondentsFieldName.length + 3
    let variantHeader = null
    if (hasComparisons) {
      variantHeader = <th>Variant</th>
      colspan += 1
    }

    return (
      <div className='white'>
        <div className='fixed-action-btn horizontal right mtop'>
          <Tooltip text='Download'>
            <a className='btn-floating btn-large waves-effect waves-light green'>
              <i className='material-icons'>get_app</i>
            </a>
          </Tooltip>
          <ul>
            <li>
              <Tooltip text='Download CSV 1'>
                <a className='btn-floating waves-effect waves-light green' onClick={() => this.downloadCSV()}><i className='material-icons'>get_app</i></a>
              </Tooltip>
            </li>
            <li>
              <Tooltip text='Download CSV 2'>
                <a className='btn-floating waves-effect waves-light green' onClick={() => this.downloadCSV()}><i className='material-icons'>get_app</i></a>
              </Tooltip>
            </li>
          </ul>
        </div>
        <CardTable title={title} footer={footer} tableScroll>
          <thead>
            <tr>
              <th>Phone number</th>
              {respondentsFieldName.map(field =>
                <th key={field}>{field}</th>
              )}
              {variantHeader}
              <th>Disposition</th>
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

              const responses = respondentsFieldName.map((field) => {
                return {
                  name: field,
                  value: responseOf(respondents, respondent.id, field)
                }
              })

              return <RespondentRow
                key={index}
                respondent={respondent}
                responses={responses}
                variantColumn={variantColumn}
                />
            })}
          </tbody>
        </CardTable>
      </div>
    )
  }
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
