---
name: probat-testing
description: Use when generating ProBat unit tests for TLPP classes and functions on TOTVS Protheus
---

# ProBat Testing

## Overview

ProBat is the native unit testing engine of tlppCore for creating and executing tests in TLPP programs on TOTVS Protheus. The name comes from Latin and means "proof/tests". It supports unit, functional, and integration tests, code coverage analysis, TDD workflows, and CI/CD integration.

> **ProBat only works with TLPP.** Tests for ADVPL sources must also be written in TLPP. If the target code is `.prw`, the test file is still `.tlpp`.

## Required Include

Every test file must include the ProBat header:

```tlpp
#include "tlpp-probat.th"
```

If using tlppCore features (JsonObject, REST, etc.), also include:

```tlpp
#include "tlpp-core.th"
#include "tlpp-probat.th"
```

## Namespace Convention

Test namespaces follow the pattern `test.<module>` or `custom.tests.<module>`:

```tlpp
namespace test.financeiro
namespace custom.tests.faturamento
```

## Annotations

All annotations below are confirmed in the official TOTVS `tlpp-probat-samples` repository.

### @TestFixture

Marks a function or class as a test fixture. This is the **only** way ProBat discovers test code.

```tlpp
// Minimal
@TestFixture()

// With properties
@TestFixture(owner='team_name')
@TestFixture(owner='team_name', target='source_file.tlpp')
@TestFixture(owner='team_name', suite='suite_name')
@TestFixture(priority=1)
@TestFixture(runWithAll=.F.)  // Exclude from "run all" mode
@TestFixture(rwa=.F.)        // Short alias for runWithAll
```

| Property | Type | Description |
|----------|------|-------------|
| `owner` | Character | Team or author identifier |
| `target` | Character | Source file being tested (for traceability) |
| `suite` | Character | Suite name (for grouped execution) |
| `priority` | Numeric | Execution order (lower = first) |
| `runWithAll` / `rwa` | Logical | If `.F.`, test is excluded from "run all" mode |

### @Test

Marks a method in a `@TestFixture` class as a test to execute. The description parameter is **mandatory**.

```tlpp
@Test('description of what is being tested')
public method myTestMethod()
```

> If a class has `@TestFixture` but no methods with `@Test`, the result will be SKIPPED.

### @OneTimeSetUp (runs once before all tests)

Marks a method to run **once** before all `@Test` methods in the class. Multiple `@OneTimeSetUp` methods are allowed.

```tlpp
@OneTimeSetUp()
public method initDatabase()
```

### @Setup (runs before each test)

Marks a method to run **before each** `@Test` method.

```tlpp
@Setup()
public method resetState()
```

### @TearDown (runs after each test)

Marks a method to run **after each** `@Test` method.

```tlpp
@TearDown()
public method cleanupState()
```

### @OneTimeTearDown (runs once after all tests)

Marks a method to run **once** after all `@Test` methods in the class.

```tlpp
@OneTimeTearDown()
public method closeConnections()
```

### @Skip

Skips an entire test fixture (function or class) or a specific method. Supports conditional filters.

```tlpp
// Skip unconditionally
@Skip()

// Skip with filters
@Skip(system="windows")
@Skip(appServerName="HARPIA")
@Skip(tlppVersion=">= 01.02.10")
@Skip(system="windows", appServerName="HARPIA", tlppVersion=">= 01.02.10")
```

### @ErrorLog

Marks a test that is expected to produce an error. The test passes if the specified error occurs.

```tlpp
@Test('test that expects an error')
@ErrorLog('type mismatch')
public method testExpectedError()
```

### SKIPASSERT (inline command)

Skips the next assertion only. Useful for conditional skipping inside a test.

```tlpp
SKIPASSERT
assertError('this assert will be skipped')

// With filters
SKIPASSERT TLPPVERSION ">= 01.02.10"
SKIPASSERT SYSTEM "windows"
SKIPASSERT APPSERVERNAME "HARPIA"
SKIPASSERT SYSTEM "windows" APPSERVERNAME "HARPIA" TLPPVERSION ">= 01.02.10"
```

## Assertion Functions

All assertions belong to the `tlpp.probat` namespace. They can be called either by using the namespace directive or with the full qualified name.

```tlpp
// Option 1: using namespace
using namespace tlpp.probat
assertEquals(xValue, xExpected, 'description')

// Option 2: full qualified name
tlpp.probat.assertEquals(xValue, xExpected, 'description')
```

### Complete Assertion Reference

| Function | Signature | Description |
|----------|-----------|-------------|
| `assertEquals` | `(xValue, xExpected [, cDesc])` | Values must be equal |
| `assertNotEquals` | `(xValue, xExpected [, cDesc])` | Values must be different |
| `assertTrue` | `(lValue [, cDesc])` | Value must be `.T.` |
| `assertFalse` | `(lValue [, cDesc])` | Value must be `.F.` |
| `assertGreater` | `(xValue, xCompare [, cDesc])` | Value must be greater than expected |
| `assertGreaterOrEqual` | `(xValue, xCompare [, cDesc])` | Value must be greater than or equal to expected |
| `assertLess` | `(xValue, xCompare [, cDesc])` | Value must be less than expected |
| `assertLessOrEqual` | `(xValue, xCompare [, cDesc])` | Value must be less than or equal to expected |
| `assertNil` | `(xValue [, cDesc])` | Value must be NIL |
| `assertVector` | `(aValue, aExpected [, cDesc])` | Arrays must be equal |
| `assertJson` | `(xValue, xExpected [, cDesc])` | JSON objects/strings must be equal |
| `assertIsRegExFull` | `(cValue, cPattern [, cDesc])` | String must fully match regex |
| `assertIsRegExPartial` | `(cValue, cPattern [, cDesc])` | String must partially match regex |
| `assertIsContained` | `(cValue, cSearch [, cDesc])` | String must contain the search value |
| `assertOK` | `(cDesc)` | Registers a positive result (always passes) |
| `assertError` | `(cDesc)` | Registers a negative result (always fails) |
| `assertWarning` | `(cDesc)` | Registers a warning (no pass/fail impact) |

## Execution Lifecycle (Class-based)

```
Constructor (new)
  |
  +-- @OneTimeSetUp methods (once)
        |
        +-- @Setup methods (before each test)
        |     |
        |     +-- @Test method
        |     |
        |     +-- @TearDown methods (after each test)
        |
        +-- @Setup methods (before each test)
        |     |
        |     +-- @Test method
        |     |
        |     +-- @TearDown methods (after each test)
        |
        +-- @OneTimeTearDown methods (once)
```

## Test Execution

### Via REST API (programmatic)

Tests can be discovered and executed using ProBat's REST API or through the main runner. See the official `tlpp-probat-samples` repository for script-based execution examples.

### Via VSCode Extension

TOTVS provides a VSCode extension for ProBat that integrates test discovery and execution directly into the editor.

## References

- `patterns-unit-tests.md` - Templates and patterns for writing ProBat tests
- [Official samples](https://github.com/totvs/tlpp-probat-samples) - TOTVS official ProBat examples repository
- [TDN ProBat](https://tdn.totvs.com/display/tec/PROBAT) - Official documentation on TOTVS Developer Network
- [TDN Asserts](https://tdn.totvs.com/display/tec/d+-+Asserts) - Assertion functions reference
