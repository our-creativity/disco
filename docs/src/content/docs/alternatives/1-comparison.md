---
title: Comparison
description: Challenges and limitations found in previous approaches
---

Disco was developed to overcome the challenges and limitations of the Flutter ecosystem in the context of dependency injection. Let's understand them together.

### Provider package

Provider, a well known package among the Flutter community, works by providing a value of some type into the widget tree (the descendants of the relative `ProviderScope` where the value was provided), and injecting it into the tree by solely specifying its type, e.g. `context.get<SomeClass>()`. This approach has had some drawbacks, mainly:

- Shadowing: providers with the same type are shadowed by the nearest one.
  - Solutions include using a wrapper type or specifying an ID.
    - Wrapper types are a good approach, but they introduce a lot of verbosity and can hide the intent of the providers.
    - The IDs are usually strings, which are very error prone. This is especially noticeable when refactoring.
- Not compile-time safe: when injecting a type, deducing if a provider even exists for that type implies inspecting the codebase. Similarly, when a provider is removed but not its type — which means no wrapper type was used — this does not result in a static error; thus, the IDE cannot detect invalid provider injections.
  - Even worse than invalid provider injections are injections of the wrong provider with the same type (i.e. after the removal of some provider, its unaltered provider injections result in another provider (with the same type), provided higher in the widget tree, being found and injected).
  - Reported errors have information in the stack trace that is only about the filepath and line of the injection and the type that is not found. There is no concept of unique provider instance used as ID. So this might result in some debugging if no wrapper type or additional ID was used.

### Global State Management Approaches

Due to the limitations mentioned earlier, the Flutter ecosystem saw the emergence of multiple global state management packages. These packages address issues like compile-time safety and shadowing, while also separating business logic from UI. However, they introduce new challenges:

- **Circular dependencies**  
- **Local-state-like logic** that doesn’t behave exactly like real local state  
  - This complicates logic, especially for beginners
  - Sometimes it feels like you’re fighting against the framework
- **Code generation** in some packages  
  - It should not be necessary  
  - Creates a high learning curve for new developers 

## Inspirations and Key Features

Disco is inspired by the approaches mentioned above, particularly:

- **Scoping from Provider**  
  - It fosters synergy with the widget tree.
  
- **Safety from Riverpod**  
  - Providers are injected via their instance, acting as an identifier, rather than by type.

- **Injecting observables/signals directly**  
  - Allows for injecting the observables/signals themselves, enabling loose coupling with third-party state management solutions.