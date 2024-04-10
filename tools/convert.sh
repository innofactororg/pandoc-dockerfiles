#!/usr/bin/env sh
# shellcheck disable=SC3043
set -e
error() {
  local line="${1}"
  local message="${2}"
  if [ $# -gt 2 ]; then
    local code="${3}"
  else
    local code=-1
  fi
  local line_message=""
  if [ "$line" != '' ]; then
    line_message=" on or near line ${line}"
  fi
  if test -n "${message}"; then
    message="${message} (exit code ${code})"
  else
    message="Unspecified (exit code ${code})"
  fi
  command printf '\033[1;31mError%s\033[0m: %s\n' "${line_message}" "${message}" 1>&2
  exit "${code}"
}
warning() {
  command printf '\033[1;33mWarning\033[0m: %s\n' "$1" 1>&2
}
info() {
  currentTime=$(date "+%Y-%m-%d %T")
  if [ $# -gt 1 ]; then
    command printf '\033[36m%14s\033[0m %s\n' "${currentTime} ${1}" "${2}" 1>&2
  else
    command printf '\033[36m%s\033[0m\n' "${currentTime} ${1}" 1>&2
  fi
}
get_param_shifts() {
  if [ "${1%%=*}" = "$1" ]; then
    printf 2
  else
    printf 1
  fi
}
set_param_value() {
  ARG="${1%%=*}"
  if [ "${ARG}" = "$1" ]; then
    shift
    if [ -z "$1" ]; then
      >&2 echo "You must specify a value for property ${ARG}"
      return 1
    fi
    VALUE="$1"
  else
    VALUE="${1#*=}"
  fi
  shift
}
set_InputContent() {
  local FILE NAME FOLDER CONTENT ITEMS="$#"
  while [ "$#" -gt 0 ]; do
    case "${1}" in
      *)
        FILE="${1}"
        shift
        if [ "$(printf '%s' "${FILE}" | tail -c 3)" = '.md' ]; then
          FOLDER=$(dirname "$FILE")
          NAME=$(basename "$FILE")
          # Get content from file and replace relative links with full links
          CONTENT=$(
            printf '%s' "$(sed \
              -e "s|\(\[.*\](\)\(\../\)\(.*)\)|\1${FOLDER}/\2\3|g" \
              -e "s|\(\[.*\](\)\(\./\)\(.*)\)|\1${FOLDER}/\3|g" \
              -e "s|\(\[.*\](\)\(asset\)\(.*)\)|\1${FOLDER}/\2\3|g" \
              -e "s|\(\[.*\](\)\(attach\)\(.*)\)|\1${FOLDER}/\2\3|g" \
              -e "s|\(\[.*\](\)\(image\)\(.*)\)|\1${FOLDER}/\2\3|g" \
              -e "s|\(\[.*\](\)\(\.\)\(.*)\)|\1${FOLDER}/\2\3|g" \
              "${FILE}")"
          )
          if test -n "${CONTENT}"; then
            if [ "${ITEMS}" -gt 1 ]; then
              info "${NAME} has ${#CONTENT} characters"
            fi
            if test -z "${InputContent}"; then
              InputContent=$(printf '%s\n' "${CONTENT}")
            else
              InputContent=$(printf '%s\n' "${InputContent}\n\n${CONTENT}")
            fi
          fi
        fi
        ;;
    esac
  done
}
set_InputList() {
  local FILE
  while [ "$#" -gt 0 ]; do
    case "${1}" in
      *)
        FILE="${1}"
        shift
        if ! test -f "${FILE}"; then
          error '' "Unable to find ${FILE}" 1
        fi
        if [ "$(printf '%s' "${FILE}" | tail -c 6)" = '.order' ]; then
          OrderList="${OrderList}$(printf '%s\n' "$(sed \
            -e '/^#/d' \
            -e '/^[[:space:]]*$/d' \
            "${FILE}")" | tr '\n' ' ' | tr -d '\r') "
        else
          case "${InputList}" in
            *${FILE}*) ;; # skip file if already in list
            *) InputList="${InputList}$(readlink -f "${FILE}") " ;;
          esac
        fi
        # If InputPath is not set
        if test -z "${InputPath}"; then
          # Set InputPath to the path of first file
          InputPath=$(dirname "$(readlink -f "${FILE}")")
        fi
        ;;
    esac
  done
}
set_metadataChangeHistory() {
  local historyFilePath lineCount historyJson mergeLogs tmp
  local author authors date description line version versionHistory
  # If metadata file has version-history key
  if [ "$(jq 'has("version-history")' "${MetadataFile}")" = 'true' ]; then
    info 'Get version history'
    # If a history file is specified
    if test -n "${HistoryFile}"; then
      # Get full path to history file
      historyFilePath=$(readlink -f "${HistoryFile}")
      if ! test -f "${historyFilePath}"; then
        error '' "Unable to find history file ${HistoryFile}" 1
      fi
      # Get mergeLogs from history file
      mergeLogs=$(cat "${historyFilePath}")
    elif [ "${SkipGitHistory}" != 'true' ]; then
      # If GitLogLimit is not specified
      if [ "${GitLogLimit}" = '' ]; then
        # Default to 15 entries
        GitLogLimit=15
      fi
      # Get mergeLogs from git log
      mergeLogs=$(
        git --no-pager log "-${GitLogLimit}" --date-order --date=format:'%b %e, %Y' \
          --no-merges --oneline --pretty=format:'%D|%ad|%an|%s' "${InputPath}"
      )
    fi
    # If mergeLogs is not empty
    if test -n "${mergeLogs}"; then
      # Count the log lines
      lineCount=$(echo "${mergeLogs}" | wc -l)
      historyJson='[]'
      tmp=$(mktemp)
      # Read log lines
      printf '%s\n' "${mergeLogs}" | while read -r line; do
        # Reduse line count by 1
        lineCount=$((lineCount-1))
        # Get version from log line
        version=$(echo "${line}" | cut -d'|' -f1 | rev | cut -d'/' -f1 | rev)
        # If version is empty or not a version
        if test -z "${version}" || ! echo "${version}" | grep -Eq '^[0-9].*'; then
          # Use version 1.0. + line count
          version="1.0.${lineCount}"
        fi
        # Get date from log line
        date=$(echo "${line}" | cut -d'|' -f2)
        # Get author from log line
        author=$(echo "${line}" | cut -d'|' -f3)
        # Get description from log line
        description=$(echo "${line}" | cut -d'|' -f4)
        # If temp file has content
        if test -s "${tmp}"; then
          # Put that content into variable
          historyJson=$(jq '.' "${tmp}")
        fi
        # Add data from log line to temp file
        printf '%s\n' "${historyJson}" | jq \
          --arg version "${version}" \
          --arg date "${date}" \
          --arg author "${author}" \
          --arg description "${description}" \
          '. +=[{ version: $version, date: $date, author: $author, description: $description }]' > "${tmp}"
      done
    elif test -n "${MainAuthor}" && test -n "${FirstChangeDescription}"; then
      # Add default values to temp file
      printf '%s\n' '[]' | jq \
        --arg version '1.0.0' \
        --arg date "$(date "+%B %d, %Y")" \
        --arg author "${MainAuthor}" \
        --arg description "${FirstChangeDescription}" \
        '. +=[{ version: $version, date: $date, author: $author, description: $description }]' > "${tmp}"
    fi
    # If temp file has content
    if test -s "${tmp}"; then
      versionHistory=$(jq '.' "${tmp}")
      set_metadataField version-history "${versionHistory}"
      if [ "$(jq 'has("author")' "${MetadataFile}")" = 'true' ]; then
        authors="[$(echo "${versionHistory}" | jq '.[].author' | uniq | sed ':a; N; $!ba; s/\n/,/g')]"
        set_metadataField author "${authors}"
      fi
    fi
    rm -f "${tmp}"
  fi
}
set_metadataField() {
  local tmp
  # If metadata file has key
  if [ "$(jq --arg k "${1}" 'has($k)' "${MetadataFile}")" = 'true' ]; then
    # Create a tmp file
    tmp=$(mktemp)
    # Set the key value and write to tmp file
    jq --arg k "${1}" --arg v "${2}" '.[$k] = $v' "${MetadataFile}" > "${tmp}"
    # Replace metadata file with tmp file
    mv -f "${tmp}" "${MetadataFile}"
  fi
}
set_metadataImage() {
  local newPath tmp
  if test -n "${InputPath}" && test -f "${InputPath}/${Template}-${1}.png"; then
    # Image file exist in input files folder and is prefixed with template name
    newPath="${InputPath}/${Template}-${1}.png"
  elif test -n "${InputPath}" && test -f "${InputPath}/${1}.png"; then
    # Image file exist in input files folder
    newPath="${InputPath}/${1}.png"
  elif test -f "${TemplatePath}/${Template}-${1}.png"; then
    # Image file exist in template folder and is prefixed with template name
    newPath="${TemplatePath}/${Template}-${1}.png"
  elif test -f "${TemplatePath}/${1}.png"; then
    # Image file exist in template folder
    newPath="${TemplatePath}/${1}.png"
  fi
  if test -n "${newPath}" && [ "${newPath}" != "/.pandoc/templates/designdoc-${1}.png" ]; then
    # Create a tmp file
    tmp=$(mktemp)
    # Set the image key value
    jq --arg k "${2}" --arg l "${newPath}" '.[$k] = $l' "${MetadataFile}" > "${tmp}"
    # Replace metadata file with tmp file
    mv -f "${tmp}" "${MetadataFile}"
  fi
}
process_params() {
  local VALUE ARG POSITIONAL_SHIFTS=0
  while [ "$#" -gt "$POSITIONAL_SHIFTS" ]; do
    case "${1%%=*}" in
      --author)
        set_param_value "$@"
        shift "$(get_param_shifts "$@")"
        MainAuthor="$VALUE"
        ;;
      --description)
        set_param_value "$@"
        shift "$(get_param_shifts "$@")"
        FirstChangeDescription="$VALUE"
        ;;
      --git-log-limit)
        set_param_value "$@"
        shift "$(get_param_shifts "$@")"
        GitLogLimit="$VALUE"
        ;;
      --history-file)
        set_param_value "$@"
        shift "$(get_param_shifts "$@")"
        HistoryFile="$VALUE"
        ;;
      --input-files)
        set_param_value "$@"
        shift "$(get_param_shifts "$@")"
        InputFiles="$VALUE"
        ;;
      -o|--output)
        set_param_value "$@"
        shift "$(get_param_shifts "$@")"
        OutputFile="$VALUE"
        ;;
      --project)
        set_param_value "$@"
        shift "$(get_param_shifts "$@")"
        Project="$VALUE"
        ;;
      --replace-file)
        set_param_value "$@"
        shift "$(get_param_shifts "$@")"
        ReplaceFile="$VALUE"
        ;;
      --skip-git-history)
        shift
        SkipGitHistory='true'
        ;;
      --subtitle)
        set_param_value "$@"
        shift "$(get_param_shifts "$@")"
        Subtitle="$VALUE"
        ;;
      --template)
        set_param_value "$@"
        shift "$(get_param_shifts "$@")"
        Template="$VALUE"
        ;;
      --title)
        set_param_value "$@"
        shift "$(get_param_shifts "$@")"
        Title="$VALUE"
        ;;
      --ascii|--bash-completion|--biblatex|-C|--citeproc|--dump-args| \
      --embed-resources|--epub-title-page|--fail-if-warnings|--file-scope| \
      --gladtex|-h|--help|--html-q-tags|-i|--ignore-args|--incremental| \
      --katex|--list-extensions|--list-highlight-languages| \
      --list-highlight-styles|--list-input-formats|--list-output-formats| \
      --list-tables|--listings|--mathml|-N|--natbib|--no-check-certificate| \
      --no-highlight|--number-sections|-p|--preserve-tabs|--reference-links| \
      -s|--sandbox|--section-divs--self-contained|--standalone| \
      --strip-comments|--table-of-contents|--toc|--trace|-v|--verbose| \
      --version|--webtex|--quiet)
        ARG="${1}"
        shift
        PandocOptions="${PandocOptions}${ARG} "
        ;;
      -*)
        set_param_value "$@"
        shift "$(get_param_shifts "$@")"
        PandocOptions="${PandocOptions}${ARG}=${VALUE} "
        ;;
      *)
        VALUE="$1"
        shift
        set -- "$@" "$VALUE"
        POSITIONAL_SHIFTS="$((POSITIONAL_SHIFTS+1))"
        PositionalInput="${PositionalInput}${VALUE} "
        ;;
    esac
  done
}
# Process script arguments and options
process_params "$@"
PandocOptions=$(echo "${PandocOptions}" | xargs)
# If InputFiles was not set with option --input-files
if test -z "${InputFiles}"; then
  # Get InputFiles from positional script arguments
  InputFiles=$(echo "${PositionalInput}" | xargs)
fi
if test -z "${InputFiles}"; then
  error '' 'Missing input files. Value not set for option --input-files' 1
fi
# Process input files (can be more than one and be in .order file)
# Disable SC2086 because word splitting is intended
# shellcheck disable=SC2086
set_InputList $InputFiles
# If using .order file(s)
if test -n "${OrderList}"; then
  # Process input files in the .order files
  # Note: if mixing both .order files and other files, the other files
  # will be added to the final input before the files in the .order files
  # Disable SC2086 because word splitting is intended
  # shellcheck disable=SC2086
  set_InputList $OrderList
fi
if test -z "${InputList}"; then
  error '' "Unable to find input: ${InputFiles}" 1
fi
# Merge markdown files into one InputContent variable
# Disable SC2086 because word splitting is intended
# shellcheck disable=SC2086
set_InputContent $InputList
# If the output file is a markdown file
if [ "$(printf '%s' "${OutputFile}" | tail -c 3)" = '.md' ]; then
  # Set input file the same as output file
  PandocInput="${OutputFile}"
elif test -n "${InputContent}"; then
  # Ensure PandocInput ends with .md and strip away existing file extension
  PandocInput="$(echo "$OutputFile" | sed 's|\(.*\)\..*|\1|')_input.md"
  # Write markdown content to file
  printf '%s\n' "${InputContent}" > "${PandocInput}"
else
  # Use the input list as it is
  PandocInput=$InputList
fi
# If the input is markdown content
if test -n "${InputContent}"; then
  # If a replace file is specified
  if test -n "${ReplaceFile}"; then
    ReplaceFilePath=$(readlink -f "${ReplaceFile}")
    if ! test -f "${ReplaceFilePath}"; then
      error '' "Unable to find replace file ${ReplaceFile}" 1
    fi
    # Read content of replace json file into tab separated key value list
    tab_values=$(jq -r 'to_entries[] | [.key, .value] | @tsv' "${ReplaceFilePath}")
    # Read each line in the tab separated key value list into key and value variable
    printf '%s\n' "${tab_values}" | while IFS="$(printf '\t')" read -r key value; do
      # If pandoc input contains key
      if [ "${InputContent#*"${key}"}" != "${InputContent}" ]; then
        info "input: replace '${key}' with '${value}'"
        # Replace key with value in InputContent (inline)
        sed -i -e "s/${key}/${value}/g" "${PandocInput}"
      fi
    done
    # Update InputContent from file
    InputContent=$(cat "${PandocInput}")
  fi
  if ! test -s "${PandocInput}"; then
    error '' "No content found in ${PandocInput}!" 1
  fi
  info "Found ${#InputContent} characters in pandoc input"
fi
# If template is specified
if test -n "${Template}"; then
  # Get template path
  case "${Template}" in
    designdoc)
      TemplateFile='/.pandoc/templates/designdoc.tex'
      TemplatePath='/.pandoc/templates'
      ;;
    eisvogel)
      TemplateFile='/.pandoc/templates/eisvogel.latex'
      TemplatePath='/.pandoc/templates'
      ;;
    *)
      TemplateFile=$(readlink -f "${Template}")
      TemplatePath=$(dirname "${TemplateFile}")
      ;;
  esac
  # If template is not found
  if ! test -f "${TemplateFile}"; then
    error '' "Unable to find template ${Template}" 1
  fi
fi
# Get metadata file path
if test -n "${InputPath}" && test -f "${InputPath}/${Template}-metadata.json"; then
  # Metadata file exist in input files folder and is prefixed with template name
  MetadataFile="${InputPath}/${Template}-metadata.json"
elif test -n "${InputPath}" && test -f "${InputPath}/metadata.json"; then
  # Metadata file exist in input files folder
  MetadataFile="${InputPath}/metadata.json"
elif test -f "${TemplatePath}/${Template}-metadata.json"; then
  # Metadata file exist in template folder and is prefixed with template name
  MetadataFile="${TemplatePath}/${Template}-metadata.json"
elif test -f "${TemplatePath}/metadata.json"; then
  # Metadata file exist in template folder
  MetadataFile="${TemplatePath}/metadata.json"
elif [ "${Template}" = 'designdoc' ]; then
  # Use default metadata file for designdoc template
  MetadataFile='/.pandoc/templates/designdoc-metadata.json'
fi
# If a metadata file is specified
if test -n "${MetadataFile}"; then
  # Update metadata file
  set_metadataField date "$(date "+%B %d, %Y")"
  set_metadataField project "${Project}"
  set_metadataField subtitle "${Subtitle}"
  set_metadataField title "${Title}"
  # If using default metadata file for designdoc template
  if [ "${MetadataFile}" = '/.pandoc/templates/designdoc-metadata.json' ]; then
    # Update path to images
    set_metadataImage logo logo
    set_metadataImage cover titlepage-top-cover-image
  fi
  # Update change history
  set_metadataChangeHistory
  PandocOptions="${PandocOptions} --metadata-file=${MetadataFile}"
fi
PandocOptions="${PandocOptions} --template=${TemplateFile}"
PandocOptions="${PandocOptions} --output=${OutputFile}"
info "Running: pandoc ${PandocOptions} ${PandocInput}"
# Disable SC2086 because word splitting is intended
# shellcheck disable=SC2086
/usr/local/bin/pandoc ${PandocOptions} ${PandocInput}
if ! test -f "${OutputFile}"; then
  error '' "Failed to create ${OutputFile}" 1
else
  # Calculate output file size
  size=$(($(stat -c '%s' "${OutputFile}") / 1000))
  info "Created ${OutputFile} (${size} KB)"
fi
