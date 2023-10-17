// @flow
import iso6393 from "iso-639-3"

export function nameToCode(name: string): ?string {
  let match = iso6393.find((l) => l.name == name)
  return match ? idForLanguage(match) : null
}

export const idForLanguage = (lang) => (lang.iso6391 ? lang.iso6391 : lang.iso6393)

export function livingLanguages() {
  return iso6393.filter((lang) => lang.type == "living")
}

export function codeToName(code: string): ?string {
  let match = iso6393.find((l) => l.iso6391 == code || l.iso6393 == code)
  return match ? match.name : null
}
