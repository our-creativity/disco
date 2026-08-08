# Provider Benchmark Results

**Date**: 2026-08-08 19:46:29 UTC

## Results

| Benchmark | Time (ms) |
|-----------|-----------|
| Create 100 simple eager providers | 163 |
| Create 100 simple lazy providers | 19 |
| Create 50 providers with dependencies | 16 |
| Retrieve 100 lazy provider values | 0 |
| Create 100 ArgProviders | 18 |
| Access 100 providers in nested scopes | 8 |
| Complex dependency chain (30 providers) | 18 |
| Mixed lazy and eager (100 total) | 7 |
| ArgProviders with dependencies (50) | 19 |
| Large scale (500 providers) | 7 |
| Deep dependency chain (100 levels) | 18 |
| Wide dependency tree (100 dependents) | 20 |
| Multiple nested scopes (5 levels) | 20 |
