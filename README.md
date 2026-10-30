# cs-style

Shared C# style baseline for Unity and plain .NET projects. It provides an `.editorconfig`, shared compiler settings, and a non-blocking CI style check.

The rules apply to the folder they are placed in and everything beneath it. This repo is a tool and is not meant to be bundled into a package's export path.

## What's in here

| File | Purpose |
|---|---|
| `.editorconfig` | The single source of style rules. Read by Visual Studio Code, Rider, and `dotnet format`. |
| `Directory.Build.props` | Language version (C# 9), nullable off, and XML doc file generation. |
| `ci/StyleCheck/StyleCheck.csproj` | CI-only project that includes every `.cs` file in the repo so `dotnet format` can check them. |
| `ci/DocCheck/` | CI-only tool that reports missing XML docs and syntax newer than the target C# version. It only parses files, so it works on Unity code without UnityEngine. |
| `ci/annotate.sh` | Turns tool output into warning annotations on the PR. |
| `.github/workflows/style.yml` | Runs the checks on pull requests. Violations are reported as warnings and never block a merge. |
| `.vscode/extensions.json` | Recommends the C# and EditorConfig extensions. |
| `.gitattributes` | Forces LF line endings. |

## Baseline rules

- C# 9 (Unity 2022 and Unity 6 compatible). Change `LangVersion` in `Directory.Build.props` to upgrade. For C# 13 or later, also raise the `Microsoft.CodeAnalysis.CSharp` version in `ci/DocCheck/DocCheck.csproj`.
- 4 spaces, LF, Allman braces, block-scoped namespaces, `using` outside the namespace, `System` usings first.
- Private fields are `_camelCase`. Constants and static readonly fields are `PascalCase`. Async methods end in `Async`. Interfaces start with `I`. Types and members are `PascalCase`.
- `this.` only when required.
- `var` only when the type is apparent. Built-in types (`int`, `string`, ...) always use the keyword.
- Nullable reference types are disabled.
- Public and protected members need `///` doc comments (CS1591). `<inheritdoc />` counts. Param and return tags are not checked.
- The 120-character line length is an editor hint, not an enforced rule.

## Using it in a project

Copy these into the project root:

- `.editorconfig`
- `Directory.Build.props`
- `ci/`
- `.github/workflows/style.yml`
- `.vscode/extensions.json` (optional)
- `.gitattributes`

Check locally:

```bash
dotnet format whitespace ci/StyleCheck/StyleCheck.csproj --verify-no-changes
```

```bash
dotnet format style ci/StyleCheck/StyleCheck.csproj --verify-no-changes
```

```bash
dotnet run --project ci/DocCheck/DocCheck.csproj -- .
```

Fix whitespace and style. Run style first: on Windows its fixes can insert CRLF, and the whitespace pass converts them back to LF.

```bash
dotnet format style ci/StyleCheck/StyleCheck.csproj
```

```bash
dotnet format whitespace ci/StyleCheck/StyleCheck.csproj
```

Naming violations and missing docs are not auto-fixed. Rename the symbol, or add the doc comment.

## How CI reports

Each push and pull request runs three checks: whitespace, style and naming, and documentation plus language version. Each finding becomes a warning annotation on the file and line. GitHub shows up to 10 per check. The job summary lists every finding. The job always passes, so merges are never blocked.

## Known limits

- Rules must be at `warning` severity to show up in CI. `dotnet format` ignores `suggestion`-level rules.
- `UPPER_SNAKE_CASE` constants such as `MAX_SPEED` pass the PascalCase rule. Roslyn only checks that the first letter is uppercase.
- Param and return doc tags are not enforced. That would need the StyleCop analyzer, which was deliberately left out.
- DocCheck does not read `.editorconfig`. Turning off CS1591 there will not silence it in CI.
- Code inside `#if` blocks that are not defined by default (such as `#if UNITY_EDITOR`) is not checked by DocCheck.
- Rider reads `.editorconfig` directly, so it needs no extra files.
