import React, { Component, PropTypes } from 'react'
import { bindActionCreators } from 'redux'
import { connect } from 'react-redux'
import * as actions from '../../actions/respondents'
import range from 'lodash/range'
import values from 'lodash/values'
import { CardTable } from '../ui'

class RespondentIndex extends Component {
  componentDidMount() {
    const { projectId, surveyId, pageSize } = this.props
    if (projectId && surveyId) {
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

  render() {
    if (!this.props.respondents) {
      return <div>Loading...</div>
    }

    const { totalCount } = this.props

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

    return (
      <CardTable title={title} footer={footer}>
        <thead>
          <tr>
            <th>Phone number</th>
            {allFieldNames(respondents).map(field =>
              <th key={field}>{field}</th>
            )}
            <th>Date</th>
          </tr>
        </thead>
        <tbody>
          { range(0, pageSize).map(index => {
            const respondent = respondentsList[index]
            if (!respondent) return <tr key={-index}><td colSpan='2'>&nbsp;</td></tr>

            return (
              <tr key={respondent.id}>
                <td> {respondent.phoneNumber}</td>
                {allFieldNames(respondents).map(function(field) {
                  return <td key={parseInt(respondent.id) + field}>{responseOf(respondents, respondent.id, field)}</td>
                })}
                <td>
                  {respondent.date ? new Date(respondent.date).toUTCString() : '-'}
                </td>
              </tr>
            )
          })}
        </tbody>
      </CardTable>
    )
  }
}

RespondentIndex.propTypes = {
  actions: PropTypes.object.isRequired,
  projectId: PropTypes.any,
  surveyId: PropTypes.any,
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
  actions: bindActionCreators(actions, dispatch)
})

export default connect(mapStateToProps, mapDispatchToProps)(RespondentIndex)
