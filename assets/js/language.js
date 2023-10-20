import iso6393 from "iso-639-3"
import { config } from "./config"

const languages = (() => {
  let langs = iso6393
  for (const [code, name] of Object.entries(config.custom_language_names)) {
    let lang = langs.find((l) => l.iso6393 == code)
    if (lang) {
      lang.name = name
    }
  }
  return langs
})()

export function nameToCode(name: string): ?string {
  let match = languages.find((l) => l.name == name)
  return match ? idForLanguage(match) : null
}

export const idForLanguage = (lang): string => (lang.iso6391 ? lang.iso6391 : lang.iso6393)

export function livingLanguages() {
  return languages.filter((lang) => lang.type == "living")
}

export function codeToName(code: string): ?string {
  let match = languages.find((l) => l.iso6391 == code || l.iso6393 == code)
  return match ? match.name : null
}
