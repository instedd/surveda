import * as d3 from "d3"

export function percentFormat(number) {
  return d3.format(".1%")(number)
}

export function numberFormat(number) {
  return number < 0.1 ? d3.format(".1%")(number) : d3.format(".0%")(number)
}

export function labelFormat(number) {
  return number > 0 && number < 1 ? d3.format(".2f")(number) : d3.format(".0f")(number)
}

