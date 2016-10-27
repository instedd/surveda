import React, { Component, PropTypes } from 'react'
import { bindActionCreators } from 'redux'
import { connect } from 'react-redux'
import { withRouter } from 'react-router'
import range from 'lodash/range'
import { orderedItems } from '../../dataTable'
import * as actions from '../../actions/questionnaires'
import * as projectActions from '../../actions/project'
import { AddButton, EmptyPage, SortableHeader, CardTable, UntitledIfEmpty } from '../ui'
import * as routes from '../../routes'

class QuestionnaireIndex extends Component {
  componentDidMount() {
    const { projectId } = this.props
    // Fetch project for title
    this.props.projectActions.fetchProject(projectId)
    this.props.actions.fetchQuestionnaires(projectId)
  }

  nextPage(e) {
    e.preventDefault()
    this.props.actions.nextQuestionnairesPage()
  }

  previousPage(e) {
    e.preventDefault()
    this.props.actions.previousQuestionnairesPage()
  }

  sortBy(property) {
    this.props.actions.sortQuestionnairesBy(property)
  }

  render() {
    const { questionnaires, sortBy, sortAsc, pageSize, startIndex, endIndex,
      totalCount, hasPreviousPage, hasNextPage, projectId, router } = this.props

    if (!questionnaires) {
      return (
        <div>
          <CardTable title='Loading questionnaires...' highlight />
        </div>
      )
    }

    const title = `${totalCount} ${(totalCount === 1) ? ' questionnaire' : ' questionnaires'}`
    const footer = (
      <div className='right-align'>
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
      <div>
        <AddButton text='Add questionnaire' linkPath={routes.newQuestionnaire(projectId)} />
        { (questionnaires.length === 0)
          ? <EmptyPage icon='assignment' title='You have no questionnaires on this project' linkPath={routes.newQuestionnaire(projectId)} />
        : <CardTable title={title} footer={footer} highlight>
          <thead>
            <tr>
              <SortableHeader text='Name' property='name' sortBy={sortBy} sortAsc={sortAsc} onClick={(name) => this.sortBy(name)} />
              <th>Modes</th>
            </tr>
          </thead>
          <tbody>
            { range(0, pageSize).map(index => {
              const questionnaire = questionnaires[index]
              if (!questionnaire) return <tr key={-index}><td colSpan='2'>&nbsp;</td></tr>

              return (
                <tr key={questionnaire.id} onClick={() => router.push(routes.editQuestionnaire(projectId, questionnaire.id))}>
                  <td>
                    <UntitledIfEmpty text={questionnaire.name} />
                  </td>
                  <td>
                    { (questionnaire.modes || []).join(', ') }
                  </td>
                </tr>
                )
            }
              )}
          </tbody>
        </CardTable>
        }
      </div>
    )
  }
}

QuestionnaireIndex.propTypes = {
  actions: PropTypes.object.isRequired,
  projectActions: PropTypes.object.isRequired,
  projectId: PropTypes.number,
  questionnaires: PropTypes.array,
  sortBy: PropTypes.string,
  sortAsc: PropTypes.bool.isRequired,
  pageSize: PropTypes.number.isRequired,
  startIndex: PropTypes.number.isRequired,
  endIndex: PropTypes.number.isRequired,
  hasPreviousPage: PropTypes.bool.isRequired,
  hasNextPage: PropTypes.bool.isRequired,
  totalCount: PropTypes.number.isRequired,
  router: PropTypes.object
}

const mapStateToProps = (state, ownProps) => {
  let questionnaires = orderedItems(state.questionnaires.items, state.questionnaires.order)
  const sortBy = state.questionnaires.sortBy
  const sortAsc = state.questionnaires.sortAsc
  const totalCount = questionnaires ? questionnaires.length : 0
  const pageIndex = state.questionnaires.page.index
  const pageSize = state.questionnaires.page.size
  if (questionnaires) {
    questionnaires = questionnaires.slice(pageIndex, pageIndex + pageSize)
  }
  const startIndex = Math.min(totalCount, pageIndex + 1)
  const endIndex = Math.min(pageIndex + pageSize, totalCount)
  const hasPreviousPage = startIndex > 1
  const hasNextPage = endIndex < totalCount
  return {
    projectId: parseInt(ownProps.params.projectId),
    sortBy,
    sortAsc,
    questionnaires,
    pageSize,
    startIndex,
    endIndex,
    hasPreviousPage,
    hasNextPage,
    totalCount
  }
}

const mapDispatchToProps = (dispatch) => ({
  actions: bindActionCreators(actions, dispatch),
  projectActions: bindActionCreators(projectActions, dispatch)
})

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(QuestionnaireIndex))
