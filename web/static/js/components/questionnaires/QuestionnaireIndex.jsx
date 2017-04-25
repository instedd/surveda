import React, { Component, PropTypes } from 'react'
import { bindActionCreators } from 'redux'
import { connect } from 'react-redux'
import { withRouter } from 'react-router'
import range from 'lodash/range'
import { orderedItems } from '../../reducers/collection'
import * as actions from '../../actions/questionnaires'
import * as questionnaireActions from '../../actions/questionnaire'
import * as userSettingsActions from '../../actions/userSettings'
import * as projectActions from '../../actions/project'
import { AddButton, EmptyPage, SortableHeader, CardTable, UntitledIfEmpty, Tooltip } from '../ui'
import * as routes from '../../routes'

class QuestionnaireIndex extends Component {
  componentDidMount() {
    this.creatingQuestionnaire = false
    this.duplicatingQuestionnaire = false

    const { projectId } = this.props
    // Fetch project for title
    this.props.projectActions.fetchProject(projectId)
    this.props.actions.fetchQuestionnaires(projectId)
    this.props.userSettingsActions.fetchSettings()
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

  newQuestionnaire(e) {
    e.preventDefault()

    // Prevent multiple clicks to create multiple questionnaires
    if (this.creatingQuestionnaire) return
    this.creatingQuestionnaire = true

    const { router, projectId, questionnaireActions } = this.props

    questionnaireActions.createQuestionnaire(projectId)
      .then(questionnaire => {
        this.creatingQuestionnaire = false
        router.push({
          pathname: routes.questionnaire(projectId, questionnaire.id),
          state: {isNew: true}
        })
      })
  }

  goTo(questionnaireId) {
    const { projectId, router } = this.props
    router.push(routes.editQuestionnaire(projectId, questionnaireId))
  }

  duplicate(questionnaire) {
    // Prevent multiple clicks to duplicate multiple questionnaires
    if (this.duplicatingQuestionnaire) return
    this.duplicatingQuestionnaire = true

    const { router, projectId, questionnaireActions } = this.props
    questionnaireActions.duplicateQuestionnaire(projectId, questionnaire)
      .then(questionnaire => {
        this.duplicatingQuestionnaire = false
        router.push(routes.questionnaire(projectId, questionnaire.id))
      })
  }

  render() {
    const { questionnaires, project, sortBy, sortAsc, pageSize, startIndex, endIndex,
      totalCount, hasPreviousPage, hasNextPage, userSettings } = this.props

    if (!questionnaires || !userSettings.settings) {
      return (
        <div>
          <CardTable title='Loading questionnaires...' highlight />
        </div>
      )
    }

    const title = `${totalCount} ${(totalCount == 1) ? ' questionnaire' : ' questionnaires'}`
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

    const readOnly = !project || project.readOnly

    let addButton = null
    if (!readOnly) {
      addButton = (
        <AddButton text='Add questionnaire' onClick={e => this.newQuestionnaire(e)} />
      )
    }

    return (
      <div>
        {addButton}
        { (questionnaires.length == 0)
          ? <EmptyPage icon='assignment' title='You have no questionnaires on this project' onClick={e => this.newQuestionnaire(e)} />
        : <CardTable title={title} footer={footer} highlight style={{tableLayout: 'fixed'}}>
          <thead>
            <tr>
              <SortableHeader text='Name' property='name' sortBy={sortBy} sortAsc={sortAsc} onClick={(name) => this.sortBy(name)} />
              <th>Modes</th>
              {readOnly ? null : <th className='duplicate' />}
              <th style={{width: '20px'}} />
            </tr>
          </thead>
          <tbody>
            { range(0, pageSize).map(index => {
              const questionnaire = questionnaires[index]
              if (!questionnaire) return <tr key={-index} className='empty-row'><td colSpan={readOnly ? 3 : 4} /></tr>

              return (
                <tr key={questionnaire.id}>
                  <td onClick={() => this.goTo(questionnaire.id)}>
                    <UntitledIfEmpty text={questionnaire.name} entityName='questionnaire' />
                  </td>
                  <td onClick={() => this.goTo(questionnaire.id)}>
                    { (questionnaire.modes || []).join(', ').toUpperCase() }
                  </td>
                  {readOnly ? null
                    : <td className='duplicate'>
                      <Tooltip text='Duplicate questionnaire'>
                        <a onClick={() => this.duplicate(questionnaire)}>
                          <i className='material-icons'>content_copy</i>
                        </a>
                      </Tooltip>
                    </td>}
                  <td>
                    {!questionnaire.valid
                    ? <span className='questionnaire-tooltip-error' />
                    : null}
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
  questionnaireActions: PropTypes.object.isRequired,
  userSettingsActions: PropTypes.object.isRequired,
  userSettings: PropTypes.object,
  projectId: PropTypes.any,
  project: PropTypes.object,
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
  const userSettings = state.userSettings
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
    projectId: ownProps.params.projectId,
    project: state.project.data,
    sortBy,
    sortAsc,
    questionnaires,
    userSettings,
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
  projectActions: bindActionCreators(projectActions, dispatch),
  questionnaireActions: bindActionCreators(questionnaireActions, dispatch),
  userSettingsActions: bindActionCreators(userSettingsActions, dispatch)
})

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(QuestionnaireIndex))
