# Web4PyComponent Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build the Python genesis component for Web4 — a thin kernel that gives standard Python classes Web4 superpowers (self-discovery, hibernation, delegation, versioning, auto-build).

**Architecture:** 5-layer component model mirroring Web4TSComponent. Layer 3 (Protocols/types) is built first, then Layer 2 (implementation), then Layer 5 (CLI). The `@ucpComponent` decorator enforces Radical OOP conventions at both type-check and runtime. Docstrings are the single source of truth for CLI, help, and completion.

**Tech Stack:** Python 3.12+, Pydantic 2.x, pytest, mypy/pyright

**Design Document:** `docs/plans/2026-03-05-web4pycomponent-design.md`

**Base Path:** `$PROJECT_ROOT/components/Web4PyComponent/0.1.0.0/` (repository TBD — can be Web4Articles or standalone)

**Abbreviation:** `$C` = `$PROJECT_ROOT/components/Web4PyComponent/0.1.0.0`

---

## Phase 1: Project Scaffold & Layer 3 (Interfaces)

Foundation types with zero dependencies on other kernel modules.

### Task 1: Project scaffold

**Files:**
- Create: `$C/pyproject.toml`
- Create: `$C/src/py/__init__.py`
- Create: `$C/src/py/layer3/__init__.py`
- Create: `$C/src/py/layer2/__init__.py`
- Create: `$C/src/py/layer4/__init__.py`
- Create: `$C/src/py/layer5/__init__.py`
- Create: `$C/test/pytest/__init__.py`

**Step 1: Create directory structure and pyproject.toml**

```toml
# $C/pyproject.toml
[project]
name = "web4pycomponent"
version = "0.1.0.0"
requires-python = ">=3.12"
dependencies = [
    "pydantic>=2.0",
]

[project.optional-dependencies]
dev = [
    "pytest>=8.0",
    "pytest-asyncio>=0.24",
    "mypy>=1.10",
]

[project.scripts]
web4pycomponent = "src.py.__main__:main"

[tool.pytest.ini_options]
testpaths = ["test/pytest"]
asyncio_mode = "auto"

[build-system]
requires = ["setuptools>=68.0"]
build-backend = "setuptools.backends._legacy:_Backend"
```

**Step 2: Create `__init__.py` files** (empty) for all packages.

**Step 3: Create venv and install**

```bash
cd $C
python3 -m venv .venv
.venv/bin/pip install -e ".[dev]"
```

**Step 4: Verify pytest runs**

```bash
.venv/bin/pytest --co -q
# Expected: "no tests ran"
```

**Step 5: Commit**

```bash
git add components/Web4PyComponent/
git commit -m "feat(web4py): scaffold project structure with pyproject.toml"
```

---

### Task 2: Model base class with flat validation

**Files:**
- Create: `$C/src/py/layer3/model.py`
- Create: `$C/test/pytest/test_model.py`

**Step 1: Write the failing tests**

```python
# $C/test/pytest/test_model.py
import pytest
from uuid import uuid4
from pydantic import ValidationError


class TestModel:
    def test_createWithRequiredFields(self):
        from src.py.layer3.model import Model
        m = Model(uuid=uuid4(), name="Test", origin="test", definition="a test model")
        assert m.name == "Test"
        assert m.origin == "test"

    def test_rejectsObjectReference(self):
        from src.py.layer3.model import Model

        class SomeObject:
            pass

        with pytest.raises(ValidationError):
            Model(uuid=uuid4(), name="Test", origin="test", definition="",
                  badField=SomeObject())

    def test_allowsNestedPydanticModel(self):
        from src.py.layer3.model import Model
        from pydantic import BaseModel

        class ExtendedModel(Model):
            extra: str = "hello"

        m = ExtendedModel(uuid=uuid4(), name="Test", origin="test", definition="")
        assert m.extra == "hello"

    def test_allowsPrimitives(self):
        from src.py.layer3.model import Model

        class AppModel(Model):
            count: int = 0
            tags: list[str] = []
            active: bool = True

        m = AppModel(uuid=uuid4(), name="Test", origin="test", definition="")
        assert m.count == 0
        assert m.tags == []
        assert m.active is True
```

**Step 2: Run tests to verify they fail**

```bash
cd $C && .venv/bin/pytest test/pytest/test_model.py -v
# Expected: FAIL — ModuleNotFoundError
```

**Step 3: Write implementation**

```python
# $C/src/py/layer3/model.py
from uuid import UUID
from typing import Self
from pydantic import BaseModel, model_validator


class Model(BaseModel):
    """Base model for all Web4 components — flat, serializable, no object references."""
    uuid: UUID
    name: str
    origin: str
    definition: str

    model_config = {"extra": "forbid"}

    @model_validator(mode="after")
    def validateFlat(self) -> Self:
        """Reject fields that contain live object references."""
        for fieldName, value in self:
            if value is None:
                continue
            if hasattr(value, '__dict__') and not isinstance(value, BaseModel):
                raise ValueError(
                    f"Model field '{fieldName}' contains object reference "
                    f"({type(value).__name__}). Models must be flat. "
                    f"Use IOR or nested Scenario instead."
                )
        return self
```

**Step 4: Run tests to verify they pass**

```bash
cd $C && .venv/bin/pytest test/pytest/test_model.py -v
# Expected: 4 passed
```

**Step 5: Commit**

```bash
git add -A && git commit -m "feat(web4py): Model base class with flat validation"
```

---

### Task 3: IOR type

**Files:**
- Create: `$C/src/py/layer3/ior.py`
- Create: `$C/test/pytest/test_ior.py`

**Step 1: Write the failing tests**

```python
# $C/test/pytest/test_ior.py
from uuid import uuid4


class TestIOR:
    def test_createIOR(self):
        from src.py.layer3.ior import IOR
        ior = IOR(uuid=uuid4(), component="MyApp", version="0.1.0.0")
        assert ior.component == "MyApp"
        assert ior.version == "0.1.0.0"

    def test_toURI(self):
        from src.py.layer3.ior import IOR
        uid = uuid4()
        ior = IOR(uuid=uid, component="MyApp", version="0.1.0.0")
        uri = ior.toURI()
        assert uri == f"ior:MyApp:{uid}:0.1.0.0"

    def test_fromURI(self):
        from src.py.layer3.ior import IOR
        uid = uuid4()
        uri = f"ior:MyApp:{uid}:0.1.0.0"
        ior = IOR.fromURI(uri)
        assert ior.uuid == uid
        assert ior.component == "MyApp"
        assert ior.version == "0.1.0.0"

    def test_fromURIInvalid(self):
        import pytest
        from src.py.layer3.ior import IOR
        with pytest.raises(ValueError):
            IOR.fromURI("not-a-valid-ior")

    def test_serializesToJSON(self):
        import json
        from src.py.layer3.ior import IOR
        ior = IOR(uuid=uuid4(), component="MyApp", version="0.1.0.0")
        data = json.loads(ior.model_dump_json())
        assert data["component"] == "MyApp"
```

**Step 2: Run tests to verify they fail**

**Step 3: Write implementation**

```python
# $C/src/py/layer3/ior.py
from uuid import UUID
from pydantic import BaseModel


class IOR(BaseModel):
    """Interoperable Object Reference -- identity across network."""
    uuid: UUID
    component: str
    version: str

    def toURI(self) -> str:
        """Convert IOR to URI string for network transmission."""
        return f"ior:{self.component}:{self.uuid}:{self.version}"

    @classmethod
    def fromURI(cls, uri: str) -> "IOR":
        """Parse URI string back to IOR."""
        parts = uri.split(":")
        if len(parts) != 4 or parts[0] != "ior":
            raise ValueError(f"Invalid IOR URI: {uri}")
        return cls(
            component=parts[1],
            uuid=UUID(parts[2]),
            version=parts[3],
        )
```

**Step 4: Run tests — all pass**

**Step 5: Commit**

```bash
git add -A && git commit -m "feat(web4py): IOR type with URI serialization"
```

---

### Task 4: Scenario generic type

**Files:**
- Create: `$C/src/py/layer3/scenario.py`
- Create: `$C/test/pytest/test_scenario.py`

**Step 1: Write the failing tests**

```python
# $C/test/pytest/test_scenario.py
import json
from uuid import uuid4


class TestScenario:
    def test_createScenario(self):
        from src.py.layer3.scenario import Scenario
        from src.py.layer3.model import Model
        from src.py.layer3.ior import IOR

        model = Model(uuid=uuid4(), name="Test", origin="test", definition="")
        ior = IOR(uuid=model.uuid, component="Test", version="0.1.0.0")
        scenario = Scenario(ior=ior, model=model)

        assert scenario.ior.component == "Test"
        assert scenario.model.name == "Test"
        assert scenario.owner == ""

    def test_serializesToJSON(self):
        from src.py.layer3.scenario import Scenario
        from src.py.layer3.model import Model
        from src.py.layer3.ior import IOR

        model = Model(uuid=uuid4(), name="Test", origin="test", definition="")
        ior = IOR(uuid=model.uuid, component="Test", version="0.1.0.0")
        scenario = Scenario(ior=ior, model=model)

        jsonStr = scenario.model_dump_json(indent=2)
        data = json.loads(jsonStr)
        assert "ior" in data
        assert "model" in data
        assert data["model"]["name"] == "Test"

    def test_deserializesFromJSON(self):
        from src.py.layer3.scenario import Scenario
        from src.py.layer3.model import Model
        from src.py.layer3.ior import IOR

        model = Model(uuid=uuid4(), name="Test", origin="test", definition="")
        ior = IOR(uuid=model.uuid, component="Test", version="0.1.0.0")
        original = Scenario(ior=ior, model=model)

        jsonStr = original.model_dump_json()
        restored = Scenario[Model].model_validate_json(jsonStr)
        assert restored.ior.uuid == original.ior.uuid
        assert restored.model.name == "Test"

    def test_withOwner(self):
        import base64
        from src.py.layer3.scenario import Scenario
        from src.py.layer3.model import Model
        from src.py.layer3.ior import IOR

        model = Model(uuid=uuid4(), name="Test", origin="test", definition="")
        ior = IOR(uuid=model.uuid, component="Test", version="0.1.0.0")
        owner = base64.b64encode(b'{"user": "hannes"}').decode()
        scenario = Scenario(ior=ior, owner=owner, model=model)

        assert scenario.owner == owner
```

**Step 2: Run tests to verify they fail**

**Step 3: Write implementation**

```python
# $C/src/py/layer3/scenario.py
from pydantic import BaseModel
from src.py.layer3.ior import IOR
from src.py.layer3.model import Model


class Scenario[T: Model](BaseModel):
    """Complete component state, serializable to JSON / .unit file."""
    ior: IOR
    owner: str = ""     # Base64-encoded owner scenario
    model: T
```

**Step 4: Run tests — all pass**

**Step 5: Commit**

```bash
git add -A && git commit -m "feat(web4py): Scenario generic type"
```

---

### Task 5: MethodSignature and Param types

**Files:**
- Create: `$C/src/py/layer3/methodSignature.py`
- Create: `$C/test/pytest/test_methodSignature.py`

**Step 1: Write the failing tests**

```python
# $C/test/pytest/test_methodSignature.py

class TestMethodSignature:
    def test_createParam(self):
        from src.py.layer3.methodSignature import Param
        p = Param(name="inputFile", required=True, default=None)
        assert p.name == "inputFile"
        assert p.required is True

    def test_createOptionalParam(self):
        from src.py.layer3.methodSignature import Param
        p = Param(name="outputFormat", required=False, default="json")
        assert p.required is False
        assert p.default == "json"

    def test_createMethodSignature(self):
        from src.py.layer3.methodSignature import MethodSignature, Param
        sig = MethodSignature(
            name="processData",
            params=[Param(name="inputFile", required=True, default=None)],
            description="process input data file",
            isAsync=False,
        )
        assert sig.name == "processData"
        assert len(sig.params) == 1
        assert sig.description == "process input data file"

    def test_paramFormatRequired(self):
        from src.py.layer3.methodSignature import Param
        p = Param(name="inputFile", required=True, default=None)
        assert p.format() == "<inputFile>"

    def test_paramFormatOptionalWithDefault(self):
        from src.py.layer3.methodSignature import Param
        p = Param(name="outputFormat", required=False, default="json")
        assert p.format() == "<?outputFormat:json>"

    def test_paramFormatOptionalNoDefault(self):
        from src.py.layer3.methodSignature import Param
        p = Param(name="target", required=False, default=None)
        assert p.format() == "<?target>"
```

**Step 2: Run tests to verify they fail**

**Step 3: Write implementation**

```python
# $C/src/py/layer3/methodSignature.py
from dataclasses import dataclass, field


@dataclass
class Param:
    """A method parameter parsed from a docstring."""
    name: str
    required: bool
    default: str | None

    def format(self) -> str:
        if self.required:
            return f"<{self.name}>"
        elif self.default:
            return f"<?{self.name}:{self.default}>"
        else:
            return f"<?{self.name}>"


@dataclass
class MethodSignature:
    """Metadata about a discovered component method."""
    name: str
    params: list[Param] = field(default_factory=list)
    description: str = ""
    isAsync: bool = False
```

**Step 4: Run tests — all pass**

**Step 5: Commit**

```bash
git add -A && git commit -m "feat(web4py): MethodSignature and Param types"
```

---

### Task 6: Component Protocol

**Files:**
- Create: `$C/src/py/layer3/component.py`
- Create: `$C/test/pytest/test_componentProtocol.py`

**Step 1: Write the failing tests**

```python
# $C/test/pytest/test_componentProtocol.py
from uuid import uuid4


class TestComponentProtocol:
    def test_classImplementingProtocol(self):
        """A class with the right methods satisfies the Protocol."""
        from src.py.layer3.component import Component
        from src.py.layer3.model import Model
        from src.py.layer3.scenario import Scenario
        from src.py.layer3.methodSignature import MethodSignature

        class FakeModel(Model):
            pass

        class FakeComponent:
            model: FakeModel

            def init(self, scenario=None):
                self.model = FakeModel(uuid=uuid4(), name="Fake",
                                       origin="test", definition="")
                return self

            async def toScenario(self, name=None):
                return None

            def hasMethod(self, name):
                return False

            def getMethodSignature(self, name):
                return None

            def listMethods(self):
                return []

        comp = FakeComponent()
        assert isinstance(comp, Component)

    def test_classMissingMethodNotProtocol(self):
        """A class missing required methods does NOT satisfy the Protocol."""
        from src.py.layer3.component import Component

        class Incomplete:
            pass

        assert not isinstance(Incomplete(), Component)
```

**Step 2: Run tests to verify they fail**

**Step 3: Write implementation**

```python
# $C/src/py/layer3/component.py
from typing import Protocol, Self, runtime_checkable
from pydantic import BaseModel
from src.py.layer3.scenario import Scenario
from src.py.layer3.methodSignature import MethodSignature


@runtime_checkable
class Component[TModel: BaseModel](Protocol):
    """UCP Component Protocol -- every Web4 component satisfies this."""
    model: TModel

    def init(self, scenario: Scenario | None = None) -> Self: ...
    async def toScenario(self, name: str | None = None) -> Scenario: ...
    def hasMethod(self, name: str) -> bool: ...
    def getMethodSignature(self, name: str) -> MethodSignature | None: ...
    def listMethods(self) -> list[str]: ...
```

**Step 4: Run tests — all pass**

**Step 5: Commit**

```bash
git add -A && git commit -m "feat(web4py): Component Protocol (Layer 3 complete)"
```

---

## Phase 2: Discovery Engine

### Task 7: Docstring parser

**Files:**
- Create: `$C/src/py/layer2/discovery.py`
- Create: `$C/test/pytest/test_discovery.py`

**Step 1: Write the failing tests**

```python
# $C/test/pytest/test_discovery.py

class TestParseDocstring:
    def test_requiredParam(self):
        from src.py.layer2.discovery import parseDocstring

        def myMethod(self, inputFile: str):
            """<inputFile> # process input data"""

        sig = parseDocstring(myMethod)
        assert sig is not None
        assert sig.name == "myMethod"
        assert len(sig.params) == 1
        assert sig.params[0].name == "inputFile"
        assert sig.params[0].required is True
        assert sig.description == "process input data"

    def test_optionalParamWithDefault(self):
        from src.py.layer2.discovery import parseDocstring

        def exportResult(self, fmt: str = "json"):
            """<?fmt:json> # export results"""

        sig = parseDocstring(exportResult)
        assert sig.params[0].required is False
        assert sig.params[0].default == "json"

    def test_multipleParams(self):
        from src.py.layer2.discovery import parseDocstring

        def copy(self, source: str, dest: str, flags: str = "r"):
            """<source> <dest> <?flags:r> # copy files"""

        sig = parseDocstring(copy)
        assert len(sig.params) == 3
        assert sig.params[0].name == "source"
        assert sig.params[0].required is True
        assert sig.params[2].name == "flags"
        assert sig.params[2].required is False

    def test_noParams(self):
        from src.py.layer2.discovery import parseDocstring

        def listAll(self):
            """# list all items"""

        sig = parseDocstring(listAll)
        assert len(sig.params) == 0
        assert sig.description == "list all items"

    def test_noDocstring(self):
        from src.py.layer2.discovery import parseDocstring

        def bare(self):
            pass

        sig = parseDocstring(bare)
        assert sig is None

    def test_asyncMethod(self):
        from src.py.layer2.discovery import parseDocstring

        async def fetch(self, url: str):
            """<url> # fetch data from URL"""

        sig = parseDocstring(fetch)
        assert sig.isAsync is True

    def test_optionalWithoutDefault(self):
        from src.py.layer2.discovery import parseDocstring

        def attach(self, target: str = None):
            """<?target> # attach to session"""

        sig = parseDocstring(attach)
        assert sig.params[0].required is False
        assert sig.params[0].default is None


class TestDiscoverMethods:
    def test_discoversPublicMethods(self):
        from src.py.layer2.discovery import discoverMethods

        class MyClass:
            def processData(self, f: str):
                """<f> # process"""
                pass

            def exportResult(self):
                """# export"""
                pass

            def _private(self):
                pass

        sigs = discoverMethods(MyClass())
        assert "processData" in sigs
        assert "exportResult" in sigs
        assert "_private" not in sigs

    def test_skipsFrameworkMethods(self):
        from src.py.layer2.discovery import discoverMethods

        class MyClass:
            def init(self):
                """# init"""
                pass

            def toScenario(self):
                """# scenario"""
                pass

            def hasMethod(self, name):
                pass

            def getMethodSignature(self, name):
                pass

            def listMethods(self):
                pass

            def userMethod(self):
                """# user method"""
                pass

        sigs = discoverMethods(MyClass())
        assert "userMethod" in sigs
        assert "init" not in sigs
        assert "toScenario" not in sigs
        assert "hasMethod" not in sigs

    def test_skipsCompletionClass(self):
        from src.py.layer2.discovery import discoverMethods

        class MyClass:
            def doWork(self):
                """# work"""
                pass

            class Completion:
                @staticmethod
                def doWork__param():
                    return ["a", "b"]

        sigs = discoverMethods(MyClass())
        assert "Completion" not in sigs
        assert "doWork" in sigs
```

**Step 2: Run tests to verify they fail**

**Step 3: Write implementation**

```python
# $C/src/py/layer2/discovery.py
import re
import inspect
from src.py.layer3.methodSignature import MethodSignature, Param

FRAMEWORK_METHODS = frozenset({
    "init", "toScenario", "hasMethod", "getMethodSignature",
    "listMethods", "shCompletion",
})


def parseDocstring(method) -> MethodSignature | None:
    """
    Parse oosh-style docstring into MethodSignature.

    Format: <required> <?optional> <?optional:default> # description
    """
    doc = getattr(method, '__doc__', None)
    if not doc:
        return None

    doc = doc.strip()

    # Split on last # to get description
    parts = doc.rsplit("#", 1)
    description = parts[1].strip() if len(parts) > 1 else ""
    paramStr = parts[0].strip() if len(parts) > 1 else ""

    # Parse parameters: <name> or <?name> or <?name:default>
    params = []
    for match in re.finditer(r'<(\??)([\w]+)(?::([^>]*))?>', paramStr):
        optional, name, default = match.groups()
        params.append(Param(
            name=name,
            required=(optional != "?"),
            default=default,
        ))

    return MethodSignature(
        name=method.__name__,
        params=params,
        description=description,
        isAsync=inspect.iscoroutinefunction(method),
    )


def discoverMethods(instance: object) -> dict[str, MethodSignature]:
    """
    Discover all public, non-framework methods on an instance.
    Skip underscore-prefixed, framework methods, and non-callables.
    """
    signatures: dict[str, MethodSignature] = {}

    for name in dir(instance):
        if name.startswith('_'):
            continue
        if name in FRAMEWORK_METHODS:
            continue
        attr = getattr(instance, name)
        if not callable(attr):
            continue
        if isinstance(attr, type):
            continue  # Skip inner classes like Completion
        sig = parseDocstring(attr)
        if sig:
            signatures[name] = sig

    return signatures
```

**Step 4: Run tests — all pass**

**Step 5: Commit**

```bash
git add -A && git commit -m "feat(web4py): discovery engine — docstring parser and method discovery"
```

---

## Phase 3: @ucpComponent Decorator

### Task 8: @ucpComponent decorator

**Files:**
- Create: `$C/src/py/layer2/ucpComponent.py`
- Create: `$C/test/pytest/test_ucpComponent.py`

**Step 1: Write the failing tests**

```python
# $C/test/pytest/test_ucpComponent.py
import pytest
from uuid import uuid4


class TestUcpComponentValidation:
    def test_rejectsConstructorWithArgs(self):
        from src.py.layer2.ucpComponent import ucpComponent, UCPViolation
        from src.py.layer3.model import Model

        with pytest.raises(UCPViolation, match="__init__ must be empty"):
            @ucpComponent
            class Bad:
                model: Model
                def __init__(self, name: str):
                    pass
                def init(self, scenario=None):
                    return self
                async def toScenario(self, name=None):
                    return None

    def test_rejectsMissingInit(self):
        from src.py.layer2.ucpComponent import ucpComponent, UCPViolation

        with pytest.raises(UCPViolation, match="must implement init"):
            @ucpComponent
            class Bad:
                model: object
                async def toScenario(self, name=None):
                    return None

    def test_rejectsMissingToScenario(self):
        from src.py.layer2.ucpComponent import ucpComponent, UCPViolation

        with pytest.raises(UCPViolation, match="must implement toScenario"):
            @ucpComponent
            class Bad:
                model: object
                def init(self, scenario=None):
                    return self

    def test_rejectsMissingModelAnnotation(self):
        from src.py.layer2.ucpComponent import ucpComponent, UCPViolation

        with pytest.raises(UCPViolation, match="must declare 'model'"):
            @ucpComponent
            class Bad:
                def init(self, scenario=None):
                    return self
                async def toScenario(self, name=None):
                    return None


class TestUcpComponentInjection:
    def test_injectsUcpMarker(self):
        from src.py.layer2.ucpComponent import ucpComponent
        from src.py.layer3.model import Model

        @ucpComponent
        class Good:
            model: Model
            def init(self, scenario=None):
                return self
            async def toScenario(self, name=None):
                return None

        assert Good._ucp_component is True

    def test_injectsHasMethod(self):
        from src.py.layer2.ucpComponent import ucpComponent
        from src.py.layer3.model import Model

        @ucpComponent
        class Good:
            model: Model
            def init(self, scenario=None):
                self._discoverMethods()
                return self
            async def toScenario(self, name=None):
                return None
            def doWork(self):
                """# do some work"""
                return self

        g = Good().init()
        assert g.hasMethod("doWork") is True
        assert g.hasMethod("nonexistent") is False

    def test_injectsListMethods(self):
        from src.py.layer2.ucpComponent import ucpComponent
        from src.py.layer3.model import Model

        @ucpComponent
        class Good:
            model: Model
            def init(self, scenario=None):
                self._discoverMethods()
                return self
            async def toScenario(self, name=None):
                return None
            def doWork(self):
                """# do work"""
                return self
            def doMore(self):
                """# do more"""
                return self

        g = Good().init()
        methods = g.listMethods()
        assert "doWork" in methods
        assert "doMore" in methods
        assert "init" not in methods

    def test_injectsGetMethodSignature(self):
        from src.py.layer2.ucpComponent import ucpComponent
        from src.py.layer3.model import Model

        @ucpComponent
        class Good:
            model: Model
            def init(self, scenario=None):
                self._discoverMethods()
                return self
            async def toScenario(self, name=None):
                return None
            def processData(self, inputFile: str):
                """<inputFile> # process data"""
                return self

        g = Good().init()
        sig = g.getMethodSignature("processData")
        assert sig is not None
        assert sig.params[0].name == "inputFile"

    def test_allowsEmptyDefaultInit(self):
        """Classes with no explicit __init__ should pass (Python default is empty)."""
        from src.py.layer2.ucpComponent import ucpComponent
        from src.py.layer3.model import Model

        @ucpComponent
        class Good:
            model: Model
            def init(self, scenario=None):
                return self
            async def toScenario(self, name=None):
                return None

        # Should not raise
        g = Good()
        assert g._ucp_component is True
```

**Step 2: Run tests to verify they fail**

**Step 3: Write implementation**

```python
# $C/src/py/layer2/ucpComponent.py
import inspect
from src.py.layer2.discovery import discoverMethods
from src.py.layer3.methodSignature import MethodSignature


class UCPViolation(Exception):
    """Raised when a class violates UCP (Unified Component Protocol) conventions."""
    pass


def ucpComponent(cls):
    """
    Decorator that enforces Web4 Radical OOP conventions
    and injects kernel capabilities.

    Validates at class definition time (fail fast):
    - __init__ takes no business arguments
    - init() and toScenario() methods exist
    - 'model' annotation declared

    Injects:
    - _discoverMethods(), hasMethod(), listMethods(), getMethodSignature()
    - _ucp_component marker
    """

    # --- VALIDATION ---

    # 1. Empty constructor check
    if '__init__' in cls.__dict__:
        initParams = inspect.signature(cls.__init__).parameters
        businessParams = [p for p in initParams if p != 'self']
        if businessParams:
            raise UCPViolation(
                f"{cls.__name__}.__init__ must be empty (Radical OOP). "
                f"Found parameters: {businessParams}. "
                f"Move initialization to init(scenario)."
            )

    # 2. Required methods check
    if not hasattr(cls, 'init') or not callable(getattr(cls, 'init')):
        raise UCPViolation(f"{cls.__name__} must implement init()")

    if not hasattr(cls, 'toScenario') or not callable(getattr(cls, 'toScenario')):
        raise UCPViolation(f"{cls.__name__} must implement toScenario()")

    # 3. Model annotation check
    annotations = {}
    for klass in reversed(cls.__mro__):
        annotations.update(getattr(klass, '__annotations__', {}))
    if 'model' not in annotations:
        raise UCPViolation(
            f"{cls.__name__} must declare 'model: YourModel' annotation"
        )

    # --- INJECTION ---

    # 4. Inject method discovery
    def _discoverMethods(self):
        self._signatures = discoverMethods(self)

    def hasMethod(self, name: str) -> bool:
        return name in getattr(self, '_signatures', {})

    def getMethodSignature(self, name: str) -> MethodSignature | None:
        return getattr(self, '_signatures', {}).get(name)

    def listMethods(self) -> list[str]:
        return list(getattr(self, '_signatures', {}).keys())

    cls._discoverMethods = _discoverMethods
    cls.hasMethod = hasMethod
    cls.getMethodSignature = getMethodSignature
    cls.listMethods = listMethods

    # 5. Mark as UCP component
    cls._ucp_component = True

    return cls
```

**Step 4: Run tests — all pass**

**Step 5: Commit**

```bash
git add -A && git commit -m "feat(web4py): @ucpComponent decorator with validation and discovery injection"
```

---

## Phase 4: Scenario Persistence

### Task 9: ScenarioStore

**Files:**
- Create: `$C/src/py/layer2/scenarioStore.py`
- Create: `$C/test/pytest/test_scenarioStore.py`

**Step 1: Write the failing tests**

```python
# $C/test/pytest/test_scenarioStore.py
import pytest
from pathlib import Path
from uuid import uuid4


@pytest.fixture
def tmpStore(tmp_path):
    from src.py.layer2.scenarioStore import ScenarioStore
    return ScenarioStore(tmp_path)


@pytest.fixture
def sampleScenario():
    from src.py.layer3.scenario import Scenario
    from src.py.layer3.model import Model
    from src.py.layer3.ior import IOR
    uid = uuid4()
    return Scenario(
        ior=IOR(uuid=uid, component="TestComp", version="0.1.0.0"),
        model=Model(uuid=uid, name="TestComp", origin="test", definition=""),
    )


class TestScenarioStore:
    @pytest.mark.asyncio
    async def test_saveAndLoad(self, tmpStore, sampleScenario):
        path = await tmpStore.save(sampleScenario)
        assert path.exists()
        assert path.suffix == ".json"

        loaded = await tmpStore.load(sampleScenario.ior.uuid)
        assert loaded.ior.uuid == sampleScenario.ior.uuid
        assert loaded.model.name == "TestComp"

    @pytest.mark.asyncio
    async def test_loadNonexistent(self, tmpStore):
        from src.py.layer2.scenarioStore import ScenarioNotFound
        with pytest.raises(ScenarioNotFound):
            await tmpStore.load(uuid4())

    @pytest.mark.asyncio
    async def test_findByComponent(self, tmpStore, sampleScenario):
        await tmpStore.save(sampleScenario)
        results = await tmpStore.find(component="TestComp")
        assert len(results) == 1
        assert results[0].model.name == "TestComp"

    @pytest.mark.asyncio
    async def test_findNoMatch(self, tmpStore, sampleScenario):
        await tmpStore.save(sampleScenario)
        results = await tmpStore.find(component="NonExistent")
        assert len(results) == 0

    @pytest.mark.asyncio
    async def test_uuidPathStructure(self, tmpStore, sampleScenario):
        path = await tmpStore.save(sampleScenario)
        uid = str(sampleScenario.ior.uuid)
        assert uid[:8] in str(path)
```

**Step 2: Run tests to verify they fail**

**Step 3: Write implementation**

```python
# $C/src/py/layer2/scenarioStore.py
import json
from pathlib import Path
from uuid import UUID
from src.py.layer3.scenario import Scenario
from src.py.layer3.model import Model


class ScenarioNotFound(Exception):
    pass


class ScenarioStore:
    """Manages scenario persistence -- save, load, index by UUID."""

    def __init__(self, projectRoot: Path):
        self.indexDir = projectRoot / "scenarios" / "index"

    def _uuidPath(self, uuid: UUID) -> Path:
        prefix = str(uuid)[:8]
        return self.indexDir / prefix / f"{uuid}.scenario.json"

    async def save(self, scenario: Scenario) -> Path:
        path = self._uuidPath(scenario.ior.uuid)
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(scenario.model_dump_json(indent=2))
        return path

    async def load(self, uuid: UUID) -> Scenario:
        path = self._uuidPath(uuid)
        if not path.exists():
            raise ScenarioNotFound(f"No scenario found for UUID: {uuid}")
        data = json.loads(path.read_text())
        return Scenario[Model].model_validate(data)

    async def find(self, component: str | None = None,
                   name: str | None = None) -> list[Scenario]:
        results = []
        if not self.indexDir.exists():
            return results
        for jsonFile in self.indexDir.rglob("*.scenario.json"):
            data = json.loads(jsonFile.read_text())
            scenario = Scenario[Model].model_validate(data)
            if component and scenario.ior.component != component:
                continue
            if name and scenario.model.name != name:
                continue
            results.append(scenario)
        return results
```

**Step 4: Run tests — all pass**

**Step 5: Commit**

```bash
git add -A && git commit -m "feat(web4py): ScenarioStore — UUID-indexed persistence"
```

---

### Task 10: UnitManager

**Files:**
- Create: `$C/src/py/layer2/unitManager.py`
- Create: `$C/test/pytest/test_unitManager.py`

**Step 1: Write the failing tests**

```python
# $C/test/pytest/test_unitManager.py
import pytest
from pathlib import Path
from uuid import uuid4


@pytest.fixture
def tmpSetup(tmp_path):
    from src.py.layer2.scenarioStore import ScenarioStore
    from src.py.layer2.unitManager import UnitManager
    store = ScenarioStore(tmp_path)
    manager = UnitManager(store)
    return store, manager, tmp_path


@pytest.fixture
def sampleScenario():
    from src.py.layer3.scenario import Scenario
    from src.py.layer3.model import Model
    from src.py.layer3.ior import IOR
    uid = uuid4()
    return Scenario(
        ior=IOR(uuid=uid, component="TestComp", version="0.1.0.0"),
        model=Model(uuid=uid, name="TestComp", origin="test", definition=""),
    )


class TestUnitManager:
    @pytest.mark.asyncio
    async def test_createUnit(self, tmpSetup, sampleScenario):
        store, manager, root = tmpSetup
        unitPath = root / "mySession.unit"
        result = await manager.create(sampleScenario, unitPath)
        assert result.suffix == ".unit"
        assert result.is_symlink()

    @pytest.mark.asyncio
    async def test_resolveUnit(self, tmpSetup, sampleScenario):
        store, manager, root = tmpSetup
        unitPath = root / "mySession.unit"
        await manager.create(sampleScenario, unitPath)
        resolved = await manager.resolve(unitPath)
        assert resolved.ior.uuid == sampleScenario.ior.uuid

    @pytest.mark.asyncio
    async def test_checkSyncValid(self, tmpSetup, sampleScenario):
        store, manager, root = tmpSetup
        unitPath = root / "mySession.unit"
        await manager.create(sampleScenario, unitPath)
        status = await manager.checkSync(unitPath)
        assert status == "SYNCED"

    @pytest.mark.asyncio
    async def test_checkSyncBroken(self, tmpSetup, sampleScenario):
        store, manager, root = tmpSetup
        unitPath = root / "mySession.unit"
        await manager.create(sampleScenario, unitPath)
        # Delete the target file to break the symlink
        target = unitPath.resolve()
        target.unlink()
        status = await manager.checkSync(unitPath)
        assert status == "BROKEN"

    @pytest.mark.asyncio
    async def test_resolveNotSymlink(self, tmpSetup):
        store, manager, root = tmpSetup
        from src.py.layer2.unitManager import UnitError
        regularFile = root / "notAUnit.unit"
        regularFile.write_text("not a symlink")
        with pytest.raises(UnitError):
            await manager.resolve(regularFile)
```

**Step 2: Run tests to verify they fail**

**Step 3: Write implementation**

```python
# $C/src/py/layer2/unitManager.py
import os
from pathlib import Path
from src.py.layer2.scenarioStore import ScenarioStore
from src.py.layer3.scenario import Scenario


class UnitError(Exception):
    pass


class UnitBroken(UnitError):
    pass


class UnitManager:
    """Manages .unit symlinks -- create, resolve, sync."""

    def __init__(self, store: ScenarioStore):
        self.store = store

    async def create(self, scenario: Scenario, unitPath: Path) -> Path:
        storedPath = await self.store.save(scenario)

        unitPath = unitPath.with_suffix(".unit")
        relativeTarget = os.path.relpath(storedPath, unitPath.parent)

        if unitPath.exists() or unitPath.is_symlink():
            unitPath.unlink()
        unitPath.symlink_to(relativeTarget)

        return unitPath

    async def resolve(self, unitPath: Path) -> Scenario:
        if not unitPath.is_symlink():
            raise UnitError(f"{unitPath} is not a .unit symlink")

        realPath = unitPath.resolve()
        if not realPath.exists():
            raise UnitBroken(f"{unitPath} -> {realPath} (target missing)")

        import json
        from src.py.layer3.model import Model
        data = json.loads(realPath.read_text())
        return Scenario[Model].model_validate(data)

    async def checkSync(self, unitPath: Path) -> str:
        try:
            await self.resolve(unitPath)
            return "SYNCED"
        except (UnitBroken, FileNotFoundError):
            return "BROKEN"
```

**Step 4: Run tests — all pass**

**Step 5: Commit**

```bash
git add -A && git commit -m "feat(web4py): UnitManager — .unit symlink management"
```

---

## Phase 5: SemanticVersion & CLI

### Task 11: SemanticVersion component

**Files:**
- Create: `$C/src/py/layer2/semanticVersion.py`
- Create: `$C/test/pytest/test_semanticVersion.py`

**Step 1: Write the failing tests**

```python
# $C/test/pytest/test_semanticVersion.py

class TestSemanticVersion:
    def test_fromString(self):
        from src.py.layer2.semanticVersion import SemanticVersion
        v = SemanticVersion.fromString("0.3.21.1")
        assert v.model.major == 0
        assert v.model.minor == 3
        assert v.model.patch == 21
        assert v.model.revision == 1

    def test_toString(self):
        from src.py.layer2.semanticVersion import SemanticVersion
        v = SemanticVersion.fromString("1.2.3.4")
        assert v.toString() == "1.2.3.4"
        assert str(v) == "1.2.3.4"

    def test_nextBuild(self):
        from src.py.layer2.semanticVersion import SemanticVersion
        v = SemanticVersion.fromString("0.1.0.3")
        n = v.nextBuild()
        assert str(n) == "0.1.0.4"
        # Original unchanged (immutable)
        assert str(v) == "0.1.0.3"

    def test_nextPatch(self):
        from src.py.layer2.semanticVersion import SemanticVersion
        v = SemanticVersion.fromString("0.1.5.3")
        n = v.nextPatch()
        assert str(n) == "0.1.6.0"

    def test_nextMinor(self):
        from src.py.layer2.semanticVersion import SemanticVersion
        v = SemanticVersion.fromString("0.3.21.1")
        n = v.nextMinor()
        assert str(n) == "0.4.0.0"

    def test_nextMajor(self):
        from src.py.layer2.semanticVersion import SemanticVersion
        v = SemanticVersion.fromString("0.3.21.1")
        n = v.nextMajor()
        assert str(n) == "1.0.0.0"

    def test_comparison(self):
        from src.py.layer2.semanticVersion import SemanticVersion
        v1 = SemanticVersion.fromString("0.1.0.0")
        v2 = SemanticVersion.fromString("0.1.0.1")
        v3 = SemanticVersion.fromString("0.2.0.0")
        assert v1 < v2
        assert v2 < v3
        assert not v3 < v1

    def test_isUcpComponent(self):
        from src.py.layer2.semanticVersion import SemanticVersion
        v = SemanticVersion.fromString("0.1.0.0")
        assert hasattr(v, '_ucp_component')
        assert v._ucp_component is True

    def test_initAndToScenario(self):
        import asyncio
        from src.py.layer2.semanticVersion import SemanticVersion
        v = SemanticVersion.fromString("0.1.0.0")
        scenario = asyncio.run(v.toScenario())
        assert scenario.ior.component == "SemanticVersion"
        assert scenario.ior.version == "0.1.0.0"

        v2 = SemanticVersion().init(scenario)
        assert str(v2) == "0.1.0.0"
```

**Step 2: Run tests to verify they fail**

**Step 3: Write implementation**

```python
# $C/src/py/layer2/semanticVersion.py
from typing import Self, ClassVar
from uuid import uuid4
from src.py.layer2.ucpComponent import ucpComponent
from src.py.layer3.model import Model
from src.py.layer3.scenario import Scenario
from src.py.layer3.ior import IOR


class SemanticVersionModel(Model):
    major: int = 0
    minor: int = 0
    patch: int = 0
    revision: int = 0
    versionString: str = "0.0.0.0"


@ucpComponent
class SemanticVersion:
    model: SemanticVersionModel

    SEMANTIC_LINKS: ClassVar[list[str]] = ["latest", "dev", "test", "prod"]

    def init(self, scenario: Scenario[SemanticVersionModel] | None = None) -> Self:
        if not hasattr(self, '_initialized'):
            self.model = SemanticVersionModel(
                uuid=uuid4(), name="SemanticVersion",
                origin="kernel", definition="version component",
            )
        if scenario and scenario.model:
            self.model = self.model.model_copy(
                update=scenario.model.model_dump(exclude_unset=False)
            )
        self._discoverMethods()
        self._initialized = True
        return self

    async def toScenario(self, name: str | None = None) -> Scenario[SemanticVersionModel]:
        return Scenario(
            ior=IOR(
                uuid=self.model.uuid,
                component="SemanticVersion",
                version=self.toString(),
            ),
            model=self.model,
        )

    @classmethod
    def fromString(cls, version: str) -> "SemanticVersion":
        v = cls().init()
        parts = version.split(".")
        v.model.major = int(parts[0]) if len(parts) > 0 else 0
        v.model.minor = int(parts[1]) if len(parts) > 1 else 0
        v.model.patch = int(parts[2]) if len(parts) > 2 else 0
        v.model.revision = int(parts[3]) if len(parts) > 3 else 0
        v.model.versionString = version
        return v

    def nextBuild(self) -> "SemanticVersion":
        """# promote build: X.Y.Z.W -> X.Y.Z.(W+1)"""
        new = SemanticVersion().init()
        new.model = self.model.model_copy(update={
            "revision": self.model.revision + 1,
        })
        new.model.versionString = new.toString()
        return new

    def nextPatch(self) -> "SemanticVersion":
        """# promote patch: X.Y.Z.W -> X.Y.(Z+1).0"""
        new = SemanticVersion().init()
        new.model = self.model.model_copy(update={
            "patch": self.model.patch + 1,
            "revision": 0,
        })
        new.model.versionString = new.toString()
        return new

    def nextMinor(self) -> "SemanticVersion":
        """# promote minor: X.Y.Z.W -> X.(Y+1).0.0"""
        new = SemanticVersion().init()
        new.model = self.model.model_copy(update={
            "minor": self.model.minor + 1,
            "patch": 0,
            "revision": 0,
        })
        new.model.versionString = new.toString()
        return new

    def nextMajor(self) -> "SemanticVersion":
        """# promote major: X.Y.Z.W -> (X+1).0.0.0"""
        new = SemanticVersion().init()
        new.model = self.model.model_copy(update={
            "major": self.model.major + 1,
            "minor": 0,
            "patch": 0,
            "revision": 0,
        })
        new.model.versionString = new.toString()
        return new

    def toString(self) -> str:
        m = self.model
        return f"{m.major}.{m.minor}.{m.patch}.{m.revision}"

    def __str__(self) -> str:
        return self.toString()

    def __lt__(self, other: "SemanticVersion") -> bool:
        return (self.model.major, self.model.minor,
                self.model.patch, self.model.revision) < \
               (other.model.major, other.model.minor,
                other.model.patch, other.model.revision)
```

**Step 4: Run tests — all pass**

**Step 5: Commit**

```bash
git add -A && git commit -m "feat(web4py): SemanticVersion as first @ucpComponent"
```

---

### Task 12: CLIRouter

**Files:**
- Create: `$C/src/py/layer2/cliRouter.py`
- Create: `$C/test/pytest/test_cliRouter.py`

**Step 1: Write the failing tests**

```python
# $C/test/pytest/test_cliRouter.py
import pytest


class FakeModel:
    pass


class FakeComponent:
    """Test component with known methods."""
    model = FakeModel()
    _results: list[tuple] = []

    def __init__(self):
        self._results = []
        self._signatures = {}

    def processData(self, inputFile: str):
        """<inputFile> # process input data"""
        self._results.append(("processData", inputFile))
        return self

    def exportResult(self, fmt: str = "json"):
        """<?fmt:json> # export results"""
        self._results.append(("exportResult", fmt))
        return self

    def listAll(self):
        """# list all items"""
        self._results.append(("listAll",))
        return self


class TestCLIRouter:
    @pytest.mark.asyncio
    async def test_singleMethod(self):
        from src.py.layer2.cliRouter import CLIRouter
        comp = FakeComponent()
        router = CLIRouter(comp)
        await router.execute(["processData", "input.csv"])
        assert comp._results == [("processData", "input.csv")]

    @pytest.mark.asyncio
    async def test_methodChaining(self):
        from src.py.layer2.cliRouter import CLIRouter
        comp = FakeComponent()
        router = CLIRouter(comp)
        await router.execute(["processData", "input.csv", "exportResult", "xml"])
        assert comp._results == [
            ("processData", "input.csv"),
            ("exportResult", "xml"),
        ]

    @pytest.mark.asyncio
    async def test_methodWithNoArgs(self):
        from src.py.layer2.cliRouter import CLIRouter
        comp = FakeComponent()
        router = CLIRouter(comp)
        await router.execute(["listAll"])
        assert comp._results == [("listAll",)]

    @pytest.mark.asyncio
    async def test_methodChainWithNoArgMethod(self):
        from src.py.layer2.cliRouter import CLIRouter
        comp = FakeComponent()
        router = CLIRouter(comp)
        await router.execute(["processData", "input.csv", "listAll", "exportResult", "xml"])
        assert comp._results == [
            ("processData", "input.csv"),
            ("listAll",),
            ("exportResult", "xml"),
        ]

    @pytest.mark.asyncio
    async def test_unknownMethod(self):
        from src.py.layer2.cliRouter import CLIRouter, MethodNotFound
        comp = FakeComponent()
        router = CLIRouter(comp)
        with pytest.raises(MethodNotFound):
            await router.execute(["nonexistent"])

    @pytest.mark.asyncio
    async def test_missingRequiredParam(self):
        from src.py.layer2.cliRouter import CLIRouter, MissingParam
        comp = FakeComponent()
        router = CLIRouter(comp)
        with pytest.raises(MissingParam):
            await router.execute(["processData"])

    @pytest.mark.asyncio
    async def test_optionalParamOmitted(self):
        from src.py.layer2.cliRouter import CLIRouter
        comp = FakeComponent()
        router = CLIRouter(comp)
        await router.execute(["exportResult"])
        # Default used — no arg passed, method still called
        assert comp._results == [("exportResult",)]
```

**Step 2: Run tests to verify they fail**

**Step 3: Write implementation**

```python
# $C/src/py/layer2/cliRouter.py
import inspect
from src.py.layer2.discovery import discoverMethods
from src.py.layer3.methodSignature import MethodSignature


class MethodNotFound(Exception):
    def __init__(self, method: str, available: list[str] | None = None):
        self.method = method
        self.available = available or []
        suggestions = ""
        if self.available:
            matches = [m for m in self.available if method in m or m in method]
            if matches:
                suggestions = f" Did you mean: {', '.join(matches)}"
        super().__init__(f"Method '{method}' not found.{suggestions}")


class MissingParam(Exception):
    def __init__(self, method: str, param: str):
        super().__init__(f"Method '{method}' requires parameter <{param}>")


class CLIRouter:
    """Routes positional CLI arguments to method calls with chaining."""

    def __init__(self, component):
        self.component = component
        self.signatures = discoverMethods(component)

    async def execute(self, args: list[str]) -> None:
        remaining = list(args)

        while remaining:
            methodName = remaining.pop(0)

            if methodName not in self.signatures:
                raise MethodNotFound(methodName, list(self.signatures.keys()))

            sig = self.signatures[methodName]
            method = getattr(self.component, methodName)

            # Consume arguments for this method's parameters
            methodArgs = []
            for param in sig.params:
                if remaining and remaining[0] not in self.signatures:
                    methodArgs.append(remaining.pop(0))
                elif param.required:
                    raise MissingParam(methodName, param.name)
                # Optional param with no arg: don't pass anything

            # Call method
            if sig.isAsync:
                await method(*methodArgs)
            else:
                method(*methodArgs)
```

**Step 4: Run tests — all pass**

**Step 5: Commit**

```bash
git add -A && git commit -m "feat(web4py): CLIRouter — positional args with method chaining"
```

---

### Task 13: HelpGenerator and CompletionGenerator

**Files:**
- Create: `$C/src/py/layer4/helpGenerator.py`
- Create: `$C/src/py/layer4/completionGenerator.py`
- Create: `$C/test/pytest/test_helpAndCompletion.py`

**Step 1: Write the failing tests**

```python
# $C/test/pytest/test_helpAndCompletion.py
from src.py.layer3.methodSignature import MethodSignature, Param


def makeSigs():
    return {
        "processData": MethodSignature(
            name="processData",
            params=[Param(name="inputFile", required=True, default=None)],
            description="process input data file",
        ),
        "exportResult": MethodSignature(
            name="exportResult",
            params=[Param(name="fmt", required=False, default="json")],
            description="export results",
        ),
    }


class TestHelpGenerator:
    def test_generatesHelp(self):
        from src.py.layer4.helpGenerator import HelpGenerator
        gen = HelpGenerator()
        text = gen.generate(makeSigs(), "myapp")
        assert "myapp" in text
        assert "processData" in text
        assert "<inputFile>" in text
        assert "process input data file" in text
        assert "exportResult" in text
        assert "<?fmt:json>" in text

    def test_emptySignatures(self):
        from src.py.layer4.helpGenerator import HelpGenerator
        gen = HelpGenerator()
        text = gen.generate({}, "myapp")
        assert "myapp" in text


class TestCompletionGenerator:
    def test_generatesBashCompletion(self):
        from src.py.layer4.completionGenerator import CompletionGenerator
        gen = CompletionGenerator()
        script = gen.generateBash("myapp", makeSigs())
        assert "_myapp_completion" in script
        assert "processData" in script
        assert "exportResult" in script
        assert "complete -F" in script

    def test_containsShCompletionCall(self):
        from src.py.layer4.completionGenerator import CompletionGenerator
        gen = CompletionGenerator()
        script = gen.generateBash("myapp", makeSigs())
        assert "shCompletion" in script
```

**Step 2: Run tests to verify they fail**

**Step 3: Write implementations**

```python
# $C/src/py/layer4/helpGenerator.py
from src.py.layer3.methodSignature import MethodSignature


class HelpGenerator:
    """Generates help text from discovered method signatures."""

    def generate(self, signatures: dict[str, MethodSignature],
                 componentName: str,
                 delegatedSignatures: dict[str, MethodSignature] | None = None) -> str:
        lines = [
            f"{componentName}: command   Parameter and Description",
            "=" * 60,
        ]

        if signatures:
            for sig in sorted(signatures.values(), key=lambda s: s.name):
                paramStr = " ".join(p.format() for p in sig.params)
                lines.append(f"  {sig.name:<20} {paramStr:<30} {sig.description}")

        if delegatedSignatures:
            lines.append("")
            lines.append("  Delegated (via Web4PyComponent):")
            lines.append("  " + "-" * 56)
            for sig in sorted(delegatedSignatures.values(), key=lambda s: s.name):
                paramStr = " ".join(p.format() for p in sig.params)
                lines.append(f"  {sig.name:<20} {paramStr:<30} {sig.description}")

        return "\n".join(lines)
```

```python
# $C/src/py/layer4/completionGenerator.py
from src.py.layer3.methodSignature import MethodSignature


class CompletionGenerator:
    """Generates shell completion scripts from discovered signatures."""

    def generateBash(self, componentName: str,
                     signatures: dict[str, MethodSignature]) -> str:
        methodNames = " ".join(signatures.keys())
        return f'''
_{componentName}_completion() {{
    local cur prev methods
    COMPREPLY=()
    cur="${{COMP_WORDS[COMP_CWORD]}}"
    prev="${{COMP_WORDS[COMP_CWORD-1]}}"
    methods="{methodNames}"

    # First arg: complete method names
    if [ $COMP_CWORD -eq 1 ]; then
        COMPREPLY=( $(compgen -W "$methods" -- "$cur") )
        return 0
    fi

    # Subsequent args: call component shCompletion
    local method="${{COMP_WORDS[1]}}"
    local paramIndex=$(( COMP_CWORD - 2 ))
    local completions
    completions=$({componentName} shCompletion "$method" "$paramIndex" "$cur" 2>/dev/null)
    if [ -n "$completions" ]; then
        COMPREPLY=( $(compgen -W "$completions" -- "$cur") )
    fi
}}
complete -F _{componentName}_completion {componentName}
'''
```

**Step 4: Run tests — all pass**

**Step 5: Commit**

```bash
git add -A && git commit -m "feat(web4py): HelpGenerator and CompletionGenerator"
```

---

## Phase 6: DelegationProxy

### Task 14: DelegationProxy

**Files:**
- Create: `$C/src/py/layer2/delegationProxy.py`
- Create: `$C/test/pytest/test_delegationProxy.py`

**Step 1: Write the failing tests**

```python
# $C/test/pytest/test_delegationProxy.py
import pytest
from uuid import uuid4
from src.py.layer2.ucpComponent import ucpComponent
from src.py.layer3.model import Model
from src.py.layer3.scenario import Scenario
from src.py.layer3.ior import IOR


class TargetModel(Model):
    value: str = ""

@ucpComponent
class TargetComponent:
    model: TargetModel

    def init(self, scenario=None):
        self.model = TargetModel(
            uuid=uuid4(), name="Target", origin="test", definition="",
        )
        self._discoverMethods()
        return self

    async def toScenario(self, name=None):
        return Scenario(
            ior=IOR(uuid=self.model.uuid, component="Target", version="0.1.0.0"),
            model=self.model,
        )

    def ownMethod(self, val: str = "") -> "TargetComponent":
        """<?val> # own method"""
        self.model.value = val
        return self


class GenesisModel(Model):
    pass

@ucpComponent
class FakeGenesis:
    model: GenesisModel

    def init(self, scenario=None):
        self.model = GenesisModel(
            uuid=uuid4(), name="Genesis", origin="test", definition="",
        )
        self._discoverMethods()
        return self

    async def toScenario(self, name=None):
        return Scenario(
            ior=IOR(uuid=self.model.uuid, component="Genesis", version="0.1.0.0"),
            model=self.model,
        )

    def delegatedMethod(self) -> "FakeGenesis":
        """# a delegated method"""
        return self

    def anotherDelegated(self, x: str = "") -> "FakeGenesis":
        """<?x> # another delegated"""
        return self


class TestDelegationProxy:
    def test_ownMethodCallable(self):
        from src.py.layer2.delegationProxy import DelegationProxy
        target = TargetComponent().init()
        genesis = FakeGenesis().init()
        proxy = DelegationProxy(target, genesis)
        proxy.ownMethod("hello")
        assert target.model.value == "hello"

    def test_delegatedMethodCallable(self):
        from src.py.layer2.delegationProxy import DelegationProxy
        target = TargetComponent().init()
        genesis = FakeGenesis().init()
        proxy = DelegationProxy(target, genesis)
        # Should not raise — delegates to genesis
        proxy.delegatedMethod()

    def test_unknownMethodRaises(self):
        from src.py.layer2.delegationProxy import DelegationProxy
        target = TargetComponent().init()
        genesis = FakeGenesis().init()
        proxy = DelegationProxy(target, genesis)
        with pytest.raises(AttributeError):
            proxy.totallyUnknown()

    def test_listMethodsReturnsOnlyOwn(self):
        from src.py.layer2.delegationProxy import DelegationProxy
        target = TargetComponent().init()
        genesis = FakeGenesis().init()
        proxy = DelegationProxy(target, genesis)
        methods = proxy.listMethods()
        assert "ownMethod" in methods
        assert "delegatedMethod" not in methods

    def test_listDelegatedMethods(self):
        from src.py.layer2.delegationProxy import DelegationProxy
        target = TargetComponent().init()
        genesis = FakeGenesis().init()
        proxy = DelegationProxy(target, genesis)
        delegated = proxy.listDelegatedMethods()
        assert "delegatedMethod" in delegated
        assert "anotherDelegated" in delegated

    def test_hasDelegation(self):
        from src.py.layer2.delegationProxy import DelegationProxy
        target = TargetComponent().init()
        genesis = FakeGenesis().init()
        proxy = DelegationProxy(target, genesis)
        assert proxy.hasDelegation() is True

    def test_modelAccessesTarget(self):
        from src.py.layer2.delegationProxy import DelegationProxy
        target = TargetComponent().init()
        genesis = FakeGenesis().init()
        proxy = DelegationProxy(target, genesis)
        assert proxy.model.name == "Target"

    def test_privateNotDelegated(self):
        from src.py.layer2.delegationProxy import DelegationProxy
        target = TargetComponent().init()
        genesis = FakeGenesis().init()
        proxy = DelegationProxy(target, genesis)
        with pytest.raises(AttributeError):
            proxy._private()
```

**Step 2: Run tests to verify they fail**

**Step 3: Write implementation**

```python
# $C/src/py/layer2/delegationProxy.py
import inspect
from src.py.layer2.discovery import discoverMethods
from src.py.layer3.methodSignature import MethodSignature


class DelegationProxy:
    """
    Wraps a component to transparently delegate missing methods
    to a genesis component. Zero boilerplate for generated components.
    """

    def __init__(self, target, genesis):
        object.__setattr__(self, '_target', target)
        object.__setattr__(self, '_genesis', genesis)
        object.__setattr__(self, '_genesisSignatures', discoverMethods(genesis))

    def __getattr__(self, name: str):
        # Don't delegate dunder or private
        if name.startswith('_'):
            raise AttributeError(name)

        target = object.__getattribute__(self, '_target')
        genesis = object.__getattribute__(self, '_genesis')

        # 1. Try target component (own methods)
        if hasattr(target, name):
            attr = getattr(target, name)
            if callable(attr):
                def chainable(*args, **kwargs):
                    attr(*args, **kwargs)
                    return self
                return chainable
            return attr

        # 2. Delegate to genesis
        if hasattr(genesis, name):
            attr = getattr(genesis, name)
            if callable(attr):
                def delegated(*args, **kwargs):
                    result = attr(*args, **kwargs)
                    if inspect.isawaitable(result):
                        import asyncio
                        asyncio.get_event_loop().run_until_complete(result)
                    return self
                return delegated

        raise AttributeError(
            f"'{target.model.name}' has no method '{name}' "
            f"(checked own methods and genesis delegation)"
        )

    @property
    def model(self):
        return object.__getattribute__(self, '_target').model

    def init(self, scenario=None):
        object.__getattribute__(self, '_target').init(scenario)
        return self

    async def toScenario(self, name=None):
        return await object.__getattribute__(self, '_target').toScenario(name)

    def listMethods(self) -> list[str]:
        target = object.__getattribute__(self, '_target')
        return target.listMethods()

    def listDelegatedMethods(self) -> list[str]:
        sigs = object.__getattribute__(self, '_genesisSignatures')
        return list(sigs.keys())

    def hasDelegation(self) -> bool:
        return True

    def getDelegationTarget(self):
        return object.__getattribute__(self, '_genesis')

    def hasMethod(self, name: str) -> bool:
        target = object.__getattribute__(self, '_target')
        if target.hasMethod(name):
            return True
        sigs = object.__getattribute__(self, '_genesisSignatures')
        return name in sigs

    def getMethodSignature(self, name: str) -> MethodSignature | None:
        target = object.__getattribute__(self, '_target')
        sig = target.getMethodSignature(name)
        if sig:
            return sig
        sigs = object.__getattribute__(self, '_genesisSignatures')
        return sigs.get(name)
```

**Step 4: Run tests — all pass**

**Step 5: Commit**

```bash
git add -A && git commit -m "feat(web4py): DelegationProxy — transparent __getattr__ delegation"
```

---

## Phase 7: Version Lifecycle & Self-Build

### Task 15: VersionLifecycle manager

**Files:**
- Create: `$C/src/py/layer2/versionLifecycle.py`
- Create: `$C/test/pytest/test_versionLifecycle.py`

**Step 1: Write the failing tests**

```python
# $C/test/pytest/test_versionLifecycle.py
import pytest
from pathlib import Path


@pytest.fixture
def tmpComponents(tmp_path):
    from src.py.layer2.versionLifecycle import VersionLifecycle
    compDir = tmp_path / "components"
    compDir.mkdir()
    # Create MyApp/0.1.0.0
    (compDir / "MyApp" / "0.1.0.0").mkdir(parents=True)
    (compDir / "MyApp" / "0.1.0.0" / "marker.txt").write_text("v0.1.0.0")
    # Create symlinks
    (compDir / "MyApp" / "latest").symlink_to("0.1.0.0")
    (compDir / "MyApp" / "dev").symlink_to("0.1.0.0")
    return VersionLifecycle(compDir), compDir


class TestVersionLifecycle:
    def test_resolveLink(self, tmpComponents):
        lifecycle, _ = tmpComponents
        v = lifecycle.resolveLink("MyApp", "latest")
        assert str(v) == "0.1.0.0"

    def test_resolveLinkNotFound(self, tmpComponents):
        from src.py.layer2.versionLifecycle import VersionNotFound
        lifecycle, _ = tmpComponents
        with pytest.raises(VersionNotFound):
            lifecycle.resolveLink("MyApp", "prod")

    def test_updateLink(self, tmpComponents):
        lifecycle, compDir = tmpComponents
        # Create a new version dir
        (compDir / "MyApp" / "0.1.0.1").mkdir()
        lifecycle.updateLink("MyApp", "dev", "0.1.0.1")
        v = lifecycle.resolveLink("MyApp", "dev")
        assert str(v) == "0.1.0.1"
        # latest unchanged
        v2 = lifecycle.resolveLink("MyApp", "latest")
        assert str(v2) == "0.1.0.0"
```

**Step 2: Run tests to verify they fail**

**Step 3: Write implementation**

```python
# $C/src/py/layer2/versionLifecycle.py
from pathlib import Path
from src.py.layer2.semanticVersion import SemanticVersion


class VersionNotFound(Exception):
    pass


class VersionLifecycle:
    """Manages semantic symlinks and version promotion."""

    def __init__(self, componentsDir: Path):
        self.componentsDir = componentsDir

    def resolveLink(self, component: str, link: str) -> SemanticVersion:
        linkPath = self.componentsDir / component / link
        if linkPath.is_symlink():
            target = linkPath.resolve().name
            return SemanticVersion.fromString(target)
        raise VersionNotFound(f"{component}/{link} not found")

    def updateLink(self, component: str, link: str, version: str) -> None:
        linkPath = self.componentsDir / component / link
        targetPath = self.componentsDir / component / version
        if not targetPath.is_dir():
            raise VersionNotFound(f"{component}/{version} not found")
        if linkPath.is_symlink() or linkPath.exists():
            linkPath.unlink()
        linkPath.symlink_to(version)
```

**Step 4: Run tests — all pass**

**Step 5: Commit**

```bash
git add -A && git commit -m "feat(web4py): VersionLifecycle — symlink management"
```

---

### Task 16: SelfHeal

**Files:**
- Create: `$C/src/py/layer2/selfHeal.py`
- Create: `$C/test/pytest/test_selfHeal.py`

**Step 1: Write the failing tests**

```python
# $C/test/pytest/test_selfHeal.py
import pytest
from pathlib import Path


@pytest.fixture
def componentDir(tmp_path):
    root = tmp_path / "MyApp" / "0.1.0.0"
    root.mkdir(parents=True)
    (root / "pyproject.toml").write_text('[project]\nname="myapp"')
    return root


class TestSelfHeal:
    @pytest.mark.asyncio
    async def test_diagnoseMissingVenv(self, componentDir):
        from src.py.layer2.selfHeal import SelfHeal
        healer = SelfHeal(componentDir)
        issues = await healer.diagnose()
        descriptions = [i.description for i in issues]
        assert any("Virtual environment" in d for d in descriptions)

    @pytest.mark.asyncio
    async def test_diagnoseBrokenUnit(self, componentDir):
        from src.py.layer2.selfHeal import SelfHeal
        # Create a broken .unit symlink
        broken = componentDir / "broken.unit"
        broken.symlink_to("nonexistent.json")
        healer = SelfHeal(componentDir)
        issues = await healer.diagnose()
        descriptions = [i.description for i in issues]
        assert any("Broken .unit" in d for d in descriptions)

    @pytest.mark.asyncio
    async def test_diagnoseHealthy(self, componentDir):
        from src.py.layer2.selfHeal import SelfHeal
        # Create venv and stamp
        venv = componentDir / ".venv"
        venv.mkdir()
        (venv / ".deps-installed").touch()
        healer = SelfHeal(componentDir)
        issues = await healer.diagnose()
        # Only venv exists, no broken units
        assert len(issues) == 0
```

**Step 2: Run tests to verify they fail**

**Step 3: Write implementation**

```python
# $C/src/py/layer2/selfHeal.py
from dataclasses import dataclass, field
from pathlib import Path
from typing import Callable, Awaitable


@dataclass
class Issue:
    severity: str
    description: str
    fix: Callable[[], Awaitable[None]] | None = None


class SelfHeal:
    """Detects and repairs common component problems."""

    def __init__(self, componentRoot: Path):
        self.root = componentRoot
        self.venvDir = componentRoot / ".venv"

    async def diagnose(self) -> list[Issue]:
        issues = []

        # 1. Virtual environment missing
        if not self.venvDir.exists():
            issues.append(Issue(
                severity="critical",
                description="Virtual environment missing",
            ))

        # 2. Dependencies stale
        pyproject = self.root / "pyproject.toml"
        stamp = self.venvDir / ".deps-installed"
        if self.venvDir.exists() and pyproject.exists() and (
            not stamp.exists() or
            pyproject.stat().st_mtime > stamp.stat().st_mtime
        ):
            issues.append(Issue(
                severity="warning",
                description="Dependencies may be stale",
            ))

        # 3. Broken .unit symlinks
        for unit in self.root.rglob("*.unit"):
            if unit.is_symlink() and not unit.resolve().exists():
                issues.append(Issue(
                    severity="warning",
                    description=f"Broken .unit symlink: {unit.name}",
                ))

        # 4. Broken semantic version links
        parent = self.root.parent
        for link in ["latest", "dev", "test", "prod"]:
            linkPath = parent / link
            if linkPath.is_symlink() and not linkPath.resolve().exists():
                issues.append(Issue(
                    severity="error",
                    description=f"Broken version link: {link}",
                ))

        return issues
```

**Step 4: Run tests — all pass**

**Step 5: Commit**

```bash
git add -A && git commit -m "feat(web4py): SelfHeal — component health diagnostics"
```

---

## Phase 8: Component Generator & CLI Entry Point

### Task 17: Bash wrapper template

**Files:**
- Create: `$C/templates/bashWrapper.template`

**Step 1: Write the bash wrapper template**

```bash
#!/bin/bash
# Auto-generated by Web4PyComponent -- do not edit manually
# Location-independent, self-building, self-healing
COMPONENT_NAME="{{componentNameCLI}}"

# --- Resolve script location (follow symlinks) ---
SCRIPT_FILE="${BASH_SOURCE[0]}"
while [ -L "$SCRIPT_FILE" ]; do
    SCRIPT_FILE="$(readlink "$SCRIPT_FILE")"
    [[ "$SCRIPT_FILE" != /* ]] && SCRIPT_FILE="$(dirname "${BASH_SOURCE[0]}")/$SCRIPT_FILE"
done
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_FILE")" && pwd -P)"

# --- Find project root ---
find_project_root() {
    local dir="$PWD"
    if [[ "$dir" == */test/data* ]]; then
        echo "${dir%%/test/data*}/test/data"
        return
    fi
    local git_root
    git_root=$(git rev-parse --show-toplevel 2>/dev/null)
    if [ -n "$git_root" ] && [ -d "$git_root/components" ]; then
        echo "$git_root"
        return
    fi
    while [ "$dir" != "/" ]; do
        [ -d "$dir/components" ] && echo "$dir" && return
        dir="$(dirname "$dir")"
    done
    echo "$PWD"
}
PROJECT_ROOT=$(find_project_root)

# --- Self-Build ---
VENV_DIR="$SCRIPT_DIR/.venv"
if [ ! -d "$VENV_DIR" ]; then
    echo "Creating virtual environment..." >&2
    python3 -m venv "$VENV_DIR" || { echo "ERROR: python3 required" >&2; exit 1; }
fi

REQS="$SCRIPT_DIR/pyproject.toml"
STAMP="$VENV_DIR/.deps-installed"
if [[ "$1" != "shCompletion" ]] || [ ! -f "$STAMP" ]; then
    if [ "$REQS" -nt "$STAMP" ] 2>/dev/null || [ ! -f "$STAMP" ]; then
        "$VENV_DIR/bin/pip" install -q -e "$SCRIPT_DIR" 2>&1 | grep -v "already satisfied" >&2
        touch "$STAMP"
    fi
fi

# --- Execute ---
cd "$PROJECT_ROOT" || exit 1
exec "$VENV_DIR/bin/python" -m "src.py" "$@"
```

**Step 2: Commit**

```bash
git add -A && git commit -m "feat(web4py): bash wrapper template for generated components"
```

---

### Task 18: ComponentGenerator

**Files:**
- Create: `$C/src/py/layer2/componentGenerator.py`
- Create: `$C/templates/defaultComponent.py.template`
- Create: `$C/templates/componentCLI.py.template`
- Create: `$C/templates/componentMain.py.template`
- Create: `$C/templates/componentTest.py.template`
- Create: `$C/templates/pyproject.toml.template`
- Create: `$C/templates/sourceEnv.template`
- Create: `$C/test/pytest/test_componentGenerator.py`

**Step 1: Write the failing tests**

```python
# $C/test/pytest/test_componentGenerator.py
import pytest
from pathlib import Path


@pytest.fixture
def generatorSetup(tmp_path):
    from src.py.layer2.componentGenerator import ComponentGenerator
    templatesDir = Path(__file__).parent.parent.parent / "templates"
    componentsDir = tmp_path / "components"
    componentsDir.mkdir()
    return ComponentGenerator(templatesDir, componentsDir), componentsDir


class TestComponentGenerator:
    @pytest.mark.asyncio
    async def test_createDirectoryStructure(self, generatorSetup):
        gen, compDir = generatorSetup
        result = await gen.create("MyApp", "0.1.0.0")
        assert (compDir / "MyApp" / "0.1.0.0" / "src" / "py" / "layer2").is_dir()
        assert (compDir / "MyApp" / "0.1.0.0" / "src" / "py" / "layer5").is_dir()
        assert (compDir / "MyApp" / "0.1.0.0" / "test" / "pytest").is_dir()

    @pytest.mark.asyncio
    async def test_createBashWrapper(self, generatorSetup):
        gen, compDir = generatorSetup
        await gen.create("MyApp", "0.1.0.0")
        wrapper = compDir / "MyApp" / "0.1.0.0" / "myapp"
        assert wrapper.exists()
        import os
        assert os.access(wrapper, os.X_OK)

    @pytest.mark.asyncio
    async def test_createSemanticSymlinks(self, generatorSetup):
        gen, compDir = generatorSetup
        await gen.create("MyApp", "0.1.0.0")
        assert (compDir / "MyApp" / "latest").is_symlink()
        assert (compDir / "MyApp" / "dev").is_symlink()

    @pytest.mark.asyncio
    async def test_createPyprojectToml(self, generatorSetup):
        gen, compDir = generatorSetup
        await gen.create("MyApp", "0.1.0.0")
        pyproject = compDir / "MyApp" / "0.1.0.0" / "pyproject.toml"
        assert pyproject.exists()
        content = pyproject.read_text()
        assert "myapp" in content.lower()
        assert "0.1.0.0" in content

    @pytest.mark.asyncio
    async def test_componentAlreadyExists(self, generatorSetup):
        from src.py.layer2.componentGenerator import ComponentExists
        gen, compDir = generatorSetup
        await gen.create("MyApp", "0.1.0.0")
        with pytest.raises(ComponentExists):
            await gen.create("MyApp", "0.1.0.0")

    @pytest.mark.asyncio
    async def test_generatedComponentFile(self, generatorSetup):
        gen, compDir = generatorSetup
        await gen.create("MyApp", "0.1.0.0")
        compFile = compDir / "MyApp" / "0.1.0.0" / "src" / "py" / "layer2" / "defaultMyApp.py"
        assert compFile.exists()
        content = compFile.read_text()
        assert "@ucpComponent" in content
        assert "class MyApp" in content
        assert "MyAppModel" in content
```

**Step 2: Run tests to verify they fail**

**Step 3: Create template files**

```python
# $C/templates/defaultComponent.py.template
from typing import Self
from uuid import uuid4
from src.py.layer2.ucpComponent import ucpComponent
from src.py.layer3.model import Model
from src.py.layer3.scenario import Scenario
from src.py.layer3.ior import IOR


class {{componentName}}Model(Model):
    """{{componentName}} model -- add your fields here."""
    pass


@ucpComponent
class {{componentName}}:
    model: {{componentName}}Model

    def init(self, scenario: Scenario[{{componentName}}Model] | None = None) -> Self:
        if not hasattr(self, '_initialized'):
            self.model = {{componentName}}Model(
                uuid=uuid4(),
                name="{{componentName}}",
                origin="web4pycomponent create",
                definition="",
            )
        if scenario and scenario.model:
            self.model = self.model.model_copy(update=scenario.model.model_dump())
        self._discoverMethods()
        self._initialized = True
        return self

    async def toScenario(self, name: str | None = None) -> Scenario[{{componentName}}Model]:
        return Scenario(
            ior=IOR(uuid=self.model.uuid, component="{{componentName}}", version="{{version}}"),
            model=self.model,
        )

    # Add your methods below:
    # def myMethod(self, param: str) -> Self:
    #     """<param> # description"""
    #     ...
    #     return self
```

```python
# $C/templates/componentCLI.py.template
import sys
import asyncio
from src.py.layer2.cliRouter import CLIRouter
from src.py.layer2.defaultMyApp import {{componentName}}


def main():
    component = {{componentName}}().init()
    router = CLIRouter(component)

    if len(sys.argv) < 2:
        from src.py.layer2.discovery import discoverMethods
        from src.py.layer4.helpGenerator import HelpGenerator
        sigs = discoverMethods(component)
        print(HelpGenerator().generate(sigs, "{{componentNameCLI}}"))
        return

    asyncio.run(router.execute(sys.argv[1:]))


if __name__ == "__main__":
    main()
```

```python
# $C/templates/componentMain.py.template
from src.py.layer5.{{componentNameCLI}}CLI import main

if __name__ == "__main__":
    main()
```

```python
# $C/templates/componentTest.py.template
import pytest
import asyncio
from uuid import uuid4


class Test{{componentName}}:
    def test_emptyConstructor(self):
        from src.py.layer2.default{{componentName}} import {{componentName}}
        comp = {{componentName}}()
        assert not hasattr(comp, '_initialized')

    def test_initCreatesModel(self):
        from src.py.layer2.default{{componentName}} import {{componentName}}
        comp = {{componentName}}().init()
        assert comp.model.name == "{{componentName}}"
        assert comp.model.uuid is not None

    def test_roundTripScenario(self):
        from src.py.layer2.default{{componentName}} import {{componentName}}
        original = {{componentName}}().init()
        scenario = asyncio.run(original.toScenario())
        restored = {{componentName}}().init(scenario)
        assert restored.model.uuid == original.model.uuid

    def test_isUcpComponent(self):
        from src.py.layer2.default{{componentName}} import {{componentName}}
        assert {{componentName}}._ucp_component is True
```

```toml
# $C/templates/pyproject.toml.template
[project]
name = "{{componentNameCLI}}"
version = "{{version}}"
requires-python = ">=3.12"
dependencies = [
    "pydantic>=2.0",
]

[project.optional-dependencies]
dev = [
    "pytest>=8.0",
    "pytest-asyncio>=0.24",
]

[project.scripts]
{{componentNameCLI}} = "src.py.__main__:main"

[build-system]
requires = ["setuptools>=68.0"]
build-backend = "setuptools.backends._legacy:_Backend"
```

```bash
# $C/templates/sourceEnv.template
# Shell integration for {{componentName}}
# Source this file to enable tab completion:
#   source components/{{componentName}}/latest/source.env

_{{componentNameCLI}}_completion() {
    local cur prev
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    if [ $COMP_CWORD -eq 1 ]; then
        local methods
        methods=$({{componentNameCLI}} shCompletion "" "" "" 2>/dev/null)
        COMPREPLY=( $(compgen -W "$methods" -- "$cur") )
        return 0
    fi
    local method="${COMP_WORDS[1]}"
    local paramIndex=$(( COMP_CWORD - 2 ))
    local completions
    completions=$({{componentNameCLI}} shCompletion "$method" "$paramIndex" "$cur" 2>/dev/null)
    if [ -n "$completions" ]; then
        COMPREPLY=( $(compgen -W "$completions" -- "$cur") )
    fi
}
complete -F _{{componentNameCLI}}_completion {{componentNameCLI}}
```

**Step 4: Write ComponentGenerator implementation**

```python
# $C/src/py/layer2/componentGenerator.py
import os
from pathlib import Path
from uuid import uuid4


class ComponentExists(Exception):
    pass


class ComponentGenerator:
    """Creates new Web4 Python components from templates."""

    def __init__(self, templatesDir: Path, componentsDir: Path):
        self.templatesDir = templatesDir
        self.componentsDir = componentsDir

    async def create(self, name: str, version: str) -> Path:
        """Create a new component from templates."""
        componentDir = self.componentsDir / name / version

        if componentDir.exists():
            raise ComponentExists(f"{name}/{version} already exists")

        # Create directory structure
        for subdir in [
            "src/py/layer2", "src/py/layer3",
            "src/py/layer4", "src/py/layer5",
            "test/pytest", "templates",
        ]:
            (componentDir / subdir).mkdir(parents=True)

        context = {
            "{{componentName}}": name,
            "{{componentNameCLI}}": name[0].lower() + name[1:] if name else name,
            "{{version}}": version,
            "{{uuid}}": str(uuid4()),
        }

        # Render templates
        templateMap = {
            "defaultComponent.py.template": f"src/py/layer2/default{name}.py",
            "componentCLI.py.template": f"src/py/layer5/{context['{{componentNameCLI}}']}CLI.py",
            "componentMain.py.template": "src/py/__main__.py",
            "componentTest.py.template": f"test/pytest/test_{name}.py",
            "pyproject.toml.template": "pyproject.toml",
            "sourceEnv.template": "source.env",
            "bashWrapper.template": context["{{componentNameCLI}}"],
        }

        for templateName, outputRelPath in templateMap.items():
            templatePath = self.templatesDir / templateName
            if not templatePath.exists():
                continue
            content = templatePath.read_text()
            for placeholder, value in context.items():
                content = content.replace(placeholder, value)
            outputPath = componentDir / outputRelPath
            outputPath.parent.mkdir(parents=True, exist_ok=True)
            outputPath.write_text(content)

        # Create __init__.py files
        for initDir in ["src/py", "src/py/layer2", "src/py/layer3",
                        "src/py/layer4", "src/py/layer5", "test/pytest"]:
            (componentDir / initDir / "__init__.py").touch()

        # Make bash wrapper executable
        wrapper = componentDir / context["{{componentNameCLI}}"]
        if wrapper.exists():
            wrapper.chmod(0o755)

        # Create semantic symlinks
        for link in ["latest", "dev"]:
            linkPath = self.componentsDir / name / link
            if linkPath.is_symlink():
                linkPath.unlink()
            linkPath.symlink_to(version)

        return componentDir
```

**Step 5: Run tests — all pass**

**Step 6: Commit**

```bash
git add -A && git commit -m "feat(web4py): ComponentGenerator — create components from templates"
```

---

## Phase 9: MDA, IOR Resolver, PDCA, Oosh Bridge

### Task 19: MDA Ontology

**Files:**
- Create: `$C/src/py/layer2/mdaOntology.py`
- Create: `$C/test/pytest/test_mdaOntology.py`

Implement `MDAOntology` with `register()`, `query()`, and `addRelationship()` methods as described in design section 11. Use `ScenarioStore` and `UnitManager` for persistence. Test: register a component as CLASS, query it back, verify .unit file created.

**Commit:** `feat(web4py): MDA ontology — M3 meta-model`

---

### Task 20: IOR Resolver

**Files:**
- Create: `$C/src/py/layer2/iorResolver.py`
- Create: `$C/test/pytest/test_iorResolver.py`

Implement `IORResolver` with `registerType()`, `resolve()` as described in design section 12. Test: register a component type, save a scenario, resolve by IOR UUID.

**Commit:** `feat(web4py): IORResolver — component resolution by IOR`

---

### Task 21: PDCA component

**Files:**
- Create: `$C/src/py/layer2/pdca.py`
- Create: `$C/test/pytest/test_pdca.py`

Implement `PDCA` as `@ucpComponent` with `create()`, `advance()`, `save()` as described in design section 13. Test: create PDCA, advance through phases, save to filesystem.

**Commit:** `feat(web4py): PDCA process documentation component`

---

### Task 22: Oosh Bridge

**Files:**
- Create: `$C/src/py/layer2/ooshBridge.py`
- Create: `$C/test/pytest/test_ooshBridge.py`

Implement `OoshBridge` with `call()`, `listScripts()`, `readConfig()`, `generateOoshCompletion()` as described in design section 14. Test: readConfig with a mock user.env, generateOoshCompletion output format. Note: `call()` tests require oosh to be installed — mark with `@pytest.mark.skipif(not oosh_available)`.

**Commit:** `feat(web4py): OoshBridge — bash/Python interop`

---

## Phase 10: Integration & Genesis

### Task 23: DefaultWeb4PyComponent (the genesis itself)

**Files:**
- Create: `$C/src/py/layer2/defaultWeb4PyComponent.py`
- Create: `$C/test/pytest/test_defaultWeb4PyComponent.py`

The genesis component — an `@ucpComponent` that provides the development methods all other components delegate to:

```python
@ucpComponent
class Web4PyComponent:
    model: Web4PyComponentModel

    # Methods that generated components delegate to:
    def create(self, name: str, version: str = "0.1.0.0") -> Self:
        """<name> <?version:0.1.0.0> # create new Python component"""
        ...

    def upgrade(self, versionPromotion: str) -> Self:
        """<versionPromotion> # promote version (nextBuild/nextPatch/nextMinor/nextMajor)"""
        ...

    def test(self, scope: str = "") -> Self:
        """<?scope> # run tests"""
        ...

    def build(self) -> Self:
        """# build component (install deps)"""
        ...

    def clean(self) -> Self:
        """# clean build artifacts"""
        ...

    def tree(self, depth: str = "3") -> Self:
        """<?depth:3> # show component tree"""
        ...

    def info(self) -> Self:
        """# show component info"""
        ...

    def heal(self) -> Self:
        """# diagnose and repair component"""
        ...
```

Test: init, toScenario, create delegates to ComponentGenerator, info prints component details.

**Commit:** `feat(web4py): DefaultWeb4PyComponent — the genesis component`

---

### Task 24: Web4PyComponentCLI (Layer 5 entry point)

**Files:**
- Create: `$C/src/py/layer5/web4PyComponentCLI.py`
- Create: `$C/src/py/__main__.py`
- Create: `$C/web4pycomponent` (bash wrapper)
- Create: `$C/source.env`

Wire everything together: CLI that creates genesis, wraps with DelegationProxy (for self-delegation), routes args.

**Commit:** `feat(web4py): Web4PyComponentCLI — Layer 5 entry point`

---

### Task 25: End-to-end integration test

**Files:**
- Create: `$C/test/pytest/test_e2e.py`

Test the full flow:
1. Create genesis component → init
2. Call `web4pycomponent create TestApp 0.1.0.0`
3. Verify TestApp directory structure created
4. Verify TestApp bash wrapper is executable
5. Verify TestApp has own methods + delegated methods
6. Test method chaining via CLIRouter
7. Test scenario round-trip (init → toScenario → init)
8. Test help output includes both own and delegated sections

**Commit:** `feat(web4py): end-to-end integration test`

---

## Phase 11: Semantic Symlinks & Final Polish

### Task 26: Create semantic symlinks for Web4PyComponent itself

```bash
cd $PROJECT_ROOT/components/Web4PyComponent
ln -sf 0.1.0.0 latest
ln -sf 0.1.0.0 dev
```

**Commit:** `feat(web4py): semantic symlinks for genesis component`

---

## Summary

| Phase | Tasks | What it delivers |
|---|---|---|
| 1. Scaffold & Layer 3 | 1-6 | Project structure, Model, IOR, Scenario, MethodSignature, Protocol |
| 2. Discovery | 7 | Docstring parser, method discovery |
| 3. Decorator | 8 | @ucpComponent with validation + injection |
| 4. Persistence | 9-10 | ScenarioStore, UnitManager |
| 5. Version & CLI | 11-13 | SemanticVersion, CLIRouter, Help, Completion |
| 6. Delegation | 14 | DelegationProxy via __getattr__ |
| 7. Lifecycle | 15-16 | VersionLifecycle, SelfHeal |
| 8. Generator | 17-18 | Templates, ComponentGenerator |
| 9. Higher-level | 19-22 | MDA, IOR Resolver, PDCA, Oosh Bridge |
| 10. Genesis | 23-25 | DefaultWeb4PyComponent, CLI, E2E test |
| 11. Polish | 26 | Symlinks, final cleanup |

**Total: 26 tasks, ~130 steps**

Each task follows TDD: write failing test → verify failure → implement → verify pass → commit.
