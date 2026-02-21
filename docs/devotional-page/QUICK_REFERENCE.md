# LiveIT SvelteKit — Quick Reference

> Ringkasan singkat untuk navigasi codebase dengan cepat.
> Untuk penjelasan mendalam, baca `CODEBASE_DEEP_DIVE.md`.

---

## 🗂️ Struktur Project

```text
src/
├── lib/                    # $lib alias — reusable code
│   ├── api.ts              # Axios instance + auth interceptor
│   ├── theme.ts            # Dark/light theme store
│   ├── contracts/          # TypeScript types (mirrors backend)
│   └── components/         # Reusable Svelte components
│
└── routes/                 # File-based routing
    ├── +layout.svelte      # Root layout (theme init)
    ├── +page.svelte        # / — redirects to /login or /articles
    ├── login/+page.svelte  # /login
    └── (app)/              # Route group (auth required)
        ├── +layout.svelte  # App shell (sidebar, auth check)
        └── articles/
            ├── +page.svelte        # /articles (list)
            ├── create/+page.svelte # /articles/create
            └── [id]/+page.svelte   # /articles/:id (edit)
```

---

## 🔧 Svelte 5 Runes (vs React)

| Svelte 5            | React Equivalent      | Example                              |
| ------------------- | --------------------- | ------------------------------------ |
| `let x = $state(0)` | `useState(0)`         | `let count = $state(0); count++;`    |
| `$derived(expr)`    | `useMemo(() => expr)` | `const total = $derived(a + b);`     |
| `$effect(() => {})` | `useEffect(() => {})` | `$effect(() => { fetch(id); });`     |
| `$props()`          | props parameter       | `let { name } = $props();`           |
| `$bindable()`       | n/a                   | `let { value = $bindable('') } = $props();` |

---

## 🔗 Backend Integration

**API Base**: `VITE_API_URL` env var atau `/api` (Vite proxy)

**Auth Flow**:

```text
Login → POST /auth/login → Store token in localStorage → Redirect to /articles
```

**API Call Pattern**:

```typescript
import { api } from '$lib/api';
import type { Article } from '$lib/contracts/articles';

const res = await api.get<Article>('/cms/articles/123');
const article = res.data;
```

**Endpoints yang Dipakai**:

| Method | Endpoint                    | Purpose           |
| ------ | --------------------------- | ----------------- |
| POST   | `/auth/login`               | Login             |
| GET    | `/cms/articles`             | List articles     |
| GET    | `/cms/articles/:id`         | Get single        |
| POST   | `/articles`                 | Create            |
| PUT    | `/articles/:id`             | Update            |
| POST   | `/articles/:id/publish`     | Publish           |
| POST   | `/articles/:id/unpublish`   | Unpublish         |
| POST   | `/articles/upload-asset`    | Upload image/video|

---

## 📄 Template Syntax Cheat Sheet

```svelte
<!-- Output variable -->
<p>{name}</p>

<!-- Conditional -->
{#if isLoading}
  <Spinner />
{:else if error}
  <Error />
{:else}
  <Content />
{/if}

<!-- Loop -->
{#each items as item (item.id)}
  <li>{item.name}</li>
{/each}

<!-- Two-way binding -->
<input bind:value={email} />

<!-- Event handler -->
<button onclick={handleClick}>Click</button>
<form onsubmit={handleSubmit}>...</form>

<!-- Conditional class -->
<div class:active={isActive}>...</div>

<!-- Render children (in layout) -->
{@render children()}
```

---

## 📦 Important Imports

```typescript
// SvelteKit navigation
import { goto } from '$app/navigation';
import { page } from '$app/stores';        // $page.params.id
import { browser } from '$app/environment';
import { resolve } from '$app/paths';

// Svelte lifecycle
import { onMount, onDestroy } from 'svelte';

// Our lib
import { api } from '$lib/api';
import { theme, toggleTheme } from '$lib/theme';
import type { Article } from '$lib/contracts/articles';
```

---

## 🎯 Common Tasks

### Fetch data on page load

```svelte
<script lang="ts">
  import { onMount } from 'svelte';
  import { api } from '$lib/api';

  let data = $state<Item[]>([]);
  let isLoading = $state(true);

  onMount(async () => {
    const res = await api.get('/items');
    data = res.data;
    isLoading = false;
  });
</script>
```

### React to param change

```svelte
<script lang="ts">
  import { page } from '$app/stores';

  const id = $derived($page.params.id);

  $effect(() => {
    if (id) fetchItem(id);
  });
</script>
```

### Submit form

```svelte
<script lang="ts">
  let email = $state('');
  let isSubmitting = $state(false);

  async function handleSubmit(e: Event) {
    e.preventDefault();
    isSubmitting = true;
    await api.post('/submit', { email });
    isSubmitting = false;
  }
</script>

<form onsubmit={handleSubmit}>
  <input bind:value={email} />
  <button disabled={isSubmitting}>Submit</button>
</form>
```

### Redirect programmatically

```typescript
import { goto } from '$app/navigation';
import { resolve } from '$app/paths';

goto(resolve('/articles'));
```

---

## 🔐 Auth Check Pattern

```svelte
<!-- In (app)/+layout.svelte -->
<script lang="ts">
  import { goto } from '$app/navigation';
  import { onMount } from 'svelte';

  onMount(() => {
    const hasToken = !!localStorage.getItem('accessToken');
    if (!hasToken) goto('/login');
  });
</script>
```

---

## 🧩 Component Props Pattern

```svelte
<!-- Parent -->
<MyComponent name="John" bind:value={selectedValue} />

<!-- MyComponent.svelte -->
<script lang="ts">
  let {
    name,                        // Required prop
    value = $bindable('')        // Optional, two-way bindable
  } = $props();
</script>
```

---

## 🎨 Theme Toggle

```svelte
<script lang="ts">
  import { theme, toggleTheme } from '$lib/theme';
</script>

<button onclick={toggleTheme}>
  {$theme === 'dark' ? '☀️' : '🌙'}
</button>
```

---

## 📁 File Naming Convention

| File Pattern       | URL                | Purpose               |
| ------------------ | ------------------ | --------------------- |
| `+page.svelte`     | (matches folder)   | Page component        |
| `+layout.svelte`   | -                  | Wraps child routes    |
| `(folder)/`        | (no URL segment)   | Route grouping        |
| `[param]/`         | `:param`           | Dynamic route         |

---

## 🛠️ Dev Commands

```bash
npm run dev      # Start dev server (localhost:5173)
npm run build    # Production build
npm run check    # TypeScript check
npm run lint     # ESLint + Prettier
```

---

*Last updated: 2025-12-21*
