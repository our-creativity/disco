# Provider Performance Benchmarks

This directory contains comprehensive benchmarks for testing provider performance across various scenarios.

## Running the Benchmarks

To run all benchmarks:

```bash
cd packages/disco
flutter test benchmark/provider_benchmark.dart
```

## Benchmark Scenarios

### Basic Performance Tests

1. **Create 100 simple eager providers** - Tests initialization overhead for non-lazy providers
2. **Create 100 simple lazy providers** - Tests registration overhead without initialization
3. **Retrieve 100 lazy provider values** - Tests lazy initialization performance
4. **Create 100 ArgProviders** - Tests performance of argumented providers

### Dependency Tests

1. **Create 50 providers with dependencies** - Tests chain dependency resolution
2. **Complex dependency chain with 30 providers** - Tests multi-level dependency trees
3. **ArgProviders with dependencies** - Tests ArgProviders that depend on other providers

### Scope Tests

1. **Access providers in nested scopes** - Tests performance across scope boundaries
2. **Multiple nested scopes (5 levels)** - Tests deep scope nesting

### Stress Tests

1. **Deep dependency chain (100 levels)** - Maximum depth dependency testing
2. **Wide dependency tree (base + 100 dependents)** - Maximum breadth testing
3. **Large scale - 500 providers** - Tests scalability

## Expected Performance Characteristics

### Time Complexity Analysis

- **Provider registration**: O(n) where n is the number of providers
- **Provider lookup**: O(1) using HashMap
- **Duplicate detection**: O(n) using Set for uniqueness checks
- **Forward reference detection**: O(1) using reverse index map

### Optimization Details

#### 1. Duplicate Detection (Implemented)
- **Before**: O(n²) using List.contains()
- **After**: O(n) using Set.add() for O(1) membership test
- **Impact**: Significant for large provider lists (100+ providers)

#### 2. Forward Reference Detection (Implemented)
- **Before**: O(n) using firstWhere() on error
- **After**: O(1) using reverse index HashMap
- **Impact**: Only affects error cases, but provides better user experience

#### 3. Single-Pass Validation (Implemented)
- **Before**: Two separate loops for Provider and ArgProvider validation
- **After**: Combined into single loop
- **Impact**: Reduces iteration overhead by 50%

## Performance Tips

1. **Use lazy providers** when possible to defer initialization cost
2. **Order providers** with dependencies after their dependents
3. **Minimize deep nesting** of provider scopes when possible
4. **Use eager providers** only when values are needed at initialization

## Baseline Results

### Latest Benchmark Results

The table below shows the most recent benchmark results from the CI pipeline. Results will vary based on:
- CPU performance
- Available memory
- Flutter version
- Dart VM optimizations

| Benchmark | Time (ms) | Description |
|-----------|-----------|-------------|
| Create 100 simple eager providers | _See CI_ | Non-lazy provider initialization |
| Create 100 simple lazy providers | _See CI_ | Lazy provider registration only |
| Create 50 providers with dependencies | _See CI_ | Chain dependency resolution |
| Retrieve 100 lazy provider values | _See CI_ | Lazy initialization on access |
| Create 100 ArgProviders | _See CI_ | Argumented provider performance |
| Access 100 providers in nested scopes | _See CI_ | Cross-scope lookup performance |
| Complex dependency chain (30 providers) | _See CI_ | Multi-level dependency trees |
| Mixed lazy and eager (100 total) | _See CI_ | 50/50 split performance |
| ArgProviders with dependencies (50) | _See CI_ | ArgProvider dependency resolution |
| Large scale (500 providers) | _See CI_ | Scalability test |
| Deep dependency chain (100 levels) | _See CI_ | Maximum depth stress test |
| Wide dependency tree (100 dependents) | _See CI_ | Maximum breadth stress test |
| Multiple nested scopes (5 levels) | _See CI_ | Deep nesting performance |

> **Note**: Benchmark results are automatically updated by the CI pipeline on each PR and push to main/dev branches.
> View the latest results in the workflow artifacts or PR comments.

### Running Benchmarks Locally

To get baseline numbers on your local machine:

```bash
cd packages/disco
flutter test benchmark/provider_benchmark.dart
```

Compare your results with the CI benchmarks to understand performance on different hardware.

## Automated Benchmarking

A GitHub Actions workflow (`benchmark.yaml`) automatically runs benchmarks on:
- Every pull request that modifies provider code
- Pushes to `main` and `dev` branches
- Manual workflow dispatch

The workflow:
1. Runs all benchmark tests
2. Generates a markdown table with results
3. Posts results as a PR comment (for pull requests)
4. Uploads results as an artifact

### Comparing Performance Between PRs

1. Check the PR comment for benchmark results
2. Compare with previous PR or main branch results
3. Look for regressions (>10% slower) or improvements (>10% faster)
4. Investigate significant changes by profiling specific benchmarks

## Contributing

When adding new features to the provider system:
1. Add relevant benchmark scenarios
2. Run benchmarks before and after changes
3. Document any significant performance changes
4. Consider adding stress tests for edge cases
