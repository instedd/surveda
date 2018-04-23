// @flow
import React, { Component } from 'react'
import { bindActionCreators } from 'redux'
import { connect } from 'react-redux'
import * as actions from '../../actions/integrations'
import * as surveyActions from '../../actions/survey'
import * as projectActions from '../../actions/project'
import values from 'lodash/values'
import { AddButton, CardTable, InputWithLabel, Modal } from '../ui'
import IntegrationRow from './IntegrationRow'

type Props = {
  projectId: number,
  surveyId: number,
  survey: Survey,
  project: Project,
  integrations: Integration[],
  surveyActions: any,
  projectActions: any,
  actions: any,
  fetching: boolean
};

type State = {
  editedIntegration: Integration
};

type DefaultProps = {};
class IntegrationIndex extends Component<DefaultProps, Props, State> {
  static defaultProps = {}
  props: Props
  state: State

  constructor(props) {
    super(props)
    this.state = {
      editedIntegration: {
        id: 0,
        name: '',
        uri: '',
        authToken: '',
        state: 'disabled'
      }
    }
  }

  componentDidMount() {
    const { projectId, surveyId } = this.props
    if (projectId && surveyId) {
      this.props.projectActions.fetchProject(projectId)
      this.props.surveyActions.fetchSurvey(projectId, surveyId)
      this.props.actions.fetchIntegrations(projectId, surveyId)
    }
  }

  nameOnChange(e) {
    const integration = this.state.editedIntegration
    integration.name = e.target.value
    this.setState({
      editedIntegration: integration
    })
  }

  uriOnChange(e) {
    const integration = this.state.editedIntegration
    integration.uri = e.target.value
    this.setState({
      editedIntegration: integration
    })
  }

  tokenOnChange(e) {
    const integration = this.state.editedIntegration
    integration.authToken = e.target.value
    this.setState({
      editedIntegration: integration
    })
  }

  createIntegration(e) {
    e.preventDefault()
    this.props.actions.createIntegration(this.props.projectId, this.props.surveyId, this.state.editedIntegration)
  }

  modalNewIntegration() {
    return <Modal id='newIntegration' confirmationText='New integration' card>
      <div>
        <div className='card-title header'>
          <h5>Create a new integration</h5>
          <p>Surveda will periodically push responses from this survey to the service you configure here.</p>
        </div>
        <div className='card-content' style={{maxHeight: '100vh'}}>
          <div className='row'>
            <div className='input-field'>
              <InputWithLabel id='integration_name' value={undefined} label='Enter a name to identify your integration (e.g.: "ONA")'>
                <input type='text' onChange={e => { this.nameOnChange(e) }} />
              </InputWithLabel>
            </div>
            <div className='input-field'>
              <InputWithLabel id='integration_uri' value={undefined} label='URI of the service that will receive the data (e.g.: "https://api.ona.io/api/v1/")'>
                <input type='text' onChange={e => { this.uriOnChange(e) }} />
              </InputWithLabel>
            </div>
            <div className='input-field'>
              <InputWithLabel id='integration_token' value={undefined} label='Authorization token (e.g.: "Token tGzv3JOkF0XG5Qx2TlKWIA")'>
                <input type='text' onChange={e => { this.tokenOnChange(e) }} />
              </InputWithLabel>
            </div>
          </div>
          <div className='row button-actions'>
            <div className='col s12'>
              <a href='#!' className='modal-action modal-close waves-effect btn-medium blue' onClick={(e) => this.createIntegration(e)}>Create Integration</a>
            </div>
          </div>
        </div>
      </div>
    </Modal>
  }

  render() {
    if (!this.props.integrations || this.props.fetching || !this.props.survey || !this.props.project) {
      return <div>Loading...</div>
    }

    const { integrations } = this.props

    return (
      <div className='white'>
        <AddButton text='Add integration' onClick={(e) => { e.preventDefault(); $('#newIntegration').modal('open') }} />
        {this.modalNewIntegration()}
        <CardTable title='Integrations' tableScroll>
          <thead>
            <tr>
              <th>Name</th>
              <th>Uri</th>
              <th>Token</th>
              <th>State</th>
            </tr>
          </thead>
          <tbody>
            {
              integrations.map((integration: Integration, index: number) => {
                return <IntegrationRow
                  key={index}
                  integration={integration}
                  />
              })
            }
          </tbody>
        </CardTable>
      </div>
    )
  }
}

const mapStateToProps = (state, ownProps) => {
  return {
    projectId: ownProps.params.projectId,
    surveyId: ownProps.params.surveyId,
    survey: state.survey.data,
    project: state.project.data,
    integrations: values(state.integrations.items),
    fetching: state.integrations.fetching
  }
}

const mapDispatchToProps = (dispatch) => ({
  actions: bindActionCreators(actions, dispatch),
  surveyActions: bindActionCreators(surveyActions, dispatch),
  projectActions: bindActionCreators(projectActions, dispatch)
})

export default connect(mapStateToProps, mapDispatchToProps)(IntegrationIndex)
