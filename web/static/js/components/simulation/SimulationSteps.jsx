// @flow
import React, { Component } from "react"
import { icon } from "../../step"
import { translate } from "react-i18next"
import { Card, UntitledIfEmpty } from "../ui"
import classNames from "classnames/bind"
import { flatMapDepth } from "lodash"

type Step = {
  type: string,
  title: string,
  id: string,
  steps: ?Array<Step>,
}

type PreparedStep = Step & {
  status: string,
  response: ?string,
}

type Submission = {
  stepId: string,
  response: ?string,
}

type Props = {
  submissions: Array<Submission>,
  steps: Array<Step>,
  currentStepId: string,
  t: Function,
  simulationIsEnded: boolean,
}

class SimulationSteps extends Component<Props> {
  render() {
    const { steps, submissions, simulationIsEnded, currentStepId } = this.props

    const headedBySectionSteps = flatMapDepth(
      steps,
      (step) => {
        if (step.type == "section") {
          return [step, step.steps]
        } else {
          return step
        }
      },
      2
    )

    const stepStatus = (step) => {
      const active =
        step.type == "section"
          ? !!step.steps && step.steps.some((s) => s.id == currentStepId)
          : currentStepId == step.id
      if (active) return "active"

      const completed =
        step.type == "section"
          ? !!step.steps && step.steps.some((st) => submissions.some((su) => su.stepId == st.id))
          : submissions.some((su) => su.stepId == step.id)
      if (completed) return "completed"

      const skipped = simulationIsEnded
        ? true
        : headedBySectionSteps.findIndex((s) => s.id == step.id) <
          headedBySectionSteps.findIndex((s) => s.id == currentStepId)
      if (skipped) return "skipped"

      return "pending"
    }

    const stepResponses = submissions.reduce((stepResponses, submission) => {
      if (submission.response) stepResponses[submission.stepId] = submission.response
      return stepResponses
    }, {})

    const preparedSteps = headedBySectionSteps.map((step: Step): PreparedStep => ({
      ...step,
      status: stepStatus(step),
      response: stepResponses[step.id],
    }))

    return (
      <div className="quex-simulation-steps">
        <Card>
          <ul className="collection simulation">
            {preparedSteps.map((step, index) => (
              <StepItem step={step} key={`step-item-${index}`} />
            ))}
          </ul>
        </Card>
      </div>
    )
  }
}

type StepItemProps = {
  step: PreparedStep,
  t: Function,
}

const StepItem = translate()(
  class extends Component<StepItemProps> {
    render() {
      const { step, t } = this.props
      const { type, title, response, status } = step
      const isSection = type == "section"
      const isCompleted = status == "completed"
      const itemClassNames = classNames("collection-item", {
        done: isCompleted,
        skipped: status == "skipped",
        active: status == "active",
        pending: status == "pending",
        section: isSection,
      })
      return (
        <li className={itemClassNames}>
          <i className="material-icons left sharp">
            {!isSection && isCompleted ? "check_circle" : icon(type)}
          </i>
          <UntitledIfEmpty
            className="title"
            text={title}
            emptyText={isSection ? t("Untitled section") : t("Untitled question")}
          />
          <br />
          <span className="value">{response}</span>
        </li>
      )
    }
  }
)

export default translate()(SimulationSteps)
