// @flow
import * as actions from '../../actions/channel'
import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import 'materialize-autocomplete'
import AddProject from './AddProject'
import map from 'lodash/map'
import { translate } from 'react-i18next'
import { UntitledIfEmpty } from '../ui'

type Props = {
  projects: IndexedList<Project>,
  selectedProjects: number[],
  channelId: number,
  dispatch: Function,
  t: Function
};

class ProjectsList extends Component<Props> {
  removeSharedProject(projectId) {
    return () => this.props.dispatch(actions.removeSharedProject(projectId))
  }

  renderProjectRow(projectId, name) {
    const { t } = this.props
    return <li key={projectId}>
      <span key='remove-language' className='remove-language' onClick={this.removeSharedProject(projectId)}>
        <i className='material-icons'>close</i>
      </span>
      <span className='language-name' title={name}>
        <UntitledIfEmpty text={name} emptyText={t('Untitled project')} />
      </span>
    </li>
  }

  render() {
    const { selectedProjects, t, projects } = this.props

    if (!projects) {
      return null
    }

    return (
      <div className='projects'>
        {
          selectedProjects && selectedProjects.length != 0
            ? <ProjectSection title={t('Share on projects')}>
              {
                map(selectedProjects, (id) => this.renderProjectRow(id, projects[id] && projects[id].name))
              }
            </ProjectSection>
            : ''
        }
        <div className='row'>
          <AddProject selectedProjects={selectedProjects} projects={projects} />
        </div>
      </div>
    )
  }
}

const ProjectSection = ({title, children}) =>
  <div className='row'>
    <div className='col s12'>
      <p className='grey-text'>{title}</p>
      <ul className='languages-list'>{children}</ul>
    </div>
  </div>

ProjectSection.propTypes = {
  title: PropTypes.string,
  children: PropTypes.node
}

const mapStateToProps = (state) => ({
  projects: state.projects.items
})

export default translate()(connect(mapStateToProps)(ProjectsList))
