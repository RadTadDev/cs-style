#!/usr/bin/env bash
# Checks one package folder against its own .editorconfig.
#
# usage: ci/check-package.sh <package-folder>
#   e.g. ci/check-package.sh Assets/MyTools
#
# A package is any folder that contains its own .editorconfig. Each package is checked
# on its own, so packages can use different rules. Every .editorconfig must set root = true
# so rules never leak from one package into another or into the rest of the project.
#
# Exit code is non-zero when style violations or compile warnings were found.
# CI treats that as a warning, not a failure.

set -uo pipefail

pkg="${1%/}"
if [ -z "$pkg" ] || [ ! -f "$pkg/.editorconfig" ]; then
  echo "error: '$pkg' is not a package folder (no .editorconfig in it)" >&2
  exit 2
fi

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
pkg_abs="$(cd "$pkg" && pwd)"
pkg_rel="${pkg_abs#"$repo_root"/}"

# Stub project generated per package. It only exists so dotnet format has a project to work on.
# Language version is set here, not in a shared props file, so Unity's own .csproj files are untouched.
stub_dir="$repo_root/ci/.stylecheck/$(echo "$pkg_rel" | tr '/ ' '__')"
mkdir -p "$stub_dir"
stub="$stub_dir/StyleCheck.csproj"

cat > "$stub" <<EOF
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>netstandard2.1</TargetFramework>
    <LangVersion>${LANG_VERSION:-9.0}</LangVersion>
    <Nullable>disable</Nullable>
    <GenerateDocumentationFile>true</GenerateDocumentationFile>
    <EnableDefaultCompileItems>false</EnableDefaultCompileItems>
    <IsPackable>false</IsPackable>
  </PropertyGroup>
  <ItemGroup>
    <Compile Include="$pkg_abs/**/*.cs" />
  </ItemGroup>
</Project>
EOF

status=0

dotnet format whitespace "$stub" --verify-no-changes --verbosity normal || status=1
dotnet format style "$stub" --verify-no-changes --severity info --verbosity normal || status=1

dotnet build "$stub" --nologo > "$stub_dir/build.log" 2>&1 || status=1
# Surface compiler warnings (CS1591 missing docs, etc.) so they show up in the CI log.
grep -E ': (warning|error) ' "$stub_dir/build.log" | sort -u || true

exit $status
