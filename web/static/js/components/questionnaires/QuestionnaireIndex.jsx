// @flow
import React, { Component, PropTypes } from 'react'
import { bindActionCreators } from 'redux'
import { connect } from 'react-redux'
import { withRouter } from 'react-router'
import range from 'lodash/range'
import dateformat from 'dateformat'
import { orderedItems } from '../../reducers/collection'
import * as actions from '../../actions/questionnaires'
import * as questionnaireActions from '../../actions/questionnaire'
import * as userSettingsActions from '../../actions/userSettings'
import * as projectActions from '../../actions/project'
import {
  AddButton,
  EmptyPage,
  SortableHeader,
  CardTable,
  UntitledIfEmpty,
  Tooltip,
  ArchiveIcon,
  ArchiveFilter,
  ConfirmationModal,
  PagingFooter
} from '../ui'
import * as routes from '../../routes'
import { modeLabel, modeOrder } from '../../questionnaire.mode'
import { translate, Trans } from 'react-i18next'

class QuestionnaireIndex extends Component<any> {
  creatingQuestionnaire: boolean
  duplicatingQuestionnaire: boolean

  componentDidMount() {
    this.creatingQuestionnaire = false
    this.duplicatingQuestionnaire = false

    const { projectId } = this.props
    // Fetch project for title
    this.props.projectActions.fetchProject(projectId)
    this.fetchQuestionnaires()
    this.props.userSettingsActions.fetchSettings()
  }

  fetchQuestionnaires(archived: boolean = false) {
    const { projectId } = this.props
    this.props.actions.fetchQuestionnaires(projectId, {'archived': archived})
  }

  nextPage() {
    this.props.actions.nextQuestionnairesPage()
  }

  previousPage() {
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

  delete(questionnaire: Questionnaire) {
    const { projectId, actions, t } = this.props

    const deleteConfirmationModal: ConfirmationModal = this.refs.deleteConfirmationModal
    deleteConfirmationModal.open({
      modalText: <Trans>
        <p>Are you sure you want to delete the questionnaire <b><UntitledIfEmpty text={questionnaire.name} emptyText={t('Untitled questionnaire')} /></b>?</p>
      </Trans>,
      onConfirm: () => {
        actions.deleteQuestionnaire(projectId, questionnaire)
      }
    })
  }

  readOnly() {
    const { project } = this.props
    return !project || project.readOnly
  }

  archiveIconForQuestionnaire(questionnaire: Questionnaire, archived: boolean) {
    const action = archived ? 'unarchive' : 'archive'
    const onClick = () => this.archiveOrUnarchive(questionnaire, action)
    return (
      <td className='action'>
        <ArchiveIcon archived={archived} onClick={onClick} />
      </td>
    )
  }

  archiveOrUnarchive(questionnaire: Questionnaire, action: string) {
    const { t, actions, startIndex } = this.props
    actions.archiveOrUnarchive(questionnaire, action).then(() => {
      const { questionnaires } = this.props
      if (questionnaires.length == 0 && startIndex > 0) {
        actions.previousPage()
      }
      const description = action == 'archive' ? t('Project successfully archived') : t('Questionnaire successfully unarchived')
      window.Materialize.toast(description, 5000)
    })
  }

  render() {
    const { questionnaires, sortBy, sortAsc, pageSize, startIndex, endIndex, totalCount, userSettings, archived, t } = this.props

    if (!questionnaires || !userSettings.settings) {
      return (
        <div>
          <CardTable title={t('Loading questionnaires...')} highlight />
        </div>
      )
    }

    const title = `${totalCount} ${(totalCount == 1) ? ' questionnaire' : ' questionnaires'}`
    const footer = <PagingFooter
      {...{startIndex, endIndex, totalCount}}
      onPreviousPage={() => this.previousPage()}
      onNextPage={() => this.nextPage()} />

    const readOnly = this.readOnly()
    const actionHeaders = Array(3).fill().map((_, i) => <th className='action' key={i} />)

    let addButton = null
    if (!readOnly) {
      addButton = (
        <AddButton text={t('Add questionnaire')} onClick={e => this.newQuestionnaire(e)} />
      )
    }

    const quexTable = (
      <CardTable title={title} footer={footer} highlight style={{tableLayout: 'fixed'}}>
        <thead>
          <tr>
            <SortableHeader text='Name' property='name' sortBy={sortBy} sortAsc={sortAsc} onClick={(name) => this.sortBy(name)} />
            <SortableHeader text='Last Modified' property='updatedAt' sortBy={sortBy} sortAsc={sortAsc} onClick={(propertyName) => this.sortBy(propertyName)} />
            <th>{t('Modes')}</th>
            { actionHeaders }
            <th style={{width: '20px'}} />
          </tr>
        </thead>
        <tbody>
          { range(0, pageSize).map(index => {
            const questionnaire = questionnaires[index]
            if (!questionnaire) return <tr key={-index} className='empty-row'><td colSpan={readOnly ? 3 : 5} /></tr>

            return (
              <tr key={questionnaire.id} title={questionnaire.description}>
                <td onClick={() => this.goTo(questionnaire.id)}>
                  <UntitledIfEmpty text={questionnaire.name} emptyText={t('Untitled questionnaire')} />
                </td>
                <td onClick={() => this.goTo(questionnaire.id)}>
                  {questionnaire.updatedAt ? dateformat(new Date(questionnaire.updatedAt), 'mmm d, yyyy HH:MM') : '-'}
                </td>
                <td onClick={() => this.goTo(questionnaire.id)}>
                  { (questionnaire.modes || []).sort((x, y) => modeOrder(x) - modeOrder(y)).map(x => modeLabel(x)).join(', ') }
                </td>
                {readOnly ? null
                  : <td className='action'>
                    <Tooltip text={t('Duplicate questionnaire')}>
                      <a onClick={() => this.duplicate(questionnaire)}>
                        <i className='material-icons'>content_copy</i>
                      </a>
                    </Tooltip>
                  </td>}
                {
                  readOnly
                    ? null
                    : this.archiveIconForQuestionnaire(questionnaire, archived)
                }
                {readOnly ? null
                  : <td className='action'>
                    <Tooltip text={t('Delete questionnaire')}>
                      <a onClick={() => this.delete(questionnaire)}>
                        <i className='material-icons'>delete</i>
                      </a>
                    </Tooltip>
                  </td>}
                <td className='tdError'>
                  {!questionnaire.valid
                  ? <span className='questionnaire-error' />
                  : null}
                </td>
              </tr>
            )
          }
          )}
        </tbody>
      </CardTable>
    )

    return (
      <div>
        {addButton}
        { (questionnaires.length == 0 && !archived)
          ? <EmptyPage icon='assignment' title={t('You have no questionnaires on this project')} onClick={e => this.newQuestionnaire(e)} readOnly={readOnly} createText={t('Create one', {context: 'questionnaire'})} />
          : (
            <div>
              <div className='row'>
                <ArchiveFilter
                  archived={archived}
                  onChange={selection => {
                    this.fetchQuestionnaires(selection == 'archived')
                  }}
                />
              </div>
              {quexTable}
            </div>
          )
        }
        <ConfirmationModal modalId='questionnaire_index_delete' ref='deleteConfirmationModal' confirmationText={t('DELETE')} header={t('Delete questionnaire')} showCancel />
      </div>
    )
  }
}

QuestionnaireIndex.propTypes = {
  t: PropTypes.func,
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
  totalCount: PropTypes.number.isRequired,
  router: PropTypes.object,
  archived: PropTypes.bool
}

const mapStateToProps = (state, ownProps) => {
  let questionnaires = orderedItems(state.questionnaires.items, state.questionnaires.order)
  const archived = questionnaires ? state.questionnaires.filter.archived : false
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
    totalCount,
    archived
  }
}

const mapDispatchToProps = (dispatch) => ({
  actions: bindActionCreators(actions, dispatch),
  projectActions: bindActionCreators(projectActions, dispatch),
  questionnaireActions: bindActionCreators(questionnaireActions, dispatch),
  userSettingsActions: bindActionCreators(userSettingsActions, dispatch)
})

export default translate()(withRouter(connect(mapStateToProps, mapDispatchToProps)(QuestionnaireIndex)))
