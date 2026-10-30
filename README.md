# cs-style

Shared C# style baseline for Unity and plain .NET projects. It provides an `.editorconfig`, shared compiler settings, and a non-blocking CI style check.

## What's in here

| File | Purpose |
|---|---|
| `.editorconfig` | The single source of style rules. Read by Visual Studio Code, Rider, and `dotnet format`. |
| `Directory.Build.props` | Language version (C# 9), nullable off, and XML doc file generation. |
| `ci/StyleCheck/StyleCheck.csproj` | CI-only project that includes every `.cs` file in the repo so `dotnet format` can check them. |
| `.github/workflows/style.yml` | Runs the style check on pull requests. Violations are reported as warnings and never block a merge. |
| `.vscode/extensions.json` | Recommends the C# and EditorConfig extensions. |
| `.gitattributes` | Forces LF line endings. |

## Baseline rules

- C# 9 (Unity 2022 and Unity 6 compatible). Change `LangVersion` in `Directory.Build.props` to upgrade.
- 4 spaces, LF, Allman braces, block-scoped namespaces, `using` outside the namespace.
- Private fields are `_camelCase`. Constants and static readonly fields are `PascalCase`. Async methods end in `Async`. Interfaces start with `I`.
- `this.` only when required. `var` only when the type is apparent.
- Nullable reference types are disabled.
- Public and protected members need `///` doc comments (warning CS1591). Param and return tags are not checked.
- The 120-character line length is an editor hint, not an enforced rule.

## Using it in a project

Copy these into the project root:

- `.editorconfig`
- `Directory.Build.props`
- `ci/`
- `.github/workflows/style.yml`
- `.vscode/extensions.json` (optional)
- `.gitattributes`

Then run the formatter locally:

```bash
dotnet format whitespace ci/StyleCheck/StyleCheck.csproj --verify-no-changes
dotnet format style ci/StyleCheck/StyleCheck.csproj --verify-no-changes --severity info
```

Use the non-verifying form to apply the fixes:

```bash
dotnet format ci/StyleCheck/StyleCheck.csproj --severity info
```

## How CI reports

Each push and pull request runs the workflow. Violations appear in the job summary and as warnings on the run. The job always passes, so merges are never blocked.

## Known limits

- Param and return doc tags are not enforced. That would need the StyleCop analyzer, which was deliberately left out.
- The CI project has no Unity references, so the compiler step will show errors about Unity types. The CS1591 warnings still come through, but this has not been verified.
- Rider reads `.editorconfig` directly, so it needs no extra files.
