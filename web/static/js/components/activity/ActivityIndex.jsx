import React, { Component, PropTypes } from "react"
import { connect } from "react-redux"
import { bindActionCreators } from "redux"
import { orderedItems } from "../../reducers/collection"
import { CardTable, SortableHeader, PagingFooter } from "../ui"
import ActivityDescription from "./ActivityDescription"
import * as actions from "../../actions/activities"
import dateformat from "dateformat"
import { translate } from "react-i18next"

class ActivityIndex extends Component {
  componentDidMount() {
    const { projectId, pageNumber } = this.props
    if (projectId) {
      this.fetchActivities(pageNumber)
    }
  }

  nextPage() {
    const { pageNumber } = this.props
    this.fetchActivities(pageNumber + 1)
  }

  previousPage() {
    const { pageNumber } = this.props
    this.fetchActivities(pageNumber - 1)
  }

  fetchActivities(pageNumber = 1) {
    const { actions, projectId, pageSize, sortAsc } = this.props
    actions.fetchActivities(projectId, pageSize, pageNumber, sortAsc)
  }

  sort() {
    const { projectId } = this.props
    this.props.actions.sortActivities(projectId)
  }

  changePageSize(pageSize) {
    const { projectId, actions } = this.props
    if (pageSize != this.props.pageSize) {
      actions.changePageSize(projectId, pageSize)
    }
  }

  render() {
    const { activities, totalCount, startIndex, pageSize, endIndex, sortBy, sortAsc, t } =
      this.props

    if (!activities) {
      return (
        <div>
          <CardTable title={t("Loading activities...")} highlight />
        </div>
      )
    }

    const title = `${totalCount} ${totalCount == 1 ? t("activity") : t("activities")}`
    const footer = (
      <PagingFooter
        {...{ startIndex, endIndex, totalCount, pageSize }}
        onPreviousPage={() => this.previousPage()}
        onNextPage={() => this.nextPage()}
        onPageSizeChange={(pageSize) => this.changePageSize(pageSize)}
        pageSizeOptions={[5, 15, 50, 100]}
      />
    )

    const userContent = (userName, userEmail, remoteIp) => {
      if (userName) return userName
      if (userEmail) return userEmail
      if (remoteIp == "0.0.0.0") return t("Background process")
      return remoteIp
    }

    return (
      <div>
        <CardTable title={title} footer={footer}>
          <thead>
            <tr>
              <th>{t("User")}</th>
              <th>{t("Action")}</th>
              <SortableHeader
                text={t("Last activity")}
                property="insertedAt"
                sortBy={sortBy}
                sortAsc={sortAsc}
                onClick={() => this.sort()}
              />
            </tr>
          </thead>
          <tbody>
            {activities.map((activity) => {
              return (
                <tr key={activity.id}>
                  <td>{userContent(activity.userName, activity.userEmail, activity.remoteIp)}</td>
                  <td>
                    <ActivityDescription activity={activity} />
                  </td>
                  <td>{dateformat(new Date(activity.insertedAt), "mmm d, yyyy HH:MM")}</td>
                </tr>
              )
            })}
          </tbody>
        </CardTable>
      </div>
    )
  }
}

ActivityIndex.propTypes = {
  t: PropTypes.func,
  projectId: PropTypes.any.isRequired,
  actions: PropTypes.object.isRequired,
  activities: PropTypes.array,
  sortBy: PropTypes.string.isRequired,
  sortAsc: PropTypes.bool,
  totalCount: PropTypes.number.isRequired,
  startIndex: PropTypes.number.isRequired,
  endIndex: PropTypes.number.isRequired,
  pageNumber: PropTypes.number.isRequired,
  pageSize: PropTypes.number.isRequired,
}

const mapDispatchToProps = (dispatch) => ({
  actions: bindActionCreators(actions, dispatch),
})

const mapStateToProps = (state, ownProps) => {
  let activities = orderedItems(state.activities.items, state.activities.order)
  const sortBy = state.activities.sortBy
  const sortAsc = state.activities.sortAsc
  const totalCount = state.activities.page.totalCount
  const pageNumber = state.activities.page.number
  const pageSize = state.activities.page.size
  const startIndex = (pageNumber - 1) * pageSize + 1
  const endIndex = Math.min(startIndex + pageSize - 1, totalCount)

  return {
    projectId: ownProps.params.projectId,
    activities,
    totalCount,
    pageNumber,
    pageSize,
    startIndex,
    endIndex,
    sortBy,
    sortAsc,
  }
}

export default translate()(connect(mapStateToProps, mapDispatchToProps)(ActivityIndex))
