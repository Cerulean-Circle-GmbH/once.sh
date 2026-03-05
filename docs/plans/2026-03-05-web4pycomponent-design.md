# Web4PyComponent — Design Document

**Date:** 2026-03-05
**Status:** Approved
**Scope:** Full Web4 implementation in Python (research + implementation plan)

---

## 1. Vision

Web4PyComponent is the **Python genesis component** for the Web4 ecosystem — the Python equivalent of Web4TSComponent. It is NOT a port of oosh; it applies the fundamental Web4 Radical OOP philosophy natively in Python.

Python already IS object-oriented. Libraries like PySide6/Qt6, Django, and FastAPI use standard Python OOP. The Web4PyComponent kernel does NOT reimplement OOP — it provides a **thin meta-layer** that gives standard Python classes Web4 superpowers:

- **Self-discovery** — auto-generate CLI, help, and tab completion from code
- **Self-building** — auto-detect missing builds, install dependencies, repair
- **Self-healing** — detect broken state and fix it
- **Scenario hibernation** — serialize/restore any component via init/toScenario
- **IOR addressing** — network-addressable components
- **Version lifecycle** — semantic versions, symlink promotion (dev/test/prod)
- **DelegationProxy** — transparent zero-boilerplate method delegation
- **Component generation** — create new components from templates

---

## 2. Key Decisions

| Decision | Choice | Rationale |
|---|---|---|
| CLI pattern | Both: `./myScript method arg` AND `python -m module method arg` | Maximum flexibility, oosh-compatible |
| Naming convention | camelCase + dots (oosh style) | Faithful to Web4/oosh identity |
| Python version | 3.12+ | Modern features, `type` statement, improved typing |
| Dependencies | Whatever fits best | Pydantic, etc. — quality over minimalism |
| Interop | Interoperable with oosh bash scripts | Shared completion, config, callable both ways |
| Blackbox enforcement | Both static (mypy/pyright) AND runtime (@ucpComponent) | Belt and suspenders |
| Decorator name | `@ucpComponent` | UCP = Unified Component Protocol |
| Approach | Docstring-driven convention | Code IS the documentation — oosh's `# <param> # desc` maps to docstrings |

---

## 3. Architecture Overview

### 5-Layer Model (mirrors Web4TSComponent)

```
Layer 5 (CLI)         Entry point, bash wrapper, arg routing
Layer 4 (Utilities)   Colors, completion filter, helpers
Layer 3 (Interfaces)  Component Protocol, Scenario, Model, IOR
Layer 2 (Logic)       DefaultWeb4PyComponent, DelegationProxy,
                      DefaultCLI, SemanticVersion
Layer 1 (Infra)       Filesystem, logging, config, build
```

### Component Directory Structure

```
components/
  Web4PyComponent/
    0.1.0.0/
      src/py/
        layer2/            Implementation
          defaultWeb4PyComponent.py
          delegationProxy.py
          defaultCLI.py
          semanticVersion.py
        layer3/            Interfaces (Protocols)
          component.py
          scenario.py
          cli.py
          ior.py
        layer4/            Utilities
          colors.py
          completion.py
        layer5/            CLI entry point
          web4PyComponentCLI.py
      templates/           Component generation templates
      test/pytest/
      web4pycomponent      Bash wrapper (executable)
      pyproject.toml
      source.env           Shell integration
    latest -> 0.1.0.0     Semantic symlinks
    dev -> 0.1.0.0
    test -> (none yet)
    prod -> (none yet)
```

### Kernel Modules (7 responsibilities)

```
Web4PyComponent Kernel
  1. component.py      @ucpComponent decorator + Component Protocol
  2. scenario.py       Scenario[T] persistence, .unit files, UUID storage
  3. discovery.py      Docstring parsing -> CLI + help + completion
  4. delegation.py     DelegationProxy via __getattr__
  5. version.py        SemanticVersion component, symlink management
  6. build.py          Self-build / self-heal
  7. generator.py      Component generator from templates
```

---

## 4. Component Protocol & @ucpComponent

### Layer 3 — The Protocol (static enforcement)

```python
from typing import Protocol, Self, runtime_checkable
from pydantic import BaseModel

@runtime_checkable
class Component[TModel: BaseModel](Protocol):
    """UCP Component Protocol -- every Web4 component satisfies this."""
    model: TModel

    def init(self, scenario: "Scenario[TModel] | None" = None) -> Self: ...
    async def toScenario(self, name: str | None = None) -> "Scenario[TModel]": ...
    def hasMethod(self, name: str) -> bool: ...
    def getMethodSignature(self, name: str) -> "MethodSignature | None": ...
    def listMethods(self) -> list[str]: ...
```

### Scenario & Model (Pydantic-enforced flat model)

```python
class IOR(BaseModel):
    uuid: UUID
    component: str
    version: str

class Model(BaseModel):
    uuid: UUID
    name: str
    origin: str
    definition: str

    class Config:
        arbitrary_types_allowed = False  # Enforces flat model

    @model_validator(mode="after")
    def validateFlat(self) -> Self:
        for fieldName, value in self:
            if hasattr(value, '__dict__') and not isinstance(value, BaseModel):
                raise ValueError(
                    f"Model field '{fieldName}' contains object reference "
                    f"({type(value).__name__}). Models must be flat."
                )
        return self

class Scenario[T: Model](BaseModel):
    ior: IOR
    owner: str = ""
    model: T
```

### @ucpComponent Decorator (runtime enforcement)

The decorator validates at class definition time:
- `__init__` takes no business arguments (empty constructor)
- `init()` and `toScenario()` methods exist
- `model` annotation is a Pydantic BaseModel subclass

And injects:
- Method discovery (hasMethod, listMethods, getMethodSignature)
- `_ucp_component = True` marker for DelegationProxy detection
- shCompletion built-in method

### What a real component looks like

```python
class MyAppModel(Model):
    inputPath: str = ""
    outputFormat: str = "json"
    processedCount: int = 0

@ucpComponent
class MyApp:
    model: MyAppModel

    def init(self, scenario: Scenario[MyAppModel] | None = None) -> Self:
        if not hasattr(self, '_initialized'):
            self.model = MyAppModel(
                uuid=uuid4(), name="MyApp",
                origin="web4pycomponent create", definition="",
            )
        if scenario and scenario.model:
            self.model = self.model.model_copy(update=scenario.model.model_dump())
        self._discoverMethods()
        self._initialized = True
        return self

    async def toScenario(self, name: str | None = None) -> Scenario[MyAppModel]:
        return Scenario(
            ior=IOR(uuid=self.model.uuid, component="MyApp", version="0.1.0.0"),
            model=self.model,
        )

    def processData(self, inputFile: str) -> Self:
        """<inputFile> # process input data file"""
        self.model.inputPath = inputFile
        self.model.processedCount += 1
        return self

    def exportResult(self, outputFormat: str = "json") -> Self:
        """<outputFormat:json> # export results in given format"""
        self.model.outputFormat = outputFormat
        return self

    def _internalHelper(self):
        """Not discovered -- underscore prefix."""
        ...

    class Completion:
        @staticmethod
        def exportResult__outputFormat() -> list[str]:
            return ["json", "xml", "csv", "parquet"]
```

### CLI usage (auto-generated from the above)

```bash
./myapp processData input.csv exportResult xml
# Method chaining: processData("input.csv").exportResult("xml")

./myapp
#  processData    <inputFile>           process input data file
#  exportResult   <outputFormat:json>   export results

./myapp proc<TAB>       -> processData
./myapp exportResult <TAB>  -> json, xml, csv, parquet
```

---

## 5. Self-Discovery Engine

The heart of the kernel. Reads code and auto-generates CLI routing, help text, and tab completion.

### Docstring Format (single source of truth)

```python
def processData(self, inputFile: str, outputFormat: str = "json") -> Self:
    """<inputFile> <?outputFormat:json> # process input data file"""
```

Parsed into:

```python
MethodSignature(
    name="processData",
    params=[
        Param(name="inputFile", required=True, default=None),
        Param(name="outputFormat", required=False, default="json"),
    ],
    description="process input data file",
    isAsync=False,
)
```

### Three outputs from one source

```
Method definition + docstring
         |
    Discovery Engine
         |
   +-----+-----+-----+
   |           |           |
CLI Router  Help Text   Completion
```

### CLI Router — positional args with method chaining

`./myapp processData input.csv exportResult xml` becomes:
1. Pop "processData", consume "input.csv" as its param, call method
2. Pop "exportResult", consume "xml" as its param, call method
3. No more args, done

Methods that appear in the signature map are treated as command boundaries.

### Custom Completions — via inner class

```python
class Completion:
    @staticmethod
    def exportResult__outputFormat() -> list[str]:
        return ["json", "xml", "csv"]
```

Double underscore convention: `method__param` maps to the right completion context.

### shCompletion built-in

Every @ucpComponent gets `shCompletion` injected automatically. The bash completion function calls `./myapp shCompletion methodName paramIndex currentWord` and the component returns matching completions to stdout.

---

## 6. Scenario System — Hibernation & .unit Files

### Scenario Lifecycle

```
.unit file (JSON)  --init(scenario)-->  Living Object
       ^                                      |
       |           <--toScenario()--          |
       |                                      v
  scenarios/index/{uuid}/          method chaining
  {uuid}.scenario.json             .method1().method2()
```

### ScenarioStore — UUID-indexed persistence

Scenarios stored at `scenarios/index/{first-8-chars-of-uuid}/{uuid}.scenario.json`.
Supports save, load, and find (by component name or model name).

### UnitManager — .unit symlinks

A `.unit` file is a symlink giving a human-readable name to a UUID-indexed scenario.
Supports create, resolve, and sync-status checking (SYNCED or BROKEN).

### Nested Scenarios

When a component's model contains other components, `toScenario()` recursively serializes them. Object references are filtered out (flat model principle); nested components become nested scenario JSON.

### Flat Model Enforcement

Pydantic's `model_validator` rejects any field containing live object references. Only primitives, IORs, and nested Pydantic models are allowed.

---

## 7. DelegationProxy

Solves the boilerplate problem: generated components automatically inherit all Web4PyComponent methods (upgrade, test, build, clean, tree, etc.) without writing delegation code.

### Implementation via `__getattr__`

Resolution order:
1. Own attributes/methods (Python handles before `__getattr__`)
2. Target component's methods
3. Genesis (Web4PyComponent) methods -- delegation
4. AttributeError

### Factory method

```python
component = await DelegationProxy.start(MyApp().init())
component.processData("x")     # own method
component.upgrade("nextBuild") # delegated to Web4PyComponent
```

### Discovery metadata

- `listMethods()` returns only own methods
- `listDelegatedMethods()` returns genesis methods
- `hasDelegation()` returns True
- CLI shows both sections separately

---

## 8. Version Lifecycle

### SemanticVersion as @ucpComponent

Version itself is a component with init/toScenario, supporting:
- `fromString("0.1.0.0")` class method
- `nextBuild()`, `nextPatch()`, `nextMinor()`, `nextMajor()` — immutable promotion
- Comparison operators for sorting

### Semantic Symlinks

```
components/MyApp/
  0.1.0.0/
  0.1.0.1/
  latest -> 0.1.0.0
  dev -> 0.1.0.1
  test -> (none yet)
  prod -> (none yet)
```

### VersionLifecycle Manager

- `resolveLink(component, "latest")` -> actual version
- `updateLink(component, "dev", version)` -> update symlink
- `promote(component, "nextPatch")` -> copy dir, update symlinks

---

## 9. Self-Build / Self-Heal

### Bash Wrapper (entry point for every component)

Location-independent, self-building:
1. Resolve script location (follow symlinks)
2. Find project root (test isolation aware, git root, directory traversal)
3. Self-build: create venv if missing, install deps if stale
4. Skip build for completion (speed optimization)
5. Execute: `python -m componentname "$@"`

### SelfHeal class

Diagnoses and auto-fixes:
- Missing virtual environment
- Stale dependencies
- Broken .unit symlinks
- Broken semantic version links

---

## 10. Component Generator

`web4pycomponent create MyApp 0.1.0.0` generates:

```
components/MyApp/0.1.0.0/
  src/py/
    layer2/defaultMyApp.py        @ucpComponent implementation
    layer3/myApp.py               Protocol definition
    layer5/myAppCLI.py            CLI entry point
    __main__.py                   python -m entry point
  test/pytest/test_myApp.py       Tests (empty constructor, init, chaining)
  templates/
  myapp                           Bash wrapper (executable)
  pyproject.toml                  Dependencies, entry points
  source.env                      Shell integration
components/MyApp/latest -> 0.1.0.0
components/MyApp/dev -> 0.1.0.0
```

All generated files use templates with variable substitution (componentName, version, uuid).

---

## 11. MDA / Ontology

M3 meta-model organizes components into semantic categories using .unit files:

```
scenarios/mda/M3/
  CLASS/          Component.unit, MyApp.unit, ...
  FOLDER/         Version folder concepts
  RELATIONSHIP/   extends.unit, delegates.unit
```

MDAOntology class supports:
- `register(component, category)` — add to ontology
- `query(category, name)` — search ontology
- `addRelationship(source, target, type)` — record relationships

Auto-registration: `web4pycomponent create` automatically registers new components.

---

## 12. IOR — Interoperable Object Reference

### Structure

```python
IOR(uuid=UUID, component="MyApp", version="0.1.0.0")
```

### URI format

```
ior:MyApp:550e8400-e29b-41d4-a716-446655440000:0.1.0.0
```

### IORResolver

Resolution order:
1. Local scenario store (by UUID)
2. Component directory (by name + version)
3. Network registry (future: distributed IOR)

### Usage in models

Components reference each other by IOR in their model (flat, serializable), not by live object reference.

---

## 13. PDCA — Process Documentation

PDCA is a documentation component (`@ucpComponent`) for Plan-Do-Check-Act workflow:
- `create(focusArea)` — start new session
- `advance()` — move to next phase
- `save(sessionDir)` — write markdown + scenario

Follows CMM3-4 maturity practices with template versioning.

---

## 14. Oosh Interop — Bridge

### Python calling oosh

```python
bridge = OoshBridge()
result = await bridge.call("otmux", "splitV")
methods = await bridge.listMethods("otmux")
config = bridge.readConfig("OOSH_DIR")
```

### Oosh calling Python

Already handled: bash wrappers make Python components callable as `./myapp method args` — identical to oosh convention.

### Shared completion

`source.env` generates oosh-compatible completion functions that integrate with oosh's c2 system.

### Shared config

OoshBridge reads/writes oosh's `~/config/user.env` for shared configuration.

---

## 15. Radical OOP Principles (Python enforcement)

| Principle | Enforcement |
|---|---|
| Empty constructor | `@ucpComponent` validates `__init__` has no business params |
| init/toScenario lifecycle | Protocol + runtime check |
| Flat model (no object refs) | Pydantic `model_validator` rejects non-serializable fields |
| Method chaining (return self) | Convention: all public methods return Self |
| Self-discovery | Discovery engine reads docstrings, not config |
| No CLI flags | CLIRouter uses positional args only |
| Private via underscore | Discovery engine skips `_` prefixed methods |
| Path authority | CLI calculates paths, components use model |
| Blackbox | Protocol defines public contract, internals hidden |
