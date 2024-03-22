#!/bin/sh

usage ()
{
    printf 'build.sh: Generates all parameters for the docker image\n\n'
    printf 'Usage: %s ACTION [OPTIONS] [EXTRA BUILD ARGS]\n\n' "$0"
    printf 'Actions:\n'
    printf '\tbuild: build and tag the image\n'
    printf '\tpush: push the tags to Docker Hub\n\n'
    printf 'Options:\n'
    printf '  -c: targeted pandoc commit, e.g. 2.9.2.1\n'
    printf '  -d: directory\n'
    printf '  -f: create freeze file\n'
    printf '  -r: targeted image repository/flavor, e.g. core or latex\n'
    printf '  -s: stack on which the image will be based\n'
    printf '  -t: docker build target\n'
    printf '  -v: increase verbosity\n'
}

create_freeze=
directory=.
pandoc_commit=main
repo=core
stack=static
target=${stack}-${repo}
verbosity=0

### Actions
action=${1}
shift

printf 'Performing %s with these parameters:\n' "$action"

while [ $# -gt 0 ]; do
    case "$1" in
        (-c)
            pandoc_commit="${2}"
            printf '\tpandoc_commit: %s\n' "$pandoc_commit"
            shift 2
            ;;
        (-d)
            directory="${2}"
            printf '\tdirectory: %s\n' "$directory"
            shift 2
            ;;
        (-r)
            repo="${2}"
            printf '\trepository: %s\n' "$repo"
            shift 2
            ;;
        (-s)
            stack="${2}"
            printf '\tstack: %s\n' "$stack"
            shift 2
            ;;
        (-t)
            target="${2}"
            printf '\ttarget: %s\n' "$target"
            shift 2
            ;;
        (-f)
            create_freeze='true'
            printf '\tcreate freeze file: true\n'
            shift
            ;;
        (-v)
            printf 'shift -v\n'
            verbosity=$((verbosity + 1))
            printf '\tverbosity: %s\n' "${verbosity}"
            shift
            ;;
        (--)
            shift
            break
            ;;
        (*)
            if [ -n "$1" ]; then
              printf 'Unknown option: %s\n' "$1"
              usage
              exit 1
            fi
            shift
            ;;
    esac
done

pandoc_version=${pandoc_commit}
if [ "$pandoc_commit" = "main" ]; then
    pandoc_version=edge
fi

# File containing the version table
version_table_file="${directory}/versions.md"
if [ ! -f "$version_table_file" ]; then
    printf 'Version table not found: %s\n' "$version_table_file" >&2
    exit 1
fi
printf '\tversion_table_file: %s\n' "${version_table_file}"

# File containing the default stack config
stack_table_file="${directory}/default-stack.md"
if [ ! -f "$stack_table_file" ]; then
    printf 'Stack table not found: %s\n' "$stack_table_file" >&2
    exit 1
fi

pandoc_version_opts=$(grep "^| *${pandoc_commit} *|" "$version_table_file")
if [ -z "$pandoc_version_opts" ]; then
    printf 'Unsupported version: %s; aborting!\n' "$pandoc_commit" >&2
    exit 1
fi

freeze_file="${directory}/${stack}/freeze/pandoc-$pandoc_commit.project.freeze"
if [ "$pandoc_commit" != "main" ] && [ ! -f "$freeze_file" ] && [ -z "$create_freeze" ]; then
    printf 'Freeze file not found: %s\n' "$freeze_file" >&2
    exit 1
fi

version_table_field ()
{
    printf '%s\n' "$pandoc_version_opts" | \
        awk -F '|' "{ gsub(/^ *| *\$/,\"\",\$$1); print \$$1 }"
}

base_image_version=
case "$stack" in
    (alpine)
        base_image_version=$(version_table_field 4)
        ;;
    (static)
        # The static binary is built on alpine
        base_image_version=$(version_table_field 4)
        ;;
    (ubuntu)
        base_image_version=$(version_table_field 5)
        ;;
    (*)
        printf 'Unknown stack: %s\n' "$stack" >&2
        exit 1
        ;;
esac
printf '\tbase_image_version: %s\n' "$base_image_version"

tag_versions=$(version_table_field 3)
printf '\ttag_versions: %s\n' "$tag_versions"
texlive_version=$(version_table_field 6)
printf '\ttexlive_version: %s\n' "$texlive_version"
lua_version=$(version_table_field 7)
printf '\tlua_version: %s\n' "$lua_version"

# Crossref
extra_packages=pandoc-crossref
without_crossref=

# Do not build pandoc-crossref for static images
if [ "$stack" = "static" ]; then
    extra_packages=
    without_crossref=true
fi
printf '\twithout_crossref: %s\n' "${without_crossref}"

## The pandoc-cli package did not exist pre pandoc 3.
## Do not try to build it if the commit starts with a 2.
if [ "${pandoc_commit#2}" = "${pandoc_commit}" ]; then
    extra_packages="pandoc-cli ${extra_packages}"
fi
printf '\textra_packages: %s\n' "$extra_packages"

# Succeeds if the stack is the default for this repo, in which case the
# stack can be omitted from the tag.
is_default_stack_for_repo ()
{
    grep -q "^| *$repo *| *${stack} *|$" "$stack_table_file"
}

# ARG 1: pandoc version
# ARG 2: stack
image_name ()
{
    if [ -z "$2" ]; then
        printf 'ghcr.io/innofactororg/%s:%s' "$repo" "${1:-edge}"
    else
        printf 'ghcr.io/innofactororg/%s:%s-%s' "$repo" "${1:-edge}" "$2"
    fi
}

# List all tags for this image.
tags ()
{
    for tag_version in $tag_versions; do
        printf '%s\n' "$(image_name "$tag_version" "$stack")"
    done
    if is_default_stack_for_repo; then
        for tag_version in $tag_versions; do
            printf '%s\n' "$(image_name "$tag_version")"
        done
    fi
}

# Produce the "tag" command line arguments for `docker build`
tag_arguments ()
{
    for tag in $(tags); do
        printf ' --tag=%s' "$tag"
    done
}

case "$action" in
    (push)
        for tag in $(tags); do
            printf 'Pushing %s...\n' "$tag"
            docker push "${tag}" ||
                exit 5
        done
        ;;
    (build)
        ## build images
        # The use of $(tag_arguments) is correct here
        # shellcheck disable=SC2046
        printf 'Run docker build %s\n' "$@"
        docker build "$@" \
               "$(tag_arguments)" \
               --build-arg pandoc_commit="${pandoc_commit}" \
               --build-arg pandoc_version="${pandoc_version}" \
               --build-arg without_crossref="${without_crossref}" \
               --build-arg extra_packages="${extra_packages}"\
               --build-arg base_image_version="${base_image_version}" \
               --build-arg texlive_version="${texlive_version}" \
               --build-arg lua_version="${lua_version}" \
               --target "${target}"\
               -f "${directory}/${stack}/Dockerfile"\
               "${directory}"
        ;;
    (*)
        printf 'Unknown action: %s\n' "$action"
        exit 2
        ;;
esac
