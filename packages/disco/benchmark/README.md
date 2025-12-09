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

Run the benchmarks to establish baseline performance on your system. Results will vary based on:
- CPU performance
- Available memory
- Flutter version
- Dart VM optimizations

## Contributing

When adding new features to the provider system:
1. Add relevant benchmark scenarios
2. Run benchmarks before and after changes
3. Document any significant performance changes
4. Consider adding stress tests for edge cases
