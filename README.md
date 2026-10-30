# cs-style

C# style baseline for Unity and plain .NET packages. It provides an `.editorconfig`, a per-package check script, and a non-blocking CI workflow.

## Model: one package, one set of rules

Rules are scoped by folder, not by assembly definition. A package is any folder that contains its own `.editorconfig`. The rules in that file apply to every file beneath the folder, and to nothing outside it. Each package can use different rules.

- Every `.editorconfig` must set `root = true`. That stops rules from leaking up into the parent project.
- Projects with no `.editorconfig` outside a package are untouched. Unity's `Packages/` folder and game code are not checked unless you add a `.editorconfig` there.
- Do not put a `.editorconfig` at a Unity project root. Its rules would reach every file in the project, including game code.

## What's in here

| Path | Purpose |
|---|---|
| `baseline/.editorconfig` | The default rules. Copy it into each package folder. |
| `ci/check-package.sh` | Checks one package folder. Builds a temporary stub project, runs `dotnet format`, and reports compile warnings. |
| `.github/workflows/style.yml` | Finds every package folder and checks each one. Violations are warnings and never block a merge. |
| `.vscode/extensions.json` | Recommends the C# and EditorConfig extensions. Harmless if copied to a project root. |
| `.gitattributes` | Forces LF line endings. |

## Baseline rules

- C# 9, Unity 2022 and Unity 6 compatible. The language version is set in `ci/check-package.sh` (override with `LANG_VERSION`). Unity's own `.csproj` files are not touched.
- 4 spaces, LF, Allman braces, block-scoped namespaces, `using` outside the namespace.
- Private fields are `_camelCase`. Constants and static readonly fields are `PascalCase`. Async methods end in `Async`. Interfaces start with `I`.
- `this.` only when required. `var` only when the type is apparent.
- Nullable reference types are disabled.
- Public and protected members need `///` doc comments (warning CS1591). Param and return tags are not checked.
- The 120-character line length is an editor hint, not an enforced rule.

## Adding a package

1. Copy `baseline/.editorconfig` into the package folder, for example `Assets/MyTools/.editorconfig`.
2. Edit the copy to change that package's rules. Keep `root = true`.
3. Commit it. CI will check the package on the next run.

To check one package locally (requires the .NET 8 SDK, bash, and a Unix-style shell):

```bash
bash ci/check-package.sh Assets/MyTools
```

## How CI reports

Each push and pull request finds every folder with its own `.editorconfig` and checks each one. Results appear in the job summary, with a warning per package that has violations. The job always passes, so merges are never blocked.

## Known limits

- Param and return doc tags are not enforced. That would need the StyleCop analyzer, which was deliberately left out.
- The stub project has no Unity references, so the build step reports errors about Unity types. The CS1591 documentation warnings still come through, but this has not been verified.
- Because the Unity project's own `.csproj` files are no longer given `GenerateDocumentationFile`, CS1591 will not show in Rider or VS Code while you edit. It only appears in CI.
