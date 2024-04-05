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
test_arg() {
  if [ $# -lt 4 ] || test -z "${4}" || echo "${4}" | grep -Eq '^-.*'; then
    if [ "${1}" = 'default' ]; then
      echo "${2}"
    else
      error '' "Value not set for argument ${3}" 1
    fi
  else
    echo "${4}"
  fi
}
test_true_false() {
  if [ $# -gt 1 ]; then
    local default="${2}"
  else
    local default='false'
  fi
  local value
  value="$(echo "${1}" | awk '{ print tolower($0) }')"
  if test -z "${value}"; then
    echo "${default}"
  elif [ "${value}" = 'true' ] || [ "${value}" = 'yes' ] || [ "${value}" = '1' ]; then
    echo 'true'
  elif [ "${value}" = 'false' ] || [ "${value}" = 'no' ] || [ "${value}" = '0' ]; then
    echo 'false'
  else
    echo "${default}"
  fi
}
get_file_path() {
  if test -z "${1}"; then
    echo ''
  elif test -e "${1}"; then
    readlink -f "${1}"
  elif test -e "${2}/${1}"; then
    readlink -f "${2}/${1}"
  else
    echo ''
  fi
}
get_version_history() {
  if test -n "${historyFilePath}"; then
    if ! test -f "${historyFilePath}"; then
      error '' "Unable to find history file ${historyFilePath}" 1
    fi
    mergeLogs=$(cat "${historyFilePath}")
  elif [ "${SkipGitCommitHistory}" = 'true' ]; then
    mergeLogs="tag: rel/repo/1.0.0|${currentDate}|${MainAuthor}|${FirstChangeDescription}"
  else
    mergeLogs=$(
      git --no-pager log "-${GitLogLimit}" --date-order --date=format:'%b %e, %Y' \
        --no-merges --oneline --pretty=format:'%D|%ad|%an|%s' "${DocsPath}"
    )
  fi
  if test -z "${mergeLogs}"; then
    mergeLogs="tag: rel/repo/1.0.0|${currentDate}|${MainAuthor}|${FirstChangeDescription}"
  fi
  lineCount=$(echo "${mergeLogs}" | wc -l)
  historyJson='[]'
  printf '%s\n' "${mergeLogs}" | while read -r line; do
    lineCount=$((lineCount-1))
    version="$(echo "$line" | cut -d'|' -f1 | rev | cut -d'/' -f1 | rev)"
    if test -z "${version}" || ! echo "${version}" | grep -Eq '^[0-9].*'; then
      version="1.0.${lineCount}"
    fi
    date="$(echo "${line}" | cut -d'|' -f2)"
    author="$(echo "${line}" | cut -d'|' -f3)"
    description="$(echo "${line}" | cut -d'|' -f4)"
    if test -f tmp_history_41231.json; then
      historyJson=$(jq '.' tmp_history_41231.json)
    fi
    printf '%s\n' "${historyJson}" | jq --arg version "${version}" \
      --arg date "${date}" \
      --arg author "${author}" \
      --arg description "${description}" \
      '. +=[{ version: $version, date: $date, author: $author, description: $description }]' > tmp_history_41231.json
  done
  if test -f tmp_history_41231.json; then
    jq '.' tmp_history_41231.json
  else
    printf '%s\n' '[]' | jq --arg version '1.0.0' \
        --arg date "${currentDate}" \
        --arg author "${MainAuthor}" \
        --arg description "${FirstChangeDescription}" \
        '. +=[{ version: $version, date: $date, author: $author, description: $description }]' > tmp_history_41231.json
    jq '.' tmp_history_41231.json
  fi
  rm -f tmp_history_41231.json
}
set_metadataContent() {
  metadataContent="$(cat)"
}
set_metadataContentFixed() {
  metadataContentFixed="$(cat)"
}
process_params() {
  while [ $# -gt 0 ]; do
    case "${1}" in
      -a|--author)
        MainAuthor=$(test_arg default 'Innofactor' "$@")
        shift 2
        ;;
      --columns)
        Columns="${2}"
        shift 2
        ;;
      -d|--description)
        FirstChangeDescription=$(test_arg default 'Initial draft' "$@")
        shift 2
        ;;
      -f|--folder)
        DocsPath=$(test_arg fail '' "$@")
        shift 2
        ;;
      --force-default)
        shift
        if [ $# -eq 0 ] || echo "${1}" | grep -Eq '^-.*'; then
          SkipGitCommitHistory='true'
        else
          SkipGitCommitHistory=$(test_true_false "${1}")
          shift
        fi
        ;;
      --from)
        InputFormat="${2}"
        shift 2
        ;;
      -h|--historyfile)
        HistoryFile=$(test_arg default '' "$@")
        shift 2
        ;;
      -i|--inputfile)
        InputFile=$(test_arg fail '' "$@")
        shift 2
        ;;
      -l|--gitloglimit)
        GitLogLimit=$(test_arg default 15 "$@")
        shift 2
        ;;
      -o|--outfile)
        OutFile=$(test_arg default 'document.pdf' "$@")
        shift 2
        ;;
      --outfolder)
        OutFolder=$(test_arg default '' "$@")
        shift 2
        ;;
      -p|--project)
        Project=$(test_arg default '' "$@")
        shift 2
        ;;
      --pdf-engine)
        PDFEngine=$(test_arg default 'xelatex' "$@")
        shift 2
        ;;
      -r|--replacefile)
        ReplaceFile=$(test_arg default '' "$@")
        shift 2
        ;;
      -s|--subtitle)
        Subtitle=$(test_arg default '' "$@")
        shift 2
        ;;
      -t|--title)
        Title=$(test_arg fail '' "$@")
        shift 2
        ;;
      --template)
        Template="${2}"
        shift 2
        ;;
      *)
        warning "Unknown parameter: ${1}"
        exit 1
        ;;
    esac
  done
}
Columns=72
DocsPath='docs'
FirstChangeDescription='Initial draft'
GitLogLimit=15
HistoryFile=''
InputFile='document.order'
InputFormat='markdown+backtick_code_blocks+escaped_line_breaks+footnotes+implicit_header_references+inline_notes+line_blocks+space_in_atx_header+table_captions+grid_tables+pipe_tables+task_lists+yaml_metadata_block'
MainAuthor='Innofactor'
OutFile='document.pdf'
OutFolder=''
PDFEngine='xelatex'
Project=''
ReplaceFile=''
SkipGitCommitHistory='false'
Subtitle=''
Template='designdoc'
Title=''
process_params "$@"
if test -z "${Title}"; then
  error '' 'Missing Title: Value not set for argument --title' 1
fi
currentPath=$(pwd)
if test -z "${OutFolder}"; then
  OutFolder=$currentPath
fi
# Ensure OutFile has full path
if ! echo "${OutFile}" | grep -Eq '^[a-zA-Z]:\\.*' && ! echo "${OutFile}" | grep -Eq '^/.*'; then
  OutFile="${OutFolder}/${OutFile}"
fi
if ! echo "${DocsPath}" | grep -Eq '^[a-zA-Z]:\\.*' && ! echo "${DocsPath}" | grep -Eq '^/.*'; then
  DocsPath="${currentPath}/${DocsPath}"
fi
if ! test -d "${DocsPath}"; then
  error '' "Unable to find folder ${DocsPath}" 1
fi
# Get path to files in the same folder as the docs
historyFilePath=$(get_file_path "${HistoryFile}" "${DocsPath}")
inputFilePath=$(get_file_path "${InputFile}" "${DocsPath}")
if ! test -f "${inputFilePath}"; then
  error '' "Unable to find input file ${inputFilePath}" 1
fi
replaceFilePath=$(get_file_path "${ReplaceFile}" "${DocsPath}")
# Get built in template
templateFilePath=$(get_file_path "${Template}.tex" '/.pandoc/templates')
# If build in template was not found
if ! test -f "${templateFilePath}"; then
  # Get specified template
  templateFilePath=$(get_file_path "${Template}" '')
  # If specified template was not found
  if ! test -f "${templateFilePath}"; then
    error '' "Unable to find template file ${templateFilePath}" 1
  fi
fi
if [ "$(printf '%s' "${OutFile}" | tail -c 3)" = '.md' ]; then
  mdOutFile="${OutFile}"
elif [ "$(printf '%s' "${inputFilePath}" | tail -c 3)" = '.md' ]; then
  mdOutFile="${inputFilePath}"
else
  mdOutFile="$(echo "$OutFile" | sed 's/.pdf$//g').md"
fi
currentDate=$(date "+%B %d, %Y")
templateCoverFilePath=$(get_file_path "${Template}-cover.png" "${DocsPath}")
if ! test -f "${templateCoverFilePath}"; then
  templateCoverFilePath=$(get_file_path "$(echo "$templateFilePath" | sed 's/.tex$//g')-cover.png" '')
  if [ "${Template}" = 'designdoc' ] && ! test -f "${templateCoverFilePath}"; then
    error '' "Unable to find template cover file ${templateCoverFilePath}" 1
  fi
fi
templateLogoFilePath=$(get_file_path "${Template}-logo.png" "${DocsPath}")
if ! test -f "${templateLogoFilePath}"; then
  templateLogoFilePath=$(get_file_path "$(echo "$templateFilePath" | sed 's/.tex$//g')-logo.png" '')
  if [ "${Template}" = 'designdoc' ] && ! test -f "${templateLogoFilePath}"; then
    error '' "Unable to find template logo file ${templateLogoFilePath}" 1
  fi
fi
metaFilePathFixed="${OutFolder}/metadata_fixed.json"
metaFilePath=$(get_file_path "${Template}-metadata.json" "${DocsPath}")
if ! test -f "${metaFilePath}"; then
  metaFilePath=$(get_file_path 'metadata.json' "${DocsPath}")
  if ! test -f "${metaFilePath}"; then
    metaFilePath=$(get_file_path "${Template}-metadata.json" "$(dirname "${templateFilePath}")")
    if ! test -f "${metaFilePath}"; then
      metaFilePath=$(get_file_path 'metadata.json' "$(dirname "${templateFilePath}")")
    fi
  fi
fi
if ! test -f "${metaFilePath}"; then
  metaFilePath="${OutFolder}/metadata.json"
fi
info 'Inputs and calculated values:'
info "- Columns:                ${Columns}"
info "- CurrentDate:            ${currentDate}"
info "- CurrentPath:            ${currentPath}"
info "- DocsPath:               ${DocsPath}"
info "- FirstChangeDescription: ${FirstChangeDescription}"
info "- GitLogLimit:            ${GitLogLimit}"
info "- HistoryFile:            ${HistoryFile}"
info "- HistoryFilePath:        ${historyFilePath}"
info "- InputFile:              ${InputFile}"
info "- InputFilePath:          ${inputFilePath}"
info "- InputFormat:            ${InputFormat}"
info "- MainAuthor:             ${MainAuthor}"
info "- MetaFilePath:           ${metaFilePath}"
info "- metaFilePathFixed:      ${metaFilePathFixed}"
info "- OutFile:                ${OutFile}"
info "- OutFile markdown:       ${mdOutFile}"
info "- OutFolder:              ${OutFolder}"
info "- PDFEngine:              ${PDFEngine}"
info "- Project:                ${Project}"
info "- ReplaceFile:            ${ReplaceFile}"
info "- ReplaceFilePath:        ${replaceFilePath}"
info "- SkipGitCommitHistory:   ${SkipGitCommitHistory}"
info "- Subtitle:               ${Subtitle}"
info "- Template:               ${Template}"
info "- TemplateFilePath:       ${templateFilePath}"
info "- TemplateCoverFilePath:  ${templateCoverFilePath}"
info "- TemplateLogoFilePath:   ${templateLogoFilePath}"
info "- Title:                  ${Title}"
if [ "$(printf '%s' "${inputFilePath}" | tail -c 6)" = '.order' ]; then
  info "Merge markdown files in ${inputFilePath}"
  printf '%s\n' "$(cat "${inputFilePath}")" | while read -r line; do
    if test -n "${line}" && ! [ "$(printf '%s' "$line" | cut -c 1)" = '#' ]; then
      if ! test -f "${DocsPath}/${line}"; then
        error '' "Unable to find markdown file ${DocsPath}/${line}" 1
      fi
      mdFile="$(readlink -f "${DocsPath}/${line}")"
      mdPath="$(dirname "$mdFile")"
      tmpContent=$(
        printf '%s' "$(sed -e "s|\(\[.*\](\)\(\../\)\(.*)\)|\1${mdPath}/\2\3|g" "${mdFile}" | sed -e "s|\(\[.*\](\)\(\./\)\(.*)\)|\1${mdPath}/\3|g" | sed -e "s|\(\[.*\](\)\(asset\)\(.*)\)|\1${mdPath}/\2\3|g" | sed -e "s|\(\[.*\](\)\(attach\)\(.*)\)|\1${mdPath}/\2\3|g" | sed -e "s|\(\[.*\](\)\(image\)\(.*)\)|\1${mdPath}/\2\3|g" | sed -e "s|\(\[.*\](\)\(\.\)\(.*)\)|\1${mdPath}/\2\3|g")"
      )
      if test -n "${tmpContent}"; then
        info "Found ${#tmpContent} characters in ${mdFile}"
        if ! test -f "${mdOutFile}"; then
          printf '%s\n' "${tmpContent}" > "${mdOutFile}"
        else
          printf '\n%s\n' "${tmpContent}" >> "${mdOutFile}"
        fi
      fi
    else
      info "Ignore ${line}"
    fi
  done
  info 'Done merging markdown files'
fi
if ! test -s "${mdOutFile}"; then
  warning "No content found in ${mdOutFile}!"
  exit 1
fi
mdContent=$(cat "${mdOutFile}")
if test -n "${ReplaceFile}"; then
  if ! test -f "${replaceFilePath}"; then
    error '' "Unable to find replace file ${replaceFilePath}" 1
  fi
  info 'Perform replace in markdown'
  tab_values=$(jq -r 'to_entries[] | [.key, .value] | @tsv' "${replaceFilePath}")
  printf '%s\n' "${tab_values}" | while IFS="$(printf '\t')" read -r key value; do
    printf '%s\n' "${mdContent}" | sed -e "s/${key}/${value}/g" > "${mdOutFile}"
  done
  mdContent="$(cat "${mdOutFile}")"
fi
if test -n "${mdContent}"; then
  info "The markdown contains ${#mdContent} characters"
  if ! [ "$(printf '%s' "${OutFile}" | tail -c 3)" = '.md' ]; then
    # If meta data file is not present in docs folder, create it
    if ! test -f "${metaFilePath}"; then
      set_metadataContent <<META_DATA || true
{
  "block-headings": true,
  "colorlinks": true,
  "disable-header-and-footer": false,
  "disclaimer": "This document contains business and trade secrets (essential information about Innofactor's business) and is therefore totally confidential. Confidentiality does not apply to pricing information",
  "page-numbers": true,
  "geometry":"a4paper,left=2.54cm,right=2.54cm,top=1.91cm,bottom=2.54cm",
  "links-as-notes": true,
  "listings-disable-line-numbers": false,
  "listings-no-page-break": false,
  "lof": false,
  "lot": false,
  "mainfont": "Carlito",
  "pandoc-latex-environment": {
    "warningblock": ["warning"],
    "importantblock": ["important"],
    "noteblock": ["note"],
    "cautionblock": ["caution"],
    "tipblock": ["tip"]
  },
  "table-use-row-colors": false,
  "tables": true,
  "titlepage": true,
  "titlepage-color":"FFFFFF",
  "titlepage-text-color": "5F5F5F",
  "toc": true,
  "toc-own-page": true,
  "toc-title": "Table of Contents"
}
META_DATA
      info "set metadataContent"
      printf '%s\n' "${metadataContent}" | jq '.' > "${metaFilePath}"
      info "done metadataContent"
    fi
    info 'Get version history'
    versionHistory=$(get_version_history)
    authors="[$(echo "${versionHistory}" | jq '.[].author' | uniq | sed ':a; N; $!ba; s/\n/,/g')]"
    set_metadataContentFixed <<META_DATA_FIXED || true
{
  "author": ${authors},
  "version-history": ${versionHistory}
}
META_DATA_FIXED
    printf '%s\n' "${metadataContentFixed}" | jq '.' > "${metaFilePathFixed}"
    # Change to the docs path so image paths can be relative
    cd "${DocsPath}"
    info "Create ${OutFile}"
    printf '%s' "${mdContent}" | pandoc \
      --columns="${Columns}" \
      --dpi=300 \
      --filter pandoc-latex-environment \
      --from="${InputFormat}" \
      --standalone \
      --listings \
      --metadata=date:"${currentDate}" \
      --metadata=logo:"${templateLogoFilePath}" \
      --metadata=project:"${Project}" \
      --metadata=subtitle:"${Subtitle}" \
      --metadata=title:"${Title}" \
      --metadata=titlepage-top-cover-image:"${templateCoverFilePath}" \
      --metadata-file="${metaFilePath}" \
      --metadata-file="${metaFilePathFixed}" \
      --output="${OutFile}" \
      --pdf-engine="${PDFEngine}" \
      --template="${templateFilePath}"
    cd "${currentPath}"
  fi
  if ! test -f "${OutFile}"; then
    warning "Unable to create ${OutFile}"
  else
    size=$(($(stat -c '%s' "${OutFile}") / 1000))
    info "Created ${OutFile} using ${size} KB"
  fi
else
  warning "Could not find any markdown content to convert from ${InputFile}"
fi
