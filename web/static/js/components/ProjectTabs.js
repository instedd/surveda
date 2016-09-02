import React from 'react'
import {Tabs, TabLink} from '.'

export const ProjectTabs = ({projectId}) => (
  <Tabs>
    <TabLink to={`/projects/${projectId}/surveys`}>Surveys</TabLink>
    <TabLink to={`/projects/${projectId}/quizzes`}>Questionnaires</TabLink>
    <TabLink to={`/projects/${projectId}/resources`}>Resources</TabLink>
  </Tabs>
)
