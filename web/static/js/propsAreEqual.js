import pickBy from "lodash/pickBy"
import isEqual from "lodash/isEqual"

/**
 * Compare two props objects to see if they are deeply equal,
 * ignoring any properties that are functions. Useful in
 * `componentWillReceiveProps` to skip setting state from props
 * that are essentially the same, avoiding a re-render and
 * solving an issue that would overwrite values while a user
 * was typing.
 */
export default function propsAreEqual(oldProps, newProps) {
  oldProps = pickBy(oldProps, isNotAFunction)
  newProps = pickBy(newProps, isNotAFunction)

  return isEqual(oldProps, newProps)
}

function isNotAFunction(value, key) {
  return typeof value != "function"
}
