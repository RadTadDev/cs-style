# cs-style

Shared C# style baseline for Unity and plain .NET projects. It provides an `.editorconfig`, shared compiler settings, and a non-blocking CI style check.

The rules apply to the folder they are placed in and everything beneath it. This repo is a tool and is not meant to be bundled into a package's export path.

## What's in here

| File | Purpose |
|---|---|
| `.editorconfig` | The single source of style rules. Read by Visual Studio Code, Rider, and `dotnet format`. |
| `Directory.Build.props` | Language version (C# 9), nullable off, and XML doc file generation for SDK-style projects (the CI projects and plain .NET). |
| `Directory.Build.targets` | Turns on the XML doc file in Unity's generated `.csproj` files, so Rider and VS Code report missing docs in Unity code. |
| `ci/StyleCheck/StyleCheck.csproj` | CI-only project that includes every `.cs` file in the repo so `dotnet format` can check them. |
| `ci/DocCheck/` | CI-only tool that reports missing XML docs and syntax newer than the target C# version. It only parses files, so it works on Unity code without UnityEngine. |
| `ci/annotate.sh` | Turns tool output into annotations on the PR. |
| `.github/workflows/style.yml` | Runs the checks on pull requests. The job fails when there are findings, but it is not a required check, so it never blocks a merge. |
| `.vscode/extensions.json` | Recommends the C# and EditorConfig extensions. VS Code offers to install them when the folder is opened. Nothing else in `.vscode/` is committed. |
| `.gitattributes` | Forces LF line endings. |

## Baseline rules

- C# 9 (Unity 2022 and Unity 6 compatible). Change `LangVersion` in `Directory.Build.props` to upgrade. For C# 13 or later, also raise the `Microsoft.CodeAnalysis.CSharp` version in `ci/DocCheck/DocCheck.csproj`.
- 4 spaces, LF, Allman braces, block-scoped namespaces, `using` outside the namespace, `System` usings first.
- Braces on every `if`/`else`/`for`/`foreach`/`while`/`using`/`lock` body, even a single statement.
- `switch` labels and case bodies are indented. No space after a cast: `(int)value`.
- Blank lines, checked in CI: never two in a row, one after a closing brace before the next statement, and none between two braces of the same kind (`}` blank line `}`).
- Blank lines, Rider only (applied when Rider reformats code): one around methods and properties with bodies, which also separates the fields from the first method; consecutive single-line fields and auto-properties stay grouped; no blank line just inside `{` or `}`, including an empty body. Text inside doc comment tags such as `<summary>` is not indented.
- Private fields are `_camelCase`. Constants and static readonly fields are `PascalCase`. Async methods end in `Async`. Interfaces start with `I`. Types and members are `PascalCase`.
- `this.` only when required.
- `var` only when the type is apparent. Built-in types (`int`, `string`, ...) always use the keyword.
- Nullable reference types are disabled.
- Public and protected members need `///` doc comments (CS1591). Param and return tags are not checked.
- Overrides and interface implementations also need a comment. Docs are not inherited implicitly: the compiler reports CS1591 for them too, even though Rider and Visual Studio show the base docs on hover. Write `/// <inheritdoc />` to reuse the base or interface docs. Rider's quick-fix on the warning can add it.
- The 120-character line length is an editor hint, not an enforced rule.

## Using it in a project

Copy these into the project root:

- `.editorconfig`
- `Directory.Build.props`
- `Directory.Build.targets`
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

Each push and pull request runs three checks: whitespace, style and naming, and documentation plus language version. Each finding becomes an annotation on the file and line. GitHub shows up to 10 per check. The job summary lists every finding.

Any finding, including warnings, fails the job, so the PR shows a red X. All three checks still run. The check is not required in branch protection, so a failing run does not block a merge. Making it required is what would turn it into a gate.

## Editors

- **VS Code**: the C# extension reads `.editorconfig` and shows naming, style, and missing-doc warnings as you type.
- **Rider**: reads `.editorconfig` by default (Settings | Editor | Code Style, and Settings | Editor | Inspection Settings, "Read settings from editorconfig, project settings and rule sets"). The `resharper_*` keys in `.editorconfig` raise Rider's own inspections for `var`, `this.`, namespaces, naming, and missing docs to warning to match CI. If a project was opened before these files were added, reopen it.
- **Missing docs in the IDE**: both editors report CS1591 for public and protected members without `///` comments. In plain .NET projects this comes from `GenerateDocumentationFile` in `Directory.Build.props`. Unity's generated `.csproj` files are old-style projects that skip `Directory.Build.props`, so `Directory.Build.targets` sets the doc file for them instead. It only affects the IDE: Unity compiles scripts itself, so builds and the Unity Console are unchanged. After adding it, reload the projects in Rider (or reopen the solution). DocCheck also covers code the IDE cannot compile. Run it locally with the command above.

## Known limits

- Rules must be at `warning` severity to show up in CI. `dotnet format` ignores `suggestion`-level rules.
- `UPPER_SNAKE_CASE` constants such as `MAX_SPEED` pass the PascalCase rule. Roslyn only checks that the first letter is uppercase.
- Param and return doc tags are not enforced. That would need the StyleCop analyzer, which was deliberately left out.
- DocCheck does not read `.editorconfig`. Turning off CS1591 there will not silence it in CI.
- Code inside `#if` blocks that are not defined by default (such as `#if UNITY_EDITOR`) is not checked by DocCheck.
- `dotnet format` has no blank-line rules for spacing between members. Those are `resharper_*` keys that only Rider applies, so CI does not check them. Run Reformat Code or Code Cleanup in Rider to apply them.
- The blank-line rules CI does check (IDE2000, IDE2002, IDE2003) are marked experimental in Roslyn. They work with the .NET 10 SDK, but their names or behavior could change in a later SDK.
